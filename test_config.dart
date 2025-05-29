import 'dart:convert';
import 'dart:io';

/// 测试配置文件的存储和加载
void main() async {
  print('=== 配置文件测试 ===');
  
  // 获取用户主目录（模拟应用支持目录）
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  final configDir = Directory('$home/.closeai');
  
  // 确保目录存在
  if (!await configDir.exists()) {
    await configDir.create(recursive: true);
  }
  
  final configFile = File('${configDir.path}/config.json');
  
  print('配置文件路径: ${configFile.path}');
  print('配置文件是否存在: ${await configFile.exists()}');
  
  if (await configFile.exists()) {
    try {
      final content = await configFile.readAsString();
      print('配置文件内容: $content');
      
      final json = jsonDecode(content);
      print('解析的JSON: $json');
      print('搜索功能开关: ${json['isToolsEnabled']}');
      print('选择的模型: ${json['selectedModelId']}');
    } catch (e) {
      print('读取配置文件失败: $e');
    }
  }
  
  // 测试写入
  print('\n=== 测试写入配置 ===');
  final testConfig = {
    'themeMode': 0,
    'isToolsEnabled': true,
    'selectedModelId': 'test-model'
  };
  
  try {
    await configFile.writeAsString(jsonEncode(testConfig));
    print('写入配置成功');
    
    // 验证写入
    final readBack = await configFile.readAsString();
    print('验证读取: $readBack');
  } catch (e) {
    print('写入配置失败: $e');
  }
}
