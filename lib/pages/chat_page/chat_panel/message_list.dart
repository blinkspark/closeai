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
        
        // 🐛 [DEBUG] 打印消息列表信息
        print('🐛 [DEBUG] ========== MessageList渲染 ==========');
        print('🐛 [DEBUG] 消息总数: ${messages.length}');
        print('🐛 [DEBUG] 流式消息状态: ${chatController.isStreaming.value}');
        print('🐛 [DEBUG] 搜索结果数: ${chatController.searchResultCount.value}');
        print('🐛 [DEBUG] 最近搜索: ${chatController.lastSearchQueries.toList()}');
        
        if (messages.isNotEmpty) {
          final lastMessage = messages.last;
          print('🐛 [DEBUG] 最后一条消息:');
          print('🐛 [DEBUG]   角色: ${lastMessage.role}');
          print('🐛 [DEBUG]   内容长度: ${lastMessage.content.length}');
          print('🐛 [DEBUG]   内容预览: ${lastMessage.content.length > 50 ? lastMessage.content.substring(0, 50) + '...' : lastMessage.content}');
        }
        print('🐛 [DEBUG] ======================================');
        
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            final message = messages[idx];
            final isStreaming = chatController.isStreaming.value &&
                               chatController.streamingMessage.value?.id == message.id;
            
            // 🐛 [DEBUG] 打印正在渲染的消息信息
            if (idx == messages.length - 1) {
              print('🐛 [DEBUG] 渲染最后一条消息 - ID: ${message.id}, 流式状态: $isStreaming');
            }
            
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
    // 🐛 [DEBUG] 检查消息内容是否包含搜索结果
    final containsSearchResults = message.contains('🔍 已搜索到') || message.contains('搜索结果');
    if (containsSearchResults) {
      print('🐛 [DEBUG] ========== 搜索结果消息 ==========');
      print('🐛 [DEBUG] 用户消息: $isUser');
      print('🐛 [DEBUG] 流式状态: $isStreaming');
      print('🐛 [DEBUG] 消息长度: ${message.length}');
      print('🐛 [DEBUG] 消息前100字符: ${message.length > 100 ? message.substring(0, 100) + '...' : message}');
      print('🐛 [DEBUG] =====================================');
    }
    
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
