// import 'package:closeai/controllers/provider_controller.dart';
import 'package:closeai/pages/home_page/nav_rail.dart';
import 'package:closeai/pages/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
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
          Expanded(child: SettingPage()),
        ],
      ),
    );
  }
}
