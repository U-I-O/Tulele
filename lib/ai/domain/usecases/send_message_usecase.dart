import 'package:tulele/ai/domain/entities/chat_message.dart';
import 'package:tulele/ai/domain/repositories/ai_chat_repository.dart';

/// 发送消息用例
class SendMessageUseCase {
  final AiChatRepository repository;

  SendMessageUseCase(this.repository);

  /// 执行发送消息操作
  Future<ChatMessage> execute(String message, List<ChatMessage> history) {
    return repository.sendMessage(message, history);
  }
} 