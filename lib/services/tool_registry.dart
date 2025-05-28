import 'package:get/get.dart';
import '../models/function_call.dart';

/// 工具注册管理器
class ToolRegistry extends GetxService {
  static final Map<String, FunctionDefinition> _tools = {};
  
  /// 注册智谱搜索工具
  static void registerZhipuSearch() {
    _tools['zhipu_web_search'] = FunctionDefinition(
      name: 'zhipu_web_search',
      description: '''使用智谱AI搜索引擎进行网页搜索，获取最新信息。
适用场景：
- 用户询问需要实时信息、最新新闻、当前事件
- 需要验证或查找具体的事实信息
- 询问最新的股价、汇率、天气等实时数据
- 需要搜索特定的产品、服务或公司信息
- 用户明确要求搜索或查找网络信息

注意：只有当问题确实需要最新或实时信息时才使用此工具。''',
      parameters: {
        'type': 'object',
        'properties': {
          'search_query': {
            'type': 'string',
            'description': '搜索查询内容，应该是简洁明确的关键词或短语，不超过78个字符。例如："2024年GDP增长率"、"iPhone 15价格"、"今日股市行情"',
          },
          'search_engine': {
            'type': 'string',
            'enum': ['search_std', 'search_pro'],
            'description': '搜索引擎类型。search_std为基础版（免费），search_pro为高阶版（更准确但收费）',
            'default': 'search_std',
          },
          'count': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 10,
            'description': '返回结果数量，建议3-8条',
            'default': 5,
          },
          'search_recency_filter': {
            'type': 'string',
            'enum': ['oneDay', 'oneWeek', 'oneMonth', 'oneYear', 'noLimit'],
            'description': '搜索时间范围过滤。oneDay=一天内，oneWeek=一周内，oneMonth=一个月内，oneYear=一年内，noLimit=不限制',
            'default': 'noLimit',
          },
        },
        'required': ['search_query'],
      },
    );
  }
  
  /// 注册所有可用工具
  static void registerAllTools() {
    registerZhipuSearch();
    print('已注册 ${_tools.length} 个工具: ${_tools.keys.join(', ')}');
  }
  
  /// 获取所有工具定义（OpenAI格式）
  static List<Map<String, dynamic>> getAllTools() {
    return _tools.values.map((tool) => {
      'type': 'function',
      'function': tool.toJson(),
    }).toList();
  }
  
  /// 获取启用的工具定义
  static List<Map<String, dynamic>> getEnabledTools({
    bool enableWebSearch = true,
  }) {
    final enabledTools = <Map<String, dynamic>>[];
    
    if (enableWebSearch && _tools.containsKey('zhipu_web_search')) {
      enabledTools.add({
        'type': 'function',
        'function': _tools['zhipu_web_search']!.toJson(),
      });
    }
    
    return enabledTools;
  }
  
  /// 获取特定工具定义
  static FunctionDefinition? getTool(String name) {
    return _tools[name];
  }
  
  /// 检查工具是否存在
  static bool hasTool(String name) {
    return _tools.containsKey(name);
  }
  
  /// 获取工具列表
  static List<String> getToolNames() {
    return _tools.keys.toList();
  }
  
  /// 获取工具数量
  static int getToolCount() {
    return _tools.length;
  }
  
  /// 验证工具调用参数
  static Map<String, String> validateToolCall(String toolName, Map<String, dynamic> arguments) {
    final errors = <String, String>{};
    
    if (!hasTool(toolName)) {
      errors['tool'] = '未知的工具: $toolName';
      return errors;
    }
    
    final tool = getTool(toolName)!;
    final required = tool.parameters['required'] as List<dynamic>?;
    
    // 检查必需参数
    if (required != null) {
      for (final param in required) {
        if (!arguments.containsKey(param) || arguments[param] == null) {
          errors[param.toString()] = '缺少必需参数: $param';
        }
      }
    }
    
    // 验证具体工具的参数
    if (toolName == 'zhipu_web_search') {
      errors.addAll(_validateZhipuSearchParams(arguments));
    }
    
    return errors;
  }
  
  /// 验证智谱搜索参数
  static Map<String, String> _validateZhipuSearchParams(Map<String, dynamic> arguments) {
    final errors = <String, String>{};
    
    // 验证搜索查询
    final searchQuery = arguments['search_query'] as String?;
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      errors['search_query'] = '搜索查询不能为空';
    } else if (searchQuery.length > 78) {
      errors['search_query'] = '搜索查询不能超过78个字符';
    }
    
    // 验证搜索引擎
    final searchEngine = arguments['search_engine'] as String?;
    if (searchEngine != null) {
      const validEngines = ['search_std', 'search_pro'];
      if (!validEngines.contains(searchEngine)) {
        errors['search_engine'] = '不支持的搜索引擎类型';
      }
    }
    
    // 验证结果数量
    final count = arguments['count'];
    if (count != null) {
      if (count is! int || count < 1 || count > 10) {
        errors['count'] = '搜索结果数量必须在1-10之间';
      }
    }
    
    // 验证时间过滤
    final recencyFilter = arguments['search_recency_filter'] as String?;
    if (recencyFilter != null) {
      const validFilters = ['oneDay', 'oneWeek', 'oneMonth', 'oneYear', 'noLimit'];
      if (!validFilters.contains(recencyFilter)) {
        errors['search_recency_filter'] = '不支持的时间过滤类型';
      }
    }
    
    return errors;
  }
  
  /// 清空所有工具
  static void clearAllTools() {
    _tools.clear();
    print('已清空所有工具注册');
  }
  
  /// 获取工具统计信息
  static Map<String, dynamic> getToolStats() {
    return {
      'total_tools': _tools.length,
      'tool_names': _tools.keys.toList(),
      'registered_at': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  void onInit() {
    super.onInit();
    registerAllTools();
  }
}