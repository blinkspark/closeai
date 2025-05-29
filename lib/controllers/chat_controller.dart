import 'dart:convert';
import 'package:get/get.dart';

import '../models/message.dart';
import '../models/session.dart';
import '../services/message_service.dart';
import '../services/openai_service_interface.dart';
import '../services/search_service_interface.dart';
import '../core/dependency_injection.dart';
import '../interfaces/common_interfaces.dart';
import '../defs.dart';
import 'app_state_controller.dart';

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
  final isToolsAvailableObs = false.obs;  @override
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
    
    // 延迟初始化工具状态，确保AppStateController配置加载完成
    _initializeToolStates();
  }
  /// 初始化工具状态监听
  void _initializeToolStates() {
    // 先尝试立即更新一次
    _updateToolStates();
    
    // 监听AppStateController的工具状态变化
    if (_toolStateManager != null) {
      // 如果有AppStateController，监听其状态变化
      try {
        final appStateController = Get.find<AppStateController>();
        // 监听isToolsEnabled的变化并同步到本地状态
        ever(appStateController.isToolsEnabled, (bool enabled) {
          _updateToolStates();
        });
        
        // 延迟一段时间后再次更新，确保配置加载完成
        Future.delayed(Duration(milliseconds: 100), () {
          _updateToolStates();
        });
      } catch (e) {
        // 无法找到AppStateController，忽略
      }
    }
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
  bool get isToolsAvailable => isToolsAvailableObs.value;  /// 切换工具开关
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
  }  /// 更新流式消息内容
  void updateStreamingMessage(String content) {
    if (streamingMessage.value != null) {
      // 先更新streamingMessage的内容
      streamingMessage.value!.content = content;
      
      // 更新UI中的消息（触发可观察更新）
      final index = messages.indexWhere((m) => m.id == streamingMessage.value!.id);
      if (index != -1) {
        // 创建新的消息对象以触发可观察更新
        final updatedMessage = Message()
          ..id = messages[index].id
          ..role = messages[index].role
          ..content = content
          ..timestamp = messages[index].timestamp;
        messages[index] = updatedMessage;
        
        // 同时更新 streamingMessage 引用以保持同步
        streamingMessage.value = updatedMessage;
      } else {
        // 如果在messages列表中找不到对应消息，强制刷新
        messages.refresh();
      }
    }
  }
  /// 完成流式消息
  Future<void> finishStreamingMessage() async {
    if (streamingMessage.value != null) {
      try {
        print('DEBUG: 开始完成流式消息，当前isStreaming=${isStreaming.value}');
        
        // 保存最终的消息内容到数据库
        await _messageService.updateMessage(streamingMessage.value!);
        
        // 立即重置流式状态
        streamingMessage.value = null;
        isStreaming.value = false;
        
        print('DEBUG: 流式消息完成，isStreaming已重置为false');
        
        // 强制触发UI更新
        messages.refresh();
      } catch (e) {
        print('DEBUG: 保存消息失败，但仍重置状态: $e');
        // 即使保存失败，也要重置状态
        streamingMessage.value = null;
        isStreaming.value = false;
        messages.refresh();
        rethrow;
      }
    } else {
      print('DEBUG: finishStreamingMessage被调用但streamingMessage为null');
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
  }  /// 发送消息（支持工具调用）
  Future<void> sendMessageWithTools({
    required String content,
    required Session session,
  }) async {
    if (content.trim().isEmpty) return;
    
    bool streamingStarted = false;
    
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
      );
      streamingStarted = true;

      // 使用流式接口（带工具支持）
      String fullContent = '';
      
      await for (final chunk in _openAIService.createChatCompletionStream(
        messages: messageHistory,
        enableTools: isToolsEnabled,
        temperature: 0.7,
      )) {
        // 处理混合数据类型：工具调用时是JSON字符串，普通响应时是文本内容
        try {
          // 尝试解析为JSON（工具调用的情况）
          final Map<String, dynamic> chunkData = json.decode(chunk);
          final choices = chunkData['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta != null && delta['content'] != null) {
              final content = delta['content'].toString();
              fullContent += content;
              updateStreamingMessage(fullContent);
            }
          }
        } catch (e) {
          // 如果解析JSON失败，说明是普通文本内容，直接添加
          if (chunk.trim().isNotEmpty) {
            fullContent += chunk;
            updateStreamingMessage(fullContent);
          }
        }
      }
        // 完成流式消息
      print('DEBUG: await for 循环结束，开始完成流式消息');
      await finishStreamingMessage();
      streamingStarted = false; // 标记流式处理已正常完成
      print('DEBUG: 流式处理正常完成');
      
    } catch (e) {
      // 如果有流式消息在进行中，取消它
      if (streamingStarted && isStreaming.value) {
        await cancelStreamingMessage();
        streamingStarted = false;
      }
      
      // 添加错误消息
      await addMessage(
        role: 'assistant',
        content: '抱歉，发生了错误：$e',
        session: session,
      );
    } finally {
      // 确保流式状态被正确重置
      if (streamingStarted && isStreaming.value) {
        try {
          await finishStreamingMessage();
        } catch (e) {
          // 如果 finishStreamingMessage 失败，强制重置状态
          isStreaming.value = false;
          streamingMessage.value = null;
        }
      }
      
      isLoading.value = false;
    }
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
