import 'package:dio/dio.dart';
import 'dart:convert';
import '../utils/app_logger.dart';

class OpenAI {
  Dio dio = Dio();
  String? apiKey;
  String baseUrl;
  late Chat chat;

  OpenAI({this.apiKey, this.baseUrl = 'https://api.openai.com/v1'}) {
    chat = Chat(openAI: this);
  }
  Future<Map<String, dynamic>> listModels() async {
    final stopwatch = Stopwatch()..start();
    try {
      AppLogger.api('ListModels', endpoint: '$baseUrl/models');
      
      Response response = await dio.get(
        '$baseUrl/models',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
      );
      
      stopwatch.stop();
      AppLogger.api(
        'ListModels',
        endpoint: '$baseUrl/models',
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );
      
      return response.data;
    } catch (e) {
      stopwatch.stop();
      AppLogger.api(
        'ListModels',
        endpoint: '$baseUrl/models',
        duration: stopwatch.elapsed,
        error: e,
      );
      rethrow;
    }
  }
}

class Chat {
  OpenAI openAI;
  late Completions completions;

  Chat({required this.openAI}) {
    completions = Completions(openAI: openAI);
  }
}

class Completions {
  OpenAI openAI;

  Completions({required this.openAI});

  Future<Map<String, dynamic>> create({
    required String model,
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    dynamic toolChoice,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    bool? stream,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    bool? logProbs,
    Map<String, dynamic>? user,  }) async {
    final stopwatch = Stopwatch()..start();
    final endpoint = '${openAI.baseUrl}/chat/completions';
    
    try {
      AppLogger.api('ChatCompletion', endpoint: endpoint, request: {
        'model': model,
        'messages_count': messages.length,
        'tools_count': tools?.length ?? 0,
        'stream': stream,
      });
      
      Response response = await openAI.dio.post(
        endpoint,
        data: {
          'model': model,
          'messages': messages,
          if (tools != null) 'tools': tools,
          if (toolChoice != null) 'tool_choice': toolChoice,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
          if (topP != null) 'top_p': topP,
          if (n != null) 'n': n,
          if (stream != null) 'stream': stream,
          if (stop != null) 'stop': stop,
          if (presencePenalty != null) 'presence_penalty': presencePenalty,
          if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
          if (logProbs != null) 'logprobs': logProbs,
          if (user != null) 'user': user,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${openAI.apiKey}',
          'Content-Type': 'application/json',
        }),
      );
      
      stopwatch.stop();
      AppLogger.api('ChatCompletion', 
        endpoint: endpoint,
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );
      
      return response.data;
    } catch (e) {
      stopwatch.stop();
      AppLogger.api('ChatCompletion',
        endpoint: endpoint,
        duration: stopwatch.elapsed,
        error: e,
      );
      rethrow;
    }
  }

  /// 创建流式聊天完成请求
  Stream<String> createStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    dynamic toolChoice,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    bool? logProbs,
    Map<String, dynamic>? user,  }) async* {
    final stopwatch = Stopwatch()..start();
    final endpoint = '${openAI.baseUrl}/chat/completions';
    
    try {
      AppLogger.api('ChatCompletionStream', endpoint: endpoint, request: {
        'model': model,
        'messages_count': messages.length,
        'tools_count': tools?.length ?? 0,
        'stream': true,
      });
      
      final response = await openAI.dio.post<ResponseBody>(
        endpoint,
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
          if (tools != null) 'tools': tools,
          if (toolChoice != null) 'tool_choice': toolChoice,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
          if (topP != null) 'top_p': topP,
          if (n != null) 'n': n,
          if (stop != null) 'stop': stop,
          if (presencePenalty != null) 'presence_penalty': presencePenalty,        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (logProbs != null) 'logprobs': logProbs,
        if (user != null) 'user': user,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${openAI.apiKey}',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
        responseType: ResponseType.stream,
      ),
    );

    String buffer = '';
    await for (final List<int> chunk in response.data!.stream) {
      final String chunkString = utf8.decode(chunk);
      buffer += chunkString;
      
      final lines = buffer.split('\n');
      // 保留最后一行，因为它可能是不完整的
      buffer = lines.last;
      
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i];
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            stopwatch.stop();
            AppLogger.api(
              'ChatCompletionStream',
              endpoint: endpoint,
              duration: stopwatch.elapsed,
            );
            return;
          }
          if (data.isNotEmpty) {
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              
              // 如果有工具调用，返回完整的JSON数据
              if (delta != null && delta['tool_calls'] != null) {
                yield data; // 返回原始JSON字符串
              } else if (delta != null && delta['content'] != null) {
                yield delta['content'] as String; // 返回内容字符串
              }
            } catch (e) {
              // 忽略解析错误，继续处理下一行
              continue;
            }
          }        }
      }
    }
    } catch (e) {
      stopwatch.stop();
      AppLogger.api(
        'ChatCompletionStream',
        endpoint: endpoint,
        duration: stopwatch.elapsed,
        error: e,
      );
      rethrow;
    }
  }
}
