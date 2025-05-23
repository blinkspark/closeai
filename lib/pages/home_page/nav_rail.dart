import 'package:closeai/controllers/app_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavRail extends StatelessWidget {
  const NavRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appState = Get.find<AppStateController>();
      return NavigationRail(
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.home),
            label: const Text('主页'),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.settings),
            label: const Text('设置'),
          ),
        ],
        labelType: NavigationRailLabelType.selected,
        selectedIndex: appState.navIndex.value,
        onDestinationSelected: (idx) => appState.navIndex.value = idx,
      );
    });
  }
}
