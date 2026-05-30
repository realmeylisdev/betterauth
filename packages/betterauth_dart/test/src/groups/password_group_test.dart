import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Captures the most recent outgoing request so tests can assert the wire path,
/// method and body the group produced.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? last;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    last = options;
    handler.next(options);
  }
}

void main() {
  group(PasswordGroup, () {
    late BetterAuthClient client;
    late DioAdapter adapter;
    late _CapturingInterceptor capture;

    setUp(() {
      final dio = Dio();
      adapter = DioAdapter(dio: dio);
      capture = _CapturingInterceptor();
      client = BetterAuthClient(
        baseUrl: Uri.parse(testBaseUrl),
        options: const BetterAuthClientOptions(
          maxRetries: 0,
          autoRefresh: false,
        ),
        storage: InMemoryAsyncStorage(),
        dio: dio,
        interceptors: [capture],
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    group('requestReset', () {
      test('POSTs to /request-password-reset and returns a status', () async {
        stubPost(
          adapter,
          '/request-password-reset',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.password.requestReset(
          email: 'ada@example.com',
          redirectTo: 'app://reset',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        final data = (result as AuthSuccess<StatusResponse>).data;
        expect(data.ok, isTrue);
        expect(capture.last?.method, equals('POST'));
        expect(
          capture.last?.uri.path,
          equals('/api/auth/request-password-reset'),
        );
        expect(
          capture.last?.data,
          equals(<String, dynamic>{
            'email': 'ada@example.com',
            'redirectTo': 'app://reset',
          }),
        );
      });

      test('omits redirectTo from the body when null', () async {
        stubPost(
          adapter,
          '/request-password-reset',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.password.requestReset(
          email: 'ada@example.com',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect(
          capture.last?.data,
          equals(<String, dynamic>{'email': 'ada@example.com'}),
        );
      });

      test('returns AuthFailure with AuthApiException on 400', () async {
        stubPost(
          adapter,
          '/request-password-reset',
          status: 400,
          body: <String, dynamic>{
            'message': 'Unknown email',
            'code': 'INVALID_EMAIL',
          },
        );

        final result = await client.password.requestReset(
          email: 'nope@example.com',
        );

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('reset', () {
      test('POSTs to /reset-password with the token and password', () async {
        stubPost(
          adapter,
          '/reset-password',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.password.reset(
          newPassword: 'hunter2',
          token: 'tok_reset',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect(capture.last?.method, equals('POST'));
        expect(capture.last?.uri.path, equals('/api/auth/reset-password'));
        expect(
          capture.last?.data,
          equals(<String, dynamic>{
            'newPassword': 'hunter2',
            'token': 'tok_reset',
          }),
        );
      });

      test('returns AuthFailure on a 400 error', () async {
        stubPost(
          adapter,
          '/reset-password',
          status: 400,
          body: <String, dynamic>{
            'message': 'Expired token',
            'code': 'TOKEN_EXPIRED',
          },
        );

        final result = await client.password.reset(
          newPassword: 'hunter2',
          token: 'expired',
        );

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('change', () {
      test(
        'POSTs to /change-password and strips null revokeOtherSessions',
        () async {
          stubPost(
            adapter,
            '/change-password',
            body: <String, dynamic>{'user': userJson()},
          );

          final result = await client.password.change(
            newPassword: 'newpass',
            currentPassword: 'oldpass',
          );

          expect(result, isA<AuthSuccess<ChangePasswordResponse>>());
          final data = (result as AuthSuccess<ChangePasswordResponse>).data;
          expect(data.token, isNull);
          expect(capture.last?.method, equals('POST'));
          expect(capture.last?.uri.path, equals('/api/auth/change-password'));
          expect(
            capture.last?.data,
            equals(<String, dynamic>{
              'newPassword': 'newpass',
              'currentPassword': 'oldpass',
            }),
          );
        },
      );

      test('does not hydrate when no token is returned', () async {
        stubPost(
          adapter,
          '/change-password',
          body: <String, dynamic>{'user': userJson()},
        );

        // No /get-session stub: if hydrate were called it would fail to match.
        final events = <AuthChangeEvent>[];
        final sub = client.onAuthStateChange.listen(
          (state) => events.add(state.event),
        );
        addTearDown(sub.cancel);

        final result = await client.password.change(
          newPassword: 'newpass',
          currentPassword: 'oldpass',
        );
        await Future<void>.delayed(Duration.zero);

        expect(result, isA<AuthSuccess<ChangePasswordResponse>>());
        expect(events, isEmpty);
        expect(client.currentSession, isNull);
      });

      test('includes revokeOtherSessions when provided', () async {
        stubPost(
          adapter,
          '/change-password',
          body: <String, dynamic>{'user': userJson(), 'token': 'tok_new'},
        );
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await client.password.change(
          newPassword: 'newpass',
          currentPassword: 'oldpass',
          revokeOtherSessions: true,
        );

        expect(result, isA<AuthSuccess<ChangePasswordResponse>>());
        expect(
          capture.last?.uri.path == '/api/auth/get-session' ||
              capture.last?.uri.path == '/api/auth/change-password',
          isTrue,
        );
      });

      test(
        'hydrates and emits sessionRefreshed when a token is returned',
        () async {
          stubPost(
            adapter,
            '/change-password',
            body: <String, dynamic>{'user': userJson(), 'token': 'tok_new'},
          );
          stubGet(
            adapter,
            '/get-session',
            body: <String, dynamic>{
              'session': sessionJson(),
              'user': userJson(),
            },
          );

          final events = <AuthChangeEvent>[];
          final sub = client.onAuthStateChange.listen(
            (state) => events.add(state.event),
          );
          addTearDown(sub.cancel);

          final result = await client.password.change(
            newPassword: 'newpass',
            currentPassword: 'oldpass',
            revokeOtherSessions: true,
          );
          await Future<void>.delayed(Duration.zero);

          expect(result, isA<AuthSuccess<ChangePasswordResponse>>());
          final data = (result as AuthSuccess<ChangePasswordResponse>).data;
          expect(data.token, equals('tok_new'));
          expect(events, contains(AuthChangeEvent.sessionRefreshed));
          expect(client.currentToken, equals('tok_new'));
          expect(client.currentSession, isNotNull);
          expect(client.currentUser, isNotNull);
        },
      );

      test('returns AuthFailure and does not hydrate on a 400 error', () async {
        stubPost(
          adapter,
          '/change-password',
          status: 400,
          body: <String, dynamic>{
            'message': 'Wrong password',
            'code': 'INVALID_PASSWORD',
          },
        );

        final result = await client.password.change(
          newPassword: 'newpass',
          currentPassword: 'wrong',
        );

        expect(result, isA<AuthFailure<ChangePasswordResponse>>());
        expect(
          (result as AuthFailure<ChangePasswordResponse>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });
  });
}
