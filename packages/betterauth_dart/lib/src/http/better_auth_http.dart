import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:betterauth_dart/src/http/auth_interceptor.dart';
import 'package:betterauth_dart/src/http/logging_interceptor.dart';
import 'package:betterauth_dart/src/http/retry_interceptor.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// Whether the program is running in debug mode (asserts enabled).
bool get isDebugMode {
  var debug = false;
  assert(
    () {
      debug = true;
      return true;
    }(),
    'enabling debug detection',
  );
  return debug;
}

/// {@template better_auth_http}
/// The transport seam between the typed client groups and dio.
///
/// Builds and owns a configured [Dio] (timeouts, JSON, the auth/retry/logging
/// interceptors), resolves absolute request URLs, and maps every outcome to an
/// [AuthResult] — never throwing across its API. Non-2xx responses and dio
/// errors become the appropriate [AuthException] subtype.
/// {@endtemplate}
class BetterAuthHttp {
  /// {@macro better_auth_http}
  BetterAuthHttp({
    required Uri baseUrl,
    required this.options,
    required this.tokenStore,
    Dio? dio,
    List<Interceptor>? interceptors,
    void Function()? onUnauthorized,
    void Function(String message)? logger,
  }) : _baseUrl = baseUrl,
       _onUnauthorized = onUnauthorized,
       _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = options.timeout
      ..sendTimeout = options.timeout
      ..receiveTimeout = options.timeout
      ..responseType = ResponseType.json
      ..headers[Headers.contentTypeHeader] = Headers.jsonContentType
      // Accept <500 so 4xx are mapped here; 5xx throw and are retried.
      ..validateStatus = (status) => status != null && status < 500;

    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenStore: tokenStore,
        transportMode: options.transportMode,
      ),
      RetryInterceptor(dio: _dio, maxRetries: options.maxRetries),
      LoggingInterceptor(
        enabled: options.enableLogging ?? isDebugMode,
        log: logger,
      ),
      ...?interceptors,
    ]);
  }

  final Uri _baseUrl;
  final Dio _dio;
  final void Function()? _onUnauthorized;

  /// The configuration in effect.
  final BetterAuthClientOptions options;

  /// The credential store shared with the auth interceptor.
  final TokenStore tokenStore;

  /// The underlying Dio instance (exposed for testing).
  @visibleForTesting
  Dio get dio => _dio;

  /// Resolves [path] (and optional [query]) against the base URL into an
  /// absolute [Uri], side-stepping dio's base-path merging.
  Uri resolve(String path, [Map<String, dynamic>? query]) {
    final base = _baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final suffix = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$base$suffix');
    if (query != null && query.isNotEmpty) {
      final stringified = <String, String>{
        for (final entry in query.entries)
          if (entry.value != null) entry.key: '${entry.value}',
      };
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, ...stringified},
      );
    }
    return uri;
  }

  /// Performs a request and returns the decoded JSON body as an [AuthResult].
  ///
  /// On success the data is the decoded body (a `Map`, `List`, or `null`).
  Future<AuthResult<Object?>> request(
    String path, {
    required String method,
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final uri = resolve(path, query);
    try {
      final response = await _dio.requestUri<dynamic>(
        uri,
        data: body,
        options: Options(method: method),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        return AuthSuccess<Object?>(response.data);
      }
      return AuthFailure<Object?>(_mapErrorResponse(status, response.data));
    } on DioException catch (e) {
      return AuthFailure<Object?>(_mapDioException(e));
    } on Object catch (e) {
      return AuthFailure<Object?>(
        AuthUnknownException('Unexpected error: $e', originalError: e),
      );
    }
  }

  AuthException _mapErrorResponse(int status, Object? data) {
    final parsed = _parseError(data);
    if (status == 401) {
      _onUnauthorized?.call();
      return AuthSessionMissingException(
        parsed.message ?? 'No active session.',
      );
    }
    return AuthApiException(
      parsed.message ?? 'Request failed with status $status.',
      statusCode: status,
      code: AuthErrorCode.fromWire(parsed.code),
      rawCode: parsed.code,
      details: parsed.details,
    );
  }

  AuthException _mapDioException(DioException err) {
    final response = err.response;
    if (response != null) {
      final status = response.statusCode ?? 0;
      if (status >= 500) {
        final parsed = _parseError(response.data);
        return AuthRetryableFetchException(
          parsed.message ?? 'Server error ($status).',
          statusCode: status,
          code: AuthErrorCode.fromWire(parsed.code),
          rawCode: parsed.code,
          details: parsed.details,
        );
      }
      return _mapErrorResponse(status, response.data);
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return AuthRetryableFetchException(
          'Network error: ${err.message ?? err.type.name}',
        );
      case DioExceptionType.cancel:
        return AuthUnknownException('Request cancelled.', originalError: err);
      case DioExceptionType.badCertificate:
        return AuthUnknownException(
          'Bad certificate.',
          originalError: err,
        );
      case DioExceptionType.badResponse:
        return AuthUnknownException(
          'Bad response.',
          originalError: err,
        );
    }
  }

  ({String? message, String? code, Map<String, Object?>? details}) _parseError(
    Object? data,
  ) {
    if (data is Map) {
      final error = data['error'];
      final source = error is Map ? error : data;
      final message = source['message'] as String?;
      final code = source['code'] as String?;
      final details = <String, Object?>{
        for (final entry in source.entries)
          if (entry.key != 'message' && entry.key != 'code')
            '${entry.key}': entry.value,
      };
      return (
        message: message,
        code: code,
        details: details.isEmpty ? null : details,
      );
    }
    if (data is String && data.isNotEmpty) {
      return (message: data, code: null, details: null);
    }
    return (message: null, code: null, details: null);
  }

  /// Closes the underlying Dio client.
  void close() => _dio.close();
}
