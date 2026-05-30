import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template password_group}
/// Password reset and change methods, exposed as `client.password`.
/// {@endtemplate}
final class PasswordGroup extends BetterAuthGroup {
  /// {@macro password_group}
  PasswordGroup(super.http, super.sink);

  /// Requests a password-reset email (`POST /request-password-reset`).
  ///
  /// [redirectTo] is the app URL the emailed link should return to.
  Future<AuthResult<StatusResponse>> requestReset({
    required String email,
    String? redirectTo,
  }) async {
    final raw = await http.request(
      '/request-password-reset',
      method: 'POST',
      body: body(<String, dynamic>{
        'email': email,
        'redirectTo': redirectTo,
      }),
    );
    return decodeStatus(raw);
  }

  /// Completes a password reset using the emailed [token]
  /// (`POST /reset-password`).
  Future<AuthResult<StatusResponse>> reset({
    required String newPassword,
    required String token,
  }) async {
    final raw = await http.request(
      '/reset-password',
      method: 'POST',
      body: <String, dynamic>{
        'newPassword': newPassword,
        'token': token,
      },
    );
    return decodeStatus(raw);
  }

  /// Changes the current user's password (`POST /change-password`).
  ///
  /// Set [revokeOtherSessions] to invalidate other sessions; when the server
  /// issues a fresh token the client adopts it and emits
  /// [AuthChangeEvent.sessionRefreshed].
  Future<AuthResult<ChangePasswordResponse>> change({
    required String newPassword,
    required String currentPassword,
    bool? revokeOtherSessions,
  }) async {
    final raw = await http.request(
      '/change-password',
      method: 'POST',
      body: body(<String, dynamic>{
        'newPassword': newPassword,
        'currentPassword': currentPassword,
        'revokeOtherSessions': revokeOtherSessions,
      }),
    );
    final result = decodeObject(raw, ChangePasswordResponse.fromJson);
    if (result case AuthSuccess<ChangePasswordResponse>(
      data: final r,
    ) when r.token != null) {
      await sink.hydrate(
        token: r.token,
        event: AuthChangeEvent.sessionRefreshed,
      );
    }
    return result;
  }
}
