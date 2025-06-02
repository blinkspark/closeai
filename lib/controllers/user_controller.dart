import 'package:get/get.dart';

class UserController extends GetxController {
  // 假数据：模拟已登录/未登录状态
  final RxBool isLoggedIn = false.obs;
  final RxString nickname = '测试用户'.obs;
  final RxString email = 'test@example.com'.obs;
  final RxString avatarUrl = ''.obs;

  void login(String username, String password) {
    // 仅做UI演示，直接登录
    isLoggedIn.value = true;
    nickname.value = username;
    email.value = '$username@example.com';
  }

  void logout() {
    isLoggedIn.value = false;
    nickname.value = '测试用户';
    email.value = 'test@example.com';
    avatarUrl.value = '';
  }

  void register(String username, String emailInput) {
    isLoggedIn.value = true;
    nickname.value = username;
    email.value = emailInput;
  }

  void changePassword() {
    // 仅做UI反馈
  }
}
