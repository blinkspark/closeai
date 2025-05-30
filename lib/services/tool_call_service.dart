import 'dart:convert';
import 'zhipu_search_service.dart';
import '../utils/tool_param_validator.dart';
import '../models/function_call.dart';

class ToolCallService {
  final ZhipuSearchService zhipuSearchService;
  ToolCallService(this.zhipuSearchService);

  /// 处理工具调用
  Future<Map<String, dynamic>> handleToolCalls({
    required Map<String, dynamic> response,
    required List<Map<String, dynamic>> originalMessages,
    required Future<String> Function(String, String) executeToolCall,
    required Future<Map<String, dynamic>> Function(List<Map<String, dynamic>>) finalCompletion,
  }) async {
    final message = response['choices'][0]['message'];
    final toolCalls = message['tool_calls'] as List;
    final updatedMessages = List<Map<String, dynamic>>.from(originalMessages);
    final assistantMessage = <String, dynamic>{
      'role': 'assistant',
      'tool_calls': message['tool_calls'],
    };
    if (message['content'] != null && message['content'].toString().trim().isNotEmpty) {
      assistantMessage['content'] = message['content'];
    }
    updatedMessages.add(assistantMessage);
    final searchResultsInfo = <String, dynamic>{};
    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'];
      final functionName = toolCall['function']['name'];
      final arguments = toolCall['function']['arguments'];
      ToolResponse toolResponse;
      try {
        final result = await executeToolCall(functionName, arguments);
        toolResponse = ToolResponse.success(
          toolCallId: toolCallId,
          content: result,
        );
        if (functionName == 'zhipu_web_search') {
          try {
            final Map<String, dynamic> args = jsonDecode(arguments);
            final searchQuery = args['search_query'] as String?;
            final count = args['count'] as int? ?? 5;
            if (searchQuery != null) {
              searchResultsInfo['queries'] = (searchResultsInfo['queries'] as List<String>? ?? [])..add(searchQuery);
              searchResultsInfo['total_count'] = (searchResultsInfo['total_count'] as int? ?? 0) + count;
              if (zhipuSearchService.lastSearchResults.isNotEmpty) {
                searchResultsInfo['results'] = zhipuSearchService.lastSearchResults;
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        toolResponse = ToolResponse.error(
          toolCallId: toolCallId,
          error: e.toString(),
        );
      }
      updatedMessages.add(toolResponse.toMessageJson());
    }
    final finalResponse = await finalCompletion(updatedMessages);
    if (searchResultsInfo.isNotEmpty && finalResponse['choices'] != null) {
      final finalChoice = finalResponse['choices'][0];
      final finalMessage = finalChoice['message'];
      finalMessage['search_results_info'] = searchResultsInfo;
    }
    return finalResponse;
  }

  /// 执行具体的工具调用
  Future<String> executeToolCall(String functionName, String arguments) async {
    Map<String, dynamic> parsedArgs;
    try {
      parsedArgs = jsonDecode(arguments);
    } catch (e) {
      throw Exception('工具调用参数解析失败: $e');
    }
    // 使用统一参数校验器
    final validationErrors = ToolParamValidator.validate(functionName, parsedArgs);
    if (validationErrors.isNotEmpty) {
      throw Exception('工具调用参数验证失败:  ${validationErrors.values.join(', ')}');
    }
    switch (functionName) {
      case 'zhipu_web_search':
        return await _executeZhipuSearch(parsedArgs);
      default:
        throw Exception('未知的工具: $functionName');
    }
  }

  Future<String> _executeZhipuSearch(Map<String, dynamic> arguments) async {
    if (!zhipuSearchService.isConfigured) {
      throw Exception('智谱AI搜索服务未配置，请先在设置中配置API Key');
    }
    try {
      final searchQuery = arguments['search_query'] as String;
      final searchEngine = arguments['search_engine'] as String? ?? 'search_std';
      final count = arguments['count'] as int? ?? 5;
      final searchRecencyFilter = arguments['search_recency_filter'] as String? ?? 'noLimit';
      final searchResponse = await zhipuSearchService.webSearch(
        searchQuery: searchQuery,
        searchEngine: searchEngine,
        count: count,
        searchRecencyFilter: searchRecencyFilter,
      );
      final formattedResult = zhipuSearchService.formatSearchResults(searchResponse);
      return formattedResult;
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }
}
