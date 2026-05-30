import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template phone_number_group}
/// Phone-number OTP methods, exposed as `client.phoneNumber`. Requires the
/// phone-number plugin. (Password sign-in is `client.signIn.phoneNumber`.)
/// {@endtemplate}
final class PhoneNumberGroup extends BetterAuthGroup {
  /// {@macro phone_number_group}
  PhoneNumberGroup(super.http, super.sink);

  /// Sends an OTP to a phone number (`POST /phone-number/send-otp`).
  Future<AuthResult<StatusResponse>> sendOtp({
    required String phoneNumber,
  }) async {
    final raw = await http.request(
      '/phone-number/send-otp',
      method: 'POST',
      body: <String, dynamic>{'phoneNumber': phoneNumber},
    );
    return decodeStatus(raw);
  }

  /// Verifies a phone-number OTP (`POST /phone-number/verify`).
  ///
  /// Set [updatePhoneNumber] to attach/replace the phone of the signed-in user
  /// (requires an active session). Set [disableSession] to verify without
  /// creating a session. When a session token is returned the client adopts it
  /// and emits [AuthChangeEvent.signedIn].
  Future<AuthResult<PhoneVerifyResponse>> verify({
    required String phoneNumber,
    required String code,
    bool? disableSession,
    bool? updatePhoneNumber,
  }) async {
    final raw = await http.request(
      '/phone-number/verify',
      method: 'POST',
      body: body(<String, dynamic>{
        'phoneNumber': phoneNumber,
        'code': code,
        'disableSession': disableSession,
        'updatePhoneNumber': updatePhoneNumber,
      }),
    );
    final result = decodeObject(raw, PhoneVerifyResponse.fromJson);
    if (result case AuthSuccess<PhoneVerifyResponse>(
      data: final r,
    ) when r.token != null) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }

  /// Requests a password-reset OTP by phone
  /// (`POST /phone-number/request-password-reset`).
  Future<AuthResult<StatusResponse>> requestPasswordReset({
    required String phoneNumber,
  }) async {
    final raw = await http.request(
      '/phone-number/request-password-reset',
      method: 'POST',
      body: <String, dynamic>{'phoneNumber': phoneNumber},
    );
    return decodeStatus(raw);
  }

  /// Resets a password using a phone OTP (`POST /phone-number/reset-password`).
  ///
  /// Note the field names: the code is `otp` and the new password is
  /// `newPassword`.
  Future<AuthResult<StatusResponse>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    final raw = await http.request(
      '/phone-number/reset-password',
      method: 'POST',
      body: <String, dynamic>{
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return decodeStatus(raw);
  }
}
