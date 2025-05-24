import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/provider.dart';

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
  }

  Future<void> reset() async {
    await loadProviders();
  }
}
