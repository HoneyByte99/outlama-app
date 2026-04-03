/// A time range during which the provider is unavailable.
class BlockedSlot {
  const BlockedSlot({
    required this.id,
    required this.date,
    this.endDate,
    this.reason,
  });

  final String id;

  /// Start of the blocked period.
  final DateTime date;

  /// End of the blocked period. If null, the entire day is blocked.
  final DateTime? endDate;

  /// Optional reason ("Congé", "RDV perso"...).
  final String? reason;

  /// Whether this slot blocks an entire day (no endDate).
  bool get isFullDay => endDate == null;
}
