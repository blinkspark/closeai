import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_page/chat_panel.dart';
import 'chat_page/session_panel.dart';

class ChatPage extends StatelessWidget {
  final bool isPhone;
  ChatPage({super.key, this.isPhone = false});

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      // 手机端：顶部AppBar+抽屉
      return Scaffold(
        appBar: AppBar(
          title: const Text('聊天'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          child: SafeArea(child: SessionPanel()),
        ),
        body: const ChatPanel(),
      );
    } else {
      // 桌面端：侧边栏+主内容
      return Row(
        children: [
          SessionPanel(),
          VerticalDivider(width: 1),
          Expanded(child: ChatPanel()),
        ],
      );
    }
  }
}
