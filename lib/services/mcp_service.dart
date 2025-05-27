import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/mcp_server.dart';
import '../models/mcp_tool.dart';
import 'mcp_client.dart';

/// MCP服务接口
abstract class MCPService {
  /// 获取所有服务器
  Future<List<MCPServer>> getAllServers();
  
  /// 添加服务器
  Future<void> addServer(MCPServerConfig config);
  
  /// 删除服务器
  Future<void> removeServer(int serverId);
  
  /// 更新服务器
  Future<void> updateServer(MCPServer server);
  
  /// 启用/禁用服务器
  Future<void> toggleServer(int serverId, bool enabled);
  
  /// 连接到服务器
  Future<void> connectToServer(int serverId);
  
  /// 断开服务器连接
  Future<void> disconnectFromServer(int serverId);
  
  /// 获取所有可用工具
  Future<List<MCPTool>> getAllAvailableTools();
  
  /// 执行工具调用
  Future<MCPToolResult> executeTool(String toolName, Map<String, dynamic> arguments);
  
  /// 获取所有可用资源
  Future<List<MCPResource>> getAllAvailableResources();
  
  /// 读取资源
  Future<MCPResource> readResource(String uri);
}

/// MCP服务实现
class MCPServiceImpl extends GetxService implements MCPService {
  final Map<int, MCPClient> _clients = {};
  final RxList<MCPServer> _servers = <MCPServer>[].obs;
  final RxList<MCPTool> _availableTools = <MCPTool>[].obs;
  final RxList<MCPResource> _availableResources = <MCPResource>[].obs;
  
  List<MCPServer> get servers => _servers;
  List<MCPTool> get availableTools => _availableTools;
  List<MCPResource> get availableResources => _availableResources;
  
  @override
  void onInit() {
    super.onInit();
    _loadServers();
  }
  
  @override
  void onClose() {
    // 断开所有连接
    for (final client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
    super.onClose();
  }
  
  /// 加载服务器列表
  Future<void> _loadServers() async {
    try {
      final isar = Get.find<Isar>();
      final servers = await isar.mCPServers.where().findAll();
      _servers.assignAll(servers);
      
      // 自动连接已启用的服务器
      for (final server in servers.where((s) => s.isEnabled)) {
        try {
          await connectToServer(server.id);
        } catch (e) {
          print('自动连接服务器失败 ${server.name}: $e');
        }
      }
    } catch (e) {
      print('加载服务器列表失败: $e');
    }
  }
  
  @override
  Future<List<MCPServer>> getAllServers() async {
    return _servers.toList();
  }
  
  @override
  Future<void> addServer(MCPServerConfig config) async {
    try {
      final isar = Get.find<Isar>();
      final server = config.toServer();
      
      await isar.writeTxn(() async {
        await isar.mCPServers.put(server);
      });
      
      _servers.add(server);
      print('服务器已添加: ${server.name}');
    } catch (e) {
      print('添加服务器失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> removeServer(int serverId) async {
    try {
      // 先断开连接
      await disconnectFromServer(serverId);
      
      final isar = Get.find<Isar>();
      await isar.writeTxn(() async {
        await isar.mCPServers.delete(serverId);
      });
      
      _servers.removeWhere((server) => server.id == serverId);
      print('服务器已删除: $serverId');
    } catch (e) {
      print('删除服务器失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> updateServer(MCPServer server) async {
    try {
      final isar = Get.find<Isar>();
      server.updatedAt = DateTime.now();
      
      await isar.writeTxn(() async {
        await isar.mCPServers.put(server);
      });
      
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server;
      }
      
      print('服务器已更新: ${server.name}');
    } catch (e) {
      print('更新服务器失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> toggleServer(int serverId, bool enabled) async {
    try {
      final server = _servers.firstWhere((s) => s.id == serverId);
      server.isEnabled = enabled;
      server.updatedAt = DateTime.now();
      
      await updateServer(server);
      
      if (enabled) {
        await connectToServer(serverId);
      } else {
        await disconnectFromServer(serverId);
      }
    } catch (e) {
      print('切换服务器状态失败: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> connectToServer(int serverId) async {
    try {
      final server = _servers.firstWhere((s) => s.id == serverId);
      
      if (_clients.containsKey(serverId)) {
        print('服务器已连接: ${server.name}');
        return;
      }
      
      MCPClient client;
      
      switch (server.transport) {
        case 'websocket':
          if (server.url == null) {
            throw Exception('WebSocket服务器需要URL');
          }
          client = WebSocketMCPClient(server.url!);
          break;
          
        case 'stdio':
          if (server.command == null) {
            throw Exception('Stdio服务器需要命令');
          }
          client = StdioMCPClient(
            command: server.command!,
            args: server.args ?? [],
            env: server.env,
          );
          break;
          
        case 'sse':
          if (server.url == null) {
            throw Exception('SSE服务器需要URL');
          }
          client = SSEMCPClient(server.url!);
          break;
          
        default:
          throw Exception('不支持的传输类型: ${server.transport}');
      }
      
      await client.connect();
      await client.getServerInfo(); // 验证连接
      
      _clients[serverId] = client;
      
      // 刷新工具和资源列表
      await _refreshToolsAndResources();
      
      print('已连接到服务器: ${server.name}');
    } catch (e) {
      print('连接服务器失败 $serverId: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> disconnectFromServer(int serverId) async {
    try {
      final client = _clients[serverId];
      if (client != null) {
        await client.disconnect();
        _clients.remove(serverId);
        
        // 刷新工具和资源列表
        await _refreshToolsAndResources();
        
        print('已断开服务器连接: $serverId');
      }
    } catch (e) {
      print('断开服务器连接失败 $serverId: $e');
      rethrow;
    }
  }
  
  /// 刷新工具和资源列表
  Future<void> _refreshToolsAndResources() async {
    final allTools = <MCPTool>[];
    final allResources = <MCPResource>[];
    
    for (final client in _clients.values) {
      try {
        final tools = await client.listTools();
        allTools.addAll(tools);
        
        final resources = await client.listResources();
        allResources.addAll(resources);
      } catch (e) {
        print('刷新工具和资源失败: $e');
      }
    }
    
    _availableTools.assignAll(allTools);
    _availableResources.assignAll(allResources);
  }
  
  @override
  Future<List<MCPTool>> getAllAvailableTools() async {
    return _availableTools.toList();
  }
  
  @override
  Future<MCPToolResult> executeTool(String toolName, Map<String, dynamic> arguments) async {
    // 查找拥有该工具的客户端
    for (final client in _clients.values) {
      try {
        final tools = await client.listTools();
        if (tools.any((tool) => tool.name == toolName)) {
          return await client.callTool(toolName, arguments);
        }
      } catch (e) {
        print('检查工具失败: $e');
        continue;
      }
    }
    
    throw Exception('未找到工具: $toolName');
  }
  
  @override
  Future<List<MCPResource>> getAllAvailableResources() async {
    return _availableResources.toList();
  }
  
  @override
  Future<MCPResource> readResource(String uri) async {
    // 查找拥有该资源的客户端
    for (final client in _clients.values) {
      try {
        final resources = await client.listResources();
        if (resources.any((resource) => resource.uri == uri)) {
          return await client.readResource(uri);
        }
      } catch (e) {
        print('检查资源失败: $e');
        continue;
      }
    }
    
    throw Exception('未找到资源: $uri');
  }
}