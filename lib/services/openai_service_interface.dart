import '../models/function_call.dart';

/// OpenAI服务抽象接口
abstract class OpenAIServiceInterface {
  /// 检查是否已配置
  bool get isConfigured;
  
  /// 获取配置状态描述
  String get configurationStatus;
  
  /// 获取当前模型ID
  String? get currentModelId;
  
  /// 刷新客户端配置
  void refreshClient();
  
  /// 创建聊天完成请求（带工具支持）
  Future<Map<String, dynamic>?> createChatCompletionWithTools({
    required List<Map<String, dynamic>> messages,
    bool enableTools = false,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    bool? stream,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    bool? logProbs,
    Map<String, dynamic>? user,
  });
  
  /// 创建聊天完成请求（原有方法保持兼容）
  Future<Map<String, dynamic>?> createChatCompletion({
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    bool? stream,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    bool? logProbs,
    Map<String, dynamic>? user,
  });
  
  /// 创建流式聊天完成请求
  Stream<String> createChatCompletionStream({
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    bool? logProbs,
    Map<String, dynamic>? user,
  });
}
