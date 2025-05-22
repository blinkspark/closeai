import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppState extends GetxController {
  static const configFileName = 'config.json';

  late File configFile;
  final themeMode = ThemeMode.system.obs;
  final Isar isar = Get.find();

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

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.value.index};
  }

  void fromJson(Map<String, dynamic> json) {
    themeMode.value = ThemeMode.values[json['themeMode']];
  }

  Future<void> loadConfig() async {
    if (await configFile.exists()) {
      final json = await configFile.readAsString();
      fromJson(jsonDecode(json));
    }
  }

  Future<void> saveConfig() async {
    final json = jsonEncode(toJson());
    await configFile.writeAsString(json);
  }
}
