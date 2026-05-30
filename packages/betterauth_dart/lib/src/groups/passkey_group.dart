import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template passkey_group}
/// WebAuthn passkey methods, exposed as `client.passkey`. Requires the passkey
/// plugin.
///
/// The `generate*Options` calls return the raw WebAuthn options maps to hand to
/// a native authenticator (see `betterauth_flutter`'s `PasskeyAuthenticator`);
/// the resulting attestation/assertion map is passed back to `verify*`. The
/// challenge travels in a cookie captured automatically by the transport.
///
/// Signing in with a passkey is `client.signIn.passkey`.
/// {@endtemplate}
final class PasskeyGroup extends BetterAuthGroup {
  /// {@macro passkey_group}
  PasskeyGroup(super.http, super.sink);

  /// Requests WebAuthn registration options
  /// (`GET /passkey/generate-register-options`). Returns the raw options map.
  Future<AuthResult<Map<String, dynamic>>> generateRegisterOptions({
    String? authenticatorAttachment,
  }) async {
    final raw = await http.request(
      '/passkey/generate-register-options',
      method: 'GET',
      query: <String, dynamic>{
        'authenticatorAttachment': ?authenticatorAttachment,
      },
    );
    return decodeObject(raw, (json) => json);
  }

  /// Verifies a passkey registration for the signed-in user
  /// (`POST /passkey/verify-registration`), returning the created [Passkey].
  ///
  /// [response] is the attestation map produced by the native authenticator.
  Future<AuthResult<Passkey>> verifyRegistration({
    required Map<String, dynamic> response,
    String? name,
  }) async {
    final raw = await http.request(
      '/passkey/verify-registration',
      method: 'POST',
      body: <String, dynamic>{...response, 'name': ?name},
    );
    return decodeObject(raw, _unwrapPasskey);
  }

  /// Requests WebAuthn authentication options
  /// (`GET /passkey/generate-authenticate-options`). Returns the raw options
  /// map.
  Future<AuthResult<Map<String, dynamic>>> generateAuthenticateOptions({
    String? email,
  }) async {
    final raw = await http.request(
      '/passkey/generate-authenticate-options',
      method: 'GET',
      query: <String, dynamic>{'email': ?email},
    );
    return decodeObject(raw, (json) => json);
  }

  /// Lists the current user's passkeys (`GET /passkey/list-user-passkeys`).
  Future<AuthResult<List<Passkey>>> listUserPasskeys() async {
    final raw = await http.request(
      '/passkey/list-user-passkeys',
      method: 'GET',
    );
    return decodeList(raw, Passkey.fromJson);
  }

  /// Renames a passkey (`POST /passkey/update-passkey`).
  Future<AuthResult<Passkey>> updatePasskey({
    required String id,
    required String name,
  }) async {
    final raw = await http.request(
      '/passkey/update-passkey',
      method: 'POST',
      body: <String, dynamic>{'id': id, 'name': name},
    );
    return decodeObject(raw, _unwrapPasskey);
  }

  /// Deletes a passkey (`POST /passkey/delete-passkey`).
  Future<AuthResult<StatusResponse>> deletePasskey({
    required String id,
  }) async {
    final raw = await http.request(
      '/passkey/delete-passkey',
      method: 'POST',
      body: <String, dynamic>{'id': id},
    );
    return decodeStatus(raw);
  }

  /// Parses a [Passkey] whether the server returns it bare or under a
  /// `passkey` key.
  static Passkey _unwrapPasskey(Map<String, dynamic> json) {
    final inner = json['passkey'];
    return Passkey.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : json,
    );
  }
}
