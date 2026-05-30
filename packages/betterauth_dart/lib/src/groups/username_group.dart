import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template username_group}
/// Username utilities, exposed as `client.username`. Requires the username
/// plugin. (Username sign-in is `client.signIn.username`.)
/// {@endtemplate}
final class UsernameGroup extends BetterAuthGroup {
  /// {@macro username_group}
  UsernameGroup(super.http, super.sink);

  /// Checks whether a username is available (`POST /is-username-available`).
  Future<AuthResult<bool>> isAvailable({required String username}) async {
    final raw = await http.request(
      '/is-username-available',
      method: 'POST',
      body: <String, dynamic>{'username': username},
    );
    return decodeObject(raw, (json) => json['available'] as bool);
  }
}
