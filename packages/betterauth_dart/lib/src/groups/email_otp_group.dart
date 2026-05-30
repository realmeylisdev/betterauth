import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template email_otp_group}
/// Email one-time-password methods, exposed as `client.emailOtp`. Requires the
/// email-OTP plugin.
/// {@endtemplate}
final class EmailOtpGroup extends BetterAuthGroup {
  /// {@macro email_otp_group}
  EmailOtpGroup(super.http, super.sink);

  /// Sends a verification OTP for the given [type]
  /// (`POST /email-otp/send-verification-otp`).
  Future<AuthResult<StatusResponse>> sendVerificationOtp({
    required String email,
    required EmailOtpType type,
  }) async {
    final raw = await http.request(
      '/email-otp/send-verification-otp',
      method: 'POST',
      body: <String, dynamic>{'email': email, 'type': type.wire},
    );
    return decodeStatus(raw);
  }

  /// Verifies an email with an OTP (`POST /email-otp/verify-email`).
  ///
  /// When the server creates a session the client adopts it and emits
  /// [AuthChangeEvent.signedIn].
  Future<AuthResult<EmailOtpVerifyResponse>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final raw = await http.request(
      '/email-otp/verify-email',
      method: 'POST',
      body: <String, dynamic>{'email': email, 'otp': otp},
    );
    final result = decodeObject(raw, EmailOtpVerifyResponse.fromJson);
    if (result case AuthSuccess<EmailOtpVerifyResponse>(
      data: final r,
    ) when r.token != null) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  /// Requests a password-reset OTP (`POST /email-otp/request-password-reset`).
  Future<AuthResult<StatusResponse>> requestPasswordReset({
    required String email,
  }) async {
    final raw = await http.request(
      '/email-otp/request-password-reset',
      method: 'POST',
      body: <String, dynamic>{'email': email},
    );
    return decodeStatus(raw);
  }

  /// Resets a password using an OTP (`POST /email-otp/reset-password`).
  Future<AuthResult<StatusResponse>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final raw = await http.request(
      '/email-otp/reset-password',
      method: 'POST',
      body: <String, dynamic>{
        'email': email,
        'otp': otp,
        'password': password,
      },
    );
    return decodeStatus(raw);
  }

  /// Checks an OTP without consuming it
  /// (`POST /email-otp/check-verification-otp`).
  Future<AuthResult<StatusResponse>> checkVerificationOtp({
    required String email,
    required String otp,
    required EmailOtpType type,
  }) async {
    final raw = await http.request(
      '/email-otp/check-verification-otp',
      method: 'POST',
      body: <String, dynamic>{
        'email': email,
        'otp': otp,
        'type': type.wire,
      },
    );
    return decodeStatus(raw);
  }
}
