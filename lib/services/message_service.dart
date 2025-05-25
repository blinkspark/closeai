import '../models/message.dart';
import '../models/session.dart';

/// 消息服务接口，定义消息相关操作
abstract class MessageService {
  /// 根据会话ID获取消息列表
  Future<List<Message>> getMessagesBySessionId(int sessionId);
  
  /// 创建新消息
  Future<Message> createMessage({
    required String role,
    required String content,
    required Session session,
  });
  
  /// 更新消息
  Future<void> updateMessage(Message message);
  
  /// 删除消息
  Future<void> deleteMessage(int messageId);
  
  /// 删除会话的所有消息
  Future<void> deleteMessagesBySessionId(int sessionId);
  
  /// 获取消息总数
  Future<int> getMessageCount();
  
  /// 获取特定会话的消息总数
  Future<int> getMessageCountBySessionId(int sessionId);
}