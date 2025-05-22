import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await AppState().init();
  Get.put(appState);
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
        themeMode: Get.find<AppState>().themeMode.value,
        home: Scaffold(body: Center(child: Text('Hello World!'))),
      );
    });
  }

  ThemeData createTheme(Brightness brightness) {
    final theme = ThemeData(
      useMaterial3: true,
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
