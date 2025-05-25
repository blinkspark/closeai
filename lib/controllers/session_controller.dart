import 'package:closeai/defs.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../clients/openai.dart';
import '../models/session.dart';
import '../models/message.dart';
import 'chat_controller.dart';

class SessionController extends GetxController {
  final Isar isar = Get.find();
  late final ChatController messageController;
  final sessions = <Rx<Session>>[].obs;
  final index = 0.obs;
  final editingTitle = false.obs;
  final messages = <Message>[].obs;
  final sendingMessage = false.obs;

  @override
  void onInit() {
    super.onInit();
    messageController = Get.find<ChatController>();
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
      final sessionId = sessions[index.value].value.id;
      final sessionMessages = await messageController.getMessagesBySessionId(sessionId);
      messages.addAll(sessionMessages);
    }
  }

  Future<void> sendMessage(Message message) async {
    sendingMessage.value = true;
    final OpenAI openai = Get.find();
    
    // 使用MessageController创建用户消息
    final userMessage = await messageController.createMessage(
      role: message.role,
      content: message.content,
      session: sessions[index.value].value,
    );
    
    messages.add(userMessage);
    
    final jsonMessages = messages.map((e) => e.toJson()).toList();
    final response = await openai.chat.completions.create(
      model: 'meta-llama/llama-3.3-8b-instruct:free',
      messages: jsonMessages,
    );
    
    // 使用MessageController创建助手回复
    final responseMessage = await messageController.createMessage(
      role: MessageRole.assistant,
      content: response['choices'][0]['message']['content'],
      session: sessions[index.value].value,
    );
    
    messages.add(responseMessage);
    await updateSession(sessions[index.value].value);
    sendingMessage.value = false;
  }

  Future<void> loadSessions() async {
    sessions.clear();
    final sessionList = await isar.sessions.where().findAll();
    sessions.addAll(sessionList.map((e) => e.obs));
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
    session.updateTime = DateTime.now();
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
    });
  }

  Future<void> removeSession(int idx) async {
    final sessionId = sessions[idx].value.id;
    
    // 使用MessageController删除该会话的所有消息
    await messageController.deleteMessagesBySessionId(sessionId);
    
    // 删除会话
    await isar.writeTxn(() async {
      await isar.sessions.delete(sessionId);
    });
    
    sessions.removeAt(idx);
    
    if (idx <= index.value) {
      index.value = index.value > 0 ? index.value - 1 : 0;
    }
    loadMessages();
  }

  Future<void> reset() async {
    await loadSessions();
    await loadMessages();
  }
}
