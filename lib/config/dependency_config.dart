import 'package:get/get.dart';
import '../core/dependency_injection.dart';
import '../services/message_service.dart';
import '../services/message_service_impl.dart';
import '../services/session_service.dart';
import '../services/session_service_impl.dart';
import '../services/system_prompt_service.dart';
import '../services/system_prompt_service_impl.dart';
import '../services/openai_service.dart';
import '../services/openai_service_interface.dart';
import '../services/zhipu_search_service.dart';
import '../services/search_service_interface.dart';
import '../services/tool_registry.dart';
import '../controllers/app_state_controller.dart';
import '../controllers/provider_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/system_prompt_controller.dart';
import '../controllers/session_controller.dart';
import '../controllers/chat_controller.dart';
import '../adapters/app_state_tool_adapter.dart';
import '../adapters/system_prompt_adapter.dart';
import '../interfaces/common_interfaces.dart';

/// 依赖注入配置类
class DependencyConfig {  /// 初始化所有依赖注入
  static Future<void> initialize() async {
    // 初始化依赖容器
    di = GetXDependencyContainer();
    
    // 注册服务层接口和实现
    _registerServices();
    
    // 注册基础控制器（不依赖于适配器的）
    _registerBasicControllers();
    
    // 注册适配器
    _registerAdapters();
      // 注册依赖于适配器的控制器
    _registerDependentControllers();
  }
    /// 注册服务层
  static void _registerServices() {
    // 基础服务
    di.registerSingleton<MessageService>(MessageServiceImpl());
    di.registerSingleton<SessionService>(SessionServiceImpl());
    di.registerSingleton<SystemPromptService>(SystemPromptServiceImpl());
    
    // 搜索服务（需要先注册，因为OpenAI服务依赖它）
    final searchService = ZhipuSearchService();
    Get.put<ZhipuSearchService>(searchService, permanent: true);
    di.registerSingleton<ZhipuSearchService>(searchService);
    di.registerSingleton<SearchServiceInterface>(searchService);
    
    // OpenAI服务
    final openAIService = OpenAIService();
    di.registerSingleton<OpenAIService>(openAIService);
    di.registerSingleton<OpenAIServiceInterface>(openAIService);
    
    // 工具注册
    di.registerSingleton<ToolRegistry>(ToolRegistry());
  }
    /// 注册基础控制器（不依赖于适配器的）
  static void _registerBasicControllers() {
    // 基础控制器
    Get.put(AppStateController());
    Get.put(ProviderController());
    Get.put(ModelController());
    Get.put(SystemPromptController());
  }
  
  /// 注册依赖于适配器的控制器
  static void _registerDependentControllers() {
    // 依赖于适配器的控制器
    Get.put(ChatController());
    Get.put(SessionController());
  }
    /// 注册适配器
  static void _registerAdapters() {
    // 延迟注册适配器，确保相关控制器已注册
    Get.put<ToolStateManager>(AppStateToolAdapter(), permanent: true);
    Get.put<SystemPromptManager>(SystemPromptAdapter(), permanent: true);
    
    // 同时在依赖容器中注册
    di.registerSingleton<ToolStateManager>(Get.find<ToolStateManager>());
    di.registerSingleton<SystemPromptManager>(Get.find<SystemPromptManager>());
  }
  
  /// 清理所有依赖
  static void cleanup() {
    di.clear();
    Get.reset();
  }
}
