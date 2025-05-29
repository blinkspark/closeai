import 'package:closeai/pages/chat_page/chat_panel/message_list.dart';
import 'package:flutter/material.dart';

import 'chat_panel/widgets/session_title_widget.dart';
import 'chat_panel/widgets/system_prompt_selector.dart';
import 'chat_panel/widgets/model_selector.dart';
import 'chat_panel/widgets/tools_toggle_row.dart';
import 'chat_panel/widgets/message_input.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});  @override
  Widget build(BuildContext context) {
    final inputController = TextEditingController();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 会话标题行
              const SessionTitleWidget(),
              SizedBox(height: 8),
              // 系统提示词选择行
              const SystemPromptSelector(),
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
                child: const ModelSelector(),
              ),
              Padding(
                padding: EdgeInsets.all(16),
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