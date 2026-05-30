import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Captures the body of the last outgoing request so tests can assert on the
/// optional-field stripping behaviour.
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
  group(TwoFactorGroup, () {
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

    group('enable', () {
      test('returns the TOTP URI and backup codes', () async {
        stubPost(
          adapter,
          '/two-factor/enable',
          body: <String, dynamic>{
            'totpURI': 'otpauth://totp/x',
            'backupCodes': <String>['a', 'b'],
          },
        );

        final result = await client.twoFactor.enable(password: 'pw');

        expect(result, isA<AuthSuccess<TwoFactorEnableResponse>>());
        final data = (result as AuthSuccess<TwoFactorEnableResponse>).data;
        expect(data.totpUri, equals('otpauth://totp/x'));
        expect(data.backupCodes, equals(<String>['a', 'b']));
        expect(recorder.lastBody!.containsKey('issuer'), isFalse);
      });

      test('includes issuer when provided', () async {
        stubPost(
          adapter,
          '/two-factor/enable',
          body: <String, dynamic>{'totpURI': 'otpauth://totp/x'},
        );

        final result = await client.twoFactor.enable(
          password: 'pw',
          issuer: 'Acme',
        );

        expect(result, isA<AuthSuccess<TwoFactorEnableResponse>>());
        expect(recorder.lastBody!['issuer'], equals('Acme'));
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/two-factor/enable',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.twoFactor.enable(password: 'pw');

        expect(
          (result as AuthFailure<TwoFactorEnableResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('disable', () {
      test('returns a StatusResponse', () async {
        stubPost(
          adapter,
          '/two-factor/disable',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.twoFactor.disable(password: 'pw');

        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/two-factor/disable',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.twoFactor.disable(password: 'pw');

        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('getTotpUri', () {
      test('returns the TOTP URI', () async {
        stubPost(
          adapter,
          '/two-factor/get-totp-uri',
          body: <String, dynamic>{'totpURI': 'otpauth://totp/y'},
        );

        final result = await client.twoFactor.getTotpUri(password: 'pw');

        expect(
          (result as AuthSuccess<TotpUriResponse>).data.totpUri,
          equals('otpauth://totp/y'),
        );
      });

      test('returns AuthUnknownException on a malformed body', () async {
        stubPost(
          adapter,
          '/two-factor/get-totp-uri',
          body: <String, dynamic>{'wrong': true},
        );

        final result = await client.twoFactor.getTotpUri(password: 'pw');

        expect(
          (result as AuthFailure<TotpUriResponse>).error,
          isA<AuthUnknownException>(),
        );
      });
    });

    group('verifyTotp', () {
      test('adopts the session and hydrates on success', () async {
        stubPost(
          adapter,
          '/two-factor/verify-totp',
          body: <String, dynamic>{
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

        final result = await client.twoFactor.verifyTotp(code: '123456');

        expect(result, isA<AuthSuccess<AuthSession>>());
        expect(
          (result as AuthSuccess<AuthSession>).data.token,
          equals('tok_123'),
        );
        expect(client.currentSession, isNotNull);
        expect(client.currentToken, equals('tok_123'));
        expect(recorder.lastBody!.containsKey('trustDevice'), isFalse);
      });

      test('includes trustDevice when provided', () async {
        stubPost(
          adapter,
          '/two-factor/verify-totp',
          body: <String, dynamic>{'token': 'tok_123', 'user': userJson()},
        );
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await client.twoFactor.verifyTotp(
          code: '123456',
          trustDevice: true,
        );

        expect(result, isA<AuthSuccess<AuthSession>>());
        expect(recorder.lastBody!['trustDevice'], isTrue);
      });

      test(
        'returns AuthApiException on failure and adopts no session',
        () async {
          stubPost(
            adapter,
            '/two-factor/verify-totp',
            status: 400,
            body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
          );

          final result = await client.twoFactor.verifyTotp(code: 'bad');

          expect(
            (result as AuthFailure<AuthSession>).error,
            isA<AuthApiException>(),
          );
          expect(client.currentSession, isNull);
        },
      );

      test('signs out locally when /get-session resolves to null', () async {
        stubPost(
          adapter,
          '/two-factor/verify-totp',
          body: <String, dynamic>{'token': 'tok_123', 'user': userJson()},
        );
        // The session re-fetch returns a literal null body, so hydrate signs
        // the client out locally.
        stubGet(adapter, '/get-session');

        final events = <AuthChangeEvent>[];
        final sub = client.onAuthStateChange.listen((s) => events.add(s.event));

        final result = await client.twoFactor.verifyTotp(code: '123456');
        await pumpEventQueue();

        expect(result, isA<AuthSuccess<AuthSession>>());
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
        expect(events, contains(AuthChangeEvent.signedOut));
        await sub.cancel();
      });
    });

    group('sendOtp', () {
      test('returns a StatusResponse', () async {
        stubPost(
          adapter,
          '/two-factor/send-otp',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.twoFactor.sendOtp();

        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(recorder.lastBody!.containsKey('trustDevice'), isFalse);
      });

      test('includes trustDevice when provided', () async {
        stubPost(
          adapter,
          '/two-factor/send-otp',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.twoFactor.sendOtp(trustDevice: true);

        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(recorder.lastBody!['trustDevice'], isTrue);
      });
    });

    group('verifyOtp', () {
      test('adopts the session and hydrates on success', () async {
        stubPost(
          adapter,
          '/two-factor/verify-otp',
          body: <String, dynamic>{
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

        final result = await client.twoFactor.verifyOtp(code: '123456');

        expect(result, isA<AuthSuccess<AuthSession>>());
        expect(client.currentSession, isNotNull);
        expect(client.currentToken, equals('tok_123'));
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/two-factor/verify-otp',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.twoFactor.verifyOtp(code: 'bad');

        expect(
          (result as AuthFailure<AuthSession>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });

    group('generateBackupCodes', () {
      test('returns the regenerated backup codes', () async {
        stubPost(
          adapter,
          '/two-factor/generate-backup-codes',
          body: <String, dynamic>{
            'status': true,
            'backupCodes': <String>['x', 'y', 'z'],
          },
        );

        final result = await client.twoFactor.generateBackupCodes(
          password: 'pw',
        );

        final data = (result as AuthSuccess<BackupCodesResponse>).data;
        expect(data.ok, isTrue);
        expect(data.backupCodes, equals(<String>['x', 'y', 'z']));
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/two-factor/generate-backup-codes',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.twoFactor.generateBackupCodes(
          password: 'pw',
        );

        expect(
          (result as AuthFailure<BackupCodesResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('verifyBackupCode', () {
      test('adopts the session when one is present', () async {
        stubPost(
          adapter,
          '/two-factor/verify-backup-code',
          body: <String, dynamic>{
            'user': userJson(),
            'session': sessionJson(),
          },
        );

        final events = <AuthChangeEvent>[];
        final sub = client.onAuthStateChange.listen((s) => events.add(s.event));

        final result = await client.twoFactor.verifyBackupCode(code: 'bc');
        await pumpEventQueue();

        expect(result, isA<AuthSuccess<VerifyBackupCodeResponse>>());
        expect(client.currentSession, isNotNull);
        expect(client.currentToken, equals('tok_123'));
        expect(events, contains(AuthChangeEvent.signedIn));
        expect(recorder.lastBody!.containsKey('disableSession'), isFalse);
        expect(recorder.lastBody!.containsKey('trustDevice'), isFalse);
        await sub.cancel();
      });

      test('does not adopt a session when none is returned', () async {
        stubPost(
          adapter,
          '/two-factor/verify-backup-code',
          body: <String, dynamic>{'user': userJson()},
        );

        final result = await client.twoFactor.verifyBackupCode(
          code: 'bc',
          disableSession: true,
          trustDevice: true,
        );

        expect(result, isA<AuthSuccess<VerifyBackupCodeResponse>>());
        expect(
          (result as AuthSuccess<VerifyBackupCodeResponse>).data.session,
          isNull,
        );
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
        expect(recorder.lastBody!['disableSession'], isTrue);
        expect(recorder.lastBody!['trustDevice'], isTrue);
      });

      test('returns AuthApiException on failure', () async {
        stubPost(
          adapter,
          '/two-factor/verify-backup-code',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.twoFactor.verifyBackupCode(code: 'bad');

        expect(
          (result as AuthFailure<VerifyBackupCodeResponse>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });
  });
}
