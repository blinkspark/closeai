# Message Collection 迁移说明

## 概述

本次更新将 `Message` 从 `Session` 的嵌入式结构改为独立的 Isar Collection，这样可以提供更好的性能和更灵活的查询能力。

## 主要变更

### 1. 模型变更

#### 之前的结构 (lib/models/session.dart)
```dart
@Collection()
class Session {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  List<Message> messages = [];  // 嵌入式消息列表
  DateTime createTime = DateTime.now();
  DateTime updateTime = DateTime.now();
}

@embedded
class Message {
  late String role;
  late String content;
  DateTime timestamp = DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}
```

#### 现在的结构

**lib/models/session.dart**
```dart
@Collection()
class Session {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  DateTime createTime = DateTime.now();
  DateTime updateTime = DateTime.now();
  
  // 通过反向链接获取消息
  @Backlink(to: 'session')
  final messages = IsarLinks<Message>();
}
```

**lib/models/message.dart** (新文件)
```dart
@Collection()
class Message {
  Id id = Isar.autoIncrement;
  late String role;
  late String content;
  DateTime timestamp = DateTime.now();
  
  // 关联到Session的链接
  final session = IsarLink<Session>();

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}
```

### 2. 控制器变更

#### 新增 MessageController (lib/controllers/message_controller.dart)
- `getMessagesBySessionId(int sessionId)` - 根据会话ID获取消息
- `createMessage()` - 创建新消息
- `updateMessage()` - 更新消息
- `deleteMessage()` - 删除消息
- `deleteMessagesBySessionId()` - 删除会话的所有消息
- `getMessageCount()` - 获取消息总数
- `getMessageCountBySessionId()` - 获取特定会话的消息数

#### SessionController 更新
- 使用 `MessageController` 来管理消息操作
- 简化了消息相关的数据库操作
- 更好的关注点分离

### 3. 数据库迁移

#### 迁移工具 (lib/utils/database_migration.dart)
- `migrateMessagesToCollection()` - 迁移消息到新结构
- `clearAllData()` - 清除所有数据
- `needsMigration()` - 检查是否需要迁移

#### 自动迁移
应用启动时会自动检查是否需要迁移，并在必要时执行迁移过程。

### 4. 主要优势

1. **性能提升**
   - 独立的 Message Collection 允许更高效的查询
   - 可以对消息进行索引优化
   - 减少了加载会话时的内存占用

2. **更好的扩展性**
   - 可以为消息添加更多属性而不影响会话结构
   - 支持更复杂的消息查询和过滤
   - 便于实现消息搜索功能

3. **数据完整性**
   - 通过 Isar 的链接机制确保数据一致性
   - 自动处理级联删除

4. **代码组织**
   - 更清晰的关注点分离
   - 专门的 MessageController 处理消息逻辑
   - 更容易测试和维护

## 使用示例

### 创建消息
```dart
final messageController = Get.find<MessageController>();
final session = Get.find<SessionController>().sessions[0].value;

final message = await messageController.createMessage(
  role: MessageRole.user,
  content: '你好',
  session: session,
);
```

### 获取会话消息
```dart
final messages = await messageController.getMessagesBySessionId(sessionId);
```

### 删除会话的所有消息
```dart
await messageController.deleteMessagesBySessionId(sessionId);
```

## 注意事项

1. **数据兼容性**: 由于结构变更，旧的嵌入式消息数据可能无法直接访问
2. **迁移建议**: 如果遇到数据问题，建议清除应用数据重新开始
3. **测试**: 建议在生产环境使用前进行充分测试

## 测试

运行消息相关测试：
```bash
flutter test test/message_test.dart
```

## 文件清单

### 新增文件
- `lib/models/message.dart` - Message 模型
- `lib/controllers/message_controller.dart` - Message 控制器
- `lib/utils/database_migration.dart` - 数据库迁移工具
- `test/message_test.dart` - Message 测试

### 修改文件
- `lib/models/session.dart` - 移除嵌入式 Message
- `lib/controllers/session_controller.dart` - 使用 MessageController
- `lib/main.dart` - 添加 MessageSchema 和迁移逻辑
- `lib/pages/chat_page/chat_panel.dart` - 更新导入