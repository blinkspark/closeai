import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/model.dart';
import '../models/provider.dart';
import '../services/openai_service.dart';
import 'app_state_controller.dart';

class ModelController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    loadModels();
  }

  final Isar isar = Get.find();
  final AppStateController appStateController = Get.find();

  final models = <Rx<Model>>[].obs;
  final selectedModel = Rx<Model?>(null);
  final titleGenerationModel = Rx<Model?>(null);

  Future<void> addModel(Model model) async {
    await isar.writeTxn(() async {
      await isar.collection<Model>().put(model);
      models.add(model.obs);
    });
  }

  Future<void> loadModels() async {
    this.models.clear();
    final models = await isar.collection<Model>().where().findAll();
    
    // 加载每个模型的关联Provider
    for (final model in models) {
      try {
        await model.provider.load();
        // 如果provider为null，尝试重新关联
        if (model.provider.value == null) {
          await _tryReassignProvider(model);
        }
      } catch (e) {
        await _tryReassignProvider(model);
      }
    }
    
    this.models.addAll(models.map((e) => e.obs));
    
    // 恢复之前选中的模型
    await _restoreSelectedModel();
    
    // 恢复标题生成模型
    await _restoreTitleGenerationModel();
  }
  
  /// 恢复之前选中的模型
  Future<void> _restoreSelectedModel() async {
    final savedModelId = appStateController.selectedModelId.value;
    
    if (savedModelId != null && models.isNotEmpty) {
      // 尝试找到保存的模型
      final savedModel = models
          .map((e) => e.value)
          .where((model) => model.modelId == savedModelId)
          .firstOrNull;
      
      if (savedModel != null) {
        selectedModel.value = savedModel;
        return;
      }    }
      // 如果没有保存的模型或找不到保存的模型，设置默认选中的模型
    if (models.isNotEmpty && selectedModel.value == null) {
      selectedModel.value = models.first.value;
      // 保存默认选择
      appStateController.setSelectedModelId(selectedModel.value?.modelId);
    }
  }
  
  Future<void> _restoreTitleGenerationModel() async {
    final savedModelId = appStateController.selectedTitleGenerationModelId.value;
    
    if (savedModelId != null && models.isNotEmpty) {
      // 尝试找到保存的模型
      final savedModel = models
          .map((e) => e.value)
          .where((model) => model.modelId == savedModelId)
          .firstOrNull;
      
      if (savedModel != null) {
        titleGenerationModel.value = savedModel;
      }
    }
  }
  
  /// 尝试重新分配供应商
  Future<void> _tryReassignProvider(Model model) async {
    try {
      // 获取所有可用的供应商
      final providers = await isar.collection<Provider>().where().findAll();
      
      // 根据模型ID尝试匹配合适的供应商
      Provider? matchedProvider;
      
      if (model.modelId.contains('gpt') || model.modelId.contains('openai')) {
        matchedProvider = providers.where((p) => p.name == 'OpenAI').firstOrNull;
      } else if (model.modelId.contains('claude')) {
        matchedProvider = providers.where((p) => p.name == 'Anthropic').firstOrNull;
      } else if (model.modelId.contains('deepseek')) {
        matchedProvider = providers.where((p) => p.name == 'DeepSeek').firstOrNull;
      } else if (model.modelId.contains('glm') || model.modelId.contains('zhipu')) {
        matchedProvider = providers.where((p) => p.name == 'ZhipuAI').firstOrNull;
      }
      
      // 如果找到匹配的供应商，重新关联
      if (matchedProvider != null) {
        await isar.writeTxn(() async {
          model.provider.value = matchedProvider;
          await isar.collection<Model>().put(model);
          await model.provider.save();
        });
      }
    } catch (e) {
      // 重新分配供应商失败，保持原状
    }
  }

  Future<void> removeModel(int index) async {
    await isar.writeTxn(() async {
      await isar.collection<Model>().delete(models[index].value.id);
      models.removeAt(index);
    });
  }  Future<void> selectModel(Model model) async {
    selectedModel.value = model;
    
    // 保存选中的模型到持久化存储
    appStateController.setSelectedModelId(model.modelId);
    
    // 刷新OpenAI服务配置
    if (Get.isRegistered<OpenAIService>()) {
      Get.find<OpenAIService>().refreshClient();
    }
  }
  
  Future<void> selectTitleGenerationModel(Model model) async {
    titleGenerationModel.value = model;
    
    // 保存选中的模型到持久化存储
    appStateController.setSelectedTitleGenerationModelId(model.modelId);
  }

  Future<void> reset() async {
    await loadModels();
  }
}