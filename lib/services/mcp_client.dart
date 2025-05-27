import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:dio/dio.dart';
import '../models/mcp_tool.dart';

/// MCP客户端接口
abstract class MCPClient {
  /// 连接到服务器
  Future<void> connect();
  
  /// 断开连接
  Future<void> disconnect();
  
  /// 是否已连接
  bool get isConnected;
  
  /// 获取服务器信息
  Future<Map<String, dynamic>> getServerInfo();
  
  /// 列出可用工具
  Future<List<MCPTool>> listTools();
  
  /// 调用工具
  Future<MCPToolResult> callTool(String name, Map<String, dynamic> arguments);
  
  /// 列出资源
  Future<List<MCPResource>> listResources();
  
  /// 读取资源
  Future<MCPResource> readResource(String uri);
}

/// WebSocket MCP客户端
class WebSocketMCPClient implements MCPClient {
  final String url;
  WebSocketChannel? _channel;
  Peer? _peer;
  bool _isConnected = false;
  
  WebSocketMCPClient(this.url);
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Future<void> connect() async {
    try {
      _channel = IOWebSocketChannel.connect(url);
      _peer = Peer(_channel!.cast<String>());
      _peer!.listen();
      _isConnected = true;
      print('WebSocket MCP客户端已连接到: $url');
    } catch (e) {
      print('WebSocket连接失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> disconnect() async {
    if (_peer != null) {
      await _peer!.close();
      _peer = null;
    }
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    print('WebSocket MCP客户端已断开连接');
  }
  
  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'roots': {'listChanged': true},
          'sampling': {},
        },
        'clientInfo': {
          'name': 'closeai',
          'version': '0.1.0',
        },
      });
      
      return result as Map<String, dynamic>;
    } catch (e) {
      print('获取服务器信息失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<MCPTool>> listTools() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('tools/list', {});
      
      // 检查响应数据是否为空或格式不正确
      if (result == null) {
        return [];
      }
      
      final toolsData = result['tools'];
      if (toolsData == null) {
        return [];
      }
      
      final tools = toolsData as List<dynamic>;
      return tools.map((tool) => MCPTool.fromJson(tool as Map<String, dynamic>)).toList();
    } catch (e) {
      print('获取工具列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('tools/call', {
        'name': name,
        'arguments': arguments,
      });
      
      return MCPToolResult.success(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        content: jsonEncode(result),
      );
    } catch (e) {
      print('工具调用失败: $e');
      return MCPToolResult.error(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<List<MCPResource>> listResources() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('resources/list', {});
      
      // 检查响应数据是否为空或格式不正确
      if (result == null) {
        return [];
      }
      
      final resourcesData = result['resources'];
      if (resourcesData == null) {
        return [];
      }
      
      final resources = resourcesData as List<dynamic>;
      return resources.map((resource) => MCPResource.fromJson(resource as Map<String, dynamic>)).toList();
    } catch (e) {
      print('获取资源列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPResource> readResource(String uri) async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('resources/read', {
        'uri': uri,
      });
      
      return MCPResource.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      print('读取资源失败: $e');
      rethrow;
    }
  }
}

/// Stdio MCP客户端
class StdioMCPClient implements MCPClient {
  final String command;
  final List<String> args;
  final Map<String, String>? env;
  
  Process? _process;
  Peer? _peer;
  bool _isConnected = false;
  
