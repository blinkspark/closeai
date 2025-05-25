import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/session.dart';
import 'session_service.dart';

/// 会话服务的具体实现
class SessionServiceImpl implements SessionService {
  final Isar isar = Get.find();

  @override
  Future<List<Session>> loadSessions() async {
    return await isar.sessions.where().findAll();
  }

  @override
  Future<Session> createSession(String title) async {
    final session = Session()..title = title;
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
    });
    return session;
  }

  @override
  Future<void> updateSession(Session session) async {
    session.updateTime = DateTime.now();
    await isar.writeTxn(() async {
      await isar.sessions.put(session);
    });
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    await isar.writeTxn(() async {
      await isar.sessions.delete(sessionId);
    });
  }

  @override
  Future<int> getSessionCount() async {
    return await isar.sessions.count();
  }
}