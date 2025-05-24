import 'package:closeai/defs.dart';
import 'package:closeai/models/session.dart';
import 'package:closeai/pages/chat_page/chat_panel/message_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/session_controller.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    final inputController = TextEditingController();
    return Obx(() {
      final index = sessionController.index.value;
      final isEmpty = sessionController.sessions.isEmpty;
      final sessionTitleController = TextEditingController(
        text: isEmpty ? '' : sessionController.sessions[index].value.title,
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
                    enabled: sessionController.editingTitle.value,
                  ),
                ),
                IconButton(
                  onPressed: isEmpty ? null : () {},
                  icon: Icon(Icons.assistant),
                  tooltip: '生成标题',
                ),
                IconButton(
                  onPressed:
                      isEmpty
                          ? null
                          : () {
                            if (sessionController.editingTitle.value) {
                              final session =
                                  sessionController.sessions[index].value;
                              session.title = sessionTitleController.text;
                              sessionController.sessions[index].value = session;
                              sessionController.updateSession(session);
                            }
                            sessionController.editingTitle.value =
                                !sessionController.editingTitle.value;
                          },
                  icon: Icon(Icons.edit),
                  tooltip: '编辑标题',
                ),
              ],
            ),
          ),
          Expanded(child: MessageList()),
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
                          controller: inputController,
                          decoration: InputDecoration(
                            enabled: !isEmpty,
                            hintText: '输入内容',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        onPressed:
                            isEmpty
                                ? null
                                : () {
                                  sessionController.addMessage(
                                    Message()
                                      ..content = inputController.text
                                      ..role = MessageRole.user,
                                  );
                                  inputController.clear();
                                },
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
