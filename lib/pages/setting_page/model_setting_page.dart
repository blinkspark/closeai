import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/model_controller.dart';
import '../../controllers/provider_controller.dart';
import '../../models/model.dart';
import '../../models/provider.dart';
import '../../services/openai_service.dart';

class ModelSettingPage extends GetView<ModelController> {
  const ModelSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('模型设置'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddModelDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.models.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无模型配置'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showAddModelDialog(context),
                  child: Text('添加模型'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.models.length,
          itemBuilder: (context, index) {
            final model = controller.models[index].value;
            return Card(
              child: ListTile(
                title: Text(model.modelId),
                subtitle: Text(
                  model.provider.value != null
                    ? '供应商: ${model.provider.value!.name}'
                    : '供应商: 未设置'
                ),
                leading: Radio<Model>(
                  value: model,
                  groupValue: controller.selectedModel.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectModel(value);
                    }
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditModelDialog(context, model, index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(context, index),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddModelDialog(BuildContext context) {
    final modelIdController = TextEditingController();
    final providerController = Get.find<ProviderController>();
    Provider? selectedProvider;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('添加模型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelIdController,
                decoration: InputDecoration(
                  labelText: '模型ID',
                  hintText: '例如：gpt-3.5-turbo, claude-3-sonnet',
                ),
              ),
              SizedBox(height: 16),
              Obx(() {
                if (providerController.providers.isEmpty) {
                  return Text('请先添加供应商配置');
                }
                
                return DropdownButtonFormField<Provider>(
                  value: selectedProvider != null
                    ? providerController.providers
                        .map((p) => p.value)
                        .where((p) => p.id == selectedProvider!.id)
                        .firstOrNull
                    : null,
                  decoration: InputDecoration(
                    labelText: '选择供应商',
                  ),
                  items: providerController.providers.map((provider) {
                    return DropdownMenuItem<Provider>(
                      value: provider.value,
                      child: Text(provider.value.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProvider = value;
                    });
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (modelIdController.text.isNotEmpty && selectedProvider != null) {
                  final model = Model()
                    ..modelId = modelIdController.text;
                  
                  model.provider.value = selectedProvider;
                  
                  controller.addModel(model);
                  Navigator.pop(context);
                }
              },
              child: Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModelDialog(BuildContext context, Model model, int index) {
    final modelIdController = TextEditingController(text: model.modelId);
    final providerController = Get.find<ProviderController>();
    Provider? selectedProvider = model.provider.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('编辑模型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelIdController,
                decoration: InputDecoration(
                  labelText: '模型ID',
                ),
              ),
              SizedBox(height: 16),
              Obx(() {
                if (providerController.providers.isEmpty) {
                  return Text('请先添加供应商配置');
                }
                
                return DropdownButtonFormField<Provider>(
                  value: selectedProvider != null
                    ? providerController.providers
                        .map((p) => p.value)
                        .where((p) => p.id == selectedProvider!.id)
                        .firstOrNull
                    : null,
                  decoration: InputDecoration(
                    labelText: '选择供应商',
                  ),
                  items: providerController.providers.map((provider) {
                    return DropdownMenuItem<Provider>(
                      value: provider.value,
                      child: Text(provider.value.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProvider = value;
                    });
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (modelIdController.text.isNotEmpty && selectedProvider != null) {
                  model.modelId = modelIdController.text;
                  model.provider.value = selectedProvider;
                  
                  // 保存到数据库
                  await controller.isar.writeTxn(() async {
                    await controller.isar.models.put(model);
                    await model.provider.save();
                  });
                  
                  controller.models[index].refresh();
                  
                  // 刷新OpenAI服务配置
                  if (Get.isRegistered<OpenAIService>()) {
                    Get.find<OpenAIService>().refreshClient();
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这个模型配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeModel(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('删除'),
          ),
        ],
      ),
    );
  }
}