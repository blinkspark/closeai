import 'package:isar/isar.dart';

part 'system_prompt.g.dart';

@Collection()
class SystemPrompt {
  Id id = Isar.autoIncrement;
  
  /// 预设名称
  late String name;
  
  /// 提示词内容
  late String content;
  
  /// 是否为默认预设
  bool isDefault = false;
  
  /// 创建时间
  DateTime createTime = DateTime.now();
  
  /// 更新时间
  DateTime updateTime = DateTime.now();
  
  /// 排序顺序
  int sortOrder = 0;
  
  /// 描述信息
  String? description;
  
  /// 是否启用变量替换
  bool enableVariables = true;
  
  SystemPrompt();
  
  SystemPrompt.create({
    required this.name,
    required this.content,
    this.isDefault = false,
    this.description,
    this.enableVariables = true,
  });
  
  /// 处理变量替换
  String processVariables({
    String? userName,
    DateTime? currentTime,
    Map<String, String>? customVariables,
  }) {
    if (!enableVariables) return content;
    
    String processedContent = content;
    
    // 替换用户名变量
    if (userName != null) {
      processedContent = processedContent.replaceAll('{{username}}', userName);
      processedContent = processedContent.replaceAll('{{用户名}}', userName);
    }
    
    // 替换时间变量
    final time = currentTime ?? DateTime.now();
    processedContent = processedContent.replaceAll('{{time}}', time.toString());
    processedContent = processedContent.replaceAll('{{date}}', '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}');
    processedContent = processedContent.replaceAll('{{时间}}', time.toString());
    processedContent = processedContent.replaceAll('{{日期}}', '${time.year}年${time.month}月${time.day}日');
    
    // 替换自定义变量
    if (customVariables != null) {
      customVariables.forEach((key, value) {
        processedContent = processedContent.replaceAll('{{$key}}', value);
      });
    }
    
    return processedContent;
  }
  
  /// 获取变量列表
  List<String> getVariables() {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(1)!).toSet().toList();
  }
  
  SystemPrompt copyWith({
    String? name,
    String? content,
    bool? isDefault,
    String? description,
    bool? enableVariables,
  }) {
    return SystemPrompt.create(
      name: name ?? this.name,
      content: content ?? this.content,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      enableVariables: enableVariables ?? this.enableVariables,
    )
      ..id = id
      ..createTime = createTime
      ..updateTime = DateTime.now()
      ..sortOrder = sortOrder;
  }
}