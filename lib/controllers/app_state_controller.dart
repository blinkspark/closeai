import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppStateController extends GetxController {
  static const configFileName = 'config.json';

  late File configFile;
  final Isar isar = Get.find();

  final themeMode = ThemeMode.system.obs;
  final isToolsEnabled = false.obs;

  final navIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    getApplicationSupportDirectory().then((value) {
      final supportPath = value.path;
      configFile = File(join(supportPath, configFileName));
      loadConfig();
    });
  }

  void setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await saveConfig();
  }

  void setToolsEnabled(bool enabled) async {
    print('🐛 [DEBUG] 设置工具开关状态: $enabled (之前: ${isToolsEnabled.value})');
    isToolsEnabled.value = enabled;
    await saveConfig();
    print('🐛 [DEBUG] 工具开关状态已保存: ${isToolsEnabled.value}');
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.value.index,
      'isToolsEnabled': isToolsEnabled.value,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    themeMode.value = ThemeMode.values[json['themeMode'] ?? 0];
    isToolsEnabled.value = json['isToolsEnabled'] ?? false;
  }

  Future<void> loadConfig() async {
    print('🐛 [DEBUG] 开始加载配置文件: ${configFile.path}');
    if (await configFile.exists()) {
      final json = await configFile.readAsString();
      print('🐛 [DEBUG] 配置文件内容: $json');
      fromJson(jsonDecode(json));
      print('🐛 [DEBUG] 配置加载完成 - 工具开关: ${isToolsEnabled.value}');
    } else {
      print('🐛 [DEBUG] 配置文件不存在，使用默认值 - 工具开关: ${isToolsEnabled.value}');
    }
  }

  Future<void> saveConfig() async {
    final json = jsonEncode(toJson());
    await configFile.writeAsString(json);
  }

  Future<void> reset() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
