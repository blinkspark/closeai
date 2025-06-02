import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'config/dependency_config.dart';
import 'controllers/app_state_controller.dart';
import 'controllers/provider_controller.dart';
import 'controllers/system_prompt_controller.dart';
import 'controllers/user_controller.dart';
import 'models/model.dart';
import 'models/provider.dart';
import 'models/session.dart';
import 'models/message.dart';
import 'models/system_prompt.dart';
import 'pages/home_page.dart';
import 'pages/user/login_page.dart';
import 'pages/user/register_page.dart';
import 'pages/user/info_page.dart';
import 'pages/user/change_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 初始化数据库
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

    // 初始化依赖注入
    await DependencyConfig.initialize();
    
    // 注入UserController
    Get.put(UserController());
    
    // 初始化默认数据
    await _initializeDefaultData();
    
    runApp(const MainApp());  } catch (e) {
    // 应用初始化失败
    
    // 显示错误页面
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('应用初始化失败', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('$e', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    ));
  }
}

/// 初始化默认数据
Future<void> _initializeDefaultData() async {
  try {    // 初始化默认供应商
    final providerController = Get.find<ProviderController>();
    await providerController.initializeDefaultProviders();
    
    // 初始化默认系统提示词
    final systemPromptController = Get.find<SystemPromptController>();
    await systemPromptController.loadSystemPrompts();
    
    // 默认数据初始化完成
  } catch (e) {
    // 默认数据初始化失败
  }
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
        getPages: [
          GetPage(name: '/user/login', page: () => const UserLoginPage()),
          GetPage(name: '/user/register', page: () => const UserRegisterPage()),
          GetPage(name: '/user/info', page: () => const UserInfoPage()),
          GetPage(name: '/user/change-password', page: () => const ChangePasswordPage()),
        ],
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
