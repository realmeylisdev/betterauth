import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template email_verification_group}
/// Email verification methods, exposed as `client.emailVerification`.
/// {@endtemplate}
final class EmailVerificationGroup extends BetterAuthGroup {
  /// {@macro email_verification_group}
  EmailVerificationGroup(super.http, super.sink);

  /// Sends a verification email (`POST /send-verification-email`).
  Future<AuthResult<StatusResponse>> send({
    required String email,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/send-verification-email',
      method: 'POST',
      body: body(<String, dynamic>{
        'email': email,
        'callbackURL': callbackURL,
      }),
    );
    return decodeStatus(raw);
  }

  /// Verifies an email using the emailed [token] (`GET /verify-email`).
  ///
  /// Omit [callbackURL] to receive a JSON result instead of a redirect.
  Future<AuthResult<VerifyEmailResponse>> verify({
    required String token,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/verify-email',
      method: 'GET',
      query: <String, dynamic>{
        'token': token,
        'callbackURL': ?callbackURL,
      },
    );
    return decodeObject(raw, VerifyEmailResponse.fromJson);
  }
}
