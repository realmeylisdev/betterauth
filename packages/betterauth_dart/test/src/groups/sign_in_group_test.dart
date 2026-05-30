import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// A test client that records the body of the last outgoing request.
typedef _CapturingClient = ({
  BetterAuthClient client,
  DioAdapter adapter,
  Map<String, dynamic> Function() lastBody,
});

/// Builds a client wired to a mock adapter plus an interceptor that records the
/// most recent request body, so tests can assert what was sent on the wire.
_CapturingClient _buildCapturingClient() {
  Object? captured;
  final dio = Dio();
  final adapter = DioAdapter(dio: dio);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Only record requests that carry a body so a follow-up GET
        // (e.g. /get-session during hydrate) does not clobber the capture.
        if (options.data != null) captured = options.data;
        handler.next(options);
      },
    ),
  );
  final client = BetterAuthClient(
    baseUrl: Uri.parse(testBaseUrl),
    options: const BetterAuthClientOptions(maxRetries: 0, autoRefresh: false),
    storage: InMemoryAsyncStorage(),
    dio: dio,
  );
  Map<String, dynamic> lastBody() => captured! as Map<String, dynamic>;
  return (client: client, adapter: adapter, lastBody: lastBody);
}

void main() {
  group(SignInGroup, () {
    late BetterAuthClient client;
    late DioAdapter adapter;

    setUp(() {
      final test = buildTestClient();
      client = test.client;
      adapter = test.adapter;
    });

    void stubSession(DioAdapter target) {
      stubGet(
        target,
        '/get-session',
        body: <String, dynamic>{
          'session': sessionJson(),
          'user': userJson(),
        },
      );
    }

    group('email', () {
      test('signs in and hydrates on a SignedIn response', () async {
        stubPost(
          adapter,
          '/sign-in/email',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(adapter);

        final result = await client.signIn.email(
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthSuccess<SignInResponse>>());
        final data = (result as AuthSuccess<SignInResponse>).data;
        expect(data, isA<SignedIn>());
        expect((data as SignedIn).token, equals('tok'));
        expect(client.currentSession, isNotNull);
        expect(client.isAuthenticated, isTrue);
      });

      test('returns a TwoFactorRequired challenge without hydrating', () async {
        stubPost(
          adapter,
          '/sign-in/email',
          body: <String, dynamic>{
            'twoFactorRedirect': true,
            'twoFactorMethods': ['totp', 'otp'],
          },
        );

        final result = await client.signIn.email(
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthSuccess<SignInResponse>>());
        final data = (result as AuthSuccess<SignInResponse>).data;
        expect(data, isA<TwoFactorRequired>());
        expect((data as TwoFactorRequired).methods, equals(['totp', 'otp']));
        expect(client.currentSession, isNull);
        expect(client.isAuthenticated, isFalse);
      });

      test('sends rememberMe and callbackURL in the body', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/email',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(capturing.adapter);

        await capturing.client.signIn.email(
          email: 'ada@example.com',
          password: 'pw',
          rememberMe: false,
          callbackURL: 'https://cb',
        );

        final body = capturing.lastBody();
        expect(body['rememberMe'], isFalse);
        expect(body['callbackURL'], equals('https://cb'));
      });

      test('returns AuthFailure on invalid credentials', () async {
        stubPost(
          adapter,
          '/sign-in/email',
          status: 400,
          body: <String, dynamic>{
            'message': 'Invalid credentials',
            'code': 'INVALID_EMAIL_OR_PASSWORD',
          },
        );

        final result = await client.signIn.email(
          email: 'ada@example.com',
          password: 'x',
        );

        expect(result, isA<AuthFailure<SignInResponse>>());
        expect(
          (result as AuthFailure<SignInResponse>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });

    group('username', () {
      test('signs in and hydrates on a SignedIn response', () async {
        stubPost(
          adapter,
          '/sign-in/username',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(adapter);

        final result = await client.signIn.username(
          username: 'ada',
          password: 'pw',
        );

        expect(result, isA<AuthSuccess<SignInResponse>>());
        expect(
          (result as AuthSuccess<SignInResponse>).data,
          isA<SignedIn>(),
        );
        expect(client.currentSession, isNotNull);
      });

      test(
        'returns a TwoFactorRequired challenge with default methods',
        () async {
          stubPost(
            adapter,
            '/sign-in/username',
            body: <String, dynamic>{'twoFactorRedirect': true},
          );

          final result = await client.signIn.username(
            username: 'ada',
            password: 'pw',
          );

          final data = (result as AuthSuccess<SignInResponse>).data;
          expect(data, isA<TwoFactorRequired>());
          expect((data as TwoFactorRequired).methods, isEmpty);
          expect(client.currentSession, isNull);
        },
      );

      test('sends rememberMe and callbackURL in the body', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/username',
          body: <String, dynamic>{'twoFactorRedirect': true},
        );

        await capturing.client.signIn.username(
          username: 'ada',
          password: 'pw',
          rememberMe: false,
          callbackURL: 'https://cb',
        );

        final body = capturing.lastBody();
        expect(body['username'], equals('ada'));
        expect(body['rememberMe'], isFalse);
        expect(body['callbackURL'], equals('https://cb'));
      });

      test('returns AuthFailure on a 400', () async {
        stubPost(
          adapter,
          '/sign-in/username',
          status: 400,
          body: <String, dynamic>{'message': 'nope', 'code': 'X'},
        );

        final result = await client.signIn.username(
          username: 'ada',
          password: 'pw',
        );

        expect(result, isA<AuthFailure<SignInResponse>>());
      });
    });

    group('phoneNumber', () {
      test('signs in and hydrates on a SignedIn response', () async {
        stubPost(
          adapter,
          '/sign-in/phone-number',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(adapter);

        final result = await client.signIn.phoneNumber(
          phoneNumber: '+15551234567',
          password: 'pw',
        );

        expect(
          (result as AuthSuccess<SignInResponse>).data,
          isA<SignedIn>(),
        );
        expect(client.currentSession, isNotNull);
      });

      test('returns a TwoFactorRequired challenge', () async {
        stubPost(
          adapter,
          '/sign-in/phone-number',
          body: <String, dynamic>{'twoFactorRedirect': true},
        );

        final result = await client.signIn.phoneNumber(
          phoneNumber: '+15551234567',
          password: 'pw',
        );

        expect(
          (result as AuthSuccess<SignInResponse>).data,
          isA<TwoFactorRequired>(),
        );
        expect(client.currentSession, isNull);
      });

      test('sends the phone number and password in the body', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/phone-number',
          body: <String, dynamic>{'twoFactorRedirect': true},
        );

        await capturing.client.signIn.phoneNumber(
          phoneNumber: '+15551234567',
          password: 'pw',
          rememberMe: false,
        );

        final body = capturing.lastBody();
        expect(body['phoneNumber'], equals('+15551234567'));
        expect(body['password'], equals('pw'));
        expect(body['rememberMe'], isFalse);
      });

      test('returns AuthFailure on a 500 retryable error', () async {
        stubPost(adapter, '/sign-in/phone-number', status: 500);

        final result = await client.signIn.phoneNumber(
          phoneNumber: '+15551234567',
          password: 'pw',
        );

        expect(result, isA<AuthFailure<SignInResponse>>());
        expect(
          (result as AuthFailure<SignInResponse>).error,
          isA<AuthRetryableFetchException>(),
        );
      });
    });

    group('social', () {
      test('hydrates on a SocialSignedIn response with an id token', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/social',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(capturing.adapter);

        final result = await capturing.client.signIn.social(
          provider: 'google',
          idToken: const IdToken(token: 'jwt', nonce: 'n'),
          callbackURL: 'https://cb',
          scopes: const ['email'],
          requestSignUp: true,
          loginHint: 'ada@example.com',
        );

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        final data = (result as AuthSuccess<SocialSignInResponse>).data;
        expect(data, isA<SocialSignedIn>());
        expect((data as SocialSignedIn).token, equals('tok'));
        expect(capturing.client.currentSession, isNotNull);

        final body = capturing.lastBody();
        expect(body['provider'], equals('google'));
        expect(
          body['idToken'],
          equals(<String, dynamic>{'token': 'jwt', 'nonce': 'n'}),
        );
        expect(body['scopes'], equals(['email']));
        expect(body['requestSignUp'], isTrue);
        expect(body['loginHint'], equals('ada@example.com'));
      });

      test('returns a SocialRedirect without creating a session', () async {
        stubPost(
          adapter,
          '/sign-in/social',
          body: <String, dynamic>{
            'redirect': true,
            'url': 'https://provider/authorize',
          },
        );

        final result = await client.signIn.social(
          provider: 'google',
          newUserCallbackURL: 'https://new',
          errorCallbackURL: 'https://err',
          disableRedirect: true,
        );

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        final data = (result as AuthSuccess<SocialSignInResponse>).data;
        expect(data, isA<SocialRedirect>());
        expect(
          (data as SocialRedirect).url,
          equals('https://provider/authorize'),
        );
        expect(client.currentSession, isNull);
      });

      test('omits idToken when none is provided', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/social',
          body: <String, dynamic>{
            'redirect': true,
            'url': 'https://provider/authorize',
          },
        );

        await capturing.client.signIn.social(provider: 'github');

        final body = capturing.lastBody();
        expect(body.containsKey('idToken'), isFalse);
        expect(body['provider'], equals('github'));
      });

      test('returns AuthFailure on a 400', () async {
        stubPost(
          adapter,
          '/sign-in/social',
          status: 400,
          body: <String, dynamic>{'message': 'bad provider', 'code': 'X'},
        );

        final result = await client.signIn.social(provider: 'google');

        expect(result, isA<AuthFailure<SocialSignInResponse>>());
      });
    });

    group('emailOtp', () {
      test('signs in and hydrates on success', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/email-otp',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(capturing.adapter);

        final result = await capturing.client.signIn.emailOtp(
          email: 'ada@example.com',
          otp: '123456',
          name: 'Ada',
          image: 'https://img',
        );

        expect(result, isA<AuthSuccess<AuthSession>>());
        final data = (result as AuthSuccess<AuthSession>).data;
        expect(data.token, equals('tok'));
        expect(capturing.client.currentSession, isNotNull);

        final body = capturing.lastBody();
        expect(body['email'], equals('ada@example.com'));
        expect(body['otp'], equals('123456'));
        expect(body['name'], equals('Ada'));
        expect(body['image'], equals('https://img'));
      });

      test('returns AuthFailure on an invalid OTP', () async {
        stubPost(
          adapter,
          '/sign-in/email-otp',
          status: 400,
          body: <String, dynamic>{'message': 'invalid otp', 'code': 'X'},
        );

        final result = await client.signIn.emailOtp(
          email: 'ada@example.com',
          otp: '000000',
        );

        expect(result, isA<AuthFailure<AuthSession>>());
        expect(client.currentSession, isNull);
      });
    });

    group('magicLink', () {
      test('returns a StatusResponse without hydrating', () async {
        stubPost(
          adapter,
          '/sign-in/magic-link',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.signIn.magicLink(
          email: 'ada@example.com',
          name: 'Ada',
          callbackURL: 'https://cb',
          newUserCallbackURL: 'https://new',
          errorCallbackURL: 'https://err',
          metadata: <String, dynamic>{'k': 'v'},
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(client.currentSession, isNull);
      });

      test('returns AuthFailure on a 400', () async {
        stubPost(
          adapter,
          '/sign-in/magic-link',
          status: 400,
          body: <String, dynamic>{'message': 'no magic-link plugin'},
        );

        final result = await client.signIn.magicLink(email: 'ada@example.com');

        expect(result, isA<AuthFailure<StatusResponse>>());
      });
    });

    group('anonymous', () {
      test('signs in and the client adopts the session', () async {
        stubPost(
          adapter,
          '/sign-in/anonymous',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(adapter);

        final result = await client.signIn.anonymous();

        expect(result, isA<AuthSuccess<AuthSession>>());
        final data = (result as AuthSuccess<AuthSession>).data;
        expect(data.token, equals('tok'));
        expect(client.currentSession, isNotNull);
        expect(client.isAuthenticated, isTrue);
      });

      test('returns AuthFailure on a 400', () async {
        stubPost(
          adapter,
          '/sign-in/anonymous',
          status: 400,
          body: <String, dynamic>{
            'message': 'no anonymous plugin',
            'code': 'X',
          },
        );

        final result = await client.signIn.anonymous();

        expect(result, isA<AuthFailure<AuthSession>>());
        expect(
          (result as AuthFailure<AuthSession>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });

    group('passkey', () {
      test('signs in and hydrates on success', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-in/passkey',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubSession(capturing.adapter);

        final result = await capturing.client.signIn.passkey(
          response: <String, dynamic>{'id': 'cred', 'rawId': 'raw'},
        );

        expect(result, isA<AuthSuccess<AuthSession>>());
        final data = (result as AuthSuccess<AuthSession>).data;
        expect(data.token, equals('tok'));
        expect(capturing.client.currentSession, isNotNull);

        final body = capturing.lastBody();
        expect(body['id'], equals('cred'));
        expect(body['rawId'], equals('raw'));
      });

      test('returns AuthFailure on a 400', () async {
        stubPost(
          adapter,
          '/sign-in/passkey',
          status: 400,
          body: <String, dynamic>{'message': 'bad assertion', 'code': 'X'},
        );

        final result = await client.signIn.passkey(
          response: <String, dynamic>{'id': 'cred'},
        );

        expect(result, isA<AuthFailure<AuthSession>>());
        expect(
          (result as AuthFailure<AuthSession>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
      });
    });

    group('decode error branches', () {
      test(
        'returns AuthUnknownException when the body is not a JSON object',
        () async {
          stubPost(
            adapter,
            '/sign-in/email',
            body: const ['not', 'an', 'object'],
          );

          final result = await client.signIn.email(
            email: 'ada@example.com',
            password: 'pw',
          );

          expect(result, isA<AuthFailure<SignInResponse>>());
          final error = (result as AuthFailure<SignInResponse>).error;
          expect(error, isA<AuthUnknownException>());
          expect(error.message, equals('Expected a JSON object response.'));
        },
      );

      test('returns AuthUnknownException when fromJson throws', () async {
        // A SignedIn response whose user has no createdAt -> parseRequiredDate
        // throws inside User.fromJson, surfaced as AuthUnknownException.
        stubPost(
          adapter,
          '/sign-in/email',
          body: <String, dynamic>{
            'token': 'tok',
            'user': <String, dynamic>{'id': 'u1'},
          },
        );

        final result = await client.signIn.email(
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthFailure<SignInResponse>>());
        final error = (result as AuthFailure<SignInResponse>).error;
        expect(error, isA<AuthUnknownException>());
        expect(error.message, startsWith('Failed to parse response:'));
        expect(client.currentSession, isNull);
      });
    });
  });

  // Exercises the shared decode helpers on BetterAuthGroup that the sign-in
  // and sign-up flows do not reach (decodeNullableObject error/parse branches,
  // decodeList, and the decodeStatus non-map success branch), driven through
  // the session group which subclasses BetterAuthGroup.
  group('BetterAuthGroup decode helpers', () {
    late BetterAuthClient client;
    late DioAdapter adapter;

    setUp(() {
      final test = buildTestClient();
      client = test.client;
      adapter = test.adapter;
    });

    group('decodeNullableObject (via session.get)', () {
      test('returns a SessionResponse on a JSON object body', () async {
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await client.session.get();

        expect(result, isA<AuthSuccess<SessionResponse?>>());
        expect(
          (result as AuthSuccess<SessionResponse?>).data,
          isA<SessionResponse>(),
        );
      });

      test('returns null success on a literal null body', () async {
        stubGet(adapter, '/get-session');

        final result = await client.session.get();

        expect(result, isA<AuthSuccess<SessionResponse?>>());
        expect((result as AuthSuccess<SessionResponse?>).data, isNull);
      });

      test('returns AuthUnknownException when fromJson throws', () async {
        // A session map missing the required userId -> a cast error inside
        // SessionResponse.fromJson, surfaced as AuthUnknownException.
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': <String, dynamic>{'token': 't'},
            'user': userJson(),
          },
        );

        final result = await client.session.get();

        expect(result, isA<AuthFailure<SessionResponse?>>());
        final error = (result as AuthFailure<SessionResponse?>).error;
        expect(error, isA<AuthUnknownException>());
        expect(error.message, startsWith('Failed to parse response:'));
      });

      test(
        'returns AuthUnknownException when the body is a JSON array',
        () async {
          stubGet(adapter, '/get-session', body: const ['nope']);

          final result = await client.session.get();

          expect(result, isA<AuthFailure<SessionResponse?>>());
          final error = (result as AuthFailure<SessionResponse?>).error;
          expect(error, isA<AuthUnknownException>());
          expect(
            error.message,
            equals('Expected a JSON object or null response.'),
          );
        },
      );

      test('propagates an API failure unchanged', () async {
        stubGet(
          adapter,
          '/get-session',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await client.session.get();

        expect(result, isA<AuthFailure<SessionResponse?>>());
        expect(
          (result as AuthFailure<SessionResponse?>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('decodeList (via session.list)', () {
      test('returns a list of sessions on a JSON array body', () async {
        stubGet(
          adapter,
          '/list-sessions',
          body: <Map<String, dynamic>>[
            sessionJson(),
            sessionJson(id: 's2'),
          ],
        );

        final result = await client.session.list();

        expect(result, isA<AuthSuccess<List<Session>>>());
        expect((result as AuthSuccess<List<Session>>).data, hasLength(2));
      });

      test(
        'returns AuthUnknownException when an element fails to parse',
        () async {
          stubGet(
            adapter,
            '/list-sessions',
            body: <Map<String, dynamic>>[
              <String, dynamic>{'token': 't'},
            ],
          );

          final result = await client.session.list();

          expect(result, isA<AuthFailure<List<Session>>>());
          final error = (result as AuthFailure<List<Session>>).error;
          expect(error, isA<AuthUnknownException>());
          expect(error.message, startsWith('Failed to parse list response:'));
        },
      );

      test(
        'returns AuthUnknownException when the body is not an array',
        () async {
          stubGet(
            adapter,
            '/list-sessions',
            body: <String, dynamic>{'not': 'a list'},
          );

          final result = await client.session.list();

          expect(result, isA<AuthFailure<List<Session>>>());
          final error = (result as AuthFailure<List<Session>>).error;
          expect(error, isA<AuthUnknownException>());
          expect(error.message, equals('Expected a JSON array response.'));
        },
      );

      test('propagates an API failure unchanged', () async {
        stubGet(
          adapter,
          '/list-sessions',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await client.session.list();

        expect(result, isA<AuthFailure<List<Session>>>());
        expect(
          (result as AuthFailure<List<Session>>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('decodeStatus (via session.revoke)', () {
      test('returns ok from a JSON object status body', () async {
        stubPost(
          adapter,
          '/revoke-session',
          body: <String, dynamic>{'status': true},
        );

        final result = await client.session.revoke(token: 't');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test(
        'treats a non-object success body as a message-less ok status',
        () async {
          stubPost(adapter, '/revoke-session', body: 'OK');

          final result = await client.session.revoke(token: 't');

          expect(result, isA<AuthSuccess<StatusResponse>>());
          final status = (result as AuthSuccess<StatusResponse>).data;
          expect(status.ok, isTrue);
          expect(status.message, isNull);
        },
      );

      test('propagates an API failure unchanged', () async {
        stubPost(
          adapter,
          '/revoke-session',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await client.session.revoke(token: 't');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
