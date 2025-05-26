import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/model_controller.dart';
import '../../services/openai_service.dart';

class ConfigStatusWidget extends StatelessWidget {
  const ConfigStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final openaiService = Get.find<OpenAIService>();
    final modelController = Get.find<ModelController>();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前配置状态',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            Obx(() {
              final selectedModel = modelController.selectedModel.value;
              final isConfigured = openaiService.isConfigured;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow(
                    '选中模型',
                    selectedModel?.modelId ?? '未选择',
                    selectedModel != null,
                  ),
                  SizedBox(height: 8),
                  _buildStatusRow(
                    '供应商',
                    selectedModel?.provider.value?.name ?? '未配置',
                    selectedModel?.provider.value != null,
                  ),
                  SizedBox(height: 8),
                  _buildStatusRow(
                    'API配置',
                    isConfigured ? '已配置' : openaiService.configurationStatus,
                    isConfigured,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        isConfigured ? Icons.check_circle : Icons.error,
                        color: isConfigured ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isConfigured ? '配置完成，可以开始聊天' : '请完成配置后使用',
                        style: TextStyle(
                          color: isConfigured ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isValid) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.orange,
            ),
          ),
        ),
        Icon(
          isValid ? Icons.check : Icons.warning,
          color: isValid ? Colors.green : Colors.orange,
          size: 16,
        ),
      ],
    );
  }
}