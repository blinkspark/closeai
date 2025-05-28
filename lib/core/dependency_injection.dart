import 'package:get/get.dart';

/// 依赖注入接口，用于解耦模块间的直接依赖
abstract class DependencyContainer {
  /// 注册单例服务
  void registerSingleton<T>(T instance);
  
  /// 注册工厂服务
  void registerFactory<T>(T Function() factory);
  
  /// 获取服务实例
  T get<T>();
  
  /// 检查服务是否已注册
  bool isRegistered<T>();
  
  /// 移除服务
  void remove<T>();
  
  /// 清空所有服务
  void clear();
}

/// GetX依赖注入容器的实现
class GetXDependencyContainer implements DependencyContainer {
  @override
  void registerSingleton<T>(T instance) {
    if (!Get.isRegistered<T>()) {
      Get.put<T>(instance);
    }
  }

  @override
  void registerFactory<T>(T Function() factory) {
    if (!Get.isRegistered<T>()) {
      Get.lazyPut<T>(factory);
    }
  }

  @override
  T get<T>() {
    return Get.find<T>();
  }

  @override
  bool isRegistered<T>() {
    return Get.isRegistered<T>();
  }

  @override
  void remove<T>() {
    Get.delete<T>();
  }

  @override
  void clear() {
    Get.reset();
  }
}

/// 全局依赖注入容器实例
late final DependencyContainer di;
