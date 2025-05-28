# 模块解耦改进方案

## 解耦前的问题

1. **直接依赖Get.find()**: 控制器和服务中大量使用`Get.find()`直接获取依赖
2. **循环依赖**: 某些控制器之间存在相互依赖
3. **硬编码的服务名称**: 直接引用具体的服务实现类
4. **缺乏抽象层**: 一些服务没有接口抽象

## 解耦后的架构

### 1. 依赖注入容器
- `DependencyContainer`: 抽象的依赖注入接口
- `GetXDependencyContainer`: GetX的具体实现
- 支持切换到其他DI框架

### 2. 服务接口抽象
- `OpenAIServiceInterface`: OpenAI服务抽象接口
- `SearchServiceInterface`: 搜索服务抽象接口
- `ToolStateManager`: 工具状态管理接口
- `SystemPromptManager`: 系统提示词管理接口

### 3. 适配器模式
- `AppStateToolAdapter`: 将AppStateController适配为ToolStateManager
- `SystemPromptAdapter`: 将SystemPromptController适配为SystemPromptManager

### 4. 解耦的控制器
- `ChatControllerNew`: 完全解耦的聊天控制器
- `SessionControllerNew`: 解耦的会话控制器

## 使用方式

### 替换现有的main.dart
```dart
// 使用新的main.dart
// 将 lib/main.dart 重命名为 lib/main_old.dart
// 将 lib/main_new.dart 重命名为 lib/main.dart
```

### 替换现有的控制器
```dart
// 在需要使用解耦版本的地方
import '../controllers/chat_controller_new.dart';
import '../controllers/session_controller_new.dart';

// 在页面中使用
final ChatController chatController = Get.find();
final SessionControllerNew sessionController = Get.find();
```

## 优势

### 1. 松耦合
- 控制器不直接依赖具体的服务实现
- 通过接口和依赖注入进行交互
- 更容易进行单元测试

### 2. 可扩展性
- 可以轻松替换数据存储实现
- 可以添加缓存、网络同步等功能
- 支持依赖注入和模拟测试

### 3. 可测试性
- 所有依赖都可以被模拟
- 接口使得单元测试更容易编写
- 减少了测试之间的相互影响

### 4. 代码复用
- 服务层可以被多个控制器复用
- 业务逻辑与UI逻辑分离
- 接口可以有多种实现

## 迁移建议

### 阶段1: 保持兼容性
- 保留原有的文件，创建新的解耦版本
- 逐步迁移各个模块到新架构
- 确保旧代码继续工作

### 阶段2: 逐步替换
- 替换关键模块（如ChatController）
- 更新相关的UI组件
- 进行充分的测试

### 阶段3: 完全迁移
- 删除旧版本的控制器
- 统一使用新的架构
- 清理未使用的代码

## 文件说明

### 新增文件
- `lib/core/dependency_injection.dart` - 依赖注入抽象
- `lib/interfaces/common_interfaces.dart` - 通用接口定义
- `lib/services/openai_service_interface.dart` - OpenAI服务接口
- `lib/services/search_service_interface.dart` - 搜索服务接口
- `lib/adapters/app_state_tool_adapter.dart` - 工具状态适配器
- `lib/adapters/system_prompt_adapter.dart` - 系统提示词适配器
- `lib/config/dependency_config.dart` - 依赖配置
- `lib/controllers/chat_controller_new.dart` - 解耦的聊天控制器
- `lib/controllers/session_controller_new.dart` - 解耦的会话控制器
- `lib/main_new.dart` - 解耦的主程序

### 修改的文件
- `lib/services/openai_service.dart` - 实现OpenAIServiceInterface
- `lib/services/zhipu_search_service.dart` - 实现SearchServiceInterface

这种架构提供了更好的模块化、可测试性和可维护性，同时保持了与现有代码的兼容性。
