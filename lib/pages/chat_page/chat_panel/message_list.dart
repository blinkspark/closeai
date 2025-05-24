import 'package:closeai/controllers/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final messages = sessionController.messages;
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            return MessageWidget(
              isUser: messages[idx].role == 'user',
              message: messages[idx].content,
            );
          },
        );
      }),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final bool isUser;
  final String message;
  const MessageWidget({super.key, required this.message, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Card(
              color:
                  isUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message,
                  style: TextStyle(
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
          ],
        ],
      ),
    );
  }
}
