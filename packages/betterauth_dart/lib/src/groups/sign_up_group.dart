import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template sign_up_group}
/// Account creation methods, exposed as `client.signUp`.
/// {@endtemplate}
final class SignUpGroup extends BetterAuthGroup {
  /// {@macro sign_up_group}
  SignUpGroup(super.http, super.sink);

  /// Creates a user with email and password (`POST /sign-up/email`).
  ///
  /// When the server returns a session token (auto-sign-in enabled and no
  /// email verification required) the client adopts the session and emits
  /// [AuthChangeEvent.signedIn]. Pass [username]/[displayUsername] when the
  /// username plugin is enabled, and any extra registration fields via
  /// [additionalFields].
  Future<AuthResult<SignUpResponse>> email({
    required String name,
    required String email,
    required String password,
    String? image,
    String? username,
    String? displayUsername,
    String? callbackURL,
    bool? rememberMe,
    Map<String, dynamic>? additionalFields,
  }) async {
    final raw = await http.request(
      '/sign-up/email',
      method: 'POST',
      body: body(<String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'image': image,
        'username': username,
        'displayUsername': displayUsername,
        'callbackURL': callbackURL,
        'rememberMe': rememberMe,
        ...?additionalFields,
      }),
    );
    final result = decodeObject(raw, SignUpResponse.fromJson);
    if (result case AuthSuccess<SignUpResponse>(
      data: final r,
    ) when r.token != null) {
      await sink.hydrate(token: r.token);
    }
    return result;
  }
}
