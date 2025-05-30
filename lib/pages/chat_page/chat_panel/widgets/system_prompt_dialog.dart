import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/system_prompt_controller.dart';

class SystemPromptDialog {
  static void show(
    BuildContext context,
    SystemPromptController controller,
  ) {
    final contentController = TextEditingController(
      text: controller.temporaryPromptContent.value,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology),
            SizedBox(width: 8),
            Text('编辑系统提示词'),
            Spacer(),
            Obx(() {
              if (controller.useTemporaryContent.value) {
                return Chip(
                  label: Text('已修改', style: TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }
              return SizedBox.shrink();
            }),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前选中的预设信息
              Obx(() {
                final prompt = controller.selectedSystemPrompt.value;
                if (prompt != null) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (prompt.isDefault)
                          Icon(Icons.star, size: 16, color: Colors.amber),
                        if (prompt.isDefault) SizedBox(width: 4),
                        Text(
                          '当前预设: ${prompt.name}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Spacer(),
                        if (prompt.enableVariables)
                          Chip(
                            label: Text(
                              '支持变量',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.green.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
              SizedBox(height: 16),

              // 内容编辑器
              Text('提示词内容:', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        '输入系统提示词内容...\n\n可用变量:\n{{username}} - 用户名\n{{time}} - 当前时间\n{{date}} - 当前日期',
                  ),
                  onChanged: (value) {
                    controller.setTemporaryContent(value);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => VariablesDialog.show(context, controller),
            icon: Icon(Icons.code, size: 16),
            label: Text('变量'),
          ),
          TextButton.icon(
            onPressed: () => PreviewDialog.show(context, controller),
            icon: Icon(Icons.preview, size: 16),
            label: Text('预览'),
          ),
          if (controller.useTemporaryContent.value)
            TextButton.icon(
              onPressed: () {
                controller.resetTemporaryContent();
                contentController.text = controller.temporaryPromptContent.value;
              },
              icon: Icon(Icons.refresh, size: 16),
              label: Text('重置'),
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

class VariablesDialog {
  static void show(
    BuildContext context,
    SystemPromptController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('模板变量'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('可用变量：', style: Theme.of(context).textTheme.titleSmall),
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
                              controller: TextEditingController(
                                text: entry.value,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                controller.setVariable(
                                  entry.key,
                                  value,
                                );
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
}

class PreviewDialog {
  static void show(
    BuildContext context,
    SystemPromptController controller,
  ) {
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
              // 复制到剪贴板的功能可以后续添加
              Get.snackbar('提示', '预览功能已显示处理后的提示词内容');
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
