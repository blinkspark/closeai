import 'package:isar/isar.dart';
import '../models/session.dart';
import '../models/message.dart';

class DatabaseMigration {
  static Future<void> migrateMessagesToCollection(Isar isar) async {
    // 这个方法用于将旧的嵌入式消息迁移到新的独立Collection
    // 由于Isar的结构变化，旧数据可能无法直接访问
    // 建议在生产环境中谨慎使用，可能需要用户重新开始会话
    
    print('开始数据库迁移：将Message从嵌入式结构迁移到独立Collection');
    
    try {
      // 获取所有现有会话
      final sessions = await isar.sessions.where().findAll();
      
      if (sessions.isEmpty) {
        print('没有找到需要迁移的会话');
        return;
      }
      
      print('找到 ${sessions.length} 个会话需要检查');
      
      // 由于结构变化，旧的嵌入式消息可能无法访问
      // 这里我们只是确保新的关系结构正确设置
      await isar.writeTxn(() async {
        for (final session in sessions) {
          // 确保会话的反向链接正确初始化
          await session.messages.load();
        }
      });
      
      print('数据库迁移完成');
      
    } catch (e) {
      print('数据库迁移过程中出现错误: $e');
      print('建议清除应用数据重新开始');
    }
  }
  
  static Future<void> clearAllData(Isar isar) async {
    // 清除所有数据的方法，用于重新开始
    await isar.writeTxn(() async {
      await isar.messages.clear();
      await isar.sessions.clear();
    });
    print('所有数据已清除');
  }
  
  static Future<bool> needsMigration(Isar isar) async {
    // 检查是否需要迁移
    // 如果有会话但没有消息，可能需要迁移或清理
    final sessionCount = await isar.sessions.count();
    final messageCount = await isar.messages.count();
    
    return sessionCount > 0 && messageCount == 0;
  }
}