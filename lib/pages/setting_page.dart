import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import '../controllers/provider_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/session_controller.dart';
import '../controllers/system_prompt_controller.dart';
import 'setting_page/setting_section.dart';
import 'setting_page/provider_setting_page.dart';
import 'setting_page/model_setting_page.dart';
import 'setting_page/system_prompt_setting_page.dart';
import 'setting_page/zhipu_setting_page.dart';
import 'setting_page/config_status_widget.dart';

class SettingPage extends GetResponsiveView<AppStateController> {
  SettingPage({super.key});

  final Rx<Widget> _selectedSettingPage =
      Rx<Widget>(const Center(child: Text('设置内容')));

  @override
  Widget builder() {
    // Initialize with the first AI setting page if on desktop and no page is selected yet,
    // or simply the default text.
    // For a better UX, ProviderSettingPage could be shown by default on desktop.
    if (screen.isDesktop && _selectedSettingPage.value is Center) {
       // You could set a default page here if desired, e.g.:
       // _selectedSettingPage.value = ProviderSettingPage();
       // For now, it will keep "设置内容" or what was last set.
    }


    return Row(
      children: [
        Container(
          width: 300,
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Builder(
                  builder: (BuildContext context) {
                    return Text(
                      '设置',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  }
                ),
                SizedBox(height: 16),
                ConfigStatusWidget(),
                SizedBox(height: 16),
                SettingSection(
                title: 'AI配置',
                children: [
                  SettingSectionItem(
                    title: '供应商管理',
                    onPressed: () {
                      final page = ProviderSettingPage();
                      if (screen.isDesktop) {
                        _selectedSettingPage.value = page;
                      } else {
                        Get.to(() => page);
                      }
                    },
                  ),
                  SettingSectionItem(
                    title: '模型管理',
                    onPressed: () {
                      final page = ModelSettingPage();
                      if (screen.isDesktop) {
                        _selectedSettingPage.value = page;
                      } else {
                        Get.to(() => page);
                      }
                    },
                  ),
                  SettingSectionItem(
                    title: '系统提示词',
                    onPressed: () {
                      final page = SystemPromptSettingPage();
                      if (screen.isDesktop) {
                        _selectedSettingPage.value = page;
                      } else {
                        Get.to(() => page);
                      }
                    },
                  ),
                  SettingSectionItem(
                    title: '智谱AI配置',
                    onPressed: () {
                      final page = ZhipuSettingPage();
                      if (screen.isDesktop) {
                        _selectedSettingPage.value = page;
                      } else {
                        Get.to(() => page);
                      }
                    },
                  ),
                ],
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
                      if (Get.isRegistered<ModelController>()) {
                        Get.find<ModelController>().reset();
                      }
                      // 重置系统提示词并重新初始化默认提示词
                      if (Get.isRegistered<SystemPromptController>()) {
                        await Get.find<SystemPromptController>().reset();
                      }
                    },
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
        VerticalDivider(thickness: 1),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Obx(() => _selectedSettingPage.value),
          ),
        ),
      ],
    );
  }
}
