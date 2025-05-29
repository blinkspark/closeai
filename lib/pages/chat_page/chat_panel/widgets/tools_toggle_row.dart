import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../setting_page/zhipu_setting_page.dart';
import 'search_details_dialog.dart';

class ToolsToggleRow extends StatelessWidget {
  const ToolsToggleRow({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Obx(() {
      return Row(
        children: [
          // 工具开关按钮
          InkWell(
            onTap: () {
              // 如果有搜索结果，显示搜索详情；否则切换工具开关
              if (chatController.searchResultCount.value > 0) {
                SearchDetailsDialog.show(context, chatController);
              } else {
                chatController.toggleTools();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chatController.isToolsEnabledObs.value
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: chatController.isToolsEnabledObs.value
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
                    color: chatController.isToolsEnabledObs.value
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Obx(() {
                    final hasSearchResults =
                        chatController.searchResultCount.value > 0;
                    final searchText = chatController.isToolsEnabledObs.value
                        ? (hasSearchResults
                            ? '已搜索到 ${chatController.searchResultCount.value} 个网页'
                            : '联网搜索')
                        : '联网搜索';

                    return Text(
                      searchText,
                      style: TextStyle(
                        fontSize: 12,
                        color: chatController.isToolsEnabledObs.value
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    );
                  }),
                  Obx(() {
                    if (chatController.isToolsEnabledObs.value) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          Icon(
                            chatController.searchResultCount.value > 0
                                ? Icons.info_outline
                                : Icons.keyboard_arrow_right,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
          // 单独的工具开关按钮（当有搜索结果时显示）
          Obx(() {
            if (chatController.searchResultCount.value > 0) {
              return Row(
                children: [
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: chatController.toggleTools,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: chatController.isToolsEnabledObs.value
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: chatController.isToolsEnabledObs.value
                              ? Colors.blue
                              : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        chatController.isToolsEnabledObs.value
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        size: 16,
                        color: chatController.isToolsEnabledObs.value
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 8),
          // 工具状态提示
          Obx(() {
            if (!chatController.isToolsAvailableObs.value) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
              );
            }
            return const SizedBox.shrink();
          }),
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
