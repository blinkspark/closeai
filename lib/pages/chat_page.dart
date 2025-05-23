import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_page/chat_panel.dart';
import 'chat_page/session_panel.dart';

class ChatPage extends GetResponsiveView {
  ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SessionPanel(),
        VerticalDivider(width: 1),
        Expanded(child: ChatPanel()),
      ],
    );
  }
}
