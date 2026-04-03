class Chat {
  const Chat({
    required this.id,
    required this.bookingId,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageAt,
    this.customerId = '',
    this.providerId = '',
  });

  final String id;
  final String bookingId;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  /// UID of the client who made the booking.
  /// Written by acceptBooking Cloud Function. Empty on legacy documents.
  final String customerId;

  /// UID of the provider who accepted the booking.
  /// Written by acceptBooking Cloud Function. Empty on legacy documents.
  final String providerId;

  Chat copyWith({
    String? bookingId,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? customerId,
    String? providerId,
  }) {
    return Chat(
      id: id,
      bookingId: bookingId ?? this.bookingId,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
    );
  }
}
