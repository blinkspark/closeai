import 'package:get/get.dart';
import 'dart:convert';

import '../clients/openai.dart';
import '../controllers/model_controller.dart';
import '../models/function_call.dart';
import '../utils/app_logger.dart';
import 'zhipu_search_service.dart';
import 'tool_registry.dart';
import 'openai_service_interface.dart';

class OpenAIService extends GetxService implements OpenAIServiceInterface {
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
      
      // 检查是否有工具调用
      final choice = response['choices']?[0];
      final message = choice?['message'];
      final toolCalls = message?['tool_calls'];
        if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
        final finalResponse = await _handleToolCalls(response, messages);
        
        // 将工具调用信息添加到最终响应中，以便聊天控制器可以提取搜索信息
        if (finalResponse['choices'] != null && finalResponse['choices'].isNotEmpty) {
          final finalChoice = finalResponse['choices'][0];
          final finalMessage = finalChoice['message'];
          
          // 保留原始工具调用信息
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
    bool enableTools = false, // 新增参数，是否启用工具
  }) async* {
    if (!isConfigured) {
      throw Exception('OpenAI客户端未配置，请先设置模型和供应商');
    }
    
    try {
      // 1. 构造参数，支持工具
      List<Map<String, dynamic>>? tools;
      dynamic toolChoice;
      if (enableTools) {
        tools = ToolRegistry.getEnabledTools(enableWebSearch: true);
        toolChoice = tools.isNotEmpty ? 'auto' : null;
      }
      
      // 2. 直接调用流式接口，OpenAI客户端已经处理了工具调用检测
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
      
      // 3. 收集所有数据，检查是否有工具调用
      List<String> allData = [];
      bool hasToolCalls = false;
      
      await for (final data in stream) {
        allData.add(data);
        
        // 如果数据是JSON格式（工具调用），则收集所有数据后处理
        if (data.startsWith('{') && data.contains('"tool_calls"')) {
          hasToolCalls = true;
        } else if (!hasToolCalls) {
          // 如果不是工具调用，直接输出内容
          yield data;
        }
      }
        // 4. 如果有工具调用，处理工具调用并重新请求
      if (hasToolCalls) {
        AppLogger.d('检测到工具调用，开始处理...');
        
        // 解析工具调用响应
        Map<String, dynamic> toolResponse;
        try {
          toolResponse = _reconstructToolCallsFromChunks(allData);
        } catch (e) {
          throw Exception('解析工具调用失败: $e');
        }
        
        // 执行工具调用并构建新的消息历史
        final newMessages = await _buildMessagesWithToolResults(messages, toolResponse);
        
        // 重新发起流式请求获取AI的最终回复
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
        
        // 如果AI没有返回任何内容，提供提示
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
    /// 处理工具调用
  Future<Map<String, dynamic>> _handleToolCalls(
    Map<String, dynamic> response,
    List<Map<String, dynamic>> originalMessages,
  ) async {
    final message = response['choices'][0]['message'];
    final toolCalls = message['tool_calls'] as List;
    
    // 添加助手消息到对话历史（确保格式正确）
    final updatedMessages = List<Map<String, dynamic>>.from(originalMessages);
    
    // 构建正确格式的assistant消息
    final assistantMessage = <String, dynamic>{
      'role': 'assistant',
      'tool_calls': message['tool_calls'],
    };
    
    // 如果原消息有content且不为空，保留它
    if (message['content'] != null && 
        message['content'].toString().trim().isNotEmpty) {
      assistantMessage['content'] = message['content'];
    }
    
    updatedMessages.add(assistantMessage);
    
    // 存储搜索结果信息
    final searchResultsInfo = <String, dynamic>{};
    
    // 执行每个工具调用
    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'];      final functionName = toolCall['function']['name'];
      final arguments = toolCall['function']['arguments'];
      
      ToolResponse toolResponse;
      try {
        final result = await _executeToolCall(functionName, arguments);        toolResponse = ToolResponse.success(
          toolCallId: toolCallId,
          content: result,
        );
        
        // 如果是搜索工具，保存搜索信息
        if (functionName == 'zhipu_web_search') {
          try {
            final Map<String, dynamic> args = jsonDecode(arguments);
            final searchQuery = args['search_query'] as String?;
            final count = args['count'] as int? ?? 5;
              if (searchQuery != null) {
              searchResultsInfo['queries'] = (searchResultsInfo['queries'] as List<String>? ?? [])..add(searchQuery);
              searchResultsInfo['total_count'] = (searchResultsInfo['total_count'] as int? ?? 0) + count;
              // 新增：把最新的 search_result 也加进去
              if (_zhipuSearchService.lastSearchResults.isNotEmpty) {
                searchResultsInfo['results'] = _zhipuSearchService.lastSearchResults;
              }
            }
          } catch (e) {
            // 解析搜索参数失败
          }
        }
      } catch (e) {
        toolResponse = ToolResponse.error(
          toolCallId: toolCallId,
          error: e.toString(),
        );
      }
      
      // 添加工具结果到对话历史
      updatedMessages.add(toolResponse.toMessageJson());    }
    
    // 再次调用API获取最终回答
    final finalResponse = await currentClient!.chat.completions.create(
      model: currentModelId!,
      messages: updatedMessages,
      temperature: 0.7,
    );
    
    // 将搜索信息添加到响应中
    if (searchResultsInfo.isNotEmpty && finalResponse['choices'] != null) {
      final finalChoice = finalResponse['choices'][0];
      final finalMessage = finalChoice['message'];
      finalMessage['search_results_info'] = searchResultsInfo;
    }
    
    return finalResponse;
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
      final count = arguments['count'] as int? ?? 5;      final searchRecencyFilter = arguments['search_recency_filter'] as String? ?? 'noLimit';
      
      final searchResponse = await _zhipuSearchService.webSearch(
        searchQuery: searchQuery,
        searchEngine: searchEngine,
        count: count,
        searchRecencyFilter: searchRecencyFilter,
      );      final formattedResult = _zhipuSearchService.formatSearchResults(searchResponse);
      
      return formattedResult;    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }
  /// 从流式chunks重构完整响应
  Map<String, dynamic> _reconstructResponseFromChunks(List<String> chunks) {
    final toolCalls = <Map<String, dynamic>>[];
    String? finishReason;
    
    for (final chunk in chunks) {
      try {
        final data = json.decode(chunk);
        final choices = data['choices'];
        if (choices != null && choices is List && choices.isNotEmpty) {
          final choice = choices[0];
          final delta = choice['delta'] ?? {};
          
          // 收集工具调用信息
          if (delta['tool_calls'] != null) {
            final chunkToolCalls = delta['tool_calls'] as List;
            for (final toolCall in chunkToolCalls) {
              final index = toolCall['index'] ?? 0;
              
              // 确保toolCalls数组足够大
              while (toolCalls.length <= index) {
                toolCalls.add({});
              }
              
              // 合并工具调用数据
              final existing = toolCalls[index];
              if (toolCall['id'] != null) {
                existing['id'] = toolCall['id'];
              }
              if (toolCall['type'] != null) {
                existing['type'] = toolCall['type'];
              }
              if (toolCall['function'] != null) {
                final func = toolCall['function'];
                if (existing['function'] == null) {
                  existing['function'] = <String, dynamic>{};
                }
                final existingFunc = existing['function'] as Map<String, dynamic>;
                
                if (func['name'] != null) {
                  existingFunc['name'] = func['name'];
                }
                if (func['arguments'] != null) {
                  existingFunc['arguments'] = (existingFunc['arguments'] ?? '') + func['arguments'].toString();
                }
              }
            }
          }
          
          // 检查结束原因
          if (choice['finish_reason'] != null) {
            finishReason = choice['finish_reason'];
          }
        }
      } catch (_) {
        // 忽略解析错误的chunk
      }
    }
    
    // 构建完整响应
    return {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'tool_calls': toolCalls.where((tc) => tc.isNotEmpty).toList(),
          },
          'finish_reason': finishReason ?? 'tool_calls',
        }
      ]
    };
  }

  /// 从流式chunks重构工具调用（用于流式处理）
  Map<String, dynamic> _reconstructToolCallsFromChunks(List<String> chunks) {
    return _reconstructResponseFromChunks(chunks);
  }

  /// 构建包含工具结果的消息历史
  Future<List<Map<String, dynamic>>> _buildMessagesWithToolResults(
    List<Map<String, dynamic>> originalMessages,
    Map<String, dynamic> toolResponse,
  ) async {
    final updatedMessages = List<Map<String, dynamic>>.from(originalMessages);
    
    // 添加工具调用消息
    final message = toolResponse['choices'][0]['message'];
    final assistantMessage = <String, dynamic>{
      'role': 'assistant',
      'tool_calls': message['tool_calls'],
    };
    
    if (message['content'] != null && 
        message['content'].toString().trim().isNotEmpty) {
      assistantMessage['content'] = message['content'];
    }
    
    updatedMessages.add(assistantMessage);
    
    // 执行工具调用并添加结果
    final toolCalls = message['tool_calls'] as List;
    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'];
      final functionName = toolCall['function']['name'];
      final arguments = toolCall['function']['arguments'];
      
      ToolResponse toolResponse;
      try {
        final result = await _executeToolCall(functionName, arguments);
        toolResponse = ToolResponse.success(
          toolCallId: toolCallId,
          content: result,
        );
      } catch (e) {
        toolResponse = ToolResponse.error(
          toolCallId: toolCallId,
          error: e.toString(),
        );
      }
      
      updatedMessages.add(toolResponse.toMessageJson());
    }
    
    return updatedMessages;
  }
}