import 'package:closeai/defs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/session.dart';
import '../models/message.dart';
import '../services/session_service.dart';
import '../services/message_service.dart';
import '../services/openai_service.dart';
import 'chat_controller.dart';
import 'system_prompt_controller.dart';

/// 会话控制器，负责管理会话相关的UI状态和业务逻辑
class SessionController extends GetxController {
  late final SessionService _sessionService;
  late final MessageService _messageService;
  late final ChatController _chatController;
  
  // UI状态
  final sessions = <Rx<Session>>[].obs;
  final index = 0.obs;
  final editingTitle = false.obs;
  final sendingMessage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _sessionService = Get.find<SessionService>();
    _messageService = Get.find<MessageService>();
    _chatController = Get.find<ChatController>();
    
    loadSessions().then((_) {
      if (sessions.isNotEmpty) {
        setIndex(0);
      }
    });
  }

  /// 设置当前选中的会话索引
  void setIndex(int idx) {
    index.value = idx;
    editingTitle.value = false;
    
    if (sessions.isNotEmpty && idx < sessions.length) {
      final sessionId = sessions[idx].value.id;
      _chatController.loadMessages(sessionId);
    }
  }

  /// 发送消息
  Future<void> sendMessage(Message message) async {
    if (sessions.isEmpty) return;
    
    sendingMessage.value = true;
    try {
      final openaiService = Get.find<OpenAIService>();
      final currentSession = sessions[index.value].value;
      
      // 检查是否已配置
      if (!openaiService.isConfigured) {
        Get.snackbar(
          '配置错误',
          openaiService.configurationStatus,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // 创建用户消息
      await _chatController.addMessage(
        role: message.role,
        content: message.content,
        session: currentSession,
      );
      
      // 获取当前会话的所有消息用于API调用
      final allMessages = await _messageService.getMessagesBySessionId(currentSession.id);
      final jsonMessages = allMessages.map((e) => e.toJson()).toList();
      
      // 添加系统提示词
      final systemPromptController = Get.find<SystemPromptController>();
      final systemPromptContent = systemPromptController.getCurrentPromptContent();
      if (systemPromptContent.isNotEmpty) {
        jsonMessages.insert(0, {
          'role': 'system',
          'content': systemPromptContent,
        });
      }
      
      // 开始流式响应
      await sendStreamingMessage(jsonMessages, currentSession);
      
    } catch (e) {
      Get.snackbar('发送失败', e.toString());
    } finally {
      sendingMessage.value = false;
    }
  }

  /// 发送流式消息
  Future<void> sendStreamingMessage(List<Map<String, dynamic>> messages, Session session) async {
    final openaiService = Get.find<OpenAIService>();
    
    // 创建空的助手消息用于流式更新
    await _chatController.startStreamingMessage(
      role: MessageRole.assistant,
      session: session,
    );
    
    String fullContent = '';
    
    try {
      // 获取流式响应
      await for (final chunk in openaiService.createChatCompletionStream(messages: messages)) {
        fullContent += chunk;
        _chatController.updateStreamingMessage(fullContent);
      }
      
      // 完成流式消息
      await _chatController.finishStreamingMessage();
      
      // 更新会话时间
      await _sessionService.updateSession(session);
      
    } catch (e) {
      // 如果出错，取消流式消息
      await _chatController.cancelStreamingMessage();
      rethrow;
    }
  }

  /// 加载所有会话
  Future<void> loadSessions() async {
    final sessionList = await _sessionService.loadSessions();
    sessions.assignAll(sessionList.map((e) => e.obs));
  }

  /// 创建新会话
  Future<void> newSession(String title) async {
    final session = await _sessionService.createSession(title);
    sessions.add(session.obs);
    setIndex(sessions.length - 1);
  }

  /// 更新会话
  Future<void> updateSession(Session session) async {
    await _sessionService.updateSession(session);
  }

  /// 删除会话
  Future<void> removeSession(int idx) async {
    if (idx >= sessions.length) return;
    
    final sessionId = sessions[idx].value.id;
    
    // 删除该会话的所有消息
    await _messageService.deleteMessagesBySessionId(sessionId);
    
    // 删除会话
    await _sessionService.deleteSession(sessionId);
    
    // 从UI列表中移除
    sessions.removeAt(idx);
    
    // 调整当前选中的索引
    if (sessions.isEmpty) {
      index.value = 0;
      _chatController.clearMessages();
    } else {
      if (idx <= index.value) {
        index.value = index.value > 0 ? index.value - 1 : 0;
      }
      setIndex(index.value);
    }
  }

  /// 重置数据
  Future<void> reset() async {
    await loadSessions();
    if (sessions.isNotEmpty) {
      setIndex(0);
    } else {
      _chatController.clearMessages();
    }
  }
}
