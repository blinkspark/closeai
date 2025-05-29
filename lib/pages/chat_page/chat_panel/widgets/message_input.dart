import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../models/message.dart';
import '../../../../defs.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController inputController;
  
  const MessageInput({
    super.key,
    required this.inputController,
  });

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    
    return Obx(() {
      final isEmpty = sessionController.sessions.isEmpty;
      final isSending = sessionController.sendingMessage.value;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                ): () {
                  // 单独按Enter: 发送消息
                  if (!isEmpty &&
                      !isSending &&
                      inputController.text.trim().isNotEmpty) {
                    _sendMessage(sessionController, inputController);
                  }
                },
              },
              child: TextField(
                controller: inputController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  enabled: !isEmpty && !isSending,
                  hintText: isSending
                      ? '正在发送消息...'
                      : '输入内容 (Enter发送, Shift+Enter换行)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            onPressed: isEmpty || isSending
                ? null
                : () => _sendMessage(sessionController, inputController),
            icon: isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.send),
            tooltip: isSending ? '发送中...' : '发送',
          ),
        ],
      );
    });
  }

  Future<void> _sendMessage(
    SessionController sessionController,
    TextEditingController inputController,
  ) async {
    if (inputController.text.trim().isEmpty ||
        sessionController.sendingMessage.value) {
      return;
    }

    final content = inputController.text.trim();
    inputController.clear(); // 立即清空输入框

    // 异步发送消息，不等待完成
    sessionController.sendMessage(
      Message()
        ..content = content
        ..role = MessageRole.user,
    );
  }
}
