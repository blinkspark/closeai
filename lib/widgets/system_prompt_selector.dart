import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/system_prompt_controller.dart';
import '../models/system_prompt.dart';

class SystemPromptSelector extends StatelessWidget {
  const SystemPromptSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SystemPromptController>();
    
    return Obx(() {
      return Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '系统提示词',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  if (controller.useTemporaryContent.value)
                    Chip(
                      label: Text('已修改', style: TextStyle(fontSize: 12)),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              
              // 预设选择器
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: controller.selectedSystemPrompt.value?.id,
                      decoration: InputDecoration(
                        labelText: '选择预设',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: controller.systemPrompts.map((promptRx) {
                        final prompt = promptRx.value;
                        return DropdownMenuItem<int>(
                          value: prompt.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (prompt.isDefault)
                                Icon(Icons.star, size: 16, color: Colors.amber),
                              if (prompt.isDefault) SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  prompt.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (int? promptId) {
                        if (promptId != null) {
                          final prompt = controller.systemPrompts
                              .firstWhere((p) => p.value.id == promptId)
                              .value;
                          controller.selectSystemPrompt(prompt);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showSearchDialog(context, controller),
                    icon: Icon(Icons.search),
                    tooltip: '搜索预设',
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // 提示词内容编辑器
              TextField(
                controller: TextEditingController(
                  text: controller.temporaryPromptContent.value,
                ),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '系统提示词内容',
                  border: OutlineInputBorder(),
                  hintText: '输入系统提示词内容...',
                ),
                onChanged: (value) {
                  controller.setTemporaryContent(value);
                },
              ),
              
              SizedBox(height: 8),
              
              // 操作按钮
              Row(
                children: [
                  if (controller.useTemporaryContent.value)
                    TextButton.icon(
                      onPressed: () => controller.resetTemporaryContent(),
                      icon: Icon(Icons.refresh, size: 16),
                      label: Text('重置'),
                    ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () => _showVariablesDialog(context, controller),
                    icon: Icon(Icons.code, size: 16),
                    label: Text('变量'),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showPreviewDialog(context, controller),
                    icon: Icon(Icons.preview, size: 16),
                    label: Text('预览'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showSearchDialog(BuildContext context, SystemPromptController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('搜索系统提示词'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: '搜索关键词',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                autofocus: true,
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Obx(() {
                  return ListView.builder(
                    itemCount: controller.systemPrompts.length,
                    itemBuilder: (context, index) {
                      final prompt = controller.systemPrompts[index].value;
                      return ListTile(
                        leading: prompt.isDefault 
                            ? Icon(Icons.star, color: Colors.amber)
                            : Icon(Icons.psychology),
                        title: Text(prompt.name),
                        subtitle: Text(
                          prompt.description ?? prompt.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          controller.selectSystemPrompt(prompt);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showVariablesDialog(BuildContext context, SystemPromptController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('模板变量'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '可用变量：',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 8),
              Obx(() {
                final variables = controller.variables;
                return Column(
                  children: variables.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text('{{${entry.key}}}'),
                          ),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: entry.value),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                controller.setVariable(entry.key, value);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, SystemPromptController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('提示词预览'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              controller.getCurrentPromptContent(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 复制到剪贴板
              // Clipboard.setData(ClipboardData(text: controller.getCurrentPromptContent()));
              Get.snackbar('成功', '已复制到剪贴板');
            },
            child: Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}