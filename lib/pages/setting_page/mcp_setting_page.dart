import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mcp_controller.dart';
import '../../models/mcp_server.dart';
import '../../widgets/mcp_server_tile.dart';
import '../../widgets/mcp_add_server_dialog.dart';

class MCPSettingPage extends StatelessWidget {
  const MCPSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mcpController = Get.find<MCPController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP服务器设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mcpController.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (mcpController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (mcpController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  mcpController.errorMessage.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => mcpController.refresh(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 状态卡片
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MCP状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusItem(
                          context,
                          '服务器',
                          '${mcpController.enabledServerCount}/${mcpController.servers.length}',
                          Icons.dns,
                        ),
                        const SizedBox(width: 24),
                        _buildStatusItem(
                          context,
                          '工具',
                          '${mcpController.toolCount}',
                          Icons.build,
                        ),
                        const SizedBox(width: 24),
                        _buildStatusItem(
                          context,
                          '资源',
                          '${mcpController.resourceCount}',
                          Icons.folder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 服务器列表
            Expanded(
              child: mcpController.servers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无MCP服务器',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右下角的按钮添加MCP服务器',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: mcpController.servers.length,
                      itemBuilder: (context, index) {
                        final server = mcpController.servers[index];
                        return MCPServerTile(
                          server: server,
                          onToggle: (enabled) => mcpController.toggleServer(server.id, enabled),
                          onEdit: () => _showEditServerDialog(context, server),
                          onDelete: () => _showDeleteConfirmDialog(context, server),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServerDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MCPAddServerDialog(),
    );
  }

  void _showEditServerDialog(BuildContext context, MCPServer server) {
    showDialog(
      context: context,
      builder: (context) => MCPAddServerDialog(server: server),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 "${server.name}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.find<MCPController>().removeServer(server.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}