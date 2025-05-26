import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/chat_controller.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final messages = chatController.messages;
        if (chatController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            final message = messages[idx];
            final isStreaming = chatController.isStreaming.value &&
                               chatController.streamingMessage.value?.id == message.id;
            return MessageWidget(
              isUser: message.role == 'user',
              message: message.content,
              isStreaming: isStreaming,
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
  final bool isStreaming;
  const MessageWidget({
    super.key,
    required this.message,
    this.isUser = false,
    this.isStreaming = false,
  });

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color:
                            isUser
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isStreaming) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '正在输入...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
