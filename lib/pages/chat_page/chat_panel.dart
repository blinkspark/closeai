import 'package:closeai/defs.dart';
import 'package:closeai/models/message.dart';
import 'package:closeai/pages/chat_page/chat_panel/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/session_controller.dart';
import '../../controllers/model_controller.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    final inputController = TextEditingController();
    return Obx(() {
      final index = sessionController.index.value;
      final isEmpty = sessionController.sessions.isEmpty;
      final sessionTitleController = TextEditingController(
        text: isEmpty ? '' : sessionController.sessions[index].value.title,
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sessionTitleController,
                    enabled: sessionController.editingTitle.value,
                  ),
                ),
                IconButton(
                  onPressed: isEmpty ? null : () {},
                  icon: Icon(Icons.assistant),
                  tooltip: '生成标题',
                ),
                IconButton(
                  onPressed:
                      isEmpty
                          ? null
                          : () {
                            if (sessionController.editingTitle.value) {
                              final session =
                                  sessionController.sessions[index].value;
                              session.title = sessionTitleController.text;
                              sessionController.sessions[index].value = session;
                              sessionController.updateSession(session);
                            }
                            sessionController.editingTitle.value =
                                !sessionController.editingTitle.value;
                          },
                  icon: Icon(Icons.edit),
                  tooltip: '编辑标题',
                ),
              ],
            ),
          ),
          Expanded(child: MessageList()),
          Divider(height: 1),
          // Chat Input
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                                  final providerName = modelData.provider.value?.name ?? '未知供应商';
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
                                        .firstWhere((model) => model.value.modelId == selectedModelId)
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
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.enter): () {
                              // 单独按Enter: 发送消息
                              if (!isEmpty && inputController.text.trim().isNotEmpty) {
                                _sendMessage(sessionController, inputController);
                              }
                            },
                          },
                          child: TextField(
                            controller: inputController,
                            maxLines: null,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              enabled: !isEmpty,
                              hintText: '输入内容 (Enter发送, Shift+Enter换行)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        onPressed:
                            isEmpty
                                ? null
                                : () => _sendMessage(sessionController, inputController),
                        icon: Icon(Icons.send),
                        tooltip: '发送',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _sendMessage(SessionController sessionController, TextEditingController inputController) async {
    if (inputController.text.trim().isEmpty) return;
    
    final content = inputController.text.trim();
    inputController.clear(); // 立即清空输入框
    
    // 异步发送消息，不等待完成
    sessionController.sendMessage(
      Message()
        ..content = content
        ..role = MessageRole.user,
    );
  }
}
