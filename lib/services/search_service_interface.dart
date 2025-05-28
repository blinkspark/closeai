/// 搜索服务抽象接口
abstract class SearchServiceInterface {
  /// 检查是否已配置
  bool get isConfigured;
  
  /// 获取配置状态描述
  String get configurationStatus;
  
  /// 配置API Key
  void configure(String apiKey);
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
  });
}
