import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import '../controllers/provider_controller.dart';
import '../controllers/session_controller.dart';
import 'setting_page/setting_section.dart';

class SettingPage extends GetResponsiveView<AppStateController> {
  SettingPage({super.key});

  @override
  Widget builder() {
    return Row(
      children: [
        Container(
          width: 300,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '设置',
                style: Theme.of(Get.context!).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              SettingSection(
                title: '应用',
                children: [
                  SettingSectionItem(
                    title: '主题颜色',
                    trailing: Obx(() {
                      return DropdownButton(
                        items: [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('浅色'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('深色'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('跟随系统'),
                          ),
                        ],
                        underline: Container(),
                        focusColor: Colors.transparent,
                        value: controller.themeMode.value,
                        onChanged: (idx) {
                          controller.themeMode.value = idx!;
                        },
                      );
                    }),
                  ),
                  SettingSectionItem(title: '语言', onPressed: () {}),
                  SettingSectionItem(
                    title: '重置',
                    isDanger: true,
                    onPressed: () async {
                      await controller.reset();
                      Get.find<SessionController>().reset();
                      Get.find<ProviderController>().reset();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        VerticalDivider(thickness: 1),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('设置内容')),
          ),
        ),
      ],
    );
  }
}
