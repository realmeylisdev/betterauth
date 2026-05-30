/// The purpose of an email OTP, sent as the `type` field to
/// `/email-otp/send-verification-otp` and `/email-otp/check-verification-otp`.
enum EmailOtpType {
  /// Sign the user in.
  signIn('sign-in'),

  /// Verify the user's email address.
  emailVerification('email-verification'),

  /// Begin a password reset.
  forgetPassword('forget-password')
  ;

  const EmailOtpType(this.wire);

  /// The exact wire string for this type.
  final String wire;
}
