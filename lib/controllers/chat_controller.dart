import 'package:get/get.dart';
import 'dart:convert';

import '../models/message.dart';
import '../models/session.dart';
import '../services/message_service.dart';
import '../services/openai_service.dart';
import '../services/zhipu_search_service.dart';
import 'app_state_controller.dart';

/// 聊天控制器，负责管理聊天相关的UI状态和业务逻辑
class ChatController extends GetxController {
  late final MessageService _messageService;
  late final OpenAIService _openAIService;
  late final AppStateController _appStateController;
  
  // UI状态
  final messages = <Message>[].obs;
  final isLoading = false.obs;
  final currentSessionId = Rxn<int>();
  final streamingMessage = Rxn<Message>();
  final isStreaming = false.obs;
  final searchResultCount = 0.obs;
  final lastSearchQueries = <String>[].obs;
  
  // 工具开关状态的getter
  bool get isToolsEnabled => _appStateController.isToolsEnabled.value;

  @override
  void onInit() {
    super.onInit();
    _messageService = Get.find<MessageService>();
    _openAIService = Get.find<OpenAIService>();
    _appStateController = Get.find<AppStateController>();
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
    /// 切换工具开关
  void toggleTools() {
    final oldState = isToolsEnabled;
    _appStateController.setToolsEnabled(!isToolsEnabled);
    print('🐛 [DEBUG] ========== 工具开关切换 ==========');
    print('🐛 [DEBUG] 之前状态: ${oldState ? "启用" : "禁用"}');
    print('🐛 [DEBUG] 当前状态: ${isToolsEnabled ? "启用" : "禁用"}');
    print('🐛 [DEBUG] 工具可用性: $isToolsAvailable');
    print('🐛 [DEBUG] 状态描述: $toolsStatusDescription');
    print('🐛 [DEBUG] ===================================');
  }
  
  /// 发送消息（支持工具调用）
  Future<void> sendMessageWithTools({
    required String content,
    required Session session,
  }) async {
    if (content.trim().isEmpty) return;
    
    try {
      isLoading.value = true;
      
      // 🐛 调试日志：检查工具状态
      print('🐛 [DEBUG] 工具开关状态: $isToolsEnabled');
      print('🐛 [DEBUG] 工具可用性: $isToolsAvailable');
      print('🐛 [DEBUG] 工具状态描述: $toolsStatusDescription');
      
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
      );
        // 🐛 调试日志：检查API调用参数
      print('🐛 [DEBUG] ========== ChatController发送消息 ==========');
      print('🐛 [DEBUG] 即将调用API，enableTools: $isToolsEnabled');
      print('🐛 [DEBUG] 消息历史长度: ${messageHistory.length}');
      print('🐛 [DEBUG] 工具可用性: $isToolsAvailable');
      print('🐛 [DEBUG] 会话ID: ${session.id}');
      
      // 调用OpenAI API（带工具支持）
      final response = await _openAIService.createChatCompletionWithTools(
        messages: messageHistory,
        enableTools: isToolsEnabled,
        temperature: 0.7,
        stream: false,
      );
      
      print('🐛 [DEBUG] API调用完成，响应类型: ${response.runtimeType}');
      
      if (response != null) {
        final choice = response['choices']?[0];
        final message = choice?['message'];
        final responseContent = message?['content'] ?? '';
        
        print('🐛 [DEBUG] 响应内容长度: ${responseContent.length}');
        print('🐛 [DEBUG] 响应内容预览: ${responseContent.length > 100 ? responseContent.substring(0, 100) + '...' : responseContent}');
        
        // 检查是否有搜索结果信息
        final searchResultsInfo = message?['search_results_info'];
        final toolCalls = message?['tool_calls'] ?? message?['original_tool_calls'];
        String finalContent = responseContent;
        
        print('🐛 [DEBUG] 搜索结果信息存在: ${searchResultsInfo != null}');
        print('🐛 [DEBUG] 工具调用存在: ${toolCalls != null}');
          if (searchResultsInfo != null) {
          print('🐛 [DEBUG] 发现搜索结果信息');
          // 从搜索结果信息中提取数据
          final queries = searchResultsInfo['queries'] as List<String>? ?? [];
          final totalCount = searchResultsInfo['total_count'] as int? ?? 0;
          
          print('🐛 [DEBUG] 搜索查询数量: ${queries.length}');
          print('🐛 [DEBUG] 搜索查询内容: $queries');
          print('🐛 [DEBUG] 总结果数: $totalCount');
          
          if (queries.isNotEmpty) {
            searchResultCount.value = totalCount;
            lastSearchQueries.assignAll(queries);
            
            final searchInfo = '🔍 已搜索到 $totalCount 个网页\n搜索内容: ${queries.join('、')}';
            print('🐛 [DEBUG] 生成搜索信息: $searchInfo');
            finalContent = '$searchInfo\n\n$responseContent';
          }
        } else if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
          print('🐛 [DEBUG] 发现工具调用，使用备用方案提取搜索信息');
          // 备用方案：从工具调用中提取信息
          final searchInfo = _extractSearchInfo(toolCalls);
          print('🐛 [DEBUG] 提取的搜索信息: $searchInfo');
          if (searchInfo.isNotEmpty) {
            finalContent = '$searchInfo\n\n$responseContent';
          }
        } else {
          print('🐛 [DEBUG] 未发现搜索结果信息或工具调用');
        }
        
        print('🐛 [DEBUG] 最终内容长度: ${finalContent.length}');
        print('🐛 [DEBUG] 最终内容预览: ${finalContent.length > 150 ? finalContent.substring(0, 150) + '...' : finalContent}');
        
        // 更新助手消息内容
        updateStreamingMessage(finalContent);
        await finishStreamingMessage();
        
        print('🐛 [DEBUG] 消息处理完成');
        print('🐛 [DEBUG] ============================================');
      }
      
    } catch (e) {
      print('发送消息失败: $e');
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
    print('🐛 [DEBUG] ========== 提取搜索信息 ==========');
    print('🐛 [DEBUG] 工具调用数量: ${toolCalls.length}');
    
    final searchCalls = toolCalls.where((call) =>
      call['function']?['name'] == 'zhipu_web_search').toList();
    
    print('🐛 [DEBUG] 搜索工具调用数量: ${searchCalls.length}');
    
    if (searchCalls.isEmpty) {
      print('🐛 [DEBUG] 未找到搜索工具调用');
      return '';
    }
    
    final searchQueries = <String>[];
    int totalResults = 0;
    
    for (int i = 0; i < searchCalls.length; i++) {
      final call = searchCalls[i];
      print('🐛 [DEBUG] 处理搜索调用 ${i + 1}:');
      print('🐛 [DEBUG]   工具调用结构: ${call.keys.toList()}');
      
      try {
        final arguments = call['function']['arguments'];
        print('🐛 [DEBUG]   参数类型: ${arguments.runtimeType}');
        print('🐛 [DEBUG]   参数内容: $arguments');
        
        if (arguments is String) {
          final Map<String, dynamic> args =
            arguments.startsWith('{') ?
              Map<String, dynamic>.from(
                jsonDecode(arguments)
              ) : {'search_query': arguments};
          
          print('🐛 [DEBUG]   解析后的参数: $args');
          
          final query = args['search_query'] as String?;
          final count = args['count'] as int? ?? 5;
          
          print('🐛 [DEBUG]   搜索查询: $query');
          print('🐛 [DEBUG]   结果数量: $count');
          
          if (query != null && query.isNotEmpty) {
            searchQueries.add(query);
            totalResults += count;
          }
        }
      } catch (e) {
        print('🐛 [DEBUG] 解析搜索参数失败: $e');
      }
    }
    
    print('🐛 [DEBUG] 提取完成:');
    print('🐛 [DEBUG]   查询列表: $searchQueries');
    print('🐛 [DEBUG]   总结果数: $totalResults');
    
    if (searchQueries.isEmpty) {
      print('🐛 [DEBUG] 未提取到有效搜索查询');
      return '';
    }
    
    // 更新搜索状态
    searchResultCount.value = totalResults;
    lastSearchQueries.assignAll(searchQueries);
    
    final result = '🔍 已搜索到 $totalResults 个网页\n搜索内容: ${searchQueries.join('、')}';
    print('🐛 [DEBUG] 生成的搜索信息: $result');
    print('🐛 [DEBUG] ====================================');
    
    return result;
  }
  
  /// 构建消息历史
  List<Map<String, dynamic>> _buildMessageHistory() {
    return messages.map((message) => {
      'role': message.role,
      'content': message.content,
    }).toList();
  }
  
  
  /// 检查工具是否可用
  bool get isToolsAvailable {
    try {
      final zhipuService = Get.find<ZhipuSearchService>();
      return zhipuService.isConfigured;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取工具状态描述
  String get toolsStatusDescription {
    if (!isToolsAvailable) {
      return '工具未配置';
    }
    return isToolsEnabled ? '工具已启用' : '工具已禁用';
  }
}