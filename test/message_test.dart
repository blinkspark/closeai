import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:closeai/models/session.dart';
import 'package:closeai/models/message.dart';
import 'package:closeai/controllers/message_controller.dart';
import 'package:closeai/defs.dart';
import 'package:get/get.dart';

void main() {
  group('Message Collection Tests', () {
    late Isar isar;
    late MessageController messageController;

    setUpAll(() async {
      // 初始化测试数据库
      isar = await Isar.open(
        [SessionSchema, MessageSchema],
        directory: '',
      );
      
      // 注册依赖
      Get.put(isar);
      messageController = MessageController();
    });

    tearDownAll(() async {
      await isar.close();
      Get.reset();
    });

    setUp(() async {
      // 清理测试数据
      await isar.writeTxn(() async {
        await isar.messages.clear();
        await isar.sessions.clear();
      });
    });

    test('应该能够创建Session和Message', () async {
      // 创建会话
      final session = Session()..title = '测试会话';
      await isar.writeTxn(() async {
        await isar.sessions.put(session);
      });

      // 创建消息
      final message = await messageController.createMessage(
        role: MessageRole.user,
        content: '你好',
        session: session,
      );

      expect(message.id, isNot(Isar.autoIncrement));
      expect(message.role, MessageRole.user);
      expect(message.content, '你好');
      expect(message.session.value?.id, session.id);
    });

    test('应该能够根据会话ID获取消息', () async {
      // 创建会话
      final session = Session()..title = '测试会话';
      await isar.writeTxn(() async {
        await isar.sessions.put(session);
      });

      // 创建多条消息
      await messageController.createMessage(
        role: MessageRole.user,
        content: '第一条消息',
        session: session,
      );
      
      await messageController.createMessage(
        role: MessageRole.assistant,
        content: '第二条消息',
        session: session,
      );

      // 获取消息
      final messages = await messageController.getMessagesBySessionId(session.id);
      
      expect(messages.length, 2);
      expect(messages[0].content, '第一条消息');
      expect(messages[1].content, '第二条消息');
    });

    test('应该能够删除会话的所有消息', () async {
      // 创建会话
      final session = Session()..title = '测试会话';
      await isar.writeTxn(() async {
        await isar.sessions.put(session);
      });

      // 创建消息
      await messageController.createMessage(
        role: MessageRole.user,
        content: '要被删除的消息',
        session: session,
      );

      // 验证消息存在
      var messages = await messageController.getMessagesBySessionId(session.id);
      expect(messages.length, 1);

      // 删除会话的所有消息
      await messageController.deleteMessagesBySessionId(session.id);

      // 验证消息已删除
      messages = await messageController.getMessagesBySessionId(session.id);
      expect(messages.length, 0);
    });

    test('应该能够统计消息数量', () async {
      // 创建会话
      final session = Session()..title = '测试会话';
      await isar.writeTxn(() async {
        await isar.sessions.put(session);
      });

      // 创建消息
      await messageController.createMessage(
        role: MessageRole.user,
        content: '消息1',
        session: session,
      );
      
      await messageController.createMessage(
        role: MessageRole.assistant,
        content: '消息2',
        session: session,
      );

      // 验证总数
      final totalCount = await messageController.getMessageCount();
      expect(totalCount, 2);

      // 验证会话消息数
      final sessionCount = await messageController.getMessageCountBySessionId(session.id);
      expect(sessionCount, 2);
    });

    test('Message的toJson方法应该正常工作', () {
      final message = Message()
        ..role = MessageRole.user
        ..content = '测试内容';

      final json = message.toJson();
      
      expect(json['role'], MessageRole.user);
      expect(json['content'], '测试内容');
    });
  });
}