import 'package:get/get.dart';

import '../clients/openai.dart';
import '../controllers/model_controller.dart';
import '../utils/app_logger.dart';
import 'zhipu_search_service.dart';
import 'tool_registry.dart';
import 'openai_service_interface.dart';
import 'tool_call_service.dart';
import 'response_utils.dart';
import 'message_history_utils.dart';

class OpenAIService extends GetxService implements OpenAIServiceInterface {
  OpenAI? _currentClient;
  late ZhipuSearchService _zhipuSearchService;
  late ToolCallService _toolCallService;
  
  @override
  void onInit() {
    super.onInit();
    _zhipuSearchService = Get.find<ZhipuSearchService>();
    _toolCallService = ToolCallService(_zhipuSearchService);
    ToolRegistry.registerAllTools();
  }
  
  /// 获取当前配置的OpenAI客户端
  OpenAI? get currentClient {
    if (_currentClient == null) {
      _initializeClient();
    }
    return _currentClient;
  }
  
  /// 根据当前选中的模型初始化客户端
  void _initializeClient() {
    final modelController = Get.find<ModelController>();
    final selectedModel = modelController.selectedModel.value;
    
    if (selectedModel != null && selectedModel.provider.value != null) {
      final provider = selectedModel.provider.value!;
      _currentClient = OpenAI(
        apiKey: provider.apiKey,
        baseUrl: provider.baseUrl ?? 'https://api.openai.com/v1',
      );      // OpenAI客户端初始化成功
    } else {
      // OpenAI客户端初始化失败: 模型或供应商为空
    }
  }
  
  /// 刷新客户端配置
  @override
  void refreshClient() {
    _currentClient = null;
    _initializeClient();
  }
  
  /// 获取当前选中的模型ID
  @override
  String? get currentModelId {
    final modelController = Get.find<ModelController>();
    return modelController.selectedModel.value?.modelId;
  }
  
  /// 检查是否已配置
  @override
  bool get isConfigured {
    final client = currentClient;
    final modelId = currentModelId;
    
    if (client == null || modelId == null) {
      return false;
    }
    
    // 检查API Key是否存在
    if (client.apiKey == null || client.apiKey!.isEmpty) {
      return false;
    }
    
    return true;
  }
  
  /// 获取配置状态信息
  @override
  String get configurationStatus {
    if (currentClient == null) {
      return '未找到OpenAI客户端配置';
    }
    
    if (currentModelId == null) {
      return '未选择模型';
    }
    
    if (currentClient!.apiKey == null || currentClient!.apiKey!.isEmpty) {
      return 'API Key未配置';
    }
    
    return '配置正常';
  }
  
  /// 发送聊天完成请求（带工具支持）
  @override
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
  }) async {
    if (!isConfigured) {
      throw Exception('OpenAI客户端未配置，请先设置模型和供应商');
    }
    List<Map<String, dynamic>>? tools;
    dynamic toolChoice;
    if (enableTools) {
      tools = ToolRegistry.getEnabledTools(enableWebSearch: true);
      toolChoice = tools.isNotEmpty ? 'auto' : null;
    }
    try {
      final response = await currentClient!.chat.completions.create(
        model: currentModelId!,
        messages: messages,
        tools: tools,
        toolChoice: toolChoice,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        n: n,
        stream: stream,
        stop: stop,
        presencePenalty: presencePenalty,
        frequencyPenalty: frequencyPenalty,
        logProbs: logProbs,
        user: user,
      );
      final choice = response['choices']?[0];
      final message = choice?['message'];
      final toolCalls = message?['tool_calls'];
      if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
        final finalResponse = await _toolCallService.handleToolCalls(
          response: response,
          originalMessages: messages,
          executeToolCall: _toolCallService.executeToolCall,
          finalCompletion: (updatedMessages) async {
            return await currentClient!.chat.completions.create(
              model: currentModelId!,
              messages: updatedMessages,
              temperature: 0.7,
            );
          },
        );
        if (finalResponse['choices'] != null && finalResponse['choices'].isNotEmpty) {
          final finalChoice = finalResponse['choices'][0];
          final finalMessage = finalChoice['message'];
          finalMessage['original_tool_calls'] = toolCalls;
        }
        return finalResponse;
      }
      return response;
    } catch (e) {
      throw Exception('API调用错误: $e');
    }
  }

  /// 发送聊天完成请求（原有方法保持兼容）
  @override
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
  }) async {
    if (!isConfigured) {
      throw Exception('OpenAI客户端未配置，请先设置模型和供应商');
    }
    try {
      return await currentClient!.chat.completions.create(
        model: currentModelId!,
        messages: messages,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        n: n,
        stream: stream,
        stop: stop,
        presencePenalty: presencePenalty,
        frequencyPenalty: frequencyPenalty,
        logProbs: logProbs,
        user: user,
      );    } catch (e) {
      throw Exception('API调用错误: $e');
    }
  }  /// 发送流式聊天完成请求
  @override
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
    bool enableTools = false,
  }) async* {
    if (!isConfigured) {
      throw Exception('OpenAI客户端未配置，请先设置模型和供应商');
    }
    try {
      List<Map<String, dynamic>>? tools;
      dynamic toolChoice;
      if (enableTools) {
        tools = ToolRegistry.getEnabledTools(enableWebSearch: true);
        toolChoice = tools.isNotEmpty ? 'auto' : null;
      }
      final stream = currentClient!.chat.completions.createStream(
        model: currentModelId!,
        messages: messages,
        tools: tools,
        toolChoice: toolChoice,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        n: n,
        stop: stop,
        presencePenalty: presencePenalty,
        frequencyPenalty: frequencyPenalty,
        logProbs: logProbs,
        user: user,
      );
      List<String> allData = [];
      bool hasToolCalls = false;
      await for (final data in stream) {
        allData.add(data);
        if (data.startsWith('{') && data.contains('"tool_calls"')) {
          hasToolCalls = true;
        } else if (!hasToolCalls) {
          yield data;
        }
      }
      if (hasToolCalls) {
        AppLogger.d('检测到工具调用，开始处理...');
        Map<String, dynamic> toolResponse;
        try {
          toolResponse = ResponseUtils.reconstructToolCallsFromChunks(allData);
        } catch (e) {
          throw Exception('解析工具调用失败: $e');
        }
        final newMessages = await MessageHistoryUtils.buildMessagesWithToolResults(
          originalMessages: messages,
          toolResponse: toolResponse,
          executeToolCall: _toolCallService.executeToolCall,
        );
        AppLogger.d('工具调用完成，重新请求AI回复...');
        final finalStream = currentClient!.chat.completions.createStream(
          model: currentModelId!,
          messages: newMessages,
          maxTokens: maxTokens,
          temperature: temperature,
          topP: topP,
          n: n,
          stop: stop,
          presencePenalty: presencePenalty,
          frequencyPenalty: frequencyPenalty,
          logProbs: logProbs,
          user: user,
        );
        bool hasContent = false;
        await for (final chunk in finalStream) {
          if (chunk.trim().isNotEmpty) {
            hasContent = true;
            yield chunk;
          }
        }
        if (!hasContent) {
          yield '已完成搜索，但AI未返回分析内容。请尝试重新提问。';
        }
      }
    } catch (e) {
      throw Exception('流式API调用错误: $e');
    }
  }
  
  /// 获取可用模型列表
  Future<Map<String, dynamic>?> listModels() async {
    if (currentClient == null) {
      throw Exception('OpenAI客户端未配置，请先设置供应商');
    }
    
    return await currentClient!.listModels();
  }
}