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
  Widget? builder() {
    if (screen.isPhone) {
      // 手机端：底部导航栏
      return Obx(() {
        final controller = Get.find<AppStateController>();
        return Scaffold(
          body: IndexedStack(
            index: controller.navIndex.value,
            children: [
              ChatPage(isPhone: true),
              SettingPage()
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.navIndex.value,
            onTap: (idx) => controller.navIndex.value = idx,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '主页'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
            ],
          ),
        );
      });
    } else {
      // 桌面端：侧边导航
      return Scaffold(
        body: Row(
          children: [
            NavRail(),
            VerticalDivider(thickness: 1),
            Obx(() {
              return Expanded(
                child: [ChatPage(isPhone: false), SettingPage()][controller.navIndex.value],
              );
            }),
          ],
        ),
      );
    }
  }
}
