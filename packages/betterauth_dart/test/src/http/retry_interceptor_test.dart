import 'dart:async';

import 'package:betterauth_dart/src/http/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDio extends Mock implements Dio {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

class _FakeDioException extends Fake implements DioException {}

class _FakeResponse extends Fake implements Response<dynamic> {}

DioException _exception(
  DioExceptionType type, {
  int? statusCode,
  RequestOptions? requestOptions,
}) {
  final options = requestOptions ?? RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
          ),
  );
}

void main() {
  group(RetryInterceptor, () {
    late _MockDio dio;

    setUpAll(() {
      registerFallbackValue(_FakeRequestOptions());
      registerFallbackValue(_FakeDioException());
      registerFallbackValue(_FakeResponse());
    });

    setUp(() {
      dio = _MockDio();
    });

    group('isRetryable', () {
      final interceptor = RetryInterceptor(
        dio: _MockDio(),
        maxRetries: 3,
        baseDelay: Duration.zero,
      );

      test('returns true for connectionTimeout', () {
        expect(
          interceptor.isRetryable(
            _exception(DioExceptionType.connectionTimeout),
          ),
          isTrue,
        );
      });

      test('returns true for sendTimeout', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.sendTimeout)),
          isTrue,
        );
      });

      test('returns true for receiveTimeout', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.receiveTimeout)),
          isTrue,
        );
      });

      test('returns true for connectionError', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.connectionError)),
          isTrue,
        );
      });

      test('returns true for unknown', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.unknown)),
          isTrue,
        );
      });

      test('returns true for badResponse 500', () {
        expect(
          interceptor.isRetryable(
            _exception(DioExceptionType.badResponse, statusCode: 500),
          ),
          isTrue,
        );
      });

      test('returns true for badResponse 599', () {
        expect(
          interceptor.isRetryable(
            _exception(DioExceptionType.badResponse, statusCode: 599),
          ),
          isTrue,
        );
      });

      test('returns false for badResponse 400', () {
        expect(
          interceptor.isRetryable(
            _exception(DioExceptionType.badResponse, statusCode: 400),
          ),
          isFalse,
        );
      });

      test('returns false for badResponse with no status code', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.badResponse)),
          isFalse,
        );
      });

      test('returns false for cancel', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.cancel)),
          isFalse,
        );
      });

      test('returns false for badCertificate', () {
        expect(
          interceptor.isRetryable(_exception(DioExceptionType.badCertificate)),
          isFalse,
        );
      });
    });

    group('onError', () {
      test('calls next when maxRetries is 0', () async {
        final interceptor = RetryInterceptor(
          dio: dio,
          maxRetries: 0,
          baseDelay: Duration.zero,
        );
        final err = _exception(DioExceptionType.connectionError);
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
        verifyNever(() => dio.fetch<dynamic>(any()));
      });

      test('calls next when error is not retryable', () async {
        final interceptor = RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: Duration.zero,
        );
        final err = _exception(DioExceptionType.cancel);
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
        verifyNever(() => dio.fetch<dynamic>(any()));
      });

      test('calls next when attempts are exhausted', () async {
        final interceptor = RetryInterceptor(
          dio: dio,
          maxRetries: 2,
          baseDelay: Duration.zero,
        );
        final options = RequestOptions(path: '/x')
          ..extra['betterauth_retry_attempt'] = 2;
        final err = _exception(
          DioExceptionType.connectionError,
          requestOptions: options,
        );
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
        verifyNever(() => dio.fetch<dynamic>(any()));
      });

      test('resolves with fetched response on successful retry', () async {
        final interceptor = RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: Duration.zero,
        );
        final options = RequestOptions(path: '/x');
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
        );
        when(() => dio.fetch<dynamic>(any())).thenAnswer((_) async => response);
        final err = _exception(
          DioExceptionType.connectionError,
          requestOptions: options,
        );
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.resolve(response)).called(1);
        verify(() => dio.fetch<dynamic>(any())).called(1);
        verifyNever(() => handler.next(any()));
        expect(options.extra['betterauth_retry_attempt'], equals(1));
      });

      test('increments existing attempt counter before fetching', () async {
        final interceptor = RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          baseDelay: Duration.zero,
        );
        final options = RequestOptions(path: '/x')
          ..extra['betterauth_retry_attempt'] = 1;
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
        );
        when(() => dio.fetch<dynamic>(any())).thenAnswer((_) async => response);
        final err = _exception(
          DioExceptionType.connectionError,
          requestOptions: options,
        );
        final handler = _MockErrorHandler();

        await interceptor.onError(err, handler);

        expect(options.extra['betterauth_retry_attempt'], equals(2));
        verify(() => handler.resolve(response)).called(1);
      });

      test(
        'calls next with thrown DioException when retry fetch fails',
        () async {
          final interceptor = RetryInterceptor(
            dio: dio,
            maxRetries: 3,
            baseDelay: Duration.zero,
          );
          final options = RequestOptions(path: '/x');
          final fetchError = DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
          when(() => dio.fetch<dynamic>(any())).thenThrow(fetchError);
          final err = _exception(
            DioExceptionType.connectionError,
            requestOptions: options,
          );
          final handler = _MockErrorHandler();

          await interceptor.onError(err, handler);

          verify(() => handler.next(fetchError)).called(1);
          verifyNever(() => handler.resolve(any()));
        },
      );

      test('waits for backoff delay before retrying', () {
        fakeAsync((async) {
          // Uses the default 300ms base delay to exercise the backoff branch.
          final interceptor = RetryInterceptor(
            dio: dio,
            maxRetries: 3,
          );
          final options = RequestOptions(path: '/x');
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
          );
          when(
            () => dio.fetch<dynamic>(any()),
          ).thenAnswer((_) async => response);
          final err = _exception(
            DioExceptionType.connectionError,
            requestOptions: options,
          );
          final handler = _MockErrorHandler();

          unawaited(interceptor.onError(err, handler));

          // Before the delay elapses, no fetch yet.
          async.flushMicrotasks();
          verifyNever(() => dio.fetch<dynamic>(any()));

          async
            ..elapse(const Duration(milliseconds: 300))
            ..flushMicrotasks();

          verify(() => dio.fetch<dynamic>(any())).called(1);
          verify(() => handler.resolve(response)).called(1);
        });
      });
    });
  });
}
