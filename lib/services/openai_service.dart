import 'package:get/get.dart';
import 'dart:convert';

import '../clients/openai.dart';
import '../controllers/model_controller.dart';
import '../models/function_call.dart';
import 'zhipu_search_service.dart';
import 'tool_registry.dart';

class OpenAIService extends GetxService {
  OpenAI? _currentClient;
  late ZhipuSearchService _zhipuSearchService;
  
  @override
  void onInit() {
    super.onInit();
    _zhipuSearchService = Get.find<ZhipuSearchService>();
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
      );
    }
  }
  
  /// 刷新客户端配置
  void refreshClient() {
    _currentClient = null;
    _initializeClient();
  }
  
  /// 获取当前选中的模型ID
  String? get currentModelId {
    final modelController = Get.find<ModelController>();
    return modelController.selectedModel.value?.modelId;
  }
  
  /// 检查是否已配置
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
      print('启用工具调用，可用工具数量: ${tools.length}');
    }
    
    try {
      print('发送请求到: ${currentClient!.baseUrl}');
      print('使用模型: $currentModelId');
      print('消息数量: ${messages.length}');
      print('工具启用: $enableTools');
      
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
      
      // 检查是否有工具调用
      final choice = response['choices']?[0];
      final message = choice?['message'];
      final toolCalls = message?['tool_calls'];
      
      if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
        print('检测到工具调用，数量: ${toolCalls.length}');
        return await _handleToolCalls(response, messages);
      }
      
      return response;
    } catch (e) {
      print('API调用错误: $e');
      rethrow;
    }
  }

  /// 发送聊天完成请求（原有方法保持兼容）
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
      // 添加调试信息
      print('发送请求到: ${currentClient!.baseUrl}');
      print('使用模型: $currentModelId');
      print('API Key: ${currentClient!.apiKey?.substring(0, 10)}...');
      print('消息数量: ${messages.length}');
      
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
      );
    } catch (e) {
      print('API调用错误: $e');
      rethrow;
    }
  }

  /// 发送流式聊天完成请求
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
  }) async* {
    if (!isConfigured) {
      throw Exception('OpenAI客户端未配置，请先设置模型和供应商');
    }
    
    try {
      // 添加调试信息
      print('发送流式请求到: ${currentClient!.baseUrl}');
      print('使用模型: $currentModelId');
      print('API Key: ${currentClient!.apiKey?.substring(0, 10)}...');
      print('消息数量: ${messages.length}');
      
      yield* currentClient!.chat.completions.createStream(
        model: currentModelId!,
        messages: messages,
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
    } catch (e) {
      print('流式API调用错误: $e');
      rethrow;
    }
  }
  
  /// 获取可用模型列表
  Future<Map<String, dynamic>?> listModels() async {
    if (currentClient == null) {
      throw Exception('OpenAI客户端未配置，请先设置供应商');
    }
    
    return await currentClient!.listModels();
  }
  
  /// 处理工具调用
  Future<Map<String, dynamic>> _handleToolCalls(
    Map<String, dynamic> response,
    List<Map<String, dynamic>> originalMessages,
  ) async {
    final message = response['choices'][0]['message'];
    final toolCalls = message['tool_calls'] as List;
    
    print('处理工具调用: ${toolCalls.length} 个工具');
    
    // 添加助手消息到对话历史
    final updatedMessages = List<Map<String, dynamic>>.from(originalMessages);
    updatedMessages.add(message);
    
    // 执行每个工具调用
    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'];
      final functionName = toolCall['function']['name'];
      final arguments = toolCall['function']['arguments'];
      
      print('执行工具调用: $functionName');
      print('参数: $arguments');
      
      ToolResponse toolResponse;
      try {
        final result = await _executeToolCall(functionName, arguments);
        toolResponse = ToolResponse.success(
          toolCallId: toolCallId,
          content: result,
        );
        print('工具调用成功: ${result.length} 字符');
      } catch (e) {
        print('工具调用失败: $e');
        toolResponse = ToolResponse.error(
          toolCallId: toolCallId,
          error: e.toString(),
        );
      }
      
      // 添加工具结果到对话历史
      updatedMessages.add(toolResponse.toMessageJson());
    }
    
    print('重新调用API获取最终回答，消息数量: ${updatedMessages.length}');
    
    // 再次调用API获取最终回答
    return await currentClient!.chat.completions.create(
      model: currentModelId!,
      messages: updatedMessages,
      temperature: 0.7,
    );
  }
  
  /// 执行具体的工具调用
  Future<String> _executeToolCall(String functionName, String arguments) async {
    // 验证工具调用参数
    Map<String, dynamic> parsedArgs;
    try {
      parsedArgs = jsonDecode(arguments);
    } catch (e) {
      throw Exception('工具调用参数解析失败: $e');
    }
    
    final validationErrors = ToolRegistry.validateToolCall(functionName, parsedArgs);
    if (validationErrors.isNotEmpty) {
      throw Exception('工具调用参数验证失败: ${validationErrors.values.join(', ')}');
    }
    
    switch (functionName) {
      case 'zhipu_web_search':
        return await _executeZhipuSearch(parsedArgs);
      default:
        throw Exception('未知的工具: $functionName');
    }
  }
  
  /// 执行智谱搜索
  Future<String> _executeZhipuSearch(Map<String, dynamic> arguments) async {
    if (!_zhipuSearchService.isConfigured) {
      throw Exception('智谱AI搜索服务未配置，请先在设置中配置API Key');
    }
    
    try {
      final searchQuery = arguments['search_query'] as String;
      final searchEngine = arguments['search_engine'] as String? ?? 'search_std';
      final count = arguments['count'] as int? ?? 5;
      final searchRecencyFilter = arguments['search_recency_filter'] as String? ?? 'noLimit';
      
      print('执行智谱搜索: $searchQuery');
      
      final searchResponse = await _zhipuSearchService.webSearch(
        searchQuery: searchQuery,
        searchEngine: searchEngine,
        count: count,
        searchRecencyFilter: searchRecencyFilter,
      );
      
      final formattedResult = _zhipuSearchService.formatSearchResults(searchResponse);
      print('搜索完成，结果长度: ${formattedResult.length}');
      
      return formattedResult;
    } catch (e) {
      print('智谱搜索执行失败: $e');
      throw Exception('搜索失败: $e');
    }
  }
}