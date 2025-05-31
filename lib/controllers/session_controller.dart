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

class SessionController extends GetxController {
  late final SessionService _sessionService;
  late final OpenAIServiceInterface _openAIService;
  late final ChatController _chatController;
  
  final RxList<Rx<Session>> sessions = <Rx<Session>>[].obs;
  final RxInt index = 0.obs;
  final RxBool editingTitle = false.obs;
  final RxBool sendingMessage = false.obs;
  final RxBool isGeneratingTitle = false.obs;

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

  void setIndex(int idx) {
    index.value = idx;
    editingTitle.value = false;
    
    if (sessions.isNotEmpty && idx < sessions.length) {
      final sessionId = sessions[idx].value.id;
      _chatController.loadMessages(sessionId);
    }
  }

  Future<void> loadSessions() async {
    final sessionList = await _sessionService.loadSessions();
    sessions.assignAll(sessionList.map((e) => e.obs));
  }

  Future<void> newSession(String title) async {
    final session = await _sessionService.createSession(title);
    sessions.add(session.obs);
    setIndex(sessions.length - 1);
  }

  Future<void> updateSession(Session session) async {
    if (index.value < sessions.length) {
      sessions[index.value] = session.obs;
      sessions.refresh();
      update();
      await _sessionService.updateSession(session);
    }
  }

  Future<void> removeSession(int idx) async {
    if (idx >= sessions.length) return;
    
    final sessionId = sessions[idx].value.id;
    
    await di.get<MessageService>().deleteMessagesBySessionId(sessionId);
    await _sessionService.deleteSession(sessionId);
    
    sessions.removeAt(idx);
    
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

  Future<void> reset() async {
    sessions.clear();
    index.value = 0;
    editingTitle.value = false;
    sendingMessage.value = false;
    isGeneratingTitle.value = false;
    
    if (sessions.isNotEmpty) {
      setIndex(0);
    } else {
      _chatController.clearMessages();
      Future<void> sendMessage(String content) async {
        if (sessions.isEmpty || index.value >= sessions.length) return;
        
        final session = sessions[index.value].value;
        
        sendingMessage.value = true;
        try {
          await di.get<MessageService>().createMessage(
            role: 'user',
            content: content,
            session: session,
          );
          await _chatController.loadMessages(session.id);
        } finally {
          sendingMessage.value = false;
        }
      }
    }
  }
}
