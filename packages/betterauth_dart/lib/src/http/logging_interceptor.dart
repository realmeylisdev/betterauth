import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// {@template logging_interceptor}
/// Logs requests and responses with sensitive values redacted.
///
/// Passwords, tokens, OTPs and verification codes are replaced with `***` in
/// both bodies and headers. Logging is a no-op unless [enabled] is `true`; the
/// client enables it automatically in debug builds.
/// {@endtemplate}
class LoggingInterceptor extends Interceptor {
  /// {@macro logging_interceptor}
  LoggingInterceptor({
    required this.enabled,
    void Function(String message)? log,
  }) : _log = log ?? _defaultLog;

  /// Whether logging is active.
  final bool enabled;

  final void Function(String message) _log;

  static void _defaultLog(String message) =>
      developer.log(message, name: 'betterauth');

  static const Set<String> _sensitiveKeys = {
    'password',
    'newpassword',
    'currentpassword',
    'token',
    'otp',
    'code',
    'secret',
    'backupcode',
    'backupcodes',
    'idtoken',
  };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (enabled) {
      _log(
        '→ ${options.method} ${options.uri.path} '
        'body: ${_redact(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      _log(
        '← ${response.statusCode} ${response.requestOptions.uri.path} '
        'data: ${_redact(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      _log(
        '✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri.path}',
      );
    }
    handler.next(err);
  }

  /// Returns a copy of [value] with sensitive entries masked.
  static Object? _redact(Object? value) {
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key.toString():
              _sensitiveKeys.contains(entry.key.toString().toLowerCase())
              ? '***'
              : _redact(entry.value),
      };
    }
    if (value is List) {
      return value.map(_redact).toList();
    }
    return value;
  }
}
