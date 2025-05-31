import 'package:flutter/material.dart';

import 'chat_page/chat_panel.dart';
import 'chat_page/session_panel.dart';
import 'chat_page/chat_panel/widgets/appbar_session_title.dart';

class ChatPage extends StatelessWidget {
  final bool isPhone;
  const ChatPage({super.key, this.isPhone = false});

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      // 手机端：顶部AppBar+抽屉
      return Scaffold(
        appBar: AppBar(
          title: const AppBarSessionTitle(),
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
        body: const ChatPanel(showSessionTitle: false),
      );
    } else {
      // 桌面端：侧边栏+主内容
      return Row(
        children: [
          SessionPanel(),
          VerticalDivider(width: 1),
          Expanded(child: ChatPanel(showSessionTitle: true)),
        ],
      );
    }
  }
}
