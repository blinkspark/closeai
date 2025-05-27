import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'controllers/app_state_controller.dart';
import 'controllers/provider_controller.dart';
import 'controllers/model_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/system_prompt_controller.dart';
import 'services/message_service.dart';
import 'services/message_service_impl.dart';
import 'services/session_service.dart';
import 'services/session_service_impl.dart';
import 'services/system_prompt_service.dart';
import 'services/system_prompt_service_impl.dart';
import 'services/openai_service.dart';
import 'models/model.dart';
import 'models/provider.dart';
import 'models/session.dart';
import 'models/message.dart';
import 'models/system_prompt.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final supportPath = dir.path;
  await Get.putAsync(() async {
    return await Isar.open([
      ProviderSchema,
      ModelSchema,
      SessionSchema,
      MessageSchema,
      SystemPromptSchema,
    ], directory: supportPath);
  });
  // 注册服务层
  Get.put<MessageService>(MessageServiceImpl());
  Get.put<SessionService>(SessionServiceImpl());
  Get.put<SystemPromptService>(SystemPromptServiceImpl());
  
  // 注册控制器
  Get.put(AppStateController());
  Get.put(ProviderController());
  Get.put(ModelController());
  Get.put(ChatController());
  Get.put(SessionController());
  Get.put(SystemPromptController());
  
  // 注册OpenAI服务 - 使用动态配置
  Get.put(OpenAIService());
  
  // 初始化默认系统提示词
  final systemPromptService = Get.find<SystemPromptService>();
  if (systemPromptService is SystemPromptServiceImpl) {
    await systemPromptService.initializeDefaultPrompts();
  }
  
  // 初始化默认Provider
  final providerController = Get.find<ProviderController>();
  await providerController.initializeDefaultProviders();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        theme: createTheme(Brightness.light),
        darkTheme: createTheme(Brightness.dark),
        themeMode: Get.find<AppStateController>().themeMode.value,
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      );
    });
  }

  ThemeData createTheme(Brightness brightness) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
    return theme.copyWith(
      textTheme: GoogleFonts.notoSansScTextTheme(theme.textTheme),
    );
  }
}
