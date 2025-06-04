import 'package:get_it/get_it.dart';
import '../../ai/data/di/ai_module.dart';

/// 全局服务定位器实例
final serviceLocator = GetIt.instance;

/// 服务定位器初始化配置类
class ServiceLocatorSetup {
  /// 初始化所有依赖
  static void init() {
    // 各模块的依赖注册统一在这里调用
    AiModule.register();
  }
} 