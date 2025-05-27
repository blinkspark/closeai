import 'package:get/get.dart';
import '../models/mcp_server.dart';
import '../models/mcp_tool.dart';
import '../services/mcp_service.dart';

class MCPController extends GetxController {
  late final MCPService _mcpService;
  
  final RxList<MCPServer> servers = <MCPServer>[].obs;
  final RxList<MCPTool> availableTools = <MCPTool>[].obs;
  final RxList<MCPResource> availableResources = <MCPResource>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _mcpService = Get.find<MCPService>();
    _loadData();
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final serverList = await _mcpService.getAllServers();
      servers.assignAll(serverList);
      
      final toolList = await _mcpService.getAllAvailableTools();
      availableTools.assignAll(toolList);
      
      final resourceList = await _mcpService.getAllAvailableResources();
      availableResources.assignAll(resourceList);
    } catch (e) {
      errorMessage.value = '加载数据失败: $e';
      print('加载MCP数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 刷新数据
  Future<void> refresh() async {
    await _loadData();
  }
  
  /// 添加服务器
  Future<bool> addServer(MCPServerConfig config) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _mcpService.addServer(config);
      await _loadData();
      
      Get.snackbar(
        '成功',
        '服务器 "${config.name}" 已添加',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = '添加服务器失败: $e';
      Get.snackbar(
        '错误',
        '添加服务器失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 删除服务器
  Future<bool> removeServer(int serverId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _mcpService.removeServer(serverId);
      await _loadData();
      
      Get.snackbar(
        '成功',
        '服务器已删除',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = '删除服务器失败: $e';
      Get.snackbar(
        '错误',
        '删除服务器失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 切换服务器状态
  Future<bool> toggleServer(int serverId, bool enabled) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _mcpService.toggleServer(serverId, enabled);
      await _loadData();
      
      final action = enabled ? '启用' : '禁用';
      Get.snackbar(
        '成功',
        '服务器已$action',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = '切换服务器状态失败: $e';
      Get.snackbar(
        '错误',
        '切换服务器状态失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 连接服务器
  Future<bool> connectServer(int serverId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _mcpService.connectToServer(serverId);
      await _loadData();
      
      Get.snackbar(
        '成功',
        '服务器连接成功',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = '连接服务器失败: $e';
      Get.snackbar(
        '错误',
        '连接服务器失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 断开服务器连接
  Future<bool> disconnectServer(int serverId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _mcpService.disconnectFromServer(serverId);
      await _loadData();
      
      Get.snackbar(
        '成功',
        '服务器连接已断开',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = '断开服务器连接失败: $e';
      Get.snackbar(
        '错误',
        '断开服务器连接失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 执行工具调用
  Future<MCPToolResult?> executeTool(String toolName, Map<String, dynamic> arguments) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _mcpService.executeTool(toolName, arguments);
      
      if (!result.isError) {
        Get.snackbar(
          '成功',
          '工具 "$toolName" 执行成功',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          '错误',
          '工具执行失败: ${result.content}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
      return result;
    } catch (e) {
      errorMessage.value = '执行工具失败: $e';
      Get.snackbar(
        '错误',
        '执行工具失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 读取资源
  Future<MCPResource?> readResource(String uri) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final resource = await _mcpService.readResource(uri);
      
      Get.snackbar(
        '成功',
        '资源读取成功',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return resource;
    } catch (e) {
      errorMessage.value = '读取资源失败: $e';
      Get.snackbar(
        '错误',
        '读取资源失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 获取工具按名称
  MCPTool? getToolByName(String name) {
    try {
      return availableTools.firstWhere((tool) => tool.name == name);
    } catch (e) {
      return null;
    }
  }
  
  /// 获取资源按URI
  MCPResource? getResourceByUri(String uri) {
    try {
      return availableResources.firstWhere((resource) => resource.uri == uri);
    } catch (e) {
      return null;
    }
  }
  
  /// 检查是否有可用的工具
  bool get hasAvailableTools => availableTools.isNotEmpty;
  
  /// 检查是否有可用的资源
  bool get hasAvailableResources => availableResources.isNotEmpty;
  
  /// 检查是否有已连接的服务器
  bool get hasConnectedServers => servers.any((server) => server.isEnabled);
  
  /// 获取已启用的服务器数量
  int get enabledServerCount => servers.where((server) => server.isEnabled).length;
  
  /// 获取工具数量
  int get toolCount => availableTools.length;
  
  /// 获取资源数量
  int get resourceCount => availableResources.length;
}