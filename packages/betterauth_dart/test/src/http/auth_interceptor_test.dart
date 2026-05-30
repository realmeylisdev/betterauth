import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/constants.dart';
import 'package:betterauth_dart/src/http/auth_interceptor.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
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
  group(AuthInterceptor, () {
    late TokenStore tokenStore;

    setUpAll(() {
      registerFallbackValue(_FakeRequestOptions());
      registerFallbackValue(_FakeResponse());
      registerFallbackValue(_FakeDioException());
    });

    setUp(() {
      tokenStore = TokenStore();
    });

    group('onRequest', () {
      test(
        'attaches Authorization header in bearer mode when token present',
        () {
          tokenStore.token = 'abc';
          final interceptor = AuthInterceptor(
            tokenStore: tokenStore,
            transportMode: AuthTransportMode.bearer,
          );
          final options = RequestOptions(path: '/x');
          final handler = _MockRequestHandler();

          interceptor.onRequest(options, handler);

          expect(
            options.headers[kAuthorizationHeader],
            equals('${kBearerPrefix}abc'),
          );
          verify(() => handler.next(options)).called(1);
        },
      );

      test(
        'does not attach Authorization header in bearer mode when no token',
        () {
          final interceptor = AuthInterceptor(
            tokenStore: tokenStore,
            transportMode: AuthTransportMode.bearer,
          );
          final options = RequestOptions(path: '/x');
          final handler = _MockRequestHandler();

          interceptor.onRequest(options, handler);

          expect(options.headers.containsKey(kAuthorizationHeader), isFalse);
          verify(() => handler.next(options)).called(1);
        },
      );

      test(
        'does not attach Authorization header in cookie mode with token',
        () {
          tokenStore.token = 'abc';
          final interceptor = AuthInterceptor(
            tokenStore: tokenStore,
            transportMode: AuthTransportMode.cookie,
          );
          final options = RequestOptions(path: '/x');
          final handler = _MockRequestHandler();

          interceptor.onRequest(options, handler);

          expect(options.headers.containsKey(kAuthorizationHeader), isFalse);
          verify(() => handler.next(options)).called(1);
        },
      );

      test('attaches Cookie header when cookies present', () {
        tokenStore.cookies.storeFromSetCookie(['a=b']);
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.cookie,
        );
        final options = RequestOptions(path: '/x');
        final handler = _MockRequestHandler();

        interceptor.onRequest(options, handler);

        expect(options.headers[kCookieHeader], equals('a=b'));
        verify(() => handler.next(options)).called(1);
      });

      test('does not attach Cookie header when no cookies', () {
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final options = RequestOptions(path: '/x');
        final handler = _MockRequestHandler();

        interceptor.onRequest(options, handler);

        expect(options.headers.containsKey(kCookieHeader), isFalse);
        verify(() => handler.next(options)).called(1);
      });
    });

    group('onResponse', () {
      test('captures set-auth-token and Set-Cookie then calls next', () {
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          headers: Headers.fromMap({
            kSetAuthTokenHeader: ['t'],
            kSetCookieHeader: ['a=b'],
          }),
        );
        final handler = _MockResponseHandler();

        interceptor.onResponse(response, handler);

        expect(tokenStore.token, equals('t'));
        expect(tokenStore.cookies.cookies['a'], equals('b'));
        verify(() => handler.next(response)).called(1);
      });

      test('does not change token when set-auth-token absent', () {
        tokenStore.token = 'existing';
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          headers: Headers.fromMap({}),
        );
        final handler = _MockResponseHandler();

        interceptor.onResponse(response, handler);

        expect(tokenStore.token, equals('existing'));
        expect(tokenStore.cookies.isEmpty, isTrue);
        verify(() => handler.next(response)).called(1);
      });

      test('ignores empty set-auth-token value', () {
        tokenStore.token = 'existing';
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final response = Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          headers: Headers.fromMap({
            kSetAuthTokenHeader: [''],
          }),
        );
        final handler = _MockResponseHandler();

        interceptor.onResponse(response, handler);

        expect(tokenStore.token, equals('existing'));
        verify(() => handler.next(response)).called(1);
      });
    });

    group('onError', () {
      test('captures headers from error response then calls next', () {
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final requestOptions = RequestOptions(path: '/x');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            headers: Headers.fromMap({
              kSetAuthTokenHeader: ['t'],
              kSetCookieHeader: ['a=b'],
            }),
          ),
        );
        final handler = _MockErrorHandler();

        interceptor.onError(err, handler);

        expect(tokenStore.token, equals('t'));
        expect(tokenStore.cookies.cookies['a'], equals('b'));
        verify(() => handler.next(err)).called(1);
      });

      test('calls next without capturing when error has no response', () {
        final interceptor = AuthInterceptor(
          tokenStore: tokenStore,
          transportMode: AuthTransportMode.bearer,
        );
        final err = DioException(
          requestOptions: RequestOptions(path: '/x'),
        );
        final handler = _MockErrorHandler();

        interceptor.onError(err, handler);

        expect(tokenStore.token, isNull);
        expect(tokenStore.cookies.isEmpty, isTrue);
        verify(() => handler.next(err)).called(1);
      });
    });
  });
}
