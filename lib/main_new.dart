import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'config/dependency_config.dart';
import 'controllers/app_state_controller.dart';
import 'controllers/provider_controller.dart';
import 'controllers/system_prompt_controller.dart';
import 'models/model.dart';
import 'models/provider.dart';
import 'models/session.dart';
import 'models/message.dart';
import 'models/system_prompt.dart';
import 'pages/home_page.dart';

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
    
    // 初始化默认数据
    await _initializeDefaultData();
    
    runApp(MyApp());
  } catch (e, stackTrace) {
    print('应用初始化失败: $e');
    print('堆栈跟踪: $stackTrace');
    
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
  try {
    // 初始化默认供应商
    final providerController = Get.find<ProviderController>();
    await providerController.initializeDefaultProviders();    // 初始化默认系统提示词（SystemPromptController会在初始化时自动加载）
    
    print('默认数据初始化完成');
  } catch (e) {
    print('默认数据初始化失败: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStateController appStateController = Get.find();
    
    return Obx(() {
      return MaterialApp(
        title: 'CloseAI',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ),
        ),
        themeMode: appStateController.themeMode.value,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
