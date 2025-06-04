import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/ai/domain/repositories/ai_chat_repository.dart';

/// 修改行程规划用例
class ModifyTripPlanUseCase {
  final AiChatRepository repository;

  ModifyTripPlanUseCase(this.repository);

  /// 执行修改行程操作
  Future<Map<String, dynamic>> execute(String userPrompt, Map<String, dynamic> currentPlan, List<ChatMessage> history) {
    return repository.modifyTripPlan(userPrompt, currentPlan, history);
  }
} 