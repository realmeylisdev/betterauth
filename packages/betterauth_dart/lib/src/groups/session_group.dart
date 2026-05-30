import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template session_group}
/// Session inspection and revocation methods, exposed as `client.session`.
/// {@endtemplate}
final class SessionGroup extends BetterAuthGroup {
  /// {@macro session_group}
  SessionGroup(super.http, super.sink);

  /// Fetches the current session (`GET /get-session`).
  ///
  /// Returns `null` (as a success) when there is no active session — the server
  /// responds with a literal `null` body. This is a pure query and does not
  /// itself mutate client auth-state.
  Future<AuthResult<SessionResponse?>> get({
    bool? disableCookieCache,
    bool? disableRefresh,
  }) async {
    final raw = await http.request(
      '/get-session',
      method: 'GET',
      query: <String, dynamic>{
        'disableCookieCache': ?disableCookieCache,
        'disableRefresh': ?disableRefresh,
      },
    );
    return decodeNullableObject(raw, SessionResponse.fromJson);
  }

  /// Lists all active sessions for the current user (`GET /list-sessions`).
  Future<AuthResult<List<Session>>> list() async {
    final raw = await http.request('/list-sessions', method: 'GET');
    return decodeList(raw, Session.fromJson);
  }

  /// Revokes a specific session by its [token] (`POST /revoke-session`).
  Future<AuthResult<StatusResponse>> revoke({required String token}) async {
    final raw = await http.request(
      '/revoke-session',
      method: 'POST',
      body: <String, dynamic>{'token': token},
    );
    return decodeStatus(raw);
  }

  /// Revokes all sessions for the current user (`POST /revoke-sessions`),
  /// including the current one.
  Future<AuthResult<StatusResponse>> revokeAll() async {
    final raw = await http.request('/revoke-sessions', method: 'POST');
    return decodeStatus(raw);
  }

  /// Revokes every session except the current one
  /// (`POST /revoke-other-sessions`).
  Future<AuthResult<StatusResponse>> revokeOthers() async {
    final raw = await http.request('/revoke-other-sessions', method: 'POST');
    return decodeStatus(raw);
  }
}
