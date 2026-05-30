import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Captures the most recent outgoing request so tests can assert the wire path,
/// method, query and body the group produced.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? last;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    last = options;
    handler.next(options);
  }
}

/// Registers a GET stub matching `/verify-email` regardless of the query string
/// it carries (the helper [stubGet] only matches a query-less URL).
void stubVerifyEmail(
  DioAdapter adapter, {
  int status = 200,
  Object? body,
}) {
  adapter.onGet(
    RegExp('verify-email'),
    (server) => server.reply(status, body),
  );
}

void main() {
  group(EmailVerificationGroup, () {
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

    group('send', () {
      test(
        'POSTs to /send-verification-email with email and callbackURL',
        () async {
          stubPost(
            adapter,
            '/send-verification-email',
            body: <String, dynamic>{'status': true},
          );

          final result = await client.emailVerification.send(
            email: 'ada@example.com',
            callbackURL: 'app://verified',
          );

          expect(result, isA<AuthSuccess<StatusResponse>>());
          expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
          expect(capture.last?.method, equals('POST'));
          expect(
            capture.last?.uri.path,
            equals('/api/auth/send-verification-email'),
          );
          expect(
            capture.last?.data,
            equals(<String, dynamic>{
              'email': 'ada@example.com',
              'callbackURL': 'app://verified',
            }),
          );
        },
      );

      test('omits callbackURL from the body when null', () async {
        stubPost(
          adapter,
          '/send-verification-email',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.emailVerification.send(
          email: 'ada@example.com',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect(
          capture.last?.data,
          equals(<String, dynamic>{'email': 'ada@example.com'}),
        );
      });

      test(
        'returns AuthFailure with AuthApiException on a 400 error',
        () async {
          stubPost(
            adapter,
            '/send-verification-email',
            status: 400,
            body: <String, dynamic>{
              'message': 'Already verified',
              'code': 'ALREADY_VERIFIED',
            },
          );

          final result = await client.emailVerification.send(
            email: 'ada@example.com',
          );

          expect(result, isA<AuthFailure<StatusResponse>>());
          expect(
            (result as AuthFailure<StatusResponse>).error,
            isA<AuthApiException>(),
          );
        },
      );
    });

    group('verify', () {
      test(
        'GETs /verify-email with the token query and parses the user',
        () async {
          stubVerifyEmail(
            adapter,
            body: <String, dynamic>{'status': true, 'user': userJson()},
          );

          final result = await client.emailVerification.verify(
            token: 'tok_verify',
          );

          expect(result, isA<AuthSuccess<VerifyEmailResponse>>());
          final data = (result as AuthSuccess<VerifyEmailResponse>).data;
          expect(data.ok, isTrue);
          expect(data.user, isNotNull);
          expect(data.user!.email, equals('ada@example.com'));
          expect(capture.last?.method, equals('GET'));
          expect(capture.last?.uri.path, equals('/api/auth/verify-email'));
          expect(
            capture.last?.uri.queryParameters['token'],
            equals('tok_verify'),
          );
          expect(
            capture.last?.uri.queryParameters.containsKey('callbackURL'),
            isFalse,
          );
        },
      );

      test('parses a response without a user', () async {
        stubVerifyEmail(
          adapter,
          body: <String, dynamic>{'status': true},
        );

        final result = await client.emailVerification.verify(token: 'tok');

        expect(result, isA<AuthSuccess<VerifyEmailResponse>>());
        final data = (result as AuthSuccess<VerifyEmailResponse>).data;
        expect(data.ok, isTrue);
        expect(data.user, isNull);
      });

      test('includes callbackURL in the query when provided', () async {
        stubVerifyEmail(
          adapter,
          body: <String, dynamic>{'status': true},
        );

        final result = await client.emailVerification.verify(
          token: 'tok',
          callbackURL: 'app://done',
        );

        expect(result, isA<AuthSuccess<VerifyEmailResponse>>());
        expect(
          capture.last?.uri.queryParameters['callbackURL'],
          equals('app://done'),
        );
        expect(capture.last?.uri.queryParameters['token'], equals('tok'));
      });

      test(
        'returns AuthFailure with AuthApiException on a 400 error',
        () async {
          stubVerifyEmail(
            adapter,
            status: 400,
            body: <String, dynamic>{
              'message': 'Invalid token',
              'code': 'INVALID_TOKEN',
            },
          );

          final result = await client.emailVerification.verify(token: 'bad');

          expect(result, isA<AuthFailure<VerifyEmailResponse>>());
          expect(
            (result as AuthFailure<VerifyEmailResponse>).error,
            isA<AuthApiException>(),
          );
        },
      );
    });
  });
}
