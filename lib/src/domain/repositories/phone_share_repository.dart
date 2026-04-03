import '../models/phone_share.dart';

abstract interface class PhoneShareRepository {
  /// Watch all phone shares for a booking.
  Stream<List<PhoneShare>> watchForBooking(String bookingId);

  /// Share a phone number for the current user in the context of a booking.
  Future<void> share({
    required String bookingId,
    required String uid,
    required String phone,
  });
}
