import '../enums/message_type.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.text,
    this.mediaUrl,
  });

  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final DateTime createdAt;
  final String? text;
  final String? mediaUrl;

  ChatMessage copyWith({
    String? chatId,
    String? senderId,
    MessageType? type,
    DateTime? createdAt,
    String? text,
    String? mediaUrl,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
