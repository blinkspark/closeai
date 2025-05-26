import 'package:get/get.dart';
import '../models/system_prompt.dart';
import '../services/system_prompt_service.dart';

class SystemPromptController extends GetxController {
  late final SystemPromptService _systemPromptService;
  
  // 系统提示词列表
  final systemPrompts = <Rx<SystemPrompt>>[].obs;
  
  // 当前选中的系统提示词
  final selectedSystemPrompt = Rxn<SystemPrompt>();
  
  // 临时修改的系统提示词内容（不影响原预设）
  final temporaryPromptContent = ''.obs;
  
  // 是否使用临时修改的内容
  final useTemporaryContent = false.obs;
  
  // 搜索关键词
  final searchQuery = ''.obs;
  
  // 是否正在加载
  final isLoading = false.obs;
  
  // 变量映射
  final variables = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _systemPromptService = Get.find<SystemPromptService>();
    loadSystemPrompts();
    
    // 监听搜索变化
    debounce(searchQuery, (_) => searchSystemPrompts(), time: Duration(milliseconds: 300));
  }

  /// 加载系统提示词列表
  Future<void> loadSystemPrompts() async {
    isLoading.value = true;
    try {
      final prompts = await _systemPromptService.loadSystemPrompts();
      systemPrompts.assignAll(prompts.map((e) => e.obs));
      
      // 如果没有选中的提示词，选择默认的
      if (selectedSystemPrompt.value == null && prompts.isNotEmpty) {
        final defaultPrompt = prompts.firstWhere(
          (p) => p.isDefault,
          orElse: () => prompts.first,
        );
        selectSystemPrompt(defaultPrompt);
      }
    } catch (e) {
      Get.snackbar('错误', '加载系统提示词失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 搜索系统提示词
  Future<void> searchSystemPrompts() async {
    try {
      final prompts = await _systemPromptService.searchSystemPrompts(searchQuery.value);
      systemPrompts.assignAll(prompts.map((e) => e.obs));
    } catch (e) {
      Get.snackbar('错误', '搜索失败: $e');
    }
  }

  /// 选择系统提示词
  void selectSystemPrompt(SystemPrompt prompt) {
    selectedSystemPrompt.value = prompt;
    temporaryPromptContent.value = prompt.content;
    useTemporaryContent.value = false;
    
    // 更新变量列表
    updateVariables(prompt);
  }

  /// 更新变量
  void updateVariables(SystemPrompt prompt) {
    final promptVariables = prompt.getVariables();
    variables.clear();
    
    // 添加内置变量
    variables['username'] = '用户';
    variables['用户名'] = '用户';
    variables['time'] = DateTime.now().toString();
    variables['date'] = DateTime.now().toString().split(' ')[0];
    variables['时间'] = DateTime.now().toString();
    variables['日期'] = '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日';
    
    // 添加自定义变量占位符
    for (final variable in promptVariables) {
      if (!variables.containsKey(variable)) {
        variables[variable] = '';
      }
    }
  }

  /// 设置变量值
  void setVariable(String key, String value) {
    variables[key] = value;
  }

  /// 获取当前有效的系统提示词内容
  String getCurrentPromptContent() {
    final prompt = selectedSystemPrompt.value;
    if (prompt == null) return '';
    
    final content = useTemporaryContent.value 
        ? temporaryPromptContent.value 
        : prompt.content;
    
    if (!prompt.enableVariables) return content;
    
    // 处理变量替换
    return prompt.processVariables(
      userName: variables['username'] ?? variables['用户名'],
      currentTime: DateTime.now(),
      customVariables: Map.from(variables),
    );
  }

  /// 设置临时内容
  void setTemporaryContent(String content) {
    temporaryPromptContent.value = content;
    useTemporaryContent.value = content != (selectedSystemPrompt.value?.content ?? '');
  }

  /// 重置临时内容
  void resetTemporaryContent() {
    final prompt = selectedSystemPrompt.value;
    if (prompt != null) {
      temporaryPromptContent.value = prompt.content;
      useTemporaryContent.value = false;
    }
  }

  /// 创建新的系统提示词
  Future<void> createSystemPrompt({
    required String name,
    required String content,
    String? description,
    bool isDefault = false,
    bool enableVariables = true,
  }) async {
    try {
      final prompt = SystemPrompt.create(
        name: name,
        content: content,
        description: description,
        isDefault: isDefault,
        enableVariables: enableVariables,
      );
      
      await _systemPromptService.createSystemPrompt(prompt);
      await loadSystemPrompts();
      
      Get.snackbar('成功', '系统提示词创建成功');
    } catch (e) {
      Get.snackbar('错误', '创建失败: $e');
    }
  }

  /// 更新系统提示词
  Future<void> updateSystemPrompt(SystemPrompt prompt) async {
    try {
      await _systemPromptService.updateSystemPrompt(prompt);
      await loadSystemPrompts();
      
      // 如果更新的是当前选中的提示词，重新选择
      if (selectedSystemPrompt.value?.id == prompt.id) {
        selectSystemPrompt(prompt);
      }
      
      Get.snackbar('成功', '系统提示词更新成功');
    } catch (e) {
      Get.snackbar('错误', '更新失败: $e');
    }
  }

  /// 删除系统提示词
  Future<void> deleteSystemPrompt(int id) async {
    try {
      await _systemPromptService.deleteSystemPrompt(id);
      await loadSystemPrompts();
      
      // 如果删除的是当前选中的提示词，选择第一个
      if (selectedSystemPrompt.value?.id == id) {
        if (systemPrompts.isNotEmpty) {
          selectSystemPrompt(systemPrompts.first.value);
        } else {
          selectedSystemPrompt.value = null;
        }
      }
      
      Get.snackbar('成功', '系统提示词删除成功');
    } catch (e) {
      Get.snackbar('错误', '删除失败: $e');
    }
  }

  /// 设置默认系统提示词
  Future<void> setDefaultSystemPrompt(int id) async {
    try {
      await _systemPromptService.setDefaultSystemPrompt(id);
      await loadSystemPrompts();
      Get.snackbar('成功', '默认系统提示词设置成功');
    } catch (e) {
      Get.snackbar('错误', '设置失败: $e');
    }
  }

  /// 重新排序
  Future<void> reorderSystemPrompts(List<int> ids) async {
    try {
      await _systemPromptService.reorderSystemPrompts(ids);
      await loadSystemPrompts();
    } catch (e) {
      Get.snackbar('错误', '排序失败: $e');
    }
  }

  /// 复制系统提示词
  Future<void> duplicateSystemPrompt(SystemPrompt original) async {
    await createSystemPrompt(
      name: '${original.name} (副本)',
      content: original.content,
      description: original.description,
      enableVariables: original.enableVariables,
    );
  }
}