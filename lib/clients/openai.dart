import 'package:dio/dio.dart';

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
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
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
      options: Options(headers: {'Authorization': 'Bearer ${openAI.apiKey}'}),
    );
    return response.data;
  }
}
