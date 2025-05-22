import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class AppState extends GetxController {
  static const configFileName = 'config.json';

  late String supportPath;
  final themeMode = ThemeMode.system.obs;
  final Isar isar = Get.find();

  @override
  void onInit() {
    super.onInit();
    getApplicationSupportDirectory().then((value) {
      supportPath = value.path;
      loadConfig();
    });
  }

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.value.index};
  }

  void fromJson(Map<String, dynamic> json) {
    themeMode.value = ThemeMode.values[json['themeMode']];
  }

  Future<void> loadConfig() async {
    try {
      final file = File('$supportPath/$configFileName');
      if (await file.exists()) {
        final json = await file.readAsString();
        fromJson(jsonDecode(json));
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }
}
