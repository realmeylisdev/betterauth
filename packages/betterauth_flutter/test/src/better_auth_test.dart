import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<IdToken?> googleSuccess({List<String>? scopes}) async =>
      const IdToken(token: 'g');
  Future<IdToken?> googleCancel({List<String>? scopes}) async => null;
  Future<IdToken?> appleSuccess({List<String>? scopes}) async =>
      const IdToken(token: 'a');
  Future<IdToken?> appleCancel({List<String>? scopes}) async => null;

  WebAuthenticator webReturning(Uri uri) =>
      ({required url, required callbackUrlScheme}) async => uri;

  Future<Map<String, dynamic>?> passkeyReturning(
    Map<String, dynamic> options,
  ) async => <String, dynamic>{'id': 'cred'};
  Future<Map<String, dynamic>?> passkeyCancel(
    Map<String, dynamic> options,
  ) async => null;

  /// A canonical passkey JSON map.
  Map<String, dynamic> passkeyJson() => <String, dynamic>{
    'id': 'pk_1',
    'credentialID': 'cred_1',
    'userId': 'user_1',
    'name': 'My Key',
  };

  tearDown(() async {
    if (BetterAuth.isInitialized) {
      await BetterAuth.instance.dispose();
    }
  });

  group(BetterAuth, () {
    group('instance', () {
      test('throws StateError before initialize', () {
        expect(() => BetterAuth.instance, throwsStateError);
      });

      test('returns the instance after initialize', () async {
        final h = buildTestClient();
        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        expect(BetterAuth.instance, same(instance));
      });
    });

    group('isInitialized', () {
      test('is false before initialize and true after', () async {
        expect(BetterAuth.isInitialized, isFalse);

        final h = buildTestClient();
        await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        expect(BetterAuth.isInitialized, isTrue);
      });
    });

    group('initialize', () {
      test(
        'does not add a lifecycle observer when refreshOnResume is false',
        () async {
          final h = buildTestClient();
          final instance = await BetterAuth.initialize(
            baseUrl: Uri.parse(testBaseUrl),
            client: h.client,
            refreshOnResume: false,
            google: googleSuccess,
            apple: appleSuccess,
            web: webReturning(Uri.parse('myapp://cb')),
          );

          // Disposing without an observer must not throw.
          await instance.dispose();
          expect(BetterAuth.isInitialized, isFalse);
        },
      );

      test('adds a lifecycle observer when refreshOnResume is true and removes '
          'it on dispose', () async {
        final h = buildTestClient();
        // Resume triggers client.refresh() -> GET /get-session.
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );

        // refreshOnResume defaults to true, which installs the observer.
        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        // Drive a resume so the observer callback runs.
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await pumpEventQueue();

        // Dispose removes the observer without error.
        await instance.dispose();
        expect(BetterAuth.isInitialized, isFalse);
      });

      test(
        'uses the provided storage instead of constructing a default',
        () async {
          final storage = InMemoryAsyncStorage();
          final instance = await BetterAuth.initialize(
            baseUrl: Uri.parse(testBaseUrl),
            storage: storage,
            refreshOnResume: false,
            google: googleSuccess,
            apple: appleSuccess,
            web: webReturning(Uri.parse('myapp://cb')),
          );

          expect(BetterAuth.isInitialized, isTrue);
          await instance.dispose();
        },
      );

      test('constructs a default SecureStorageAdapter when no client or '
          'storage is provided', () async {
        // Mock the flutter_secure_storage platform channel so the default
        // SecureStorageAdapter() can be constructed and read during
        // client.initialize() without a real platform.
        const channel = MethodChannel(
          'plugins.it_nomads.com/flutter_secure_storage',
        );
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async => null,
        );
        addTearDown(() {
          binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        });

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        expect(BetterAuth.isInitialized, isTrue);
        await instance.dispose();
      });
    });

    group('signInWithGoogle', () {
      test('exchanges the id token for a session on success', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithGoogle(scopes: const ['email']);

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        final data = (result as AuthSuccess<SocialSignInResponse>).data;
        expect(data, isA<SocialSignedIn>());
      });

      test('returns an AuthFailure when the user cancels', () async {
        final h = buildTestClient();
        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleCancel,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithGoogle();

        expect(result, isA<AuthFailure<SocialSignInResponse>>());
        final error = (result as AuthFailure<SocialSignInResponse>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, contains('Google'));
      });
    });

    group('signInWithApple', () {
      test('exchanges the id token for a session on success', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithApple(scopes: const ['email']);

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        final data = (result as AuthSuccess<SocialSignInResponse>).data;
        expect(data, isA<SocialSignedIn>());
      });

      test('returns an AuthFailure when the user cancels', () async {
        final h = buildTestClient();
        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleCancel,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithApple();

        expect(result, isA<AuthFailure<SocialSignInResponse>>());
        final error = (result as AuthFailure<SocialSignInResponse>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, contains('Apple'));
      });
    });

    group('signInWithProvider', () {
      test('hydrates from a token carried back in the callback URL', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{
            'redirect': true,
            'url': 'https://idp/auth',
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb?token=tok')),
        );

        final result = await instance.signInWithProvider(
          provider: 'github',
          callbackUrlScheme: 'myapp',
          scopes: const ['read'],
        );

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        final data = (result as AuthSuccess<SocialSignInResponse>).data;
        expect(data, isA<SocialSignedIn>());
      });

      test('refreshes when the callback URL carries no token', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{
            'redirect': true,
            'url': 'https://idp/auth',
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithProvider(
          provider: 'github',
          callbackUrlScheme: 'myapp',
        );

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        expect(
          (result as AuthSuccess<SocialSignInResponse>).data,
          isA<SocialSignedIn>(),
        );
      });

      test('returns immediately for a non-redirect (SocialSignedIn) response '
          'without opening the browser', () async {
        final h = buildTestClient();
        var webCalled = false;
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        Future<Uri> web({
          required String url,
          required String callbackUrlScheme,
        }) async {
          webCalled = true;
          return Uri.parse('myapp://cb');
        }

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: web,
        );

        final result = await instance.signInWithProvider(
          provider: 'github',
          callbackUrlScheme: 'myapp',
        );

        expect(result, isA<AuthSuccess<SocialSignInResponse>>());
        expect(
          (result as AuthSuccess<SocialSignInResponse>).data,
          isA<SocialSignedIn>(),
        );
        expect(webCalled, isFalse);
      });

      test('returns the AuthFailure from /sign-in/social', () async {
        final h = buildTestClient();
        var webCalled = false;
        stubPost(
          h.adapter,
          '/sign-in/social',
          status: 400,
          body: <String, dynamic>{'message': 'bad provider', 'code': 'X'},
        );

        Future<Uri> web({
          required String url,
          required String callbackUrlScheme,
        }) async {
          webCalled = true;
          return Uri.parse('myapp://cb');
        }

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: web,
        );

        final result = await instance.signInWithProvider(
          provider: 'github',
          callbackUrlScheme: 'myapp',
        );

        expect(result, isA<AuthFailure<SocialSignInResponse>>());
        expect(webCalled, isFalse);
      });

      test('returns an AuthFailure when no session is established after the '
          'callback', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/social',
          body: <String, dynamic>{
            'redirect': true,
            'url': 'https://idp/auth',
          },
        );
        // No session: /get-session returns a literal null body (the default).
        stubGet(h.adapter, '/get-session');

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInWithProvider(
          provider: 'github',
          callbackUrlScheme: 'myapp',
        );

        expect(result, isA<AuthFailure<SocialSignInResponse>>());
        final error = (result as AuthFailure<SocialSignInResponse>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, contains('did not establish a session'));
      });
    });

    group('signInAnonymously', () {
      test('delegates to the client and establishes a session', () async {
        final h = buildTestClient();
        stubPost(
          h.adapter,
          '/sign-in/anonymous',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        final result = await instance.signInAnonymously();

        expect(result, isA<AuthSuccess<AuthSession>>());
        final data = (result as AuthSuccess<AuthSession>).data;
        expect(data.token, 'tok');
      });
    });

    group('registerPasskey', () {
      test('runs the native ceremony and verifies registration', () async {
        final h = buildTestClient();
        stubGet(
          h.adapter,
          '/passkey/generate-register-options',
          body: <String, dynamic>{'challenge': 'abc'},
        );
        stubPost(
          h.adapter,
          '/passkey/verify-registration',
          body: passkeyJson(),
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
          passkeyRegistrar: passkeyReturning,
        );

        final result = await instance.registerPasskey(name: 'My Key');

        expect(result, isA<AuthSuccess<Passkey>>());
        final data = (result as AuthSuccess<Passkey>).data;
        expect(data.id, 'pk_1');
      });

      test('returns an AuthFailure when the user cancels', () async {
        final h = buildTestClient();
        stubGet(
          h.adapter,
          '/passkey/generate-register-options',
          body: <String, dynamic>{'challenge': 'abc'},
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
          passkeyRegistrar: passkeyCancel,
        );

        final result = await instance.registerPasskey();

        expect(result, isA<AuthFailure<Passkey>>());
        final error = (result as AuthFailure<Passkey>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, contains('Passkey'));
      });

      test('returns the AuthFailure from generate-register-options', () async {
        final h = buildTestClient();
        stubGet(
          h.adapter,
          '/passkey/generate-register-options',
          status: 400,
          body: <String, dynamic>{'message': 'nope', 'code': 'BAD'},
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
          passkeyRegistrar: passkeyReturning,
        );

        final result = await instance.registerPasskey();

        expect(result, isA<AuthFailure<Passkey>>());
      });
    });

    group('signInWithPasskey', () {
      test('runs the native ceremony and establishes a session', () async {
        final h = buildTestClient();
        stubGet(
          h.adapter,
          '/passkey/generate-authenticate-options',
          body: <String, dynamic>{'challenge': 'abc'},
        );
        stubPost(
          h.adapter,
          '/sign-in/passkey',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
        );
        stubGet(
          h.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
          passkeyAssertor: passkeyReturning,
        );

        final result = await instance.signInWithPasskey();

        expect(result, isA<AuthSuccess<AuthSession>>());
        final data = (result as AuthSuccess<AuthSession>).data;
        expect(data.token, 'tok');
      });

      test('returns an AuthFailure when the user cancels', () async {
        final h = buildTestClient();
        stubGet(
          h.adapter,
          '/passkey/generate-authenticate-options',
          body: <String, dynamic>{'challenge': 'abc'},
        );

        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
          passkeyAssertor: passkeyCancel,
        );

        final result = await instance.signInWithPasskey();

        expect(result, isA<AuthFailure<AuthSession>>());
        final error = (result as AuthFailure<AuthSession>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, contains('Passkey'));
      });

      test(
        'returns the AuthFailure from generate-authenticate-options',
        () async {
          final h = buildTestClient();
          stubGet(
            h.adapter,
            '/passkey/generate-authenticate-options',
            status: 400,
            body: <String, dynamic>{'message': 'nope', 'code': 'BAD'},
          );

          final instance = await BetterAuth.initialize(
            baseUrl: Uri.parse(testBaseUrl),
            client: h.client,
            refreshOnResume: false,
            google: googleSuccess,
            apple: appleSuccess,
            web: webReturning(Uri.parse('myapp://cb')),
            passkeyAssertor: passkeyReturning,
          );

          final result = await instance.signInWithPasskey();

          expect(result, isA<AuthFailure<AuthSession>>());
        },
      );
    });

    group('dispose', () {
      test('clears the singleton', () async {
        final h = buildTestClient();
        final instance = await BetterAuth.initialize(
          baseUrl: Uri.parse(testBaseUrl),
          client: h.client,
          refreshOnResume: false,
          google: googleSuccess,
          apple: appleSuccess,
          web: webReturning(Uri.parse('myapp://cb')),
        );

        await instance.dispose();

        expect(BetterAuth.isInitialized, isFalse);
        expect(() => BetterAuth.instance, throwsStateError);
      });

      test(
        'does not clear the singleton when a newer instance replaced it',
        () async {
          final h1 = buildTestClient();
          final first = await BetterAuth.initialize(
            baseUrl: Uri.parse(testBaseUrl),
            client: h1.client,
            refreshOnResume: false,
            google: googleSuccess,
            apple: appleSuccess,
            web: webReturning(Uri.parse('myapp://cb')),
          );

          final h2 = buildTestClient();
          final second = await BetterAuth.initialize(
            baseUrl: Uri.parse(testBaseUrl),
            client: h2.client,
            refreshOnResume: false,
            google: googleSuccess,
            apple: appleSuccess,
            web: webReturning(Uri.parse('myapp://cb')),
          );

          // Disposing the stale instance must not clear the current singleton.
          await first.dispose();

          expect(BetterAuth.isInitialized, isTrue);
          expect(BetterAuth.instance, same(second));
        },
      );
    });
  });
}
