import 'package:betterauth_dart/src/token/cookie_store.dart';

/// {@template token_store}
/// Holds the credentials used to authenticate requests for the lifetime of a
/// client: the bearer [token] and a [cookies] jar.
///
/// This is in-memory only; durable persistence is handled separately by the
/// client via its `AsyncStorage`.
/// {@endtemplate}
class TokenStore {
  /// {@macro token_store}
  TokenStore({CookieStore? cookies}) : cookies = cookies ?? CookieStore();

  /// The current bearer token, or `null` when unauthenticated.
  String? token;

  /// The cookie jar (challenge cookies, trust-device, and the session cookie in
  /// cookie transport mode).
  final CookieStore cookies;

  /// Whether a bearer token is present.
  bool get hasToken => token != null && token!.isNotEmpty;

  /// Clears the bearer token and all cookies.
  void clear() {
    token = null;
    cookies.clear();
  }
}
