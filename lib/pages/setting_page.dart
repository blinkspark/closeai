import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import '../controllers/provider_controller.dart';
import '../controllers/model_controller.dart';
import '../controllers/session_controller.dart';
import '../controllers/system_prompt_controller.dart';
import '../controllers/user_controller.dart';
import 'setting_page/setting_section.dart';
import 'setting_page/provider_setting_page.dart';
import 'setting_page/model_setting_page.dart';
import 'setting_page/system_prompt_setting_page.dart';
import 'setting_page/zhipu_setting_page.dart';
import 'setting_page/config_status_widget.dart';
import 'user/login_page.dart';
import 'user/register_page.dart';
import 'user/info_page.dart';
import 'user/change_password_page.dart';

class SettingPage extends GetResponsiveView<AppStateController> {
  SettingPage({super.key});

  final Rx<Widget> _selectedSettingPage =
      Rx<Widget>(const Center(child: Text('设置内容')));

  @override
  Widget? builder() {
    if (screen.isPhone) {
      // 手机端：保留和桌面端一致的SettingSection布局
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Builder(
              builder: (BuildContext context) {
                return Text(
                  '设置',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 16),
            ConfigStatusWidget(),
            const SizedBox(height: 16),
            SettingSection(
              title: 'AI配置',
              children: [
                SettingSectionItem(
                  title: '供应商管理',
                  onPressed: () => Get.to(() => ProviderSettingPage()),
                ),
                SettingSectionItem(
                  title: '模型管理',
                  onPressed: () => Get.to(() => ModelSettingPage()),
                ),
                SettingSectionItem(
                  title: '系统提示词',
                  onPressed: () => Get.to(() => SystemPromptSettingPage()),
                ),
                SettingSectionItem(
                  title: '智谱AI配置',
                  onPressed: () => Get.to(() => ZhipuSettingPage()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingSection(
              title: '应用',
              children: [
                SettingSectionItem(
                  title: '主题颜色',
                  trailing: Obx(() {
                    return DropdownButton(
                      items: const [
                        DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
                        DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
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
                    if (Get.isRegistered<SystemPromptController>()) {
                      await Get.find<SystemPromptController>().reset();
                    }
                  },
                ),
              ],
            ),
            SettingSection(
              title: '用户',
              children: [
                Obx(() {
                  final userController = Get.find<UserController>();
                  // 只显示一组
                  if (!userController.isLoggedIn.value) {
                    return Column(
                      children: [
                        SettingSectionItem(
                          title: '登录',
                          onPressed: () {
                            final page = UserLoginPage();
                            if (screen.isDesktop) {
                              _selectedSettingPage.value = page;
                            } else {
                              Get.to(() => page);
                            }
                          },
                        ),
                        SettingSectionItem(
                          title: '注册',
                          onPressed: () {
                            final page = UserRegisterPage();
                            if (screen.isDesktop) {
                              _selectedSettingPage.value = page;
                            } else {
                              Get.to(() => page);
                            }
                          },
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SettingSectionItem(
                          title: '用户信息',
                          onPressed: () {
                            final page = UserInfoPage();
                            if (screen.isDesktop) {
                              _selectedSettingPage.value = page;
                            } else {
                              Get.to(() => page);
                            }
                          },
                        ),
                        SettingSectionItem(
                          title: '修改密码',
                          onPressed: () {
                            final page = ChangePasswordPage();
                            if (screen.isDesktop) {
                              _selectedSettingPage.value = page;
                            } else {
                              Get.to(() => page);
                            }
                          },
                        ),
                        SettingSectionItem(
                          title: '退出登录',
                          isDanger: true,
                          onPressed: () {
                            userController.logout();
                            Get.snackbar('已退出登录', '', snackPosition: SnackPosition.BOTTOM);
                            if (screen.isDesktop) {
                              _selectedSettingPage.value = const Center(child: Text('设置内容'));
                            } else {
                              Get.offAllNamed('/user/login');
                            }
                          },
                        ),
                      ],
                    );
                  }
                }),
              ],
            ),
          ],
        ),
      );
    }

    // 桌面端原有Row布局
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
                        items: const [
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
              SettingSection(
                title: '用户',
                children: [
                  Obx(() {
                    final userController = Get.find<UserController>();
                    if (!userController.isLoggedIn.value) {
                      return Column(
                        children: [
                          SettingSectionItem(
                            title: '登录',
                            onPressed: () => _selectedSettingPage.value = UserLoginPage(),
                          ),
                          SettingSectionItem(
                            title: '注册',
                            onPressed: () => _selectedSettingPage.value = UserRegisterPage(),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          SettingSectionItem(
                            title: '用户信息',
                            onPressed: () => _selectedSettingPage.value = UserInfoPage(),
                          ),
                          SettingSectionItem(
                            title: '修改密码',
                            onPressed: () => _selectedSettingPage.value = ChangePasswordPage(),
                          ),
                          SettingSectionItem(
                            title: '退出登录',
                            isDanger: true,
                            onPressed: () {
                              userController.logout();
                              Get.snackbar('已退出登录', '', snackPosition: SnackPosition.BOTTOM);
                              _selectedSettingPage.value = const Center(child: Text('请选择一项设置'));
                            },
                          ),
                        ],
                      );
                    }
                  }),
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
