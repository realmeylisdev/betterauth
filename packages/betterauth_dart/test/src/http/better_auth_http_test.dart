// Const constructors run before tests and can skew coverage of the unit under
// test, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:betterauth_dart/src/http/better_auth_http.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';
import 'package:betterauth_dart/src/token/cookie_store.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

const String _baseUrl = 'https://api.test/api/auth';

String _url(String path) => '$_baseUrl$path';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
    registerFallbackValue(_FakeOptions());
  });

  group('isDebugMode', () {
    test('returns true when asserts are enabled', () {
      expect(isDebugMode, isTrue);
    });
  });

  group(BetterAuthHttp, () {
    late Dio dio;
    late DioAdapter adapter;
    late TokenStore tokenStore;
    late BetterAuthHttp http;
    late int unauthorizedCalls;

    BetterAuthHttp build({
      Uri? baseUrl,
      BetterAuthClientOptions? options,
      void Function()? onUnauthorized,
      void Function(String message)? logger,
      List<Interceptor>? interceptors,
    }) {
      return BetterAuthHttp(
        baseUrl: baseUrl ?? Uri.parse(_baseUrl),
        options:
            options ??
            const BetterAuthClientOptions(maxRetries: 0, autoRefresh: false),
        tokenStore: tokenStore,
        dio: dio,
        onUnauthorized: onUnauthorized,
        logger: logger,
        interceptors: interceptors,
      );
    }

    setUp(() {
      dio = Dio();
      adapter = DioAdapter(dio: dio);
      tokenStore = TokenStore();
      unauthorizedCalls = 0;
      http = build(onUnauthorized: () => unauthorizedCalls++);
    });

    group('constructor', () {
      test('exposes the configured dio for testing', () {
        expect(http.dio, same(dio));
      });

      test('configures dio timeouts and JSON defaults from options', () {
        final custom = build(
          options: const BetterAuthClientOptions(
            timeout: Duration(seconds: 12),
            maxRetries: 0,
          ),
        );
        expect(
          custom.dio.options.connectTimeout,
          equals(Duration(seconds: 12)),
        );
        expect(custom.dio.options.sendTimeout, equals(Duration(seconds: 12)));
        expect(
          custom.dio.options.receiveTimeout,
          equals(Duration(seconds: 12)),
        );
        expect(custom.dio.options.responseType, equals(ResponseType.json));
        expect(
          custom.dio.options.headers[Headers.contentTypeHeader],
          equals(Headers.jsonContentType),
        );
      });

      test('validateStatus accepts statuses below 500 and rejects 5xx', () {
        final validate = http.dio.options.validateStatus;
        expect(validate(200), isTrue);
        expect(validate(404), isTrue);
        expect(validate(499), isTrue);
        expect(validate(500), isFalse);
        expect(validate(null), isFalse);
      });

      test('honours an explicit enableLogging override', () {
        final custom = build(
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            enableLogging: false,
          ),
        );
        expect(custom.dio.interceptors, isNotEmpty);
      });

      test('appends extra interceptors when provided', () {
        final extra = _NoopInterceptor();
        final custom = build(interceptors: [extra]);
        expect(custom.dio.interceptors, contains(extra));
      });

      test('creates its own Dio when none is supplied', () {
        final custom = BetterAuthHttp(
          baseUrl: Uri.parse(_baseUrl),
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            autoRefresh: false,
          ),
          tokenStore: tokenStore,
        )..close();
        expect(custom.dio, isA<Dio>());
      });
    });

    group('resolve', () {
      test('joins a leading-slash path onto the base url', () {
        final uri = http.resolve('/get-session');
        expect(uri.toString(), equals('$_baseUrl/get-session'));
      });

      test('prepends a slash for a non-leading-slash path', () {
        final uri = http.resolve('get-session');
        expect(uri.toString(), equals('$_baseUrl/get-session'));
      });

      test('strips trailing slashes from the base url', () {
        final custom = build(baseUrl: Uri.parse('$_baseUrl///'));
        final uri = custom.resolve('/sign-in');
        expect(uri.toString(), equals('$_baseUrl/sign-in'));
      });

      test('does not append a query when query is null', () {
        final uri = http.resolve('/x');
        expect(uri.hasQuery, isFalse);
      });

      test('does not append a query when query is empty', () {
        final uri = http.resolve('/x', <String, dynamic>{});
        expect(uri.hasQuery, isFalse);
      });

      test('stringifies bool and int values and skips null values', () {
        final uri = http.resolve('/x', <String, dynamic>{
          'flag': true,
          'count': 3,
          'skip': null,
        });
        expect(uri.queryParameters['flag'], equals('true'));
        expect(uri.queryParameters['count'], equals('3'));
        expect(uri.queryParameters.containsKey('skip'), isFalse);
      });

      test('merges new params with existing query parameters in the path', () {
        final uri = http.resolve('/x?existing=1', <String, dynamic>{'a': 'b'});
        expect(uri.queryParameters['existing'], equals('1'));
        expect(uri.queryParameters['a'], equals('b'));
      });
    });

    group('request success', () {
      test('returns AuthSuccess with a decoded Map body on 200', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(200, <String, dynamic>{'ok': true}),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        expect(result, isA<AuthSuccess<Object?>>());
        expect(
          (result as AuthSuccess<Object?>).data,
          equals(<String, dynamic>{'ok': true}),
        );
      });

      test('returns AuthSuccess with a decoded List body on 200', () async {
        adapter.onGet(
          _url('/list'),
          (server) => server.reply(200, <dynamic>[1, 2, 3]),
        );

        final result = await http.request('/list', method: 'GET');

        expect(result, isA<AuthSuccess<Object?>>());
        expect((result as AuthSuccess<Object?>).data, equals([1, 2, 3]));
      });

      test('returns AuthSuccess with a null body on 204', () async {
        adapter.onPost(
          _url('/sign-out'),
          (server) => server.reply(204, null),
          data: Matchers.any,
        );

        final result = await http.request('/sign-out', method: 'POST');

        expect(result, isA<AuthSuccess<Object?>>());
        expect((result as AuthSuccess<Object?>).data, isNull);
      });

      test('forwards query parameters and request body', () async {
        adapter.onPost(
          _url('/echo?token=abc'),
          (server) => server.reply(200, <String, dynamic>{'received': true}),
          data: Matchers.any,
        );

        final result = await http.request(
          '/echo',
          method: 'POST',
          query: <String, dynamic>{'token': 'abc'},
          body: <String, dynamic>{'value': 1},
        );

        expect(result, isA<AuthSuccess<Object?>>());
      });
    });

    group('request error responses', () {
      test('maps a 400 to an AuthApiException with mapped code', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(400, <String, dynamic>{
            'message': 'Bad email',
            'code': 'INVALID_EMAIL',
          }),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, equals('Bad email'));
        expect(error.statusCode, equals(400));
        expect(error.code, equals(AuthErrorCode.invalidEmail));
        expect(error.rawCode, equals('INVALID_EMAIL'));
      });

      test('maps a 400 with extra fields into details', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(400, <String, dynamic>{
            'message': 'Bad',
            'code': 'INVALID_EMAIL',
            'field': 'email',
            'attempts': 2,
          }),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(
          error.details,
          equals(<String, Object?>{
            'field': 'email',
            'attempts': 2,
          }),
        );
      });

      test('parses a nested {error:{...}} body shape', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(400, <String, dynamic>{
            'error': <String, dynamic>{
              'message': 'Nested bad',
              'code': 'INVALID_PASSWORD',
              'hint': 'too short',
            },
          }),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, equals('Nested bad'));
        expect(error.code, equals(AuthErrorCode.invalidPassword));
        expect(error.details, equals(<String, Object?>{'hint': 'too short'}));
      });

      test('uses a String body as the message for _parseError', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(400, 'plain text error'),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, equals('plain text error'));
        expect(error.code, equals(AuthErrorCode.unknown));
        expect(error.rawCode, isNull);
        expect(error.details, isNull);
      });

      test(
        'falls back to a default message for an empty String body',
        () async {
          adapter.onPost(
            _url('/sign-in'),
            (server) => server.reply(400, ''),
            data: Matchers.any,
          );

          final result = await http.request('/sign-in', method: 'POST');

          final error = (result as AuthFailure<Object?>).error;
          expect(error, isA<AuthApiException>());
          expect(error.message, equals('Request failed with status 400.'));
        },
      );

      test('falls back to a default message for a null body', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.reply(400, null),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, equals('Request failed with status 400.'));
        expect(error.code, equals(AuthErrorCode.unknown));
      });

      test(
        'maps a 401 to AuthSessionMissingException and fires callback',
        () async {
          adapter.onGet(
            _url('/get-session'),
            (server) => server.reply(401, <String, dynamic>{'message': 'gone'}),
          );

          final result = await http.request('/get-session', method: 'GET');

          final error = (result as AuthFailure<Object?>).error;
          expect(error, isA<AuthSessionMissingException>());
          expect(error.message, equals('gone'));
          expect(unauthorizedCalls, equals(1));
        },
      );

      test('uses the default 401 message when none is supplied', () async {
        adapter.onGet(
          _url('/get-session'),
          (server) => server.reply(401, null),
        );

        final result = await http.request('/get-session', method: 'GET');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthSessionMissingException>());
        expect(error.message, equals('No active session.'));
      });

      test('does not throw when onUnauthorized is null on a 401', () async {
        final noCallback = build();
        adapter.onGet(
          _url('/get-session'),
          (server) => server.reply(401, null),
        );

        final result = await noCallback.request('/get-session', method: 'GET');

        expect(
          (result as AuthFailure<Object?>).error,
          isA<AuthSessionMissingException>(),
        );
      });
    });

    group('request dio exceptions', () {
      test('maps a 500 response to AuthRetryableFetchException', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: _url('/sign-in')),
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: _url('/sign-in')),
                statusCode: 500,
                data: <String, dynamic>{
                  'message': 'boom',
                  'code': 'UNEXPECTED_ERROR',
                },
              ),
            ),
          ),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthRetryableFetchException>());
        expect(error.statusCode, equals(500));
        expect(error.message, equals('boom'));
        expect(error.code, equals(AuthErrorCode.unexpectedError));
      });

      test('uses a default message for a 5xx with no message body', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.throws(
            503,
            DioException(
              requestOptions: RequestOptions(path: _url('/sign-in')),
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: _url('/sign-in')),
                statusCode: 503,
              ),
            ),
          ),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthRetryableFetchException>());
        expect(error.message, equals('Server error (503).'));
      });

      test(
        'maps a DioException with a 4xx response via _mapErrorResponse',
        () async {
          adapter.onPost(
            _url('/sign-in'),
            (server) => server.throws(
              400,
              DioException(
                requestOptions: RequestOptions(path: _url('/sign-in')),
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: _url('/sign-in')),
                  statusCode: 400,
                  data: <String, dynamic>{
                    'message': 'nope',
                    'code': 'INVALID_TOKEN',
                  },
                ),
              ),
            ),
            data: Matchers.any,
          );

          final result = await http.request('/sign-in', method: 'POST');

          final error = (result as AuthFailure<Object?>).error;
          expect(error, isA<AuthApiException>());
          expect(error.code, equals(AuthErrorCode.invalidToken));
        },
      );

      test('treats a response with a null statusCode as status 0', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: _url('/sign-in')),
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: _url('/sign-in')),
                data: <String, dynamic>{'message': 'weird'},
              ),
            ),
          ),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthApiException>());
        expect(error.statusCode, equals(0));
        expect(error.message, equals('weird'));
      });

      for (final type in const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      ]) {
        test(
          'maps $type (no response, null message) to '
          'AuthRetryableFetchException',
          () async {
            adapter.onPost(
              _url('/sign-in'),
              (server) => server.throws(
                0,
                DioException(
                  requestOptions: RequestOptions(path: _url('/sign-in')),
                  type: type,
                ),
              ),
              data: Matchers.any,
            );

            final result = await http.request('/sign-in', method: 'POST');

            final error = (result as AuthFailure<Object?>).error;
            expect(error, isA<AuthRetryableFetchException>());
            // The adapter drops the message, so the type name is used.
            expect(error.message, equals('Network error: ${type.name}'));
          },
        );
      }

      test('preserves the dio message when one is present', () async {
        final mockDio = _MockDio();
        when(() => mockDio.options).thenReturn(BaseOptions());
        when(() => mockDio.interceptors).thenReturn(Interceptors());
        when(
          () => mockDio.requestUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: _url('/sign-in')),
            type: DioExceptionType.connectionTimeout,
            message: 'down',
          ),
        );

        final custom = BetterAuthHttp(
          baseUrl: Uri.parse(_baseUrl),
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            autoRefresh: false,
          ),
          tokenStore: tokenStore,
          dio: mockDio,
        );

        final result = await custom.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthRetryableFetchException>());
        expect(error.message, equals('Network error: down'));
      });

      test('maps cancel (no response) to AuthUnknownException', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: _url('/sign-in')),
              type: DioExceptionType.cancel,
            ),
          ),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthUnknownException>());
        expect(error.message, equals('Request cancelled.'));
      });

      test(
        'maps badCertificate (no response) to AuthUnknownException',
        () async {
          adapter.onPost(
            _url('/sign-in'),
            (server) => server.throws(
              0,
              DioException(
                requestOptions: RequestOptions(path: _url('/sign-in')),
                type: DioExceptionType.badCertificate,
              ),
            ),
            data: Matchers.any,
          );

          final result = await http.request('/sign-in', method: 'POST');

          final error = (result as AuthFailure<Object?>).error;
          expect(error, isA<AuthUnknownException>());
          expect(error.message, equals('Bad certificate.'));
        },
      );

      test('maps badResponse (no response) to AuthUnknownException', () async {
        adapter.onPost(
          _url('/sign-in'),
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: _url('/sign-in')),
              type: DioExceptionType.badResponse,
            ),
          ),
          data: Matchers.any,
        );

        final result = await http.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthUnknownException>());
        expect(error.message, equals('Bad response.'));
      });
    });

    group('request non-dio errors', () {
      test('maps a thrown non-Dio error to AuthUnknownException', () async {
        final mockDio = _MockDio();
        when(() => mockDio.options).thenReturn(BaseOptions());
        when(() => mockDio.interceptors).thenReturn(Interceptors());
        when(
          () => mockDio.requestUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(_StateBoom());

        final custom = BetterAuthHttp(
          baseUrl: Uri.parse(_baseUrl),
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            autoRefresh: false,
          ),
          tokenStore: tokenStore,
          dio: mockDio,
        );

        final result = await custom.request('/sign-in', method: 'POST');

        final error = (result as AuthFailure<Object?>).error;
        expect(error, isA<AuthUnknownException>());
        expect(error.message, contains('Unexpected error:'));
        expect(
          (error as AuthUnknownException).originalError,
          isA<_StateBoom>(),
        );
      });
    });

    group('close', () {
      test('closes the underlying dio', () {
        final mockDio = _MockDio();
        when(() => mockDio.options).thenReturn(BaseOptions());
        when(() => mockDio.interceptors).thenReturn(Interceptors());
        when(() => mockDio.close(force: any(named: 'force'))).thenReturn(null);

        final custom = BetterAuthHttp(
          baseUrl: Uri.parse(_baseUrl),
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            autoRefresh: false,
          ),
          tokenStore: tokenStore,
          dio: mockDio,
        )..close();

        expect(custom.dio, same(mockDio));
        verify(() => mockDio.close(force: any(named: 'force'))).called(1);
      });
    });
  });

  group(TokenStore, () {
    late TokenStore store;

    setUp(() {
      store = TokenStore();
    });

    test('starts with no token', () {
      expect(store.token, isNull);
      expect(store.hasToken, isFalse);
    });

    test('hasToken is false for an empty token', () {
      store.token = '';
      expect(store.hasToken, isFalse);
    });

    test('hasToken is true for a non-empty token', () {
      store.token = 'abc';
      expect(store.hasToken, isTrue);
    });

    test('clear resets token and cookies', () {
      store.token = 'abc';
      store.cookies.storeFromSetCookie(['k=v']);
      store.clear();
      expect(store.token, isNull);
      expect(store.hasToken, isFalse);
      expect(store.cookies.isEmpty, isTrue);
    });

    test('adopts an injected cookie store', () {
      final cookies = CookieStore()..storeFromSetCookie(['k=v']);
      final custom = TokenStore(cookies: cookies);
      expect(custom.cookies, same(cookies));
      expect(custom.cookies.cookies['k'], equals('v'));
    });
  });
}

class _NoopInterceptor extends Interceptor {}

class _StateBoom implements Exception {
  @override
  String toString() => '_StateBoom';
}

class _MockDio extends Mock implements Dio {}

class _FakeUri extends Fake implements Uri {}

class _FakeOptions extends Fake implements Options {}
