import 'package:closeai/defs.dart';
import 'package:closeai/models/message.dart';
import 'package:closeai/pages/chat_page/chat_panel/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/session_controller.dart';
import '../../controllers/model_controller.dart';
import '../../controllers/system_prompt_controller.dart';
import '../../controllers/chat_controller.dart';
import '../setting_page/zhipu_setting_page.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = Get.find();
    final inputController = TextEditingController();
    return Obx(() {
      final index = sessionController.index.value;
      final isEmpty = sessionController.sessions.isEmpty;
      final isSending = sessionController.sendingMessage.value;
      final sessionTitleController = TextEditingController(
        text: isEmpty ? '' : sessionController.sessions[index].value.title,
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 会话标题行
                Row(
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
                                  sessionController.sessions[index].value =
                                      session;
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
                SizedBox(height: 8),
                // 系统提示词选择行
                _buildSystemPromptSelector(context),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }

                              return DropdownButton<String>(
                                isExpanded: true,
                                underline: Container(),
                                focusColor: Colors.transparent,
                                value:
                                    modelController
                                        .selectedModel
                                        .value
                                        ?.modelId,
                                hint: Text('请选择模型'),
                                items:
                                    modelController.models.map((model) {
                                      final modelData = model.value;
                                      final providerName =
                                          modelData.provider.value?.name ??
                                          '未知供应商';
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
                                    final selectedModel =
                                        modelController.models
                                            .firstWhere(
                                              (model) =>
                                                  model.value.modelId ==
                                                  selectedModelId,
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
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 工具开关行
                      _buildToolsToggleRow(),
                      SizedBox(height: 8),
                      // 输入框行
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(
                              LogicalKeyboardKey.enter,
                            ): () {
                              // 单独按Enter: 发送消息
                              if (!isEmpty &&
                                  !isSending &&
                                  inputController.text.trim().isNotEmpty) {
                                _sendMessage(
                                  sessionController,
                                  inputController,
                                );
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
                              enabled: !isEmpty && !isSending,
                              hintText:
                                  isSending
                                      ? '正在发送消息...'
                                      : '输入内容 (Enter发送, Shift+Enter换行)',
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
                            isEmpty || isSending
                                ? null
                                : () => _sendMessage(
                                  sessionController,
                                  inputController,
                                ),
                        icon:
                            isSending
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(Icons.send),
                        tooltip: isSending ? '发送中...' : '发送',
                          ),
                        ],
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

  Widget _buildSystemPromptSelector(BuildContext context) {
    final systemPromptController = Get.find<SystemPromptController>();

    return Obx(() {
      return Row(
        children: [
          Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '系统提示词:',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 32,
              child: DropdownButtonFormField<int>(
                value: systemPromptController.selectedSystemPrompt.value?.id,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                items:
                    systemPromptController.systemPrompts.map((promptRx) {
                      final prompt = promptRx.value;
                      return DropdownMenuItem<int>(
                        value: prompt.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (prompt.isDefault)
                              Icon(Icons.star, size: 14, color: Colors.amber),
                            if (prompt.isDefault) SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                prompt.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (int? promptId) {
                  if (promptId != null) {
                    final prompt =
                        systemPromptController.systemPrompts
                            .firstWhere((p) => p.value.id == promptId)
                            .value;
                    systemPromptController.selectSystemPrompt(prompt);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          if (systemPromptController.useTemporaryContent.value)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '已修改',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          IconButton(
            onPressed:
                () => _showSystemPromptDialog(context, systemPromptController),
            icon: Icon(Icons.edit, size: 16),
            tooltip: '编辑系统提示词',
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.all(4),
          ),
        ],
      );
    });
  }

  void _showSystemPromptDialog(
    BuildContext context,
    SystemPromptController controller,
  ) {
    final contentController = TextEditingController(
      text: controller.temporaryPromptContent.value,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
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
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
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
                                backgroundColor: Colors.green.withAlpha(
                                  (255 * 0.2) as int,
                                ),
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
                onPressed: () => _showVariablesDialog(context, controller),
                icon: Icon(Icons.code, size: 16),
                label: Text('变量'),
              ),
              TextButton.icon(
                onPressed: () => _showPreviewDialog(context, controller),
                icon: Icon(Icons.preview, size: 16),
                label: Text('预览'),
              ),
              if (controller.useTemporaryContent.value)
                TextButton.icon(
                  onPressed: () {
                    controller.resetTemporaryContent();
                    contentController.text =
                        controller.temporaryPromptContent.value;
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

  void _showVariablesDialog(
    BuildContext context,
    SystemPromptController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                      children:
                          variables.entries.map((entry) {
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

  void _showPreviewDialog(
    BuildContext context,
    SystemPromptController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  Future<void> _sendMessage(
    SessionController sessionController,
    TextEditingController inputController,
  ) async {
    if (inputController.text.trim().isEmpty ||
        sessionController.sendingMessage.value) {
      return;
    }

    final content = inputController.text.trim();
    inputController.clear(); // 立即清空输入框

    // 异步发送消息，不等待完成
    sessionController.sendMessage(
      Message()
        ..content = content
        ..role = MessageRole.user,
    );
  }

  /// 构建工具开关行
  Widget _buildToolsToggleRow() {
    final chatController = Get.find<ChatController>();
    
    return Obx(() {
      return Row(
        children: [
          // 工具开关按钮
          InkWell(
            onTap: chatController.toggleTools,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chatController.isToolsEnabled
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: chatController.isToolsEnabled
                    ? Colors.blue
                    : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: chatController.isToolsEnabled
                      ? Colors.blue
                      : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '联网搜索',
                    style: TextStyle(
                      fontSize: 12,
                      color: chatController.isToolsEnabled
                        ? Colors.blue
                        : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 工具状态提示
          if (!chatController.isToolsAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '未配置',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // 配置按钮
          IconButton(
            onPressed: () {
              Get.to(() => const ZhipuSettingPage());
            },
            icon: const Icon(Icons.settings, size: 16),
            tooltip: '智谱AI配置',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
        ],
      );
    });
  }
}
