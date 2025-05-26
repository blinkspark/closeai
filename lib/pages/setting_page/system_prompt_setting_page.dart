import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/system_prompt_controller.dart';
import '../../models/system_prompt.dart';

class SystemPromptSettingPage extends StatelessWidget {
  const SystemPromptSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SystemPromptController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('系统提示词管理'),
        actions: [
          IconButton(
            onPressed: () => _showCreateDialog(context, controller),
            icon: Icon(Icons.add),
            tooltip: '创建新预设',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.systemPrompts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无系统提示词预设',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '点击右上角的 + 按钮创建第一个预设',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, controller),
                  icon: Icon(Icons.add),
                  label: Text('创建预设'),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // 搜索栏
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '搜索预设',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
              ),
            ),
            
            // 预设列表
            Expanded(
              child: ReorderableListView.builder(
                itemCount: controller.systemPrompts.length,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final items = controller.systemPrompts.toList();
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  final ids = items.map((e) => e.value.id).toList();
                  controller.reorderSystemPrompts(ids);
                },
                itemBuilder: (context, index) {
                  final promptRx = controller.systemPrompts[index];
                  final prompt = promptRx.value;
                  
                  return Card(
                    key: ValueKey(prompt.id),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(Icons.drag_handle),
                          ),
                          SizedBox(width: 8),
                          if (prompt.isDefault)
                            Icon(Icons.star, color: Colors.amber)
                          else
                            Icon(Icons.psychology),
                        ],
                      ),
                      title: Text(prompt.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (prompt.description != null)
                            Text(prompt.description!),
                          SizedBox(height: 4),
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
                              _showEditDialog(context, controller, prompt);
                              break;
                            case 'duplicate':
                              controller.duplicateSystemPrompt(prompt);
                              break;
                            case 'setDefault':
                              controller.setDefaultSystemPrompt(prompt.id);
                              break;
                            case 'delete':
                              _showDeleteDialog(context, controller, prompt);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('编辑'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy),
                              title: Text('复制'),
                              dense: true,
                            ),
                          ),
                          if (!prompt.isDefault)
                            PopupMenuItem(
                              value: 'setDefault',
                              child: ListTile(
                                leading: Icon(Icons.star),
                                title: Text('设为默认'),
                                dense: true,
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('删除', style: TextStyle(color: Colors.red)),
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showEditDialog(context, controller, prompt),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showCreateDialog(BuildContext context, SystemPromptController controller) {
    _showPromptDialog(context, controller, null);
  }

  void _showEditDialog(BuildContext context, SystemPromptController controller, SystemPrompt prompt) {
    _showPromptDialog(context, controller, prompt);
  }

  void _showPromptDialog(BuildContext context, SystemPromptController controller, SystemPrompt? prompt) {
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

  void _showDeleteDialog(BuildContext context, SystemPromptController controller, SystemPrompt prompt) {
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
}