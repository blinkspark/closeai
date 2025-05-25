import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/message.dart';
import '../models/session.dart';

class ChatController extends GetxController {
  final Isar isar = Get.find();

  // 根据会话ID获取消息列表
  Future<List<Message>> getMessagesBySessionId(int sessionId) async {
    return await isar.messages
        .filter()
        .session((q) => q.idEqualTo(sessionId))
        .sortByTimestamp()
        .findAll();
  }

  // 创建新消息
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

  // 更新消息
  Future<void> updateMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
    });
  }

  // 删除消息
  Future<void> deleteMessage(int messageId) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(messageId);
    });
  }

  // 删除会话的所有消息
  Future<void> deleteMessagesBySessionId(int sessionId) async {
    final messages = await getMessagesBySessionId(sessionId);
    await isar.writeTxn(() async {
      for (final message in messages) {
        await isar.messages.delete(message.id);
      }
    });
  }

  // 获取消息总数
  Future<int> getMessageCount() async {
    return await isar.messages.count();
  }

  // 获取特定会话的消息总数
  Future<int> getMessageCountBySessionId(int sessionId) async {
    return await isar.messages
        .filter()
        .session((q) => q.idEqualTo(sessionId))
        .count();
  }
}