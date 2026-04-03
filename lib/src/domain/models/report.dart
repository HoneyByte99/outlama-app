class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.status = 'open',
  });

  final String id;
  final String reporterId;

  /// "user", "service", or "message"
  final String targetType;
  final String targetId;
  final String reason;

  /// "open", "resolved", or "dismissed"
  final String status;
  final DateTime createdAt;

  Report copyWith({
    String? reporterId,
    String? targetType,
    String? targetId,
    String? reason,
    String? status,
    DateTime? createdAt,
  }) {
    return Report(
      id: id,
      reporterId: reporterId ?? this.reporterId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
