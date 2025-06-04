import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/ai/domain/repositories/ai_chat_repository.dart';

/// 生成行程规划用例
class GenerateTripPlanUseCase {
  final AiChatRepository repository;

  GenerateTripPlanUseCase(this.repository);

  /// 执行生成行程操作
  Future<Map<String, dynamic>> execute(String userPrompt, List<ChatMessage> history) {
    return repository.generateTripPlan(userPrompt, history);
  }
} 