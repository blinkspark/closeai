import 'package:flutter/material.dart';

class EmptySystemPromptWidget extends StatelessWidget {
  final VoidCallback onCreatePrompt;

  const EmptySystemPromptWidget({super.key, required this.onCreatePrompt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '暂无系统提示词预设',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角的 + 按钮创建第一个预设',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreatePrompt,
            icon: const Icon(Icons.add),
            label: const Text('创建预设'),
          ),
        ],
      ),
    );
  }
}
