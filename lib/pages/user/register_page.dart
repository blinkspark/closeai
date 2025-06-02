import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorText;
  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {      if (userController.isLoggedIn.value) {
        // 已登录，显示注册成功信息
        return Scaffold(
          appBar: AppBar(title: const Text('注册')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text('注册成功'),
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
        appBar: AppBar(title: const Text('注册')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: '用户名'),
                  validator: (v) => v == null || v.isEmpty ? '请输入用户名' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  validator: (v) => v == null || v.isEmpty ? '请输入邮箱' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                  validator: (v) => v == null || v.length < 6 ? '密码至少6位' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '确认密码'),
                  validator: (v) => v != _passwordController.text ? '两次密码不一致' : null,
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
                        userController.register(_usernameController.text, _emailController.text);
                        Get.snackbar('注册成功', '已自动登录', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    child: const Text('注册'),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed('/user/login'),
                  child: const Text('已有账号？去登录'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
