import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/provider_controller.dart';
import '../../models/provider.dart';
import '../../services/openai_service.dart';

class ProviderSettingPage extends GetView<ProviderController> {
  const ProviderSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('供应商设置'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddProviderDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无供应商配置'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showAddProviderDialog(context),
                  child: Text('添加供应商'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.providers.length,
          itemBuilder: (context, index) {
            final provider = controller.providers[index].value;
            return Card(
              child: ListTile(
                title: Text(provider.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.baseUrl != null)
                      Text('Base URL: ${provider.baseUrl}'),
                    if (provider.apiKey != null)
                      Text('API Key: ${'*' * 8}${provider.apiKey!.substring(provider.apiKey!.length - 4)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditProviderDialog(context, provider, index),
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

  void _showAddProviderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final baseUrlController = TextEditingController();
    final apiKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加供应商'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '供应商名称',
                hintText: '例如：OpenAI, OpenRouter',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: baseUrlController,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: '例如：https://api.openai.com/v1',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: '输入API密钥',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final provider = Provider()
                  ..name = nameController.text
                  ..baseUrl = baseUrlController.text.isEmpty ? null : baseUrlController.text
                  ..apiKey = apiKeyController.text.isEmpty ? null : apiKeyController.text;
                
                controller.addProvider(provider);
                Navigator.pop(context);
              }
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditProviderDialog(BuildContext context, Provider provider, int index) {
    final nameController = TextEditingController(text: provider.name);
    final baseUrlController = TextEditingController(text: provider.baseUrl ?? '');
    final apiKeyController = TextEditingController(text: provider.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑供应商'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '供应商名称',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: baseUrlController,
              decoration: InputDecoration(
                labelText: 'Base URL',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                provider.name = nameController.text;
                provider.baseUrl = baseUrlController.text.isEmpty ? null : baseUrlController.text;
                provider.apiKey = apiKeyController.text.isEmpty ? null : apiKeyController.text;
                
                // 保存到数据库
                await controller.isar.writeTxn(() async {
                  await controller.isar.providers.put(provider);
                });
                
                controller.providers[index].refresh();
                
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
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这个供应商配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeProvider(index);
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