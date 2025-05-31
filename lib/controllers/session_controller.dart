import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/session.dart';
import '../models/message.dart';
import '../services/session_service.dart';
import '../services/message_service.dart';
import '../services/openai_service_interface.dart';
import 'chat_controller.dart';
import '../core/dependency_injection.dart';
import '../defs.dart';
import 'app_state_controller.dart';

/// 会话控制器（解耦版本），负责管理会话相关的UI状态和业务逻辑
class SessionController extends GetxController {
  late final SessionService _sessionService;
  late final OpenAIServiceInterface _openAIService;
  late final ChatController _chatController;
  
  // UI状态
  final sessions = <Rx<Session>>[].obs;
  final index = 0.obs;
  final editingTitle = false.obs;
  final sendingMessage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _sessionService = di.get<SessionService>();
    _openAIService = di.get<OpenAIServiceInterface>();
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
      final currentSession = sessions[index.value].value;
      
      // 检查是否已配置
      if (!_openAIService.isConfigured) {
        Get.snackbar(
          '配置错误',
          _openAIService.configurationStatus,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );        return;
      }
      
      // 使用ChatController的带工具支持的方法
      await _chatController.sendMessageWithTools(
        content: message.content,
        session: currentSession,
      );
        } catch (e) {
      Get.snackbar('发送失败', e.toString());
    } finally {
      sendingMessage.value = false;
    }
  }
  /// 发送流式消息
  Future<void> sendStreamingMessage(List<Map<String, dynamic>> messages, Session session) async {
    // 创建空的助手消息用于流式更新
    await _chatController.startStreamingMessage(
      role: MessageRole.assistant,
      session: session,
    );
    
    String fullContent = '';
    bool streamingStarted = true;
    
    try {
      // 获取流式响应
      await for (final chunk in _openAIService.createChatCompletionStream(messages: messages)) {
        fullContent += chunk;
        _chatController.updateStreamingMessage(fullContent);
      }
      
      // 完成流式消息
      await _chatController.finishStreamingMessage();
      streamingStarted = false;
      
      // 更新会话时间
      await _sessionService.updateSession(session);
      
    } catch (e) {
      // 如果出错，取消流式消息
      if (streamingStarted && _chatController.isStreaming.value) {
        await _chatController.cancelStreamingMessage();
        streamingStarted = false;
      }
      rethrow;
    } finally {
      // 确保流式状态被正确重置
      if (streamingStarted && _chatController.isStreaming.value) {
        try {
          await _chatController.finishStreamingMessage();
        } catch (e) {
          // 如果 finishStreamingMessage 失败，强制重置状态
          _chatController.isStreaming.value = false;
          _chatController.streamingMessage.value = null;
        }
      }
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
    await di.get<MessageService>().deleteMessagesBySessionId(sessionId);
    
    // 删除会话
    await _sessionService.deleteSession(sessionId);
    
    // 从UI列表中移除
    sessions.removeAt(idx);
    
    // 调整当前选中的索引
    if (sessions.isEmpty) {
      index.value = 0;
      _chatController.clearMessages();
    } else {      if (idx <= index.value) {
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

  /// 生成标题（调用OpenAI）
  Future<void> generateTitleForCurrentSession() async {
    if (sessions.isEmpty) return;
    final currentSession = sessions[index.value].value;
    final messages = await di.get<MessageService>().getMessagesBySessionId(currentSession.id);
    if (messages.isEmpty) return;

    // 获取用于生成标题的模型ID
    final appStateController = Get.find<AppStateController>();
    final titleModelId = appStateController.selectedTitleModelId.value;
    if (titleModelId == null || titleModelId.isEmpty) {
      Get.snackbar('未选择模型', '请在设置中选择用于生成标题的模型');
      return;
    }

    // 构造用于生成标题的 prompt
    final prompt = '请为以下对话生成一个简洁有代表性的标题：\n' +
        messages.map((m) => '[${m.role}] ${m.content}').join('\n');
    try {
      final result = await _openAIService.createChatCompletion(
        messages: [
          {'role': 'system', 'content': '你是一个标题生成助手，只返回标题本身，不要多余解释。'},
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 32,
        temperature: 0.5,
        // 指定模型
        user: {'model': titleModelId},
      );
      final title = result?['choices']?[0]?['message']?['content']?.toString().trim();
      if (title != null && title.isNotEmpty) {
        currentSession.title = title;
        await updateSession(currentSession);
        sessions[index.value].refresh();
        // 生成成功不弹出snackbar
      } else {
        Get.snackbar('生成失败', '未能获取到标题内容');
      }
    } catch (e) {
      Get.snackbar('生成失败', e.toString());
    }
  }
}
