import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../controllers/provider_controller.dart';
import '../utils/app_logger.dart';
import 'search_service_interface.dart';

/// 智谱AI搜索服务
class ZhipuSearchService extends GetxService implements SearchServiceInterface {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  
  String? _apiKey;
  
  // 缓存最近的搜索结果
  final lastSearchResponse = Rxn<Map<String, dynamic>>();
  final lastSearchQueries = <String>[].obs;
  final lastSearchResults = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadApiKeyFromProvider();
  }
    /// 从Provider系统加载API Key
  void _loadApiKeyFromProvider() {
    try {
      if (Get.isRegistered<ProviderController>()) {
        final providerController = Get.find<ProviderController>();
        
        final zhipuProvider = providerController.providers
            .map((p) => p.value)
            .where((p) => p.name == 'ZhipuAI')
            .firstOrNull;
        
        if (zhipuProvider != null &&
            zhipuProvider.apiKey != null && 
            zhipuProvider.apiKey!.isNotEmpty) {
          _apiKey = zhipuProvider.apiKey;
        }
      }
    } catch (e) {
      // 忽略加载错误
    }  }
  
  /// 配置API Key
  @override
  void configure(String apiKey) {
    _apiKey = apiKey;
  }
  
  /// 检查是否已配置
  @override
  bool get isConfigured {
    // 如果当前没有API Key，尝试重新加载
    if (_apiKey == null || _apiKey!.isEmpty) {
      _loadApiKeyFromProvider();
    }
    return _apiKey != null && _apiKey!.isNotEmpty;
  }
  
  /// 获取配置状态
  @override
  String get configurationStatus {
    if (!isConfigured) {
      return '智谱AI API Key未配置';
    }
    return '智谱AI配置正常';
  }
  
  /// 执行网页搜索
  @override
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
        ),      );      if (response.statusCode == 200) {
        final searchResponse = response.data as Map<String, dynamic>;
        
        // 缓存搜索结果
        lastSearchResponse.value = searchResponse;
        
        // 提取并缓存查询和结果详情
        final searchResults = searchResponse['search_result'] as List?;
        if (searchResults != null) {
          lastSearchQueries.clear();
          lastSearchQueries.add(searchQuery.trim());
            lastSearchResults.clear();
          lastSearchResults.addAll(
            searchResults.cast<Map<String, dynamic>>()
          );
          
          AppLogger.business('ZhipuSearchService', '搜索完成', data: {
            'query': searchQuery.trim(),
            'results_count': searchResults.length,
            'cached_results_count': lastSearchResults.length,
          });
        }
        
        return searchResponse;
      } else {
        throw Exception('搜索请求失败，状态码: ${response.statusCode}');
      }} on DioException catch (e) {
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
      }    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }
  /// 格式化搜索结果为工具响应
  String formatSearchResults(Map<String, dynamic> searchResponse) {
    try {
      final searchIntent = searchResponse['search_intent'] as List?;
      final searchResults = searchResponse['search_result'] as List?;
      
      if (searchResults == null || searchResults.isEmpty) {
        return '未找到相关搜索结果，请尝试使用不同的关键词。';
      }
      
      final StringBuffer buffer = StringBuffer();
      
      // 添加搜索意图信息
      if (searchIntent != null && searchIntent.isNotEmpty) {
        final intent = searchIntent.first;
        if (intent['keywords'] != null) {
          buffer.writeln('搜索关键词: ${intent['keywords']}');
          buffer.writeln();
        }
      }
      
      buffer.writeln('搜索结果 (共${searchResults.length}条):');
      buffer.writeln();
      
      for (int i = 0; i < searchResults.length && i < 8; i++) {
        final result = searchResults[i];
        buffer.writeln('${i + 1}. **${result['title'] ?? '无标题'}**');
        
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
      
      return buffer.toString();    } catch (e) {
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