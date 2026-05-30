import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template two_factor_group}
/// Two-factor authentication methods, exposed as `client.twoFactor`. Requires
/// the two-factor plugin.
///
/// The 2FA challenge after a password sign-in is carried by a `two_factor`
/// cookie captured automatically by the transport; the `verify*` methods below
/// complete that challenge.
/// {@endtemplate}
final class TwoFactorGroup extends BetterAuthGroup {
  /// {@macro two_factor_group}
  TwoFactorGroup(super.http, super.sink);

  /// Enables two-factor (`POST /two-factor/enable`), returning the TOTP URI and
  /// backup codes. Two-factor is only fully active after the first successful
  /// [verifyTotp].
  Future<AuthResult<TwoFactorEnableResponse>> enable({
    required String password,
    String? issuer,
  }) async {
    final raw = await http.request(
      '/two-factor/enable',
      method: 'POST',
      body: body(<String, dynamic>{'password': password, 'issuer': issuer}),
    );
    return decodeObject(raw, TwoFactorEnableResponse.fromJson);
  }

  /// Disables two-factor (`POST /two-factor/disable`).
  Future<AuthResult<StatusResponse>> disable({
    required String password,
  }) async {
    final raw = await http.request(
      '/two-factor/disable',
      method: 'POST',
      body: <String, dynamic>{'password': password},
    );
    return decodeStatus(raw);
  }

  /// Returns the current TOTP provisioning URI (`POST /two-factor/get-totp-uri`).
  Future<AuthResult<TotpUriResponse>> getTotpUri({
    required String password,
  }) async {
    final raw = await http.request(
      '/two-factor/get-totp-uri',
      method: 'POST',
      body: <String, dynamic>{'password': password},
    );
    return decodeObject(raw, TotpUriResponse.fromJson);
  }

  /// Verifies a TOTP code (`POST /two-factor/verify-totp`).
  ///
  /// On success the client adopts the session and emits
  /// [AuthChangeEvent.signedIn]. Set [trustDevice] to skip 2FA on this device
  /// for a period.
  Future<AuthResult<AuthSession>> verifyTotp({
    required String code,
    bool? trustDevice,
  }) async {
    final raw = await http.request(
      '/two-factor/verify-totp',
      method: 'POST',
      body: body(<String, dynamic>{'code': code, 'trustDevice': trustDevice}),
    );
    return _completeVerify(decodeObject(raw, AuthSession.fromJson));
  }

  /// Sends a two-factor OTP (`POST /two-factor/send-otp`).
  Future<AuthResult<StatusResponse>> sendOtp({bool? trustDevice}) async {
    final raw = await http.request(
      '/two-factor/send-otp',
      method: 'POST',
      body: body(<String, dynamic>{'trustDevice': trustDevice}),
    );
    return decodeStatus(raw);
  }

  /// Verifies a two-factor OTP (`POST /two-factor/verify-otp`).
  ///
  /// On success the client adopts the session and emits
  /// [AuthChangeEvent.signedIn].
  Future<AuthResult<AuthSession>> verifyOtp({
    required String code,
    bool? trustDevice,
  }) async {
    final raw = await http.request(
      '/two-factor/verify-otp',
      method: 'POST',
      body: body(<String, dynamic>{'code': code, 'trustDevice': trustDevice}),
    );
    return _completeVerify(decodeObject(raw, AuthSession.fromJson));
  }

  /// Regenerates backup codes (`POST /two-factor/generate-backup-codes`).
  Future<AuthResult<BackupCodesResponse>> generateBackupCodes({
    required String password,
  }) async {
    final raw = await http.request(
      '/two-factor/generate-backup-codes',
      method: 'POST',
      body: <String, dynamic>{'password': password},
    );
    return decodeObject(raw, BackupCodesResponse.fromJson);
  }

  /// Verifies a backup code (`POST /two-factor/verify-backup-code`).
  ///
  /// When a session is created the client adopts it and emits
  /// [AuthChangeEvent.signedIn]. Set [disableSession] to verify without
  /// creating a session.
  Future<AuthResult<VerifyBackupCodeResponse>> verifyBackupCode({
    required String code,
    bool? disableSession,
    bool? trustDevice,
  }) async {
    final raw = await http.request(
      '/two-factor/verify-backup-code',
      method: 'POST',
      body: body(<String, dynamic>{
        'code': code,
        'disableSession': disableSession,
        'trustDevice': trustDevice,
      }),
    );
    final result = decodeObject(raw, VerifyBackupCodeResponse.fromJson);
    if (result case AuthSuccess<VerifyBackupCodeResponse>(
      data: final r,
    ) when r.session != null) {
      await sink.setSession(session: r.session!, user: r.user);
    }
    return result;
  }

  Future<AuthResult<AuthSession>> _completeVerify(
    AuthResult<AuthSession> result,
  ) async {
    if (result case AuthSuccess<AuthSession>(data: final r)) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }
}
