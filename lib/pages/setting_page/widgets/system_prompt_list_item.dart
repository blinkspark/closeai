import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/system_prompt_controller.dart';
import '../../../models/system_prompt.dart';
import './system_prompt_dialogs.dart'; // Assuming dialogs are in the same folder

class SystemPromptListItem extends StatelessWidget {
  final Rx<SystemPrompt> promptRx;
  final int index;
  final SystemPromptController controller;

  const SystemPromptListItem({
    super.key,
    required this.promptRx,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = promptRx.value;
    return Card(
      key: ValueKey(prompt.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            const SizedBox(width: 8),
            if (prompt.isDefault)
              const Icon(Icons.star, color: Colors.amber)
            else
              const Icon(Icons.psychology),
          ],
        ),
        title: Text(prompt.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prompt.description != null && prompt.description!.isNotEmpty)
              Text(prompt.description!),
            const SizedBox(height: 4),
            Text(
              prompt.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                showPromptDialog(context, controller, prompt);
                break;
              case 'duplicate':
                controller.duplicateSystemPrompt(prompt);
                break;
              case 'setDefault':
                controller.setDefaultSystemPrompt(prompt.id);
                break;
              case 'delete':
                showDeleteDialog(context, controller, prompt);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('复制'),
                dense: true,
              ),
            ),
            if (!prompt.isDefault)
              const PopupMenuItem(
                value: 'setDefault',
                child: ListTile(
                  leading: Icon(Icons.star_outline),
                  title: Text('设为默认'),
                  dense: true,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: () => showPromptDialog(context, controller, prompt),
      ),
    );
  }
}
