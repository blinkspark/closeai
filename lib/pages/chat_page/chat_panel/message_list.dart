import 'package:flutter/material.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, idx) {
          return MessageWidget(isUser: idx % 2 == 0);
        },
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  bool isUser = false;
  MessageWidget({super.key, this.isUser = false});

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
                  'Hello, how are you? Hello, how are you? Hello, how are you? Hello, how are you?',
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
