import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    return Obx(() {
      if (!userController.isLoggedIn.value) {
        // 未登录，显示去登录/注册
        return Scaffold(
          appBar: AppBar(title: const Text('用户信息')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('未登录，请先登录或注册'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/user/login'),
                  child: const Text('去登录'),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed('/user/register'),
                  child: const Text('没有账号？去注册'),
                ),
              ],
            ),
          ),
        );
      }
      // 已登录，显示信息
      return Scaffold(
        appBar: AppBar(title: const Text('用户信息')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: userController.avatarUrl.value.isNotEmpty
                    ? NetworkImage(userController.avatarUrl.value)
                    : null,
                child: userController.avatarUrl.value.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(userController.nickname.value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(userController.email.value, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed('/user/change-password'),
                  child: const Text('修改密码'),
                ),
              ),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    userController.logout();
                    Get.snackbar('已退出登录', '', snackPosition: SnackPosition.BOTTOM);
                    Get.offAllNamed('/user/login');
                  },
                  child: const Text('退出登录'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
