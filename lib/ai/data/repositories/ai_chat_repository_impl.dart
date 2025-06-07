import 'package:tulele/ai/data/datasources/deepseek_api.dart';
import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/ai/domain/repositories/ai_chat_repository.dart';

/// AI聊天仓库实现
class AiChatRepositoryImpl implements AiChatRepository {
  final DeepseekApi _deepseekApi;

  AiChatRepositoryImpl(this._deepseekApi);

  @override
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    return await _deepseekApi.sendChatMessage(message, history);
  }

  @override
  Future<Map<String, dynamic>> generateTripPlan(String userPrompt, List<ChatMessage> history) async {
    return await _deepseekApi.generateTripPlan(userPrompt, history);
  }

  @override
  Future<Map<String, dynamic>> modifyTripPlan(String userPrompt, Map<String, dynamic> currentPlan, List<ChatMessage> history) async {
    return await _deepseekApi.modifyTripPlan(userPrompt, currentPlan, history);
  }
} 