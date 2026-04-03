enum BookingStatus {
  requested,
  accepted,
  inProgress,
  done,
  rejected,
  cancelled;

  /// Canonical Firestore string values (snake_case).
  String get value {
    switch (this) {
      case BookingStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'requested':
        return BookingStatus.requested;
      case 'accepted':
        return BookingStatus.accepted;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'done':
        return BookingStatus.done;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.requested;
    }
  }
}
