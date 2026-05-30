import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Captures the body of the last outgoing request so tests can assert on the
/// exact wire field names.
class _Recorder extends Interceptor {
  Map<String, dynamic>? lastBody;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final data = options.data;
    if (data is Map) {
      lastBody = Map<String, dynamic>.from(data);
    }
    handler.next(options);
  }
}

void main() {
  group(PhoneNumberGroup, () {
    late BetterAuthClient client;
    late DioAdapter adapter;
    late _Recorder recorder;

    setUp(() {
      final dio = Dio();
      adapter = DioAdapter(dio: dio);
      recorder = _Recorder();
      client = BetterAuthClient(
        baseUrl: Uri.parse(testBaseUrl),
        options: const BetterAuthClientOptions(
          maxRetries: 0,
          autoRefresh: false,
        ),
        storage: InMemoryAsyncStorage(),
        dio: dio,
        interceptors: [recorder],
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    group('sendOtp', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          adapter,
          '/phone-number/send-otp',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.phoneNumber.sendOtp(phoneNumber: '+1555');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/phone-number/send-otp',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.phoneNumber.sendOtp(phoneNumber: '+1555');

        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('verify', () {
      test('hydrates when a token is returned', () async {
        stubPost(
          adapter,
          '/phone-number/verify',
          body: <String, dynamic>{
            'status': true,
            'token': 'tok_123',
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

        final result = await client.phoneNumber.verify(
          phoneNumber: '+1555',
          code: '000000',
        );

        expect(result, isA<AuthSuccess<PhoneVerifyResponse>>());
        expect(
          (result as AuthSuccess<PhoneVerifyResponse>).data.token,
          equals('tok_123'),
        );
        expect(client.currentToken, equals('tok_123'));
        expect(client.currentSession, isNotNull);
        expect(client.isAuthenticated, isTrue);
      });

      test('does not hydrate when no token is returned', () async {
        stubPost(
          adapter,
          '/phone-number/verify',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.phoneNumber.verify(
          phoneNumber: '+1555',
          code: '000000',
          disableSession: true,
        );

        expect(result, isA<AuthSuccess<PhoneVerifyResponse>>());
        expect((result as AuthSuccess<PhoneVerifyResponse>).data.token, isNull);
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
      });

      test('includes optional flags when provided', () async {
        stubPost(
          adapter,
          '/phone-number/verify',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.phoneNumber.verify(
          phoneNumber: '+1555',
          code: '000000',
          updatePhoneNumber: true,
          disableSession: false,
        );

        expect(result, isA<AuthSuccess<PhoneVerifyResponse>>());
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/phone-number/verify',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.phoneNumber.verify(
          phoneNumber: '+1555',
          code: 'bad',
        );

        expect(
          (result as AuthFailure<PhoneVerifyResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('requestPasswordReset', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          adapter,
          '/phone-number/request-password-reset',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.phoneNumber.requestPasswordReset(
          phoneNumber: '+1555',
        );

        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/phone-number/request-password-reset',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.phoneNumber.requestPasswordReset(
          phoneNumber: '+1555',
        );

        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('resetPassword', () {
      test('sends otp and newPassword field names', () async {
        stubPost(
          adapter,
          '/phone-number/reset-password',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.phoneNumber.resetPassword(
          phoneNumber: '+1555',
          otp: '999999',
          newPassword: 'secret123',
        );

        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        final body = recorder.lastBody!;
        expect(body['phoneNumber'], equals('+1555'));
        expect(body['otp'], equals('999999'));
        expect(body['newPassword'], equals('secret123'));
        expect(body.containsKey('code'), isFalse);
        expect(body.containsKey('password'), isFalse);
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/phone-number/reset-password',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.phoneNumber.resetPassword(
          phoneNumber: '+1555',
          otp: 'bad',
          newPassword: 'secret123',
        );

        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
