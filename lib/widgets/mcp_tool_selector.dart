import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mcp_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/mcp_tool.dart';

class MCPToolSelector extends StatelessWidget {
  final Function(String)? onToolSelected;

  const MCPToolSelector({super.key, this.onToolSelected});

  @override
  Widget build(BuildContext context) {
    final mcpController = Get.find<MCPController>();
    final chatController = Get.find<ChatController>();

    return Obx(() {
      if (!chatController.hasMCPTools) {
        return const SizedBox.shrink();
      }

      final tools = chatController.getAvailableTools();

      return Card(
        margin: const EdgeInsets.all(8),
        child: ExpansionTile(
          leading: Icon(
            Icons.build,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'MCP工具 (${tools.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            '点击工具名称插入调用代码',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          children: [
            if (tools.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无可用工具'),
              )
            else ...[
              // 工具帮助按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showToolHelp(context),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('查看使用帮助'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 工具列表
              ...tools.map((tool) => MCPToolTile(
                tool: tool,
                onTap: () => _insertToolCall(tool),
              )),
            ],
          ],
        ),
      );
    });
  }

  void _insertToolCall(MCPTool tool) {
    // 生成工具调用代码
    final buffer = StringBuffer();
    buffer.write('@${tool.name}(');
    
    // 添加参数模板
    if (tool.inputSchema.containsKey('properties')) {
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      final required = tool.inputSchema['required'] as List<dynamic>? ?? [];
      
      final params = <String>[];
      for (final entry in properties.entries) {
        final param = entry.value as Map<String, dynamic>;
        final type = param['type'] ?? 'string';
        final isRequired = required.contains(entry.key);
        
        String defaultValue;
        switch (type) {
          case 'string':
            defaultValue = '""';
            break;
          case 'number':
          case 'integer':
            defaultValue = '0';
            break;
          case 'boolean':
            defaultValue = 'false';
            break;
          case 'array':
            defaultValue = '[]';
            break;
          case 'object':
            defaultValue = '{}';
            break;
          default:
            defaultValue = '""';
        }
        
        if (isRequired) {
          params.add('${entry.key}=$defaultValue');
        }
      }
      
      buffer.write(params.join(', '));
    }
    
    buffer.write(')');
    
    if (onToolSelected != null) {
      onToolSelected!(buffer.toString());
    }
  }

  void _showToolHelp(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final helpText = chatController.getToolCallHelp();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MCP工具使用帮助'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              helpText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class MCPToolTile extends StatelessWidget {
  final MCPTool tool;
  final VoidCallback onTap;

  const MCPToolTile({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.extension,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        '@${tool.name}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tool.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (tool.inputSchema.containsKey('properties')) ...[
            const SizedBox(height: 4),
            _buildParameterInfo(context),
          ],
        ],
      ),
      trailing: Icon(
        Icons.add_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildParameterInfo(BuildContext context) {
    final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
    final required = tool.inputSchema['required'] as List<dynamic>? ?? [];
    
    if (properties.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: properties.entries.map((entry) {
        final param = entry.value as Map<String, dynamic>;
        final type = param['type'] ?? 'string';
        final isRequired = required.contains(entry.key);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isRequired 
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.key}: $type${isRequired ? '*' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isRequired
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        );
      }).toList(),
    );
  }
}