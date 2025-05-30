import 'dart:convert';

/// 工具响应重构相关工具
class ResponseUtils {
  /// 从流式chunks重构完整响应
  static Map<String, dynamic> reconstructResponseFromChunks(List<String> chunks) {
    final toolCalls = <Map<String, dynamic>>[];
    String? finishReason;
    for (final chunk in chunks) {
      try {
        final data = json.decode(chunk);
        final choices = data['choices'];
        if (choices != null && choices is List && choices.isNotEmpty) {
          final choice = choices[0];
          final delta = choice['delta'] ?? {};
          if (delta['tool_calls'] != null) {
            final chunkToolCalls = delta['tool_calls'] as List;
            for (final toolCall in chunkToolCalls) {
              final index = toolCall['index'] ?? 0;
              while (toolCalls.length <= index) {
                toolCalls.add({});
              }
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
          if (choice['finish_reason'] != null) {
            finishReason = choice['finish_reason'];
          }
        }
      } catch (_) {}
    }
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
  static Map<String, dynamic> reconstructToolCallsFromChunks(List<String> chunks) {
    return reconstructResponseFromChunks(chunks);
  }
}
