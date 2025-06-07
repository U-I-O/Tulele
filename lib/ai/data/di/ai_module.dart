import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/generate_trip_plan_usecase.dart';
import '../../domain/usecases/modify_trip_plan_usecase.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../repositories/ai_chat_repository_impl.dart';
import '../datasources/deepseek_api.dart';
import '../../../core/di/service_locator.dart';
import '../../presentation/viewmodels/ai_chat_viewmodel.dart';

/// AI模块的依赖注入配置
class AiModule {
  /// 注册AI模块相关的依赖
  static void register() {
    // 注册数据源
    serviceLocator.registerLazySingleton<DeepseekApi>(() => DeepseekApi());
    
    // 注册仓库
    serviceLocator.registerLazySingleton<AiChatRepository>(
      () => AiChatRepositoryImpl(serviceLocator<DeepseekApi>())
    );
    
    // 注册用例
    serviceLocator.registerLazySingleton<SendMessageUseCase>(
      () => SendMessageUseCase(serviceLocator<AiChatRepository>())
    );
    serviceLocator.registerLazySingleton<GenerateTripPlanUseCase>(
      () => GenerateTripPlanUseCase(serviceLocator<AiChatRepository>())
    );
    serviceLocator.registerLazySingleton<ModifyTripPlanUseCase>(
      () => ModifyTripPlanUseCase(serviceLocator<AiChatRepository>())
    );
    
    // 注册ViewModel (工厂模式，每次请求都创建新实例)
    serviceLocator.registerFactory<AiChatViewModel>(
      () => AiChatViewModel(
        sendMessageUseCase: serviceLocator<SendMessageUseCase>(),
        generateTripPlanUseCase: serviceLocator<GenerateTripPlanUseCase>(),
        modifyTripPlanUseCase: serviceLocator<ModifyTripPlanUseCase>(),
      )
    );
  }
} 