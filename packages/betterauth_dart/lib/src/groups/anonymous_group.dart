import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template anonymous_group}
/// Anonymous-user methods, exposed as `client.anonymous`. Requires the
/// anonymous plugin. (Signing in anonymously is `client.signIn.anonymous`.)
/// {@endtemplate}
final class AnonymousGroup extends BetterAuthGroup {
  /// {@macro anonymous_group}
  AnonymousGroup(super.http, super.sink);

  /// Deletes the current anonymous user (`POST /delete-anonymous-user`).
  ///
  /// Fails with `AuthErrorCode.userIsNotAnonymous` if the current session user
  /// is a regular (non-anonymous) user.
  Future<AuthResult<StatusResponse>> deleteUser() async {
    final raw = await http.request('/delete-anonymous-user', method: 'POST');
    return decodeStatus(raw);
  }
}
