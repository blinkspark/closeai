import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../controllers/provider_controller.dart';

/// 智谱AI搜索服务
class ZhipuSearchService extends GetxService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  
  String? _apiKey;
  
  @override
  void onInit() {
    super.onInit();
    _loadApiKeyFromProvider();
  }
  
  /// 从Provider系统加载API Key
  void _loadApiKeyFromProvider() {
    try {
      print('🐛 [DEBUG] 开始从Provider加载智谱AI API Key');
      if (Get.isRegistered<ProviderController>()) {
        final providerController = Get.find<ProviderController>();
        print('🐛 [DEBUG] ProviderController已注册，Provider数量: ${providerController.providers.length}');
        
        final zhipuProvider = providerController.providers
            .map((p) => p.value)
            .where((p) => p.name == 'ZhipuAI')
            .firstOrNull;
        
        print('🐛 [DEBUG] 智谱AI Provider查找结果: ${zhipuProvider != null ? "找到" : "未找到"}');
        
        if (zhipuProvider != null) {
          print('🐛 [DEBUG] 智谱AI Provider详情 - 名称: ${zhipuProvider.name}, API Key存在: ${zhipuProvider.apiKey != null}, API Key非空: ${zhipuProvider.apiKey?.isNotEmpty ?? false}');
          
          if (zhipuProvider.apiKey != null && zhipuProvider.apiKey!.isNotEmpty) {
            _apiKey = zhipuProvider.apiKey;
            print('🐛 [DEBUG] 智谱AI API Key已从Provider加载: ${zhipuProvider.apiKey!.substring(0, 10)}...');
          } else {
            print('🐛 [DEBUG] 智谱AI API Key为空或null');
          }
        }
      } else {
        print('🐛 [DEBUG] ProviderController未注册');
      }
    } catch (e) {
      print('🐛 [DEBUG] 从Provider加载智谱AI API Key失败: $e');
    }
  }
  
  /// 配置API Key
  void configure(String apiKey) {
    _apiKey = apiKey;
    print('智谱AI API Key已配置: ${apiKey.substring(0, 10)}...');
  }
  
  /// 检查是否已配置
  bool get isConfigured {
    // 如果当前没有API Key，尝试重新加载
    if (_apiKey == null || _apiKey!.isEmpty) {
      _loadApiKeyFromProvider();
    }
    final result = _apiKey != null && _apiKey!.isNotEmpty;
    print('🐛 [DEBUG] isConfigured检查结果: $result, API Key存在: ${_apiKey != null}');
    return result;
  }
  
  /// 获取配置状态
  String get configurationStatus {
    if (!isConfigured) {
      return '智谱AI API Key未配置';
    }
    return '智谱AI配置正常';
  }
  
  /// 执行网页搜索
  Future<Map<String, dynamic>> webSearch({
    required String searchQuery,
    String searchEngine = 'search_std',
    int count = 5,
    String? searchDomainFilter,
    String searchRecencyFilter = 'noLimit',
    String contentSize = 'medium',
    String? requestId,
    String? userId,
  }) async {
    if (!isConfigured) {
      throw Exception('智谱AI API Key未配置，请先在设置中配置API Key');
    }
    
    if (searchQuery.trim().isEmpty) {
      throw Exception('搜索查询不能为空');
    }
    
    try {
      print('执行智谱搜索: $searchQuery');
      print('搜索引擎: $searchEngine, 结果数量: $count');
      
      final requestData = {
        'search_query': searchQuery.trim(),
        'search_engine': searchEngine,
        'count': count,
        'search_recency_filter': searchRecencyFilter,
        'content_size': contentSize,
        if (searchDomainFilter != null && searchDomainFilter.isNotEmpty) 
          'search_domain_filter': searchDomainFilter,
        if (requestId != null) 'request_id': requestId,
        if (userId != null) 'user_id': userId,
      };
      
      final response = await _dio.post(
        '$_baseUrl/web_search',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
        print('智谱搜索API响应状态: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // 🐛 [DEBUG] 打印搜索结果详情
        final responseData = response.data;
        print('🐛 [DEBUG] ========== 搜索结果详情 ==========');
        print('🐛 [DEBUG] 搜索查询: $searchQuery');
        print('🐛 [DEBUG] 搜索引擎: $searchEngine');
        print('🐛 [DEBUG] 请求结果数: $count');
        
        if (responseData is Map<String, dynamic>) {
          final searchResults = responseData['search_result'] as List?;
          final searchIntent = responseData['search_intent'] as List?;
          
          print('🐛 [DEBUG] 实际返回结果数: ${searchResults?.length ?? 0}');
          
          if (searchIntent != null && searchIntent.isNotEmpty) {
            final intent = searchIntent.first;
            print('🐛 [DEBUG] 搜索意图关键词: ${intent['keywords']}');
          }
          
          if (searchResults != null) {
            for (int i = 0; i < searchResults.length && i < 3; i++) {
              final result = searchResults[i];
              print('🐛 [DEBUG] 结果${i + 1}: ${result['title']}');
              print('🐛 [DEBUG]   来源: ${result['media']}');
              print('🐛 [DEBUG]   链接: ${result['link']}');
              if (result['content'] != null) {
                final content = result['content'].toString();
                final preview = content.length > 100 ? '${content.substring(0, 100)}...' : content;
                print('🐛 [DEBUG]   内容预览: $preview');
              }
            }
          }
        }
        print('🐛 [DEBUG] =====================================');
        
        return response.data;
      } else {
        throw Exception('搜索请求失败，状态码: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('智谱搜索API调用错误: ${e.message}');
      
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception('搜索失败: ${errorData['error']['message'] ?? '未知错误'}');
        }
      }
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          throw Exception('搜索请求超时，请检查网络连接');
        case DioExceptionType.receiveTimeout:
          throw Exception('搜索响应超时，请稍后重试');
        case DioExceptionType.badResponse:
          throw Exception('搜索服务响应错误: ${e.response?.statusCode}');
        default:
          throw Exception('搜索请求失败: ${e.message}');
      }
    } catch (e) {
      print('智谱搜索未知错误: $e');
      throw Exception('搜索失败: $e');
    }
  }
    /// 格式化搜索结果为工具响应
  String formatSearchResults(Map<String, dynamic> searchResponse) {
    try {
      print('🐛 [DEBUG] ========== 格式化搜索结果 ==========');
      
      final searchIntent = searchResponse['search_intent'] as List?;
      final searchResults = searchResponse['search_result'] as List?;
      
      print('🐛 [DEBUG] 原始响应数据类型: ${searchResponse.runtimeType}');
      print('🐛 [DEBUG] 搜索意图数据: ${searchIntent?.length ?? 0} 条');
      print('🐛 [DEBUG] 搜索结果数据: ${searchResults?.length ?? 0} 条');
      
      if (searchResults == null || searchResults.isEmpty) {
        print('🐛 [DEBUG] 无搜索结果，返回提示信息');
        return '未找到相关搜索结果，请尝试使用不同的关键词。';
      }
      
      final StringBuffer buffer = StringBuffer();
      
      // 添加搜索意图信息
      if (searchIntent != null && searchIntent.isNotEmpty) {
        final intent = searchIntent.first;
        if (intent['keywords'] != null) {
          buffer.writeln('搜索关键词: ${intent['keywords']}');
          buffer.writeln();
          print('🐛 [DEBUG] 添加搜索关键词: ${intent['keywords']}');
        }
      }
      
      buffer.writeln('搜索结果 (共${searchResults.length}条):');
      buffer.writeln();
      print('🐛 [DEBUG] 开始格式化 ${searchResults.length} 条结果');
      
      for (int i = 0; i < searchResults.length && i < 8; i++) {
        final result = searchResults[i];
        buffer.writeln('${i + 1}. **${result['title'] ?? '无标题'}**');
        print('🐛 [DEBUG] 格式化结果${i + 1}: ${result['title']}');
        
        if (result['media'] != null) {
          buffer.writeln('   来源: ${result['media']}');
        }
        
        if (result['publish_date'] != null) {
          buffer.writeln('   发布时间: ${result['publish_date']}');
        }
        
        if (result['link'] != null) {
          buffer.writeln('   链接: ${result['link']}');
        }
        
        if (result['content'] != null && result['content'].toString().isNotEmpty) {
          final content = result['content'].toString();
          // 限制内容长度，避免响应过长
          final truncatedContent = content.length > 300 
            ? '${content.substring(0, 300)}...' 
            : content;
          buffer.writeln('   摘要: $truncatedContent');
        }
        
        buffer.writeln();
      }
      
      // 添加搜索时间戳
      buffer.writeln('---');
      buffer.writeln('搜索时间: ${DateTime.now().toString().substring(0, 19)}');
      
      final formattedResult = buffer.toString();
      print('🐛 [DEBUG] 格式化完成，总长度: ${formattedResult.length} 字符');
      print('🐛 [DEBUG] ========================================');
      
      return formattedResult;
    } catch (e) {
      print('格式化搜索结果失败: $e');
      return '搜索结果格式化失败，但搜索已完成。原始数据: ${searchResponse.toString().substring(0, 200)}...';
    }
  }
  
  /// 格式化搜索结果为简洁版本
  String formatSearchResultsCompact(Map<String, dynamic> searchResponse) {
    try {
      final searchResults = searchResponse['search_result'] as List?;
      
      if (searchResults == null || searchResults.isEmpty) {
        return '未找到相关搜索结果。';
      }
      
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('搜索结果:');
      
      for (int i = 0; i < searchResults.length && i < 5; i++) {
        final result = searchResults[i];
        buffer.writeln('${i + 1}. ${result['title']} (${result['media']})');
        
        if (result['content'] != null) {
          final content = result['content'].toString();
          final summary = content.length > 150 
            ? '${content.substring(0, 150)}...' 
            : content;
          buffer.writeln('   $summary');
        }
        buffer.writeln();
      }
      
      return buffer.toString();
    } catch (e) {
      return '搜索结果处理失败: $e';
    }
  }
  
  /// 验证搜索引擎类型
  bool isValidSearchEngine(String engine) {
    const validEngines = [
      'search_std',
      'search_pro',
      'search_pro_sogou',
      'search_pro_quark',
      'search_pro_jina',
      'search_pro_bing',
    ];
    return validEngines.contains(engine);
  }
  
  /// 验证搜索参数
  Map<String, String> validateSearchParams({
    required String searchQuery,
    String searchEngine = 'search_std',
    int count = 5,
  }) {
    final errors = <String, String>{};
    
    if (searchQuery.trim().isEmpty) {
      errors['search_query'] = '搜索查询不能为空';
    } else if (searchQuery.length > 78) {
      errors['search_query'] = '搜索查询不能超过78个字符';
    }
    
    if (!isValidSearchEngine(searchEngine)) {
      errors['search_engine'] = '不支持的搜索引擎类型';
    }
    
    if (count < 1 || count > 50) {
      errors['count'] = '搜索结果数量必须在1-50之间';
    }
    
    return errors;
  }
  
  @override
  void onClose() {
    _dio.close();
    super.onClose();
  }
}