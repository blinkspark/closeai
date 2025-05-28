import 'package:get/get.dart';
import 'dart:convert';

import '../models/message.dart';
import '../models/session.dart';
import '../services/message_service.dart';
import '../services/openai_service_interface.dart';
import '../services/search_service_interface.dart';
import '../services/zhipu_search_service.dart';
import '../core/dependency_injection.dart';
import '../interfaces/common_interfaces.dart';
import '../defs.dart';

/// 聊天控制器，负责管理聊天相关的UI状态和业务逻辑
class ChatController extends GetxController {
  late final MessageService _messageService;
  late final OpenAIServiceInterface _openAIService;
  SearchServiceInterface? _searchService;
  ToolStateManager? _toolStateManager;
  SystemPromptManager? _systemPromptManager;
    // UI状态
  final messages = <Message>[].obs;
  final isLoading = false.obs;
  final currentSessionId = Rxn<int>();
  final streamingMessage = Rxn<Message>();
  final isStreaming = false.obs;  final searchResultCount = 0.obs;
  final lastSearchQueries = <String>[].obs;
  final lastSearchResults = <Map<String, dynamic>>[].obs;
  
  // 工具状态的可观察属性
  final isToolsEnabledObs = false.obs;
  final isToolsAvailableObs = false.obs;
  @override
  void onInit() {
    super.onInit();
    _messageService = di.get<MessageService>();
    _openAIService = di.get<OpenAIServiceInterface>();
      // 可选依赖，如果不存在不会导致错误
    try {
      _searchService = di.get<SearchServiceInterface>();
    } catch (e) {
      // 搜索服务未注册，跳过
    }
    
    try {
      _toolStateManager = di.get<ToolStateManager>();
    } catch (e) {
      // 工具状态管理器未注册，跳过
    }
    
    try {
      _systemPromptManager = di.get<SystemPromptManager>();
    } catch (e) {
      // 系统提示词管理器未注册，跳过
    }
    
    // 初始化工具状态可观察属性
    _updateToolStates();
  }
    /// 更新工具状态可观察属性
  void _updateToolStates() {
    isToolsEnabledObs.value = _toolStateManager?.isToolsEnabled ?? false;
    isToolsAvailableObs.value = _computeToolsAvailable();
  }
  
  /// 计算工具可用性
  bool _computeToolsAvailable() {
    try {
      if (_searchService == null) return false;
      // 检查搜索服务是否配置正确
      return true; // 简化实现，实际可以检查更详细的配置
    } catch (e) {
      return false;
    }
  }

  /// 工具开关状态（向后兼容的getter）
  bool get isToolsEnabled => isToolsEnabledObs.value;
  
  /// 工具可用性（向后兼容的getter）
  bool get isToolsAvailable => isToolsAvailableObs.value;
  /// 切换工具开关
  void toggleTools() {
    _toolStateManager?.setToolsEnabled(!isToolsEnabled);
    
    // 更新可观察属性
    _updateToolStates();
  }
  
  /// 获取工具状态描述
  String get toolsStatusDescription {
    if (!isToolsAvailable) {
      return '工具未配置';
    }
    return isToolsEnabled ? '工具已启用' : '工具已禁用';
  }

  /// 加载指定会话的消息
  Future<void> loadMessages(int sessionId) async {
    isLoading.value = true;
    try {
      currentSessionId.value = sessionId;
      final sessionMessages = await _messageService.getMessagesBySessionId(sessionId);
      messages.assignAll(sessionMessages);
    } finally {
      isLoading.value = false;
    }
  }

  /// 添加消息到当前会话
  Future<Message> addMessage({
    required String role,
    required String content,
    required Session session,
  }) async {
    final message = await _messageService.createMessage(
      role: role,
      content: content,
      session: session,
    );
    
    // 如果是当前会话的消息，添加到UI列表
    if (currentSessionId.value == session.id) {
      messages.add(message);
    }
    
    return message;
  }

  /// 更新消息
  Future<void> updateMessage(Message message) async {
    await _messageService.updateMessage(message);
    
    // 更新UI中的消息
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
    }
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    await _messageService.deleteMessage(messageId);
    
