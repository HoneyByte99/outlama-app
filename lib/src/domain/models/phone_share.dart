/// Represents a phoneShares document stored at
/// `bookings/{bookingId}/phoneShares/{uid}`.
///
/// The document ID is the UID of the user whose phone is shared.
/// Readable only when booking status is accepted or beyond.
class PhoneShare {
  const PhoneShare({
    required this.uid,
    required this.phone,
    required this.createdAt,
  });

  /// The UID of the user whose phone number this is (also the document ID).
  final String uid;

  /// Phone number in E.164 format.
  final String phone;
  final DateTime createdAt;
}
