import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'clients/openai.dart';
import 'controllers/app_state_controller.dart';
import 'controllers/provider_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/chat_controller.dart';
import 'services/message_service.dart';
import 'services/message_service_impl.dart';
import 'services/session_service.dart';
import 'services/session_service_impl.dart';
import 'models/model.dart';
import 'models/provider.dart';
import 'models/session.dart';
import 'models/message.dart';
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
    ], directory: supportPath);
  });
  final apiKey = Platform.environment['OR_API_KEY'];
  assert(apiKey != null);
  Get.put(OpenAI(baseUrl: 'https://openrouter.ai/api/v1', apiKey: apiKey));
  
  // 注册服务层
  Get.put<MessageService>(MessageServiceImpl());
  Get.put<SessionService>(SessionServiceImpl());
  
  // 注册控制器
  Get.put(AppStateController());
  Get.put(ProviderController());
  Get.put(ChatController());
  Get.put(SessionController());
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
