import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calls the server-authoritative `acceptBooking` Cloud Function.
///
/// Creates the chat document and sets chatId on the booking.
/// Throws [FirebaseFunctionsException] on known server errors.
class AcceptBookingUseCase {
  const AcceptBookingUseCase(this._functions);

  final FirebaseFunctions _functions;

  Future<void> call(String bookingId) async {
    final callable = _functions.httpsCallable('acceptBooking');
    await callable.call<void>({'bookingId': bookingId});
  }
}

/// Calls the server-authoritative `rejectBooking` Cloud Function.
///
/// Throws [FirebaseFunctionsException] on known server errors.
class RejectBookingUseCase {
  const RejectBookingUseCase(this._functions);

  final FirebaseFunctions _functions;

  Future<void> call(String bookingId) async {
    final callable = _functions.httpsCallable('rejectBooking');
    await callable.call<void>({'bookingId': bookingId});
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final acceptBookingUseCaseProvider = Provider<AcceptBookingUseCase>((ref) {
  return AcceptBookingUseCase(FirebaseFunctions.instance);
});

final rejectBookingUseCaseProvider = Provider<RejectBookingUseCase>((ref) {
  return RejectBookingUseCase(FirebaseFunctions.instance);
});
