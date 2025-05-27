import 'dart:convert';
import 'package:isar/isar.dart';

part 'mcp_server.g.dart';

@Collection()
class MCPServer {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String name;
  
  late String description;
  
  /// 传输类型: stdio, sse, websocket
  late String transport;
  
  /// 对于stdio传输的命令
  String? command;
  
  /// 对于stdio传输的参数
  List<String>? args;
  
  /// 对于sse/websocket传输的URL
  String? url;
  
  /// 环境变量 (JSON字符串格式)
  String? envJson;
  
  /// 是否启用
  bool isEnabled = true;
  
  /// 创建时间
  late DateTime createdAt;
  
  /// 更新时间
  late DateTime updatedAt;
  
  MCPServer() {
    final now = DateTime.now();
    createdAt = now;
    updatedAt = now;
  }
  
  /// 获取环境变量Map
  @ignore
  Map<String, String>? get env {
    if (envJson == null || envJson!.isEmpty) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(envJson!);
      return decoded.cast<String, String>();
    } catch (e) {
      return null;
    }
  }
  
  /// 设置环境变量Map
  @ignore
  set env(Map<String, String>? value) {
    if (value == null) {
      envJson = null;
    } else {
      envJson = jsonEncode(value);
    }
  }
}

/// MCP服务器配置
class MCPServerConfig {
  final String name;
  final String description;
  final String transport;
  final String? command;
  final List<String>? args;
  final String? url;
  final Map<String, String>? env;
  
  const MCPServerConfig({
    required this.name,
    required this.description,
    required this.transport,
    this.command,
    this.args,
    this.url,
    this.env,
  });
  
  MCPServer toServer() {
    return MCPServer()
      ..name = name
      ..description = description
      ..transport = transport
      ..command = command
      ..args = args
      ..url = url
      ..env = env;
  }
}