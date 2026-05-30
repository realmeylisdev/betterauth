import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/constants.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
import 'package:dio/dio.dart';

/// {@template auth_interceptor}
/// Attaches credentials to outgoing requests and captures them from responses.
///
/// On request it adds `Authorization: Bearer <token>` (bearer mode) and a
/// `Cookie` header for any stored cookies (always — this is how the
/// `two_factor` challenge and `trust_device` cookies travel, even in bearer
/// mode). On every response (and errored response) it captures the
/// `set-auth-token` header and any `Set-Cookie` headers into the [tokenStore].
/// {@endtemplate}
class AuthInterceptor extends Interceptor {
  /// {@macro auth_interceptor}
  AuthInterceptor({required this.tokenStore, required this.transportMode});

  /// The store holding the bearer token and cookies.
  final TokenStore tokenStore;

  /// The configured transport mode.
  final AuthTransportMode transportMode;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (transportMode == AuthTransportMode.bearer && tokenStore.hasToken) {
      options.headers[kAuthorizationHeader] =
          '$kBearerPrefix${tokenStore.token}';
    }
    final cookieHeader = tokenStore.cookies.header;
    if (cookieHeader != null) {
      options.headers[kCookieHeader] = cookieHeader;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _capture(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _capture(response.headers);
    }
    handler.next(err);
  }

  void _capture(Headers headers) {
    final token = headers.value(kSetAuthTokenHeader);
    if (token != null && token.isNotEmpty) {
      tokenStore.token = token;
    }
    final setCookies = headers[kSetCookieHeader];
    if (setCookies != null && setCookies.isNotEmpty) {
      tokenStore.cookies.storeFromSetCookie(setCookies);
    }
  }
}
