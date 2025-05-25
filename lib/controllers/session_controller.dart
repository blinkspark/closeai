import 'package:closeai/defs.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../clients/openai.dart';
import '../models/session.dart';

class SessionController extends GetxController {
  final Isar isar = Get.find();
  final sessions = <Rx<Session>>[].obs;
  final index = 0.obs;
  final editingTitle = false.obs;
  final messages = <Message>[].obs;
  final sendingMessage = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSessions().then((_) {
      if (sessions.isNotEmpty) {
        loadMessages();
      }
    });
  }

  void setIndex(int idx) {
    index.value = idx;
    editingTitle.value = false;
    loadMessages();
  }

  Future<void> loadMessages() async {
    messages.clear();
    if (sessions.isNotEmpty) {
      messages.addAll(sessions[index.value].value.messages);
    }
  }

  Future<void> sendMessage(Message message) async {
    sendingMessage.value = true;
    final OpenAI openai = Get.find();
    sessions[index.value].value.messages.add(message);
    messages.add(message);
    final jsonMessages = messages.map((e) => e.toJson()).toList();
    final response = await openai.chat.completions.create(
      model: 'meta-llama/llama-3.3-8b-instruct:free',
      messages: jsonMessages,
    );
    final responseMessage =
        Message()
          ..role = MessageRole.assistant
          ..content = response['choices'][0]['message']['content'];
    sessions[index.value].value.messages.add(responseMessage);
    messages.add(responseMessage);
    await updateSession(sessions[index.value].value);
    sendingMessage.value = false;
  }

  Future<void> loadSessions() async {
    this.sessions.clear();
    final sessions = await isar.sessions.where().findAll();
    for (final session in sessions) {
      session.messages = List<Message>.from(session.messages);
    }
    this.sessions.addAll(sessions.map((e) => e.obs));
  }

  Future<void> newSession(String title) async {
    final session = Session()..title = title;
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
      sessions.add(session.obs);
      setIndex(sessions.length - 1);
    });
  }

  Future<void> updateSession(Session session) async {
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
    });
  }

  Future<void> removeSession(int idx) async {
    await isar.writeTxn(() async {
      final id = sessions[idx].value.id;
      await isar.sessions.delete(id);
      sessions.removeAt(idx);
      if (idx <= index.value) {
        index.value = index.value > 0 ? index.value - 1 : 0;
      }
      loadMessages();
    });
  }

  Future<void> reset() async {
    await loadSessions();
    await loadMessages();
  }
}
