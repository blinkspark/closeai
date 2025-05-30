/// 工具参数统一校验器
/// 支持为每个工具注册独立的参数校验函数，统一入口调用
library;

typedef ToolParamValidatorFunc = Map<String, String> Function(Map<String, dynamic> arguments);

class ToolParamValidator {
  static final Map<String, ToolParamValidatorFunc> _validators = {};

  /// 注册某个工具的参数校验器
  static void register(String toolName, ToolParamValidatorFunc validator) {
    _validators[toolName] = validator;
  }

  /// 校验工具参数，返回错误信息Map（key为参数名，value为错误描述）
  static Map<String, String> validate(String toolName, Map<String, dynamic> arguments) {
    if (!_validators.containsKey(toolName)) {
      return {'tool': '未知的工具: $toolName'};
    }
    return _validators[toolName]!(arguments);
  }

  /// 清空所有校验器（用于测试或重置）
  static void clear() {
    _validators.clear();
  }
}
