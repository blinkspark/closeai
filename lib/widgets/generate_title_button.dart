import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import '../controllers/model_controller.dart';
import '../models/model.dart';
import '../services/openai_service.dart';
// 添加会话和聊天控制器导入
import '../controllers/session_controller.dart';
import '../controllers/chat_controller.dart';

/// 通用的“生成标题”按钮组件
class GenerateTitleButton extends StatefulWidget {
  final ValueChanged<String> onTitleGenerated;
  final bool isEmpty;
  final double iconSize;

  const GenerateTitleButton({
    super.key,
    required this.onTitleGenerated,
    required this.isEmpty,
    this.iconSize = 24,
  });

  @override
  State<GenerateTitleButton> createState() => _GenerateTitleButtonState();
}

class _GenerateTitleButtonState extends State<GenerateTitleButton> {
  bool _isGenerating = false;
  
  Future<void> _generateTitle() async {
    if (widget.isEmpty) return;
    
    setState(() => _isGenerating = true);
    
    Model? originalModel; // 用于保存原始模型
    final modelController = Get.find<ModelController>();
    final appStateController = Get.find<AppStateController>();
    
    try {
      final openaiService = Get.find<OpenAIService>();
      
      final model = modelController.titleGenerationModel.value;
      if (model == null) {
        throw Exception('请先在设置中选择标题生成模型');
      }
      
      // 保存当前模型
      originalModel = modelController.selectedModel.value;
      // 临时切换为标题生成模型
      modelController.selectModel(model);
      
      final sessionController = Get.find<SessionController>();
      final chatController = Get.find<ChatController>();
      
      // 获取当前会话ID
      final sessionId = sessionController.sessions[sessionController.index.value].value.id;
      
      // 获取会话消息
      final messages = await chatController.getMessagesForSession(sessionId);
      
      // 提取消息内容
      final messageContents = messages.map((m) => m.content).toList();
      
      // 生成标题的提示词
      final prompt = '请为以下对话生成一个简洁的标题（不超过10个字）：\n${messageContents.join('\n')}';
      
      // 调用OpenAI服务生成标题
      final response = await openaiService.createChatCompletion(
        messages: [
          {'role': 'system', 'content': '你是一个专业的标题生成助手，直接返回标题文本，不要包含其他内容'},
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 30,
        temperature: 0.7,
      );
      
      final title = response?['choices']?[0]?['message']?['content']?.toString().trim() ?? '生成失败';
      if (title.isNotEmpty) {
        widget.onTitleGenerated(title);
      }
    } catch (e) {
      Get.snackbar(
        '生成标题失败',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // 恢复原始模型
      if (originalModel != null) {
        modelController.selectModel(originalModel);
      }
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isGenerating
          ? SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.assistant, size: widget.iconSize),
      tooltip: '生成标题',
      onPressed: widget.isEmpty ? null : _generateTitle,
    );
  }
}
