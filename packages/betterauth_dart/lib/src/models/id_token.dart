import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template id_token}
/// A provider id-token bundle for native social sign-in (the `idToken` field of
/// `/sign-in/social`). Pass the [token] obtained from the native Google/Apple
/// flow to sign in without a browser redirect.
/// {@endtemplate}
@immutable
class IdToken extends Equatable {
  /// {@macro id_token}
  const IdToken({
    required this.token,
    this.nonce,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// The provider id token (JWT).
  final String token;

  /// The nonce used when requesting the id token, if any.
  final String? nonce;

  /// An optional provider access token.
  final String? accessToken;

  /// An optional provider refresh token.
  final String? refreshToken;

  /// Optional access-token expiry as a Unix timestamp (seconds).
  final int? expiresAt;

  /// Serializes to the wire shape expected by `/sign-in/social`.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    if (nonce != null) 'nonce': nonce,
    if (accessToken != null) 'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (expiresAt != null) 'expiresAt': expiresAt,
  };

  @override
  List<Object?> get props => [
    token,
    nonce,
    accessToken,
    refreshToken,
    expiresAt,
  ];
}