    // 从UI列表中移除
    messages.removeWhere((m) => m.id == messageId);
  }

  /// 开始流式消息
  Future<Message> startStreamingMessage({
    required String role,
    required Session session,
  }) async {
    final message = await _messageService.createMessage(
      role: role,
      content: '',
      session: session,
    );
    
    // 如果是当前会话的消息，添加到UI列表
    if (currentSessionId.value == session.id) {
      messages.add(message);
      streamingMessage.value = message;
      isStreaming.value = true;
    }
    
    return message;
  }

  /// 更新流式消息内容
  void updateStreamingMessage(String content) {
    if (streamingMessage.value != null) {
      streamingMessage.value!.content = content;
      
      // 更新UI中的消息
      final index = messages.indexWhere((m) => m.id == streamingMessage.value!.id);
      if (index != -1) {
        messages[index] = streamingMessage.value!;
      }
    }
  }

  /// 完成流式消息
  Future<void> finishStreamingMessage() async {
    if (streamingMessage.value != null) {
      // 保存最终的消息内容到数据库
      await _messageService.updateMessage(streamingMessage.value!);
      
      streamingMessage.value = null;
      isStreaming.value = false;
    }
  }

  /// 取消流式消息
  Future<void> cancelStreamingMessage() async {
    if (streamingMessage.value != null) {
      // 从UI中移除
      messages.removeWhere((m) => m.id == streamingMessage.value!.id);
      
      // 从数据库中删除
      await _messageService.deleteMessage(streamingMessage.value!.id);
      
      streamingMessage.value = null;
      isStreaming.value = false;
    }
  }

  /// 清空当前会话的消息显示
  void clearMessages() {
    messages.clear();
    currentSessionId.value = null;
    streamingMessage.value = null;
    isStreaming.value = false;
    searchResultCount.value = 0;
    lastSearchQueries.clear();
  }

  /// 获取消息总数
  Future<int> getMessageCount() async {
    return await _messageService.getMessageCount();
  }

  /// 获取特定会话的消息总数
  Future<int> getMessageCountBySessionId(int sessionId) async {
    return await _messageService.getMessageCountBySessionId(sessionId);
  }

  /// 发送消息（支持工具调用）
  Future<void> sendMessageWithTools({
    required String content,
    required Session session,
  }) async {
    if (content.trim().isEmpty) return;
    
    try {
      isLoading.value = true;
        // 添加用户消息
      await addMessage(
        role: 'user',
        content: content,
        session: session,
      );
      
      // 构建消息历史
      final messageHistory = _buildMessageHistory();
      
      // 开始流式助手消息
      await startStreamingMessage(
        role: 'assistant',
        session: session,
      );      // 调用OpenAI API（带工具支持）
      final response = await _openAIService.createChatCompletionWithTools(
        messages: messageHistory,
        enableTools: isToolsEnabled,
        temperature: 0.7,
        stream: false,      );
      
      if (response != null) {
        final choice = response['choices']?[0];
        final message = choice?['message'];        final responseContent = message?['content'] ?? '';
        
        // 检查是否有搜索结果信息
        final searchResultsInfo = message?['search_results_info'];
        final toolCalls = message?['tool_calls'] ?? message?['original_tool_calls'];
        String finalContent = responseContent;
        if (searchResultsInfo != null) {
          List<Map<String, dynamic>> results = [];
          // 从搜索结果信息中提取数据
          final queries = searchResultsInfo['queries'] as List<String>? ?? [];
          final totalCount = searchResultsInfo['total_count'] as int? ?? 0;
          // 主动补充 results 字段
          if (searchResultsInfo['results'] is List) {
            results = (searchResultsInfo['results'] as List)
              .map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (_searchService is ZhipuSearchService &&
                     (_searchService as ZhipuSearchService).lastSearchResults.isNotEmpty) {
            results = (_searchService as ZhipuSearchService).lastSearchResults;
            searchResultsInfo['results'] = results; // 补充到 info 里
          }
          lastSearchResults.assignAll(results);
          if (queries.isNotEmpty) {
            searchResultCount.value = totalCount;
            lastSearchQueries.assignAll(queries);
            final searchInfo = '🔍 已搜索到 $totalCount 个网页\n搜索内容: ${queries.join('、')}';
            finalContent = '$searchInfo\n\n$responseContent';
          }
        } else if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
          // 备用方案：从工具调用中提取信息
          final searchInfo = _extractSearchInfo(toolCalls);
          if (searchInfo.isNotEmpty) {
            finalContent = '$searchInfo\n\n$responseContent';
          }
        }
        
        // 更新助手消息内容
        updateStreamingMessage(finalContent);
        await finishStreamingMessage();
      }
        } catch (e) {
      // 如果有流式消息在进行中，取消它
      if (isStreaming.value) {
        await cancelStreamingMessage();
      }
      
      // 添加错误消息
      await addMessage(
        role: 'assistant',
        content: '抱歉，发生了错误：$e',
        session: session,
      );
    } finally {
      isLoading.value = false;
    }
  }
      /// 提取搜索信息
  String _extractSearchInfo(List toolCalls) {
    final searchCalls = toolCalls.where((call) =>
      call['function']?['name'] == 'zhipu_web_search').toList();
    
    if (searchCalls.isEmpty) {
      return '';
    }
    
    final searchQueries = <String>[];
    int totalResults = 0;
    
    for (final call in searchCalls) {
      try {
        final arguments = call['function']['arguments'];
        
        if (arguments is String) {
          final Map<String, dynamic> args =
            arguments.startsWith('{') ?
              Map<String, dynamic>.from(
                jsonDecode(arguments)
              ) : {'search_query': arguments};
          
          final query = args['search_query'] as String?;
          final count = args['count'] as int? ?? 5;
          
          if (query != null && query.isNotEmpty) {
            searchQueries.add(query);
            totalResults += count;
          }
        }
      } catch (e) {
        // 忽略解析错误，继续处理其他调用
      }
    }
      if (searchQueries.isEmpty) {
      return '';
    }
      // 尝试从搜索服务获取缓存的搜索结果详情
    try {
      if (_searchService != null && _searchService is ZhipuSearchService) {
        final zhipuService = _searchService as ZhipuSearchService;
        print('🔍 [ChatController] 尝试获取搜索结果详情');
        print('🔍 [ChatController] 搜索服务缓存结果数量: ${zhipuService.lastSearchResults.length}');
        if (zhipuService.lastSearchResults.isNotEmpty) {
          lastSearchResults.assignAll(zhipuService.lastSearchResults);
          print('🔍 [ChatController] 成功获取到 ${zhipuService.lastSearchResults.length} 个搜索结果详情');
          print('🔍 [ChatController] 第一个结果标题: ${zhipuService.lastSearchResults.first['title']}');
        } else {
          print('🔍 [ChatController] 搜索服务中没有缓存的搜索结果');
        }
      } else {
        print('🔍 [ChatController] 搜索服务不可用或类型不匹配');
      }
    } catch (e) {
      print('🔍 [ChatController] 获取搜索结果详情失败: $e');
    }
    
    // 更新搜索状态
    searchResultCount.value = totalResults;
    lastSearchQueries.assignAll(searchQueries);
    
    return '🔍 已搜索到 $totalResults 个网页\n搜索内容: ${searchQueries.join('、')}';
  }
    
  /// 构建消息历史
  List<Map<String, dynamic>> _buildMessageHistory() {
    final messageHistory = <Map<String, dynamic>>[];
      // 添加系统提示词作为第一条消息
    try {
      final systemPrompt = _systemPromptManager?.getCurrentPromptContent() ?? '';
      
      if (systemPrompt.isNotEmpty) {
        messageHistory.add({
          'role': MessageRole.system,
          'content': systemPrompt,
        });
      }
    } catch (e) {
      // 忽略系统提示词获取错误
    }
    
    // 添加对话历史
    messageHistory.addAll(messages.map((message) => {
      'role': message.role,
      'content': message.content,
    }).toList());
    
    return messageHistory;
  }
}
