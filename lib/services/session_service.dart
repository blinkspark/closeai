import '../models/session.dart';

/// 会话服务接口，定义会话相关操作
abstract class SessionService {
  /// 加载所有会话
  Future<List<Session>> loadSessions();
  
  /// 创建新会话
  Future<Session> createSession(String title);
  
  /// 更新会话
  Future<void> updateSession(Session session);
  
  /// 删除会话
  Future<void> deleteSession(int sessionId);
  
  /// 获取会话总数
  Future<int> getSessionCount();
}