import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  String? _errorText;
  bool _passwordChanged = false;
  final UserController userController = Get.find<UserController>();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!userController.isLoggedIn.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('修改密码')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('请先登录后再修改密码'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/user/login'),
                  child: const Text('去登录'),
                ),
              ],
            ),
          ),
        );
      }
      
      if (_passwordChanged) {
        return Scaffold(
          appBar: AppBar(title: const Text('修改密码')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text('密码修改成功'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _passwordChanged = false;
                      _oldPwdController.clear();
                      _newPwdController.clear();
                      _confirmPwdController.clear();
                    });
                  },
                  child: const Text('继续修改'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('修改密码')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _oldPwdController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '旧密码'),
                  validator: (v) => v == null || v.isEmpty ? '请输入旧密码' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPwdController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '新密码'),
                  validator: (v) => v == null || v.length < 6 ? '新密码至少6位' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPwdController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '确认新密码'),
                  validator: (v) => v != _newPwdController.text ? '两次密码不一致' : null,
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
                        });                        userController.changePassword();
                        setState(() {
                          _passwordChanged = true;
                        });
                        Get.snackbar('密码修改成功', '', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
