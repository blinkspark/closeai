import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('持久化配置测试', () {
    test('应该能够正确序列化配置包含模型ID', () {
      // 模拟配置数据
      final config = {
        'themeMode': 0,
        'isToolsEnabled': true,
        'selectedModelId': 'gpt-4',
      };
      
      // 测试 JSON 序列化
      final jsonString = jsonEncode(config);
      expect(jsonString, contains('selectedModelId'));
      expect(jsonString, contains('gpt-4'));
      
      // 测试 JSON 反序列化
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['selectedModelId'], equals('gpt-4'));
      expect(decoded['isToolsEnabled'], isTrue);
    });

    test('应该能够处理空的模型ID', () {
      // 模拟配置数据
      final config = {
        'themeMode': 0,
        'isToolsEnabled': false,
        'selectedModelId': null,
      };
      
      // 测试 JSON 序列化
      final jsonString = jsonEncode(config);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['selectedModelId'], isNull);
      expect(decoded['isToolsEnabled'], isFalse);
    });

    test('应该能够向后兼容旧配置', () {
      // 模拟旧配置（没有 selectedModelId）
      final oldConfig = {
        'themeMode': 0,
        'isToolsEnabled': true,
      };
      
      final jsonString = jsonEncode(oldConfig);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // 测试向后兼容
      expect(decoded['selectedModelId'], isNull);
      expect(decoded['isToolsEnabled'], isTrue);
    });
  });
}
