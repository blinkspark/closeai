import 'package:get/get.dart';

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
    _appStateController.setToolsEnabled(!isToolsEnabled);
    print('工具开关状态: ${isToolsEnabled ? "启用" : "禁用"}');
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
      );
      
      // 调用OpenAI API（带工具支持）
      final response = await _openAIService.createChatCompletionWithTools(
        messages: messageHistory,
        enableTools: isToolsEnabled,
        temperature: 0.7,
        stream: false,
      );
      
      if (response != null) {
        final choice = response['choices']?[0];
        final message = choice?['message'];
        final responseContent = message?['content'] ?? '';
        
        // 更新助手消息内容
        updateStreamingMessage(responseContent);
        await finishStreamingMessage();
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