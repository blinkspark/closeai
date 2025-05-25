import 'dart:io';

import 'package:closeai/clients/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenAI', () {
    final apiKey = Platform.environment['OR_API_KEY'];
    assert(apiKey != null);
    final OpenAI api = OpenAI(
      apiKey: apiKey,
      baseUrl: 'https://openrouter.ai/api/v1',
    );
    test('listModels', () async {
      final res = await api.listModels();
      debugPrint(res.toString());
    });

    test('chat.comletions.create', () async {
      final res = await api.chat.completions.create(
        model: 'meta-llama/llama-3.3-8b-instruct:free',
        messages: [
          {'role': 'user', 'content': '介绍一下openai'},
        ],
      );
      debugPrint(res.toString());
    });
  });
}
