import 'package:firebase_auth/firebase_auth.dart';

// Holds the ConfirmationResult between sendOtp() and verifyOtp() calls.
// Safe as a module-level variable: only one phone verification is active at a time.
ConfirmationResult? _pending;

/// Sends OTP via [FirebaseAuth.signInWithPhoneNumber].
/// Omitting the verifier triggers an invisible reCAPTCHA automatically.
///
/// Returns a placeholder token (`'web'`); the actual [ConfirmationResult]
/// is stored internally and used by [platformVerifyOtp].
Future<String?> platformSendOtp(FirebaseAuth auth, String phone) async {
  _pending = await auth.signInWithPhoneNumber(phone);
  return 'web';
}

/// Confirms [code] using the [ConfirmationResult] from [platformSendOtp].
/// The [verificationId] parameter is unused on web.
Future<UserCredential> platformVerifyOtp(
  FirebaseAuth auth,
  String verificationId,
  String code,
) async {
  final result = _pending;
  if (result == null) throw 'No pending phone verification';
  final credential = await result.confirm(code);
  _pending = null;
  return credential;
}
