import 'package:get/get.dart';
import '../interfaces/common_interfaces.dart';
import '../controllers/system_prompt_controller.dart';

/// SystemPromptController的适配器，实现SystemPromptManager接口
class SystemPromptAdapter implements SystemPromptManager {
  late final SystemPromptController _systemPromptController;
  
  SystemPromptAdapter() {
    _systemPromptController = Get.find<SystemPromptController>();
  }

  @override
  String getCurrentPromptContent() {
    return _systemPromptController.getCurrentPromptContent();
  }
}