  StdioMCPClient({
    required this.command,
    required this.args,
    this.env,
  });
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Future<void> connect() async {
    try {
      _process = await Process.start(
        command,
        args,
        environment: env,
      );
      
      // 简化实现，暂时使用基本的JSON-RPC通信
      _peer = Peer(
        StreamChannel.withGuarantees(
          _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()),
          StreamController<String>().sink,
        ),
      );
      _peer!.listen();
      _isConnected = true;
      print('Stdio MCP客户端已启动: $command ${args.join(' ')}');
    } catch (e) {
      print('Stdio进程启动失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> disconnect() async {
    if (_peer != null) {
      await _peer!.close();
      _peer = null;
    }
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
    }
    _isConnected = false;
    print('Stdio MCP客户端已断开连接');
  }
  
  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'roots': {'listChanged': true},
          'sampling': {},
        },
        'clientInfo': {
          'name': 'closeai',
          'version': '0.1.0',
        },
      });
      
      return result as Map<String, dynamic>;
    } catch (e) {
      print('获取服务器信息失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<MCPTool>> listTools() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('tools/list', {});
      
      // 检查响应数据是否为空或格式不正确
      if (result == null) {
        return [];
      }
      
      final toolsData = result['tools'];
      if (toolsData == null) {
        return [];
      }
      
      final tools = toolsData as List<dynamic>;
      return tools.map((tool) => MCPTool.fromJson(tool as Map<String, dynamic>)).toList();
    } catch (e) {
      print('获取工具列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('tools/call', {
        'name': name,
        'arguments': arguments,
      });
      
      return MCPToolResult.success(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        content: jsonEncode(result),
      );
    } catch (e) {
      print('工具调用失败: $e');
      return MCPToolResult.error(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<List<MCPResource>> listResources() async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('resources/list', {});
      
      // 检查响应数据是否为空或格式不正确
      if (result == null) {
        return [];
      }
      
      final resourcesData = result['resources'];
      if (resourcesData == null) {
        return [];
      }
      
      final resources = resourcesData as List<dynamic>;
      return resources.map((resource) => MCPResource.fromJson(resource as Map<String, dynamic>)).toList();
    } catch (e) {
      print('获取资源列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPResource> readResource(String uri) async {
    if (!_isConnected || _peer == null) {
      throw Exception('客户端未连接');
    }
    
    try {
      final result = await _peer!.sendRequest('resources/read', {
        'uri': uri,
      });
      
      return MCPResource.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      print('读取资源失败: $e');
      rethrow;
    }
  }
}

/// Server-Sent Events MCP客户端
class SSEMCPClient implements MCPClient {
  final String url;
  final Dio _dio = Dio();
  bool _isConnected = false;
  
  SSEMCPClient(this.url);
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Future<void> connect() async {
    try {
      // 对于SSE，我们只是标记为已连接，实际连接在使用时建立
      _isConnected = true;
      print('SSE MCP客户端已准备连接到: $url');
    } catch (e) {
      print('SSE连接失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> disconnect() async {
    _isConnected = false;
    print('SSE MCP客户端已断开连接');
  }
  
  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    if (!_isConnected) {
      throw Exception('客户端未连接');
    }
    
    try {
      final response = await _dio.post(
        '$url/initialize',
        data: {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'roots': {'listChanged': true},
            'sampling': {},
          },
          'clientInfo': {
            'name': 'closeai',
            'version': '0.1.0',
          },
        },
        options: Options(
          validateStatus: (status) => status! < 500, // 接受所有非服务器错误状态码
        ),
      );
      
      if (response.statusCode == 406) {
        throw Exception('服务器不支持此请求格式，可能不是有效的MCP服务器');
      }
      
      // 检查响应数据类型并处理
      if (response.data is String) {
        // 如果返回的是字符串，尝试解析为JSON
        try {
          final jsonData = jsonDecode(response.data as String);
          if (jsonData is Map<String, dynamic>) {
            return jsonData;
          } else {
            // 如果不是Map，返回包装的响应
            return {'message': response.data, 'status': 'success'};
          }
        } catch (e) {
          // JSON解析失败，返回字符串响应
          return {'message': response.data, 'status': 'success'};
        }
      } else if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else {
        // 其他类型，包装返回
        return {'data': response.data, 'status': 'success'};
      }
    } catch (e) {
      if (e.toString().contains('406')) {
        throw Exception('服务器返回406错误，可能不支持MCP协议或请求格式不正确');
      }
      print('获取服务器信息失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<MCPTool>> listTools() async {
    if (!_isConnected) {
      throw Exception('客户端未连接');
    }
    
    try {
      final response = await _dio.post(
        '$url/tools/list',
        data: {},
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 406) {
        throw Exception('服务器不支持工具列表请求');
      }
      
      // 检查响应数据是否为空或格式不正确
      if (response.data == null) {
        return [];
      }
      
      Map<String, dynamic> dataMap;
      
      // 处理不同类型的响应数据
      if (response.data is String) {
        try {
          final jsonData = jsonDecode(response.data as String);
          if (jsonData is Map<String, dynamic>) {
            dataMap = jsonData;
          } else {
            return [];
          }
        } catch (e) {
          return [];
        }
      } else if (response.data is Map<String, dynamic>) {
        dataMap = response.data as Map<String, dynamic>;
      } else {
        return [];
      }
      
      final toolsData = dataMap['tools'];
      if (toolsData == null) {
        return [];
      }
      
      final tools = toolsData as List<dynamic>;
      return tools.map((tool) => MCPTool.fromJson(tool as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e.toString().contains('406')) {
        throw Exception('服务器不支持MCP工具协议');
      }
      print('获取工具列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    if (!_isConnected) {
      throw Exception('客户端未连接');
    }
    
    try {
      final response = await _dio.post(
        '$url/tools/call',
        data: {
          'name': name,
          'arguments': arguments,
        },
      );
      
      // 处理响应数据
      String resultContent;
      if (response.data is String) {
        resultContent = response.data as String;
      } else {
        resultContent = jsonEncode(response.data);
      }
      
      return MCPToolResult.success(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        content: resultContent,
      );
    } catch (e) {
      print('工具调用失败: $e');
      return MCPToolResult.error(
        toolCallId: DateTime.now().millisecondsSinceEpoch.toString(),
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<List<MCPResource>> listResources() async {
    if (!_isConnected) {
      throw Exception('客户端未连接');
    }
    
    try {
      final response = await _dio.post(
        '$url/resources/list',
        data: {},
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 406) {
        throw Exception('服务器不支持资源列表请求');
      }
      
      // 检查响应数据是否为空或格式不正确
      if (response.data == null) {
        return [];
      }
      
      Map<String, dynamic> dataMap;
      
      // 处理不同类型的响应数据
      if (response.data is String) {
        try {
          final jsonData = jsonDecode(response.data as String);
          if (jsonData is Map<String, dynamic>) {
            dataMap = jsonData;
          } else {
            return [];
          }
        } catch (e) {
          return [];
        }
      } else if (response.data is Map<String, dynamic>) {
        dataMap = response.data as Map<String, dynamic>;
      } else {
        return [];
      }
      
      final resourcesData = dataMap['resources'];
      if (resourcesData == null) {
        return [];
      }
      
      final resources = resourcesData as List<dynamic>;
      return resources.map((resource) => MCPResource.fromJson(resource as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e.toString().contains('406')) {
        throw Exception('服务器不支持MCP资源协议');
      }
      print('获取资源列表失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<MCPResource> readResource(String uri) async {
    if (!_isConnected) {
      throw Exception('客户端未连接');
    }
    
    try {
      final response = await _dio.post(
        '$url/resources/read',
        data: {
          'uri': uri,
        },
      );
      
      // 处理不同类型的响应数据
      Map<String, dynamic> dataMap;
      
      if (response.data is String) {
        try {
          final jsonData = jsonDecode(response.data as String);
          if (jsonData is Map<String, dynamic>) {
            dataMap = jsonData;
          } else {
            throw Exception('无效的资源数据格式');
          }
        } catch (e) {
          throw Exception('解析资源数据失败: $e');
        }
      } else if (response.data is Map<String, dynamic>) {
        dataMap = response.data as Map<String, dynamic>;
      } else {
        throw Exception('不支持的资源数据类型');
      }
      
      return MCPResource.fromJson(dataMap);
    } catch (e) {
      print('读取资源失败: $e');
      rethrow;
    }
  }
}