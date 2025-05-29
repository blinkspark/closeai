/// 工具状态管理接口
abstract class ToolStateManager {
  bool get isToolsEnabled;
  void setToolsEnabled(bool enabled);
  bool get isToolsAvailable;
  String get toolsStatusDescription;
}

/// 系统提示词管理接口
abstract class SystemPromptManager {
  String getCurrentPromptContent();
}
