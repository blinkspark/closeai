// import 'package:closeai/controllers/provider_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import 'chat_page.dart';
import 'home_page/nav_rail.dart';
import 'setting_page.dart';
// import '../models/provider.dart';

class HomePage extends GetResponsiveView<AppStateController> {
  HomePage({super.key});

  @override
  Widget builder() {
    // final ProviderController providerController = Get.find();
    return Scaffold(
      body: Row(
        children: [
          NavRail(),
          VerticalDivider(thickness: 1),
          Obx(() {
            return Expanded(
              child: [ChatPage(), SettingPage()][controller.navIndex.value],
            );
          }),
        ],
      ),
    );
  }
}
