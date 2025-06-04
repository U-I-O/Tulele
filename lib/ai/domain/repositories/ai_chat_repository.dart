import '../entities/chat_message.dart';

/// AI聊天仓库接口
abstract class AiChatRepository {
  /// 向AI发送消息并获取回复
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history);
  
  /// 获取旅游行程规划
  Future<Map<String, dynamic>> generateTripPlan(String userPrompt, List<ChatMessage> history);
  
  /// 修改已有的旅游行程
  Future<Map<String, dynamic>> modifyTripPlan(String userPrompt, Map<String, dynamic> currentPlan, List<ChatMessage> history);
} 