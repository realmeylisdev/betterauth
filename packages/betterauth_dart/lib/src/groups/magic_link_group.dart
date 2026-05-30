import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template magic_link_group}
/// Magic-link verification, exposed as `client.magicLink`. Requires the
/// magic-link plugin. (Sending the link is `client.signIn.magicLink`.)
/// {@endtemplate}
final class MagicLinkGroup extends BetterAuthGroup {
  /// {@macro magic_link_group}
  MagicLinkGroup(super.http, super.sink);

  /// Verifies a magic-link [token] (`GET /magic-link/verify`).
  ///
  /// Omit [callbackURL] to receive the session as JSON; on success the client
  /// adopts the returned session and emits [AuthChangeEvent.signedIn].
  Future<AuthResult<SessionResponse>> verify({
    required String token,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/magic-link/verify',
      method: 'GET',
      query: <String, dynamic>{
        'token': token,
        'callbackURL': ?callbackURL,
      },
    );
    final result = decodeObject(raw, SessionResponse.fromJson);
    if (result case AuthSuccess<SessionResponse>(data: final r)) {
      await sink.setSession(session: r.session, user: r.user);
    }
    return result;
  }
}
