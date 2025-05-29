import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/model_controller.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '模型选择：',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(width: 8),
        Expanded(
          child: GetBuilder<ModelController>(
            init: Get.find<ModelController>(),
            builder: (modelController) {
              return Obx(() {
                if (modelController.models.isEmpty) {
                  return Text(
                    '暂无可用模型',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                return DropdownButton<String>(
                  isExpanded: true,
                  underline: Container(),
                  focusColor: Colors.transparent,
                  value: modelController.selectedModel.value?.modelId,
                  hint: Text('请选择模型'),
                  items: modelController.models.map((model) {
                    final modelData = model.value;
                    final providerName =
                        modelData.provider.value?.name ?? '未知供应商';
                    return DropdownMenuItem<String>(
                      value: modelData.modelId,
                      child: Text(
                        '$providerName - ${modelData.modelId}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? selectedModelId) {
                    if (selectedModelId != null) {
                      final selectedModel = modelController.models
                          .firstWhere(
                            (model) => model.value.modelId == selectedModelId,
                          )
                          .value;
                      modelController.selectModel(selectedModel);
                    }
                  },
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
