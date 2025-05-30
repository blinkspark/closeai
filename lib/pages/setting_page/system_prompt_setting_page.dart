import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/system_prompt_controller.dart';
import './widgets/system_prompt_dialogs.dart';
import './widgets/system_prompt_list_item.dart';
import './widgets/empty_system_prompt_widget.dart'; // Import the new empty state widget

class SystemPromptSettingPage extends StatelessWidget {
  const SystemPromptSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SystemPromptController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('系统提示词管理'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create':
                  showPromptDialog(context, controller, null); // Updated to use the new dialog helper
                  break;
                case 'reset':
                  showResetDialog(context, controller); // Updated to use the new dialog helper
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('创建新预设'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh, color: Colors.orange),
                  title: Text('重置为默认', style: TextStyle(color: Colors.orange)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.systemPrompts.isEmpty) {
          return EmptySystemPromptWidget(
            onCreatePrompt: () => showPromptDialog(context, controller, null),
          ); // Use the new empty state widget
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
                  
                  return SystemPromptListItem(
                    key: ValueKey(promptRx.value.id),
                    promptRx: promptRx,
                    index: index,
                    controller: controller,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}