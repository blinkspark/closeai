import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/message.dart';
import '../models/session.dart';
import 'message_service.dart';

/// 消息服务的具体实现
class MessageServiceImpl implements MessageService {
  final Isar isar = Get.find();

  @override
  Future<List<Message>> getMessagesBySessionId(int sessionId) async {
    return await isar.messages
        .filter()
        .session((q) => q.idEqualTo(sessionId))
        .sortByTimestamp()
        .findAll();
  }

  @override
  Future<Message> createMessage({
    required String role,
    required String content,
    required Session session,
  }) async {
    final message = Message()
      ..role = role
      ..content = content
      ..session.value = session;

    await isar.writeTxn(() async {
      await isar.messages.put(message);
      await message.session.save();
    });

    return message;
  }

  @override
  Future<void> updateMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
    });
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(messageId);
    });
  }

  @override
  Future<void> deleteMessagesBySessionId(int sessionId) async {
    final messages = await getMessagesBySessionId(sessionId);
    await isar.writeTxn(() async {
      for (final message in messages) {
        await isar.messages.delete(message.id);
      }
    });
  }

  @override
  Future<int> getMessageCount() async {
    return await isar.messages.count();
  }

  @override
  Future<int> getMessageCountBySessionId(int sessionId) async {
    return await isar.messages
        .filter()
        .session((q) => q.idEqualTo(sessionId))
        .count();
  }
}