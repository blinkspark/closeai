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
  final selectedModelId = Rxn<String>();
  final selectedTitleGenerationModelId = Rxn<String>();

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
    isToolsEnabled.value = enabled;
    await saveConfig();
  }

  void setSelectedModelId(String? modelId) async {
    selectedModelId.value = modelId;
    await saveConfig();
  }
  
  void setSelectedTitleGenerationModelId(String? modelId) async {
    selectedTitleGenerationModelId.value = modelId;
    await saveConfig();
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.value.index,
      'isToolsEnabled': isToolsEnabled.value,
      'selectedModelId': selectedModelId.value,
      'selectedTitleGenerationModelId': selectedTitleGenerationModelId.value,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    themeMode.value = ThemeMode.values[json['themeMode'] ?? 0];
    isToolsEnabled.value = json['isToolsEnabled'] ?? false;
    selectedModelId.value = json['selectedModelId'];
    selectedTitleGenerationModelId.value = json['selectedTitleGenerationModelId'];
  }
  Future<void> loadConfig() async {
    if (await configFile.exists()) {
      final json = await configFile.readAsString();
      fromJson(jsonDecode(json));
    }
  }
  Future<void> saveConfig() async {
    final configData = toJson();
    final json = jsonEncode(configData);
    await configFile.writeAsString(json);
  }

  Future<void> reset() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
