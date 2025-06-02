import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {      if (userController.isLoggedIn.value) {
        // 已登录，显示登录成功信息
        return Scaffold(
          appBar: AppBar(title: const Text('登录')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text('登录成功'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('登录')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: '用户名/邮箱'),
                  validator: (v) => v == null || v.isEmpty ? '请输入用户名或邮箱' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                  validator: (v) => v == null || v.isEmpty ? '请输入密码' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _errorText = null;
                        });
                        userController.login(_usernameController.text, _passwordController.text);
                        Get.snackbar('登录成功', '', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    child: const Text('登录'),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed('/user/register'),
                  child: const Text('没有账号？去注册'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
