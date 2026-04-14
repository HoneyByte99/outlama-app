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

  /// Returns `true` if transitioning from `this` to [to] is valid per the
  /// Outalma MVP state machine:
  ///
  ///   requested   → accepted, rejected, cancelled
  ///   accepted    → in_progress
  ///   in_progress → done
  ///   done / rejected / cancelled → (none)
  ///
  /// Note: server-side Cloud Functions are the authoritative enforcers.
  /// This method is a client-side guard to prevent offering invalid actions
  /// in the UI.
  bool canTransitionTo(BookingStatus to) {
    switch (this) {
      case BookingStatus.requested:
        return to == BookingStatus.accepted ||
            to == BookingStatus.rejected ||
            to == BookingStatus.cancelled;
      case BookingStatus.accepted:
        return to == BookingStatus.inProgress;
      case BookingStatus.inProgress:
        return to == BookingStatus.done;
      case BookingStatus.done:
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return false;
    }
  }
}
