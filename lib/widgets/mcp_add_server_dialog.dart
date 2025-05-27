import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/mcp_server.dart';
import '../controllers/mcp_controller.dart';

class MCPAddServerDialog extends StatefulWidget {
  final MCPServer? server;

  const MCPAddServerDialog({super.key, this.server});

  @override
  State<MCPAddServerDialog> createState() => _MCPAddServerDialogState();
}

class _MCPAddServerDialogState extends State<MCPAddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  final _urlController = TextEditingController();
  final _envController = TextEditingController();

  String _selectedTransport = 'stdio';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      _nameController.text = widget.server!.name;
      _descriptionController.text = widget.server!.description;
      _selectedTransport = widget.server!.transport;
      _commandController.text = widget.server!.command ?? '';
      _argsController.text = widget.server!.args?.join(' ') ?? '';
      _urlController.text = widget.server!.url ?? '';
      
      // 将环境变量Map转换为字符串
      if (widget.server!.env != null) {
        final envEntries = widget.server!.env!.entries
            .map((e) => '${e.key}=${e.value}')
            .join('\n');
        _envController.text = envEntries;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _urlController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.server == null ? '添加MCP服务器' : '编辑MCP服务器'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '服务器名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入服务器名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入描述';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTransport,
                  decoration: const InputDecoration(
                    labelText: '传输类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'stdio', child: Text('Stdio')),
                    DropdownMenuItem(value: 'websocket', child: Text('WebSocket')),
                    DropdownMenuItem(value: 'sse', child: Text('Server-Sent Events')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTransport = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedTransport == 'stdio') ...[
                  TextFormField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      labelText: '命令',
                      border: OutlineInputBorder(),
                      hintText: '例如: node',
                    ),
                    validator: (value) {
                      if (_selectedTransport == 'stdio' && (value == null || value.isEmpty)) {
                        return '请输入命令';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _argsController,
                    decoration: const InputDecoration(
                      labelText: '参数',
                      border: OutlineInputBorder(),
                      hintText: '例如: server.js --port 3000',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedTransport == 'websocket' || _selectedTransport == 'sse') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                      hintText: '例如: ws://localhost:3000 或 http://localhost:3000/events',
                    ),
                    validator: (value) {
                      if ((_selectedTransport == 'websocket' || _selectedTransport == 'sse') && 
                          (value == null || value.isEmpty)) {
                        return '请输入URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _envController,
                  decoration: const InputDecoration(
                    labelText: '环境变量',
                    border: OutlineInputBorder(),
                    hintText: '每行一个，格式: KEY=VALUE',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveServer,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.server == null ? '添加' : '保存'),
        ),
      ],
    );
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 解析环境变量
      Map<String, String>? env;
      if (_envController.text.isNotEmpty) {
        env = {};
        final lines = _envController.text.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && trimmed.contains('=')) {
            final parts = trimmed.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=').trim();
              env[key] = value;
            }
          }
        }
      }

      // 解析参数
      List<String>? args;
      if (_argsController.text.isNotEmpty) {
        args = _argsController.text.split(' ').where((arg) => arg.isNotEmpty).toList();
      }

      final config = MCPServerConfig(
        name: _nameController.text,
        description: _descriptionController.text,
        transport: _selectedTransport,
        command: _selectedTransport == 'stdio' ? _commandController.text : null,
        args: args,
        url: (_selectedTransport == 'websocket' || _selectedTransport == 'sse') 
            ? _urlController.text : null,
        env: env,
      );

      final mcpController = Get.find<MCPController>();
      
      if (widget.server == null) {
        // 添加新服务器
        final success = await mcpController.addServer(config);
        if (success && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // 更新现有服务器
        final updatedServer = config.toServer();
        updatedServer.id = widget.server!.id;
        updatedServer.createdAt = widget.server!.createdAt;
        
        // 这里需要实现更新服务器的方法
        // 暂时先删除再添加
        await mcpController.removeServer(widget.server!.id);
        final success = await mcpController.addServer(config);
        if (success && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}