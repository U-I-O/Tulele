import 'package:uuid/uuid.dart';

/// 聊天消息类型
enum ChatMessageType {
  text,       // 普通文本消息
  buttons,    // 按钮操作
  planSuggestion, // 行程建议
}

/// 聊天消息实体类
class ChatMessage {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;
  final List<String>? suggestions;
  final ChatMessageType type;
  final Map<String, dynamic>? tripPlanData; // 行程计划数据

  /// 创建普通消息
  ChatMessage({
    String? id,
    required this.content,
    required this.isUserMessage,
    this.suggestions,
    this.tripPlanData,
    ChatMessageType? type,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = DateTime.now(),
    this.type = type ?? ChatMessageType.text;
  
  /// 创建操作按钮消息
  factory ChatMessage.buttons({String? id}) {
    return ChatMessage(
      id: id,
      content: '',
      isUserMessage: false,
      type: ChatMessageType.buttons,
    );
  }
  
  /// 创建行程建议消息
  factory ChatMessage.planSuggestion({
    String? id,
    required String content,
    required Map<String, dynamic> tripPlanData,
    List<String>? suggestions,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      isUserMessage: false,
      suggestions: suggestions,
      tripPlanData: tripPlanData,
      type: ChatMessageType.planSuggestion,
    );
  }
} 