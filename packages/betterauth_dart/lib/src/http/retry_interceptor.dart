import 'package:dio/dio.dart';

/// {@template retry_interceptor}
/// Retries transient failures — connection errors, timeouts, and 5xx
/// responses — with exponential backoff, up to [maxRetries] attempts.
///
/// Note: this retries *all* request methods, including non-idempotent mutations
/// (sign-up, sign-in). A network failure that occurs *after* the server has
/// processed such a request could therefore be retried and produce a duplicate
/// side effect. This is an accepted trade-off of the configured policy.
/// {@endtemplate}
class RetryInterceptor extends Interceptor {
  /// {@macro retry_interceptor}
  RetryInterceptor({
    required this.dio,
    required this.maxRetries,
    this.baseDelay = const Duration(milliseconds: 300),
  });

  /// The Dio instance used to re-send requests.
  final Dio dio;

  /// The maximum number of retry attempts. `0` disables retrying.
  final int maxRetries;

  /// The base backoff delay; attempt _n_ waits `baseDelay * 2^n`.
  final Duration baseDelay;

  static const String _attemptKey = 'betterauth_retry_attempt';

  /// Whether [err] represents a transient, retryable failure.
  bool isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500 && status <= 599;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (maxRetries <= 0 || attempt >= maxRetries || !isRetryable(err)) {
      handler.next(err);
      return;
    }

    final delay = baseDelay * (1 << attempt);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
