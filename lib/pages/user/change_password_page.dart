import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  Widget build(BuildContext context) {
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
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _errorText = null;
                      });
                      // 仅做UI反馈
                      Get.snackbar('密码修改成功', '', snackPosition: SnackPosition.BOTTOM);
                      Get.offAllNamed('/user/info');
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
  }
}
