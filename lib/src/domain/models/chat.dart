class Chat {
  const Chat({
    required this.id,
    required this.bookingId,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageAt,
  });

  final String id;
  final String bookingId;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  Chat copyWith({
    String? bookingId,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return Chat(
      id: id,
      bookingId: bookingId ?? this.bookingId,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
