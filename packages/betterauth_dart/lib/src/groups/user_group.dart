import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template user_group}
/// Current-user mutation methods, exposed as `client.user`.
/// {@endtemplate}
final class UserGroup extends BetterAuthGroup {
  /// {@macro user_group}
  UserGroup(super.http, super.sink);

  /// Updates the current user's profile (`POST /update-user`).
  ///
  /// On success the client refreshes its session and emits
  /// [AuthChangeEvent.userUpdated]. Pass extra mutable fields via
  /// [additionalFields].
  Future<AuthResult<StatusResponse>> update({
    String? name,
    String? image,
    Map<String, dynamic>? additionalFields,
  }) async {
    final raw = await http.request(
      '/update-user',
      method: 'POST',
      body: body(<String, dynamic>{
        'name': name,
        'image': image,
        ...?additionalFields,
      }),
    );
    final result = decodeStatus(raw);
    if (result case AuthSuccess<StatusResponse>(data: final r) when r.ok) {
      await sink.hydrate(event: AuthChangeEvent.userUpdated);
    }
    return result;
  }

  /// Requests a change of the current user's email (`POST /change-email`).
  ///
  /// Depending on server configuration this may require verifying the new
  /// address via an emailed link.
  Future<AuthResult<StatusResponse>> changeEmail({
    required String newEmail,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/change-email',
      method: 'POST',
      body: body(<String, dynamic>{
        'newEmail': newEmail,
        'callbackURL': callbackURL,
      }),
    );
    return decodeStatus(raw);
  }

  /// Deletes the current user (`POST /delete-user`).
  ///
  /// Provide [password] (or a verification [token]) per server configuration;
  /// some setups instead email a confirmation link.
  Future<AuthResult<StatusResponse>> delete({
    String? password,
    String? token,
    String? callbackURL,
  }) async {
    final raw = await http.request(
      '/delete-user',
      method: 'POST',
      body: body(<String, dynamic>{
        'password': password,
        'token': token,
        'callbackURL': callbackURL,
      }),
    );
    return decodeStatus(raw);
  }
}
