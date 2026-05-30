import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template account_group}
/// Linked-account methods, exposed as `client.account`.
/// {@endtemplate}
final class AccountGroup extends BetterAuthGroup {
  /// {@macro account_group}
  AccountGroup(super.http, super.sink);

  /// Lists the current user's linked accounts (`GET /list-accounts`).
  Future<AuthResult<List<Account>>> list() async {
    final raw = await http.request('/list-accounts', method: 'GET');
    return decodeList(raw, Account.fromJson);
  }

  /// Unlinks a provider account (`POST /unlink-account`).
  ///
  /// Provide [accountId] to disambiguate when multiple accounts share a
  /// [providerId].
  Future<AuthResult<StatusResponse>> unlink({
    required String providerId,
    String? accountId,
  }) async {
    final raw = await http.request(
      '/unlink-account',
      method: 'POST',
      body: body(<String, dynamic>{
        'providerId': providerId,
        'accountId': accountId,
      }),
    );
    return decodeStatus(raw);
  }

  /// Begins linking a social provider to the current user
  /// (`POST /link-social`), returning the authorization URL to open in a
  /// browser to complete linking.
  Future<AuthResult<String>> linkSocial({
    required String provider,
    String? callbackURL,
    List<String>? scopes,
    String? errorCallbackURL,
    bool? disableRedirect,
    bool? requestSignUp,
    IdToken? idToken,
  }) async {
    final raw = await http.request(
      '/link-social',
      method: 'POST',
      body: body(<String, dynamic>{
        'provider': provider,
        'callbackURL': callbackURL,
        'scopes': scopes,
        'errorCallbackURL': errorCallbackURL,
        'disableRedirect': disableRedirect,
        'requestSignUp': requestSignUp,
        'idToken': idToken?.toJson(),
      }),
    );
    return decodeObject(raw, (json) => json['url'] as String);
  }
}
