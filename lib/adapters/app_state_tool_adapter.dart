import 'package:get/get.dart';
import '../interfaces/common_interfaces.dart';
import '../controllers/app_state_controller.dart';
import '../services/search_service_interface.dart';
import '../core/dependency_injection.dart';

/// AppStateController的适配器，实现ToolStateManager接口
class AppStateToolAdapter implements ToolStateManager {
  late final AppStateController _appStateController;
  SearchServiceInterface? _searchService;
  
  AppStateToolAdapter() {
    _appStateController = Get.find<AppStateController>();    try {
      _searchService = di.get<SearchServiceInterface>();
    } catch (e) {
      // 搜索服务未注册，跳过
    }
  }

  @override
  bool get isToolsEnabled => _appStateController.isToolsEnabled.value;
  @override
  void setToolsEnabled(bool enabled) {
    _appStateController.setToolsEnabled(enabled);
  }

  @override
  bool get isToolsAvailable {
    return _searchService?.isConfigured ?? false;
  }

  @override
  String get toolsStatusDescription {
    if (!isToolsAvailable) {
      return '工具未配置';
    }
    return isToolsEnabled ? '工具已启用' : '工具已禁用';
  }
}
