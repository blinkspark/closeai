# 持久化功能使用指南

## 功能概述

我们已经成功实现了以下持久化功能：

### 1. 搜索功能状态持久化
- **功能**：记住搜索工具是否启用的状态
- **实现**：已经存在于 `AppStateController.isToolsEnabled`
- **存储位置**：`config.json` 文件

### 2. 模型选择持久化（新增）
- **功能**：记住用户最后选择的 AI 模型
- **实现**：新增于 `AppStateController.selectedModelId`
- **存储位置**：`config.json` 文件

## 如何测试

### 测试步骤：

1. **启动应用程序**
   ```bash
   flutter run -d windows
   ```

2. **测试搜索功能持久化**
   - 在应用中启用搜索工具
   - 关闭应用程序
   - 重新启动应用程序
   - 验证搜索工具状态是否保持启用

3. **测试模型选择持久化**
   - 在应用中选择一个特定的 AI 模型（例如：GPT-4、Claude 等）
   - 关闭应用程序
   - 重新启动应用程序
   - 验证之前选择的模型是否仍然被选中

### 配置文件位置

配置文件存储在系统的应用支持目录中：
- **Windows**: `%APPDATA%\com.example\closeai\config.json`
- **文件格式**:
  ```json
  {
    "themeMode": 0,
    "isToolsEnabled": true,
    "selectedModelId": "gpt-4"
  }
  ```

## 技术实现详情

### 修改的文件：

1. **AppStateController** (`lib/controllers/app_state_controller.dart`)
   - 添加了 `selectedModelId` 字段
   - 更新了 `toJson()` 和 `fromJson()` 方法
   - 添加了 `setSelectedModelId()` 方法

2. **ModelController** (`lib/controllers/model_controller.dart`)
   - 添加了对 `AppStateController` 的依赖
   - 在 `loadModels()` 中添加了 `_restoreSelectedModel()` 调用
   - 在 `selectModel()` 中添加了持久化调用
   - 实现了 `_restoreSelectedModel()` 方法来恢复保存的模型

### 工作流程：

1. **应用启动时**：
   - `AppStateController.loadConfig()` 从 `config.json` 读取配置
   - `ModelController.loadModels()` 加载所有模型
   - `ModelController._restoreSelectedModel()` 根据保存的 `selectedModelId` 恢复选择

2. **用户选择模型时**：
   - `ModelController.selectModel()` 被调用
   - 更新 `selectedModel.value`
   - 调用 `AppStateController.setSelectedModelId()` 保存到配置
   - 自动保存到 `config.json` 文件

3. **搜索功能切换时**：
   - `AppStateController.setToolsEnabled()` 被调用
   - 自动保存到 `config.json` 文件

## 注意事项

- 配置文件会在首次设置时自动创建
- 如果配置文件损坏，应用会使用默认值并重新创建文件
- 配置更改会立即保存，无需手动保存操作
- 支持向后兼容，旧版本的配置文件仍可正常工作

## 故障排除

如果持久化功能不工作：

1. 检查应用是否有写入权限
2. 查看配置文件是否存在且格式正确
3. 检查控制台是否有相关错误信息
4. 可以删除配置文件让应用重新创建
