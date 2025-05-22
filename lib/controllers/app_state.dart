import 'package:closeai/models/model.dart';
import 'package:closeai/models/provider.dart';
import 'package:closeai/models/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class AppState extends GetxController {
  String? supportPath;
  Isar? isar;
  final themeMode = ThemeMode.system.obs;

  Future<AppState> init() async {
    final dir = await getApplicationSupportDirectory();
    supportPath = dir.path;
    isar = await Isar.open([
      ProviderSchema,
      ModelSchema,
      SessionSchema,
    ], directory: supportPath!);
    return this;
  }
}
