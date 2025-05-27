import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mcp_controller.dart';

class MCPStatusIndicator extends StatelessWidget {
  const MCPStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final mcpController = Get.find<MCPController>();

    return Obx(() {
      if (!mcpController.hasConnectedServers) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'MCP: ${mcpController.enabledServerCount}服务器 | ${mcpController.toolCount}工具',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mcpController.hasAvailableTools
                    ? Colors.green
                    : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class MCPToolCallIndicator extends StatelessWidget {
  final String toolName;
  final bool isExecuting;
  final bool isSuccess;
  final String? error;

  const MCPToolCallIndicator({
    super.key,
    required this.toolName,
    this.isExecuting = false,
    this.isSuccess = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String status;

    if (isExecuting) {
      icon = Icons.hourglass_empty;
      color = Theme.of(context).colorScheme.primary;
      status = '执行中';
    } else if (error != null) {
      icon = Icons.error;
      color = Theme.of(context).colorScheme.error;
      status = '失败';
    } else if (isSuccess) {
      icon = Icons.check_circle;
      color = Colors.green;
      status = '成功';
    } else {
      icon = Icons.radio_button_unchecked;
      color = Theme.of(context).colorScheme.outline;
      status = '待执行';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExecuting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$toolName - $status',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (error != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: error!,
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MCPToolCallHistory extends StatelessWidget {
  const MCPToolCallHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('MCP工具调用历史'),
        children: [
          // 这里可以显示最近的工具调用历史
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '工具调用历史功能即将推出...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}