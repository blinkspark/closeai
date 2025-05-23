import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/session.dart';

class SessionController extends GetxController {
  final Isar isar = Get.find();
  final sessions = <Rx<Session>>[].obs;
  final index = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Future<void> loadSessions() async {
    final sessions = await isar.sessions.where().findAll();
    this.sessions.addAll(sessions.map((e) => e.obs));
  }

  Future<void> newSession(String title) async {
    final session = Session()..title = title;
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
      sessions.add(session.obs);
      index.value = sessions.length - 1;
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
    });
  }
}
