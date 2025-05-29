import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/chat_controller.dart';

class SearchDetailsDialog {
  static void show(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.search, color: Colors.blue),
            SizedBox(width: 8),
            Text('搜索详情'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Text(
                  '搜索结果数量: ${chatController.searchResultCount.value} 个网页',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 16),
                TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.search),
                      text: '搜索查询',
                    ),
                    Tab(
                      icon: Icon(Icons.list),
                      text: '搜索结果',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 搜索查询标签页
                      _buildSearchQueriesTab(context, chatController),
                      // 搜索结果标签页
                      _buildSearchResultsTab(context, chatController),
                    ],
                  ),
                ),
              ],
            ),
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

  static Widget _buildSearchQueriesTab(
    BuildContext context, 
    ChatController chatController
  ) {
    return Obx(() {
      if (chatController.lastSearchQueries.isEmpty) {
        return Center(child: Text('暂无搜索记录'));
      }
      return ListView.builder(
        itemCount: chatController.lastSearchQueries.length,
        itemBuilder: (context, index) {
          final query = chatController.lastSearchQueries[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    query,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  static Widget _buildSearchResultsTab(
    BuildContext context, 
    ChatController chatController
  ) {
    return Obx(() {
      if (chatController.lastSearchResults.isEmpty) {
        return Center(child: Text('暂无搜索结果'));
      }
      return ListView.builder(
        itemCount: chatController.lastSearchResults.length,
        itemBuilder: (context, index) {
          final result = chatController.lastSearchResults[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(Icons.article, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${index + 1}. ${result['title'] ?? '无标题'}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // 来源和时间
                if (result['media'] != null || result['publish_date'] != null)
                  Row(
                    children: [
                      if (result['media'] != null) ...[
                        Icon(Icons.source, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '来源: ${result['media']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (result['media'] != null && result['publish_date'] != null)
                        Text(' • ', style: TextStyle(color: Colors.grey[600])),
                      if (result['publish_date'] != null) ...[
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          result['publish_date'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                // 链接
                if (result['link'] != null) ...[
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // 可以在这里添加打开链接的功能
                      Get.snackbar('链接', result['link']);
                    },
                    child: Text(
                      result['link'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // 内容摘要
                if (result['content'] != null && result['content'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      result['content'].toString().length > 200
                          ? '${result['content'].toString().substring(0, 200)}...'
                          : result['content'].toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }
}
