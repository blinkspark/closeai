import 'package:dio/dio.dart';
import 'dart:convert';

class OpenAI {
  Dio dio = Dio();
  String? apiKey;
  String baseUrl;
  late Chat chat;

  OpenAI({this.apiKey, this.baseUrl = 'https://api.openai.com/v1'}) {
    chat = Chat(openAI: this);
  }

  Future<Map<String, dynamic>> listModels() async {
    Response response = await dio.get(
      '$baseUrl/models',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
    );
    return response.data;
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
    Map<String, dynamic>? user,
  }) async {
    Response response = await openAI.dio.post(
      '${openAI.baseUrl}/chat/completions',
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
    return response.data;
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
    Map<String, dynamic>? user,
  }) async* {
    final response = await openAI.dio.post<ResponseBody>(
      '${openAI.baseUrl}/chat/completions',
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
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
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
            return;
          }
          if (data.isNotEmpty) {
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              if (delta != null && delta['content'] != null) {
                yield delta['content'] as String;
              }
            } catch (e) {
              // 忽略解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
    }
  }
}
