import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/session_controller.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    final ChatController chatController = ChatController();
    return Obx(() {
      final index = sessionController.index.value;
      final sessionTitleController = TextEditingController(
        text: sessionController.sessions[index].value.title,
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sessionTitleController,
                    enabled: chatController.editingTitle.value,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.assistant),
                  tooltip: '生成标题',
                ),
                IconButton(
                  onPressed: () {
                    if (chatController.editingTitle.value) {
                      final session = sessionController.sessions[index].value;
                      session.title = sessionTitleController.text;
                      sessionController.sessions[index].value = session;
                      sessionController.updateSession(session);
                    }
                    chatController.editingTitle.value =
                        !chatController.editingTitle.value;
                  },
                  icon: Icon(Icons.edit),
                  tooltip: '编辑标题',
                ),
              ],
            ),
          ),
          Expanded(child: Center(child: Text('Chat Message List'))),
          Divider(height: 1),
          // Chat Input
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('Chat Setting')),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '输入内容',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.send),
                        tooltip: '发送',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
