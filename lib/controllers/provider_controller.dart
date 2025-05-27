import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/provider.dart';
import '../services/openai_service.dart';

class ProviderController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    loadProviders();
  }

  final Isar isar = Get.find();

  final providers = <Rx<Provider>>[].obs;

  Future<void> addProvider(Provider provider) async {
    await isar.writeTxn(() async {
      await isar.providers.put(provider);
      providers.add(provider.obs);
    });
    
    // 刷新OpenAI服务配置
    if (Get.isRegistered<OpenAIService>()) {
      Get.find<OpenAIService>().refreshClient();
    }
  }

  Future<void> loadProviders() async {
    this.providers.clear();
    final providers = await isar.providers.where().findAll();
    this.providers.addAll(providers.map((e) => e.obs));
  }

  Future<void> removeProvider(int index) async {
    await isar.writeTxn(() async {
      await isar.providers.delete(providers[index].value.id);
      providers.removeAt(index);
    });
    
    // 刷新OpenAI服务配置
    if (Get.isRegistered<OpenAIService>()) {
      Get.find<OpenAIService>().refreshClient();
    }
  }

  Future<void> reset() async {
    // 清除所有现有的Provider
    await isar.writeTxn(() async {
      await isar.providers.clear();
    });
    
    // 强制重新创建默认Provider
    await _createDefaultProviders();
  }

  /// 初始化默认Provider
  Future<void> initializeDefaultProviders() async {
    final existingProviders = await isar.providers.where().findAll();
    
    // 如果已经有Provider，则不添加默认Provider
    if (existingProviders.isNotEmpty) {
      return;
    }

    await _createDefaultProviders();
  }

  /// 创建默认Provider的私有方法
  Future<void> _createDefaultProviders() async {
    final defaultProviders = [
      Provider()
        ..name = 'OpenAI'
        ..baseUrl = 'https://api.openai.com/v1'
        ..apiKey = '',
      Provider()
        ..name = 'Anthropic'
        ..baseUrl = 'https://api.anthropic.com/v1'
        ..apiKey = '',
      Provider()
        ..name = 'DeepSeek'
        ..baseUrl = 'https://api.deepseek.com'
        ..apiKey = '',
      Provider()
        ..name = 'ZhipuAI'
        ..baseUrl = 'https://open.bigmodel.cn/api/paas/v4'
        ..apiKey = '',
      Provider()
        ..name = 'OpenRouter'
        ..baseUrl = 'https://openrouter.ai/api/v1'
        ..apiKey = '',
      Provider()
        ..name = 'Requesty'
        ..baseUrl = 'https://router.requesty.ai/v1'
        ..apiKey = '',
    ];

    await isar.writeTxn(() async {
      for (final provider in defaultProviders) {
        await isar.providers.put(provider);
      }
    });

    // 重新加载Provider列表
    await loadProviders();
  }
}
