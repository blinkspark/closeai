import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/system_prompt_controller.dart';
import '../../../models/system_prompt.dart';
import '../../../services/system_prompt_service.dart';
import '../../../services/system_prompt_service_impl.dart';

void showPromptDialog(BuildContext context, SystemPromptController controller, SystemPrompt? prompt) {
  final isEdit = prompt != null;
  final nameController = TextEditingController(text: prompt?.name ?? '');
  final contentController = TextEditingController(text: prompt?.content ?? '');
  final descriptionController = TextEditingController(text: prompt?.description ?? '');
  final isDefault = (prompt?.isDefault ?? false).obs;
  final enableVariables = (prompt?.enableVariables ?? true).obs;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isEdit ? '编辑系统提示词' : '创建系统提示词'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '预设名称',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: '提示词内容',
                  border: OutlineInputBorder(),
                  hintText: '输入系统提示词内容...\n\n可使用变量：\n{{username}} - 用户名\n{{time}} - 当前时间\n{{date}} - 当前日期',
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Obx(() => Checkbox(
                    value: enableVariables.value,
                    onChanged: (value) => enableVariables.value = value ?? true,
                  )),
                  Text('启用变量替换'),
                  Spacer(),
                  Obx(() => Checkbox(
                    value: isDefault.value,
                    onChanged: (value) => isDefault.value = value ?? false,
                  )),
                  Text('设为默认'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final content = contentController.text.trim();
            
            if (name.isEmpty || content.isEmpty) {
              Get.snackbar('错误', '名称和内容不能为空');
              return;
            }
            
            if (isEdit) {
              final updatedPrompt = prompt.copyWith(
                name: name,
                content: content,
                description: descriptionController.text.trim().isEmpty 
                    ? null 
                    : descriptionController.text.trim(),
                isDefault: isDefault.value,
                enableVariables: enableVariables.value,
              );
              controller.updateSystemPrompt(updatedPrompt);
            } else {
              controller.createSystemPrompt(
                name: name,
                content: content,
                description: descriptionController.text.trim().isEmpty 
                    ? null 
                    : descriptionController.text.trim(),
                isDefault: isDefault.value,
                enableVariables: enableVariables.value,
              );
            }
            
            Navigator.of(context).pop();
          },
          child: Text(isEdit ? '保存' : '创建'),
        ),
      ],
    ),
  );
}

void showDeleteDialog(BuildContext context, SystemPromptController controller, SystemPrompt prompt) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('确认删除'),
      content: Text('确定要删除预设 "${prompt.name}" 吗？此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            controller.deleteSystemPrompt(prompt.id);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('删除'),
        ),
      ],
    ),
  );
}

void showResetDialog(BuildContext context, SystemPromptController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('重置系统提示词'),
      content: Text('确定要重置所有系统提示词吗？这将删除所有自定义预设并恢复默认预设。此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            // 清空所有系统提示词
            final systemPromptService = Get.find<SystemPromptService>();
            if (systemPromptService is SystemPromptServiceImpl) {
              // 删除所有现有的系统提示词
              final allPrompts = await systemPromptService.loadSystemPrompts();
              for (final prompt in allPrompts) {
                await systemPromptService.deleteSystemPrompt(prompt.id);
              }
              
              // 重新创建默认提示词
              await systemPromptService.forceInitializeDefaultPrompts();
            }
            
            // 重新加载控制器数据
            await controller.loadSystemPrompts();
            
            // 检查 widget 是否仍然挂载
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            Get.snackbar('成功', '系统提示词已重置为默认设置');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('重置'),
        ),
      ],
    ),
  );
}
