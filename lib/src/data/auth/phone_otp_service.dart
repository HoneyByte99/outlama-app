// Conditional export: web gets RecaptchaVerifier flow,
// mobile/stub gets verifyPhoneNumber flow.
export 'phone_otp_service_stub.dart'
    if (dart.library.html) 'phone_otp_service_web.dart';
