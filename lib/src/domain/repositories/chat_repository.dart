import '../models/chat.dart';
import '../models/chat_message.dart';

abstract interface class ChatRepository {
  Stream<Chat?> watchChat(String chatId);

  Stream<List<ChatMessage>> watchMessages({
    required String chatId,
    int limit = 50,
  });

  Future<ChatMessage> sendMessage(ChatMessage message);

  /// Marks all messages in [chatId] not sent by [uid] as read by [uid].
  Future<void> markMessagesRead({required String chatId, required String uid});
}
