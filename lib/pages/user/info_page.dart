import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 假数据
    const avatarUrl = '';
    const nickname = '测试用户';
    const email = 'test@example.com';
    return Scaffold(
      appBar: AppBar(title: const Text('用户信息')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 16),
            Text(nickname, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
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
                  // 仅做UI反馈
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
  }
}
