import '../models/function_call.dart';

/// 构建包含工具结果的消息历史
class MessageHistoryUtils {
  /// 构建包含工具结果的消息历史
  static Future<List<Map<String, dynamic>>> buildMessagesWithToolResults({
    required List<Map<String, dynamic>> originalMessages,
    required Map<String, dynamic> toolResponse,
    required Future<String> Function(String, String) executeToolCall,
  }) async {
    final updatedMessages = List<Map<String, dynamic>>.from(originalMessages);
    final message = toolResponse['choices'][0]['message'];
    final assistantMessage = <String, dynamic>{
      'role': 'assistant',
      'tool_calls': message['tool_calls'],
    };
    if (message['content'] != null && message['content'].toString().trim().isNotEmpty) {
      assistantMessage['content'] = message['content'];
    }
    updatedMessages.add(assistantMessage);
    final toolCalls = message['tool_calls'] as List;
    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'];
      final functionName = toolCall['function']['name'];
      final arguments = toolCall['function']['arguments'];
      dynamic toolResponseObj;
      try {
        final result = await executeToolCall(functionName, arguments);
        toolResponseObj = ToolResponse.success(
          toolCallId: toolCallId,
          content: result,
        );
      } catch (e) {
        toolResponseObj = ToolResponse.error(
          toolCallId: toolCallId,
          error: e.toString(),
        );
      }
      updatedMessages.add(toolResponseObj.toMessageJson());
    }
    return updatedMessages;
  }
}
