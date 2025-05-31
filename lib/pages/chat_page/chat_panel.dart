import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:closeai/controllers/session_controller.dart';

import 'chat_panel/message_list.dart';
import 'chat_panel/widgets/session_title_widget.dart';
import 'chat_panel/widgets/system_prompt_selector.dart';
import 'chat_panel/widgets/model_selector.dart';
import 'chat_panel/widgets/tools_toggle_row.dart';
import 'chat_panel/widgets/message_input.dart';

class ChatPanel extends StatelessWidget {
  final bool showSessionTitle;
  const ChatPanel({super.key, this.showSessionTitle = true});

  @override
  Widget build(BuildContext context) {
    final inputController = TextEditingController();
    final sessionController = Get.find<SessionController>();

    return Column(
      children: [
        if (showSessionTitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // 会话标题行（添加标题生成功能）
                SessionTitleWidget(
                  onTitleGenerated: (title) {
                    if (sessionController.sessions.isNotEmpty) {
                      final index = sessionController.index.value;
                      final session = sessionController.sessions[index].value;
                      session.title = title;
                      sessionController.updateSession(session);
                    }
                  },
                ),
                SizedBox(height: 8),
                // 系统提示词选择行
                const SystemPromptSelector(),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const SystemPromptSelector(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const ModelSelector(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // 工具开关行
                    const ToolsToggleRow(),
                    SizedBox(height: 8),
                    // 输入框行
                    MessageInput(inputController: inputController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
