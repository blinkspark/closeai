import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/model.dart';
import '../services/openai_service.dart';

class ModelController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    loadModels();
  }

  final Isar isar = Get.find();

  final models = <Rx<Model>>[].obs;
  final selectedModel = Rx<Model?>(null);

  Future<void> addModel(Model model) async {
    await isar.writeTxn(() async {
      await isar.models.put(model);
      models.add(model.obs);
    });
  }

  Future<void> loadModels() async {
    this.models.clear();
    final models = await isar.models.where().findAll();
    
    // 加载每个模型的关联Provider
    for (final model in models) {
      await model.provider.load();
    }
    
    this.models.addAll(models.map((e) => e.obs));
    
    // 设置默认选中的模型
    if (models.isNotEmpty && selectedModel.value == null) {
      selectedModel.value = models.first;
    }
  }

  Future<void> removeModel(int index) async {
    await isar.writeTxn(() async {
      await isar.models.delete(models[index].value.id);
      models.removeAt(index);
    });
  }

  Future<void> selectModel(Model model) async {
    selectedModel.value = model;
    
    // 刷新OpenAI服务配置
    if (Get.isRegistered<OpenAIService>()) {
      Get.find<OpenAIService>().refreshClient();
    }
  }

  Future<void> reset() async {
    await loadModels();
  }
}