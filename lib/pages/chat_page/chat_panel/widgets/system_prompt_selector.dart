import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/system_prompt_controller.dart';
import 'system_prompt_dialog.dart';

class SystemPromptSelector extends StatelessWidget {
  const SystemPromptSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final systemPromptController = Get.find<SystemPromptController>();

    return Obx(() {
      return Row(
        children: [
          Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '系统提示词:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 32,
              child: DropdownButtonFormField<int>(
                value: systemPromptController.selectedSystemPrompt.value?.id,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                items: systemPromptController.systemPrompts.map((promptRx) {
                  final prompt = promptRx.value;
                  return DropdownMenuItem<int>(
                    value: prompt.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prompt.isDefault)
                          Icon(Icons.star, size: 14, color: Colors.amber),
                        if (prompt.isDefault) SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            prompt.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (int? promptId) {
                  if (promptId != null) {
                    final prompt = systemPromptController.systemPrompts
                        .firstWhere((p) => p.value.id == promptId)
                        .value;
                    systemPromptController.selectSystemPrompt(prompt);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          if (systemPromptController.useTemporaryContent.value)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '已修改',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          IconButton(
            onPressed: () => SystemPromptDialog.show(context, systemPromptController),
            icon: Icon(Icons.edit, size: 16),
            tooltip: '编辑系统提示词',
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.all(4),
          ),
        ],
      );
    });
  }
}
