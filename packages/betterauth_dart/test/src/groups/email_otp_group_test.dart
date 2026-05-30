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
  group(EmailOtpGroup, () {
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

    group('sendVerificationOtp', () {
      test('POSTs the wire type to /email-otp/send-verification-otp', () async {
        stubPost(
          adapter,
          '/email-otp/send-verification-otp',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.emailOtp.sendVerificationOtp(
          email: 'ada@example.com',
          type: EmailOtpType.signIn,
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(capture.last?.method, equals('POST'));
        expect(
          capture.last?.uri.path,
          equals('/api/auth/email-otp/send-verification-otp'),
        );
        expect(
          capture.last?.data,
          equals(<String, dynamic>{
            'email': 'ada@example.com',
            'type': 'sign-in',
          }),
        );
      });

      test(
        'returns AuthFailure with AuthApiException on a 400 error',
        () async {
          stubPost(
            adapter,
            '/email-otp/send-verification-otp',
            status: 400,
            body: <String, dynamic>{
              'message': 'Rate limited',
              'code': 'RATE_LIMITED',
            },
          );

          final result = await client.emailOtp.sendVerificationOtp(
            email: 'ada@example.com',
            type: EmailOtpType.emailVerification,
          );

          expect(result, isA<AuthFailure<StatusResponse>>());
          expect(
            (result as AuthFailure<StatusResponse>).error,
            isA<AuthApiException>(),
          );
        },
      );
    });

    group('verifyEmail', () {
      test('POSTs to /email-otp/verify-email with email and otp', () async {
        stubPost(
          adapter,
          '/email-otp/verify-email',
          body: <String, dynamic>{'status': true, 'user': userJson()},
        );

        final result = await client.emailOtp.verifyEmail(
          email: 'ada@example.com',
          otp: '123456',
        );

        expect(result, isA<AuthSuccess<EmailOtpVerifyResponse>>());
        final data = (result as AuthSuccess<EmailOtpVerifyResponse>).data;
        expect(data.ok, isTrue);
        expect(data.token, isNull);
        expect(data.user.email, equals('ada@example.com'));
        expect(capture.last?.method, equals('POST'));
        expect(
          capture.last?.uri.path,
          equals('/api/auth/email-otp/verify-email'),
        );
        expect(
          capture.last?.data,
          equals(<String, dynamic>{
            'email': 'ada@example.com',
            'otp': '123456',
          }),
        );
      });

      test('does not hydrate when no token is returned', () async {
        stubPost(
          adapter,
          '/email-otp/verify-email',
          body: <String, dynamic>{'status': true, 'user': userJson()},
        );

        final events = <AuthChangeEvent>[];
        final sub = client.onAuthStateChange.listen(
          (state) => events.add(state.event),
        );
        addTearDown(sub.cancel);

        final result = await client.emailOtp.verifyEmail(
          email: 'ada@example.com',
          otp: '123456',
        );
        await Future<void>.delayed(Duration.zero);

        expect(result, isA<AuthSuccess<EmailOtpVerifyResponse>>());
        expect(events, isEmpty);
        expect(client.currentSession, isNull);
      });

      test('hydrates and emits signedIn when a token is returned', () async {
        stubPost(
          adapter,
          '/email-otp/verify-email',
          body: <String, dynamic>{
            'status': true,
            'token': 'tok_otp',
            'user': userJson(),
          },
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

        final result = await client.emailOtp.verifyEmail(
          email: 'ada@example.com',
          otp: '123456',
        );
        await Future<void>.delayed(Duration.zero);

        expect(result, isA<AuthSuccess<EmailOtpVerifyResponse>>());
        final data = (result as AuthSuccess<EmailOtpVerifyResponse>).data;
        expect(data.token, equals('tok_otp'));
        expect(events, contains(AuthChangeEvent.signedIn));
        expect(client.currentToken, equals('tok_otp'));
        expect(client.currentSession, isNotNull);
      });

      test(
        'returns AuthFailure with AuthApiException on a 400 error',
        () async {
          stubPost(
            adapter,
            '/email-otp/verify-email',
            status: 400,
            body: <String, dynamic>{
              'message': 'Bad OTP',
              'code': 'INVALID_OTP',
            },
          );

          final result = await client.emailOtp.verifyEmail(
            email: 'ada@example.com',
            otp: '000000',
          );

          expect(result, isA<AuthFailure<EmailOtpVerifyResponse>>());
          expect(
            (result as AuthFailure<EmailOtpVerifyResponse>).error,
            isA<AuthApiException>(),
          );
          expect(client.currentSession, isNull);
        },
      );
    });

    group('requestPasswordReset', () {
      test('POSTs the email to /email-otp/request-password-reset', () async {
        stubPost(
          adapter,
          '/email-otp/request-password-reset',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.emailOtp.requestPasswordReset(
          email: 'ada@example.com',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(capture.last?.method, equals('POST'));
        expect(
          capture.last?.uri.path,
          equals('/api/auth/email-otp/request-password-reset'),
        );
        expect(
          capture.last?.data,
          equals(<String, dynamic>{'email': 'ada@example.com'}),
        );
      });
    });

    group('resetPassword', () {
      test(
        'POSTs email, otp and password to /email-otp/reset-password',
        () async {
          stubPost(
            adapter,
            '/email-otp/reset-password',
            body: <String, dynamic>{'status': true},
          );

          final result = await client.emailOtp.resetPassword(
            email: 'ada@example.com',
            otp: '123456',
            password: 'newpass',
          );

          expect(result, isA<AuthSuccess<StatusResponse>>());
          expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
          expect(capture.last?.method, equals('POST'));
          expect(
            capture.last?.uri.path,
            equals('/api/auth/email-otp/reset-password'),
          );
          expect(
            capture.last?.data,
            equals(<String, dynamic>{
              'email': 'ada@example.com',
              'otp': '123456',
              'password': 'newpass',
            }),
          );
        },
      );
    });

    group('checkVerificationOtp', () {
      test(
        'POSTs the wire type to /email-otp/check-verification-otp',
        () async {
          stubPost(
            adapter,
            '/email-otp/check-verification-otp',
            body: <String, dynamic>{'status': true},
          );

          final result = await client.emailOtp.checkVerificationOtp(
            email: 'ada@example.com',
            otp: '123456',
            type: EmailOtpType.forgetPassword,
          );

          expect(result, isA<AuthSuccess<StatusResponse>>());
          expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
          expect(capture.last?.method, equals('POST'));
          expect(
            capture.last?.uri.path,
            equals('/api/auth/email-otp/check-verification-otp'),
          );
          expect(
            capture.last?.data,
            equals(<String, dynamic>{
              'email': 'ada@example.com',
              'otp': '123456',
              'type': 'forget-password',
            }),
          );
        },
      );
    });
  });
}
