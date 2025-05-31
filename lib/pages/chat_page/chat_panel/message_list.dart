import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/chat_controller.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});
  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Obx(() {
        final messages = chatController.messages;
        final currentStreamingMessage = chatController.streamingMessage.value;
        final isStreamingActive = chatController.isStreaming.value;
        
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            final message = messages[idx];
            final isStreaming = isStreamingActive &&
                               currentStreamingMessage?.id == message.id;
            
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
  });  @override
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
                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    MarkdownBody(
                      data: message,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        code: TextStyle(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          color: isUser
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href));
                        }
                      },
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
