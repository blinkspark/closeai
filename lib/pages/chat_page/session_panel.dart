import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/session_controller.dart';

class SessionPanel extends StatelessWidget {
  const SessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    return Container(
      padding: EdgeInsets.all(16),
      width: 300,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              sessionController.newSession('新会话');
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text('新会话'),
          ),
          Divider(height: 16, thickness: 1),
          Expanded(
            child: Center(
              child: Obx(() {
                return ListView.builder(
                  itemCount: sessionController.sessions.length,
                  itemBuilder: (ctx, idx) {
                    return Obx(() {
                      final session = sessionController.sessions[idx];
                      return SessionItem(
                        index: idx,
                        title: session.value.title,
                      );
                    });
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionItem extends StatelessWidget {
  final int index;
  final String title;
  const SessionItem({super.key, required this.index, required this.title});
  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          sessionController.removeSession(index);
        },
      ),
      onTap: () {
        sessionController.setIndex(index);
      },
    );
  }
}
