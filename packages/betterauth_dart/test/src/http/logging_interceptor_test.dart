import 'package:betterauth_dart/src/http/logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestHandler extends Mock implements RequestInterceptorHandler {}

class _MockResponseHandler extends Mock implements ResponseInterceptorHandler {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

class _FakeResponse extends Fake implements Response<dynamic> {}

class _FakeDioException extends Fake implements DioException {}

void main() {
  group(LoggingInterceptor, () {
    late List<String> logs;

    setUpAll(() {
      registerFallbackValue(_FakeRequestOptions());
      registerFallbackValue(_FakeResponse());
      registerFallbackValue(_FakeDioException());
    });

    setUp(() {
      logs = <String>[];
    });

    LoggingInterceptor build({required bool enabled}) => LoggingInterceptor(
      enabled: enabled,
      log: logs.add,
    );

    group('constructor', () {
      test('uses the default developer log when none is provided', () {
        // Drive a real log call through the default logger (dart:developer) to
        // exercise the fallback branch; it must not throw and must call next.
        final interceptor = LoggingInterceptor(enabled: true);
        final options = RequestOptions(path: '/x', method: 'POST');
        final handler = _MockRequestHandler();

        interceptor.onRequest(options, handler);

        verify(() => handler.next(options)).called(1);
      });
    });

    group('onRequest', () {
      test('logs redacted body and calls next when enabled', () {
        final interceptor = build(enabled: true);
        final options = RequestOptions(
          path: '/sign-in',
          method: 'POST',
          data: <String, Object?>{'email': 'a@b.com', 'password': 'secret'},
        );
        final handler = _MockRequestHandler();

        interceptor.onRequest(options, handler);

        expect(logs, hasLength(1));
        expect(logs.single, contains('→ POST'));
        expect(logs.single, contains('a@b.com'));
        expect(logs.single, contains('***'));
        expect(logs.single, isNot(contains('secret')));
        verify(() => handler.next(options)).called(1);
      });

      test('logs nothing when disabled but still calls next', () {
        final interceptor = build(enabled: false);
        final options = RequestOptions(path: '/sign-in', method: 'POST');
        final handler = _MockRequestHandler();

        interceptor.onRequest(options, handler);

        expect(logs, isEmpty);
        verify(() => handler.next(options)).called(1);
      });
    });

    group('onResponse', () {
      test('logs redacted data and calls next when enabled', () {
        final interceptor = build(enabled: true);
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/get-session'),
          statusCode: 200,
          data: <String, Object?>{'token': 't', 'user': 'ada'},
        );
        final handler = _MockResponseHandler();

        interceptor.onResponse(response, handler);

        expect(logs, hasLength(1));
        expect(logs.single, contains('← 200'));
        expect(logs.single, contains('***'));
        expect(logs.single, isNot(contains('"token"')));
        verify(() => handler.next(response)).called(1);
      });

      test('logs nothing when disabled but still calls next', () {
        final interceptor = build(enabled: false);
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/get-session'),
          statusCode: 200,
        );
        final handler = _MockResponseHandler();

        interceptor.onResponse(response, handler);

        expect(logs, isEmpty);
        verify(() => handler.next(response)).called(1);
      });
    });

    group('onError', () {
      test('logs status code when response present and calls next', () {
        final interceptor = build(enabled: true);
        final requestOptions = RequestOptions(path: '/sign-in');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
        );
        final handler = _MockErrorHandler();

        interceptor.onError(err, handler);

        expect(logs, hasLength(1));
        expect(logs.single, contains('✗ 401'));
        expect(logs.single, contains('/sign-in'));
        verify(() => handler.next(err)).called(1);
      });

      test('logs error type name when response absent', () {
        final interceptor = build(enabled: true);
        final err = DioException(
          requestOptions: RequestOptions(path: '/sign-in'),
          type: DioExceptionType.connectionError,
        );
        final handler = _MockErrorHandler();

        interceptor.onError(err, handler);

        expect(logs, hasLength(1));
        expect(logs.single, contains('connectionError'));
        verify(() => handler.next(err)).called(1);
      });

      test('logs nothing when disabled but still calls next', () {
        final interceptor = build(enabled: false);
        final err = DioException(
          requestOptions: RequestOptions(path: '/sign-in'),
        );
        final handler = _MockErrorHandler();

        interceptor.onError(err, handler);

        expect(logs, isEmpty);
        verify(() => handler.next(err)).called(1);
      });
    });

    group('redaction', () {
      test('masks all sensitive keys regardless of case', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final data = <String, Object?>{
          'password': 'p',
          'newPassword': 'p',
          'currentPassword': 'p',
          'token': 't',
          'otp': '123',
          'code': '456',
          'secret': 's',
          'backupCode': 'b',
          'backupCodes': 'b',
          'idToken': 'i',
        };
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(path: '/x', method: 'POST', data: data),
          handler,
        );

        final logged = logs.single;
        expect(logged, isNot(contains(': p')));
        expect(logged, isNot(contains('123')));
        expect(logged, isNot(contains('456')));
        // Every value should be the mask.
        expect('***'.allMatches(logged).length, equals(data.length));
      });

      test('leaves non-sensitive values intact', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(
            path: '/x',
            method: 'POST',
            data: <String, Object?>{'email': 'a@b.com', 'rememberMe': true},
          ),
          handler,
        );

        final logged = logs.single;
        expect(logged, contains('a@b.com'));
        expect(logged, contains('true'));
        expect(logged, isNot(contains('***')));
      });

      test('redacts nested maps', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(
            path: '/x',
            method: 'POST',
            data: <String, Object?>{
              'outer': <String, Object?>{'password': 'p', 'keep': 'v'},
            },
          ),
          handler,
        );

        final logged = logs.single;
        expect(logged, contains('***'));
        expect(logged, contains('keep: v'));
        expect(logged, isNot(contains('password: p')));
      });

      test('redacts maps inside lists', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(
            path: '/x',
            method: 'POST',
            data: <String, Object?>{
              'items': <Object?>[
                <String, Object?>{'token': 't'},
                'plain',
              ],
            },
          ),
          handler,
        );

        final logged = logs.single;
        expect(logged, contains('***'));
        expect(logged, contains('plain'));
      });

      test('passes through non-map non-list scalar bodies', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(path: '/x', method: 'POST', data: 'raw-string'),
          handler,
        );

        expect(logs.single, contains('raw-string'));
      });

      test('passes through null body', () {
        logs.clear();
        final interceptor = build(enabled: true);
        final handler = _MockRequestHandler();

        interceptor.onRequest(
          RequestOptions(path: '/x', method: 'POST'),
          handler,
        );

        expect(logs.single, contains('body: null'));
      });
    });
  });
}
