import 'dart:async';
import 'dart:convert';

import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:betterauth_dart/src/constants.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// A test client that records the body of the last outgoing request.
typedef _CapturingClient = ({
  BetterAuthClient client,
  DioAdapter adapter,
  InMemoryAsyncStorage storage,
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
  final storage = InMemoryAsyncStorage();
  final client = BetterAuthClient(
    baseUrl: Uri.parse(testBaseUrl),
    options: const BetterAuthClientOptions(maxRetries: 0, autoRefresh: false),
    storage: storage,
    dio: dio,
  );
  Map<String, dynamic> lastBody() => captured! as Map<String, dynamic>;
  return (
    client: client,
    adapter: adapter,
    storage: storage,
    lastBody: lastBody,
  );
}

void main() {
  group(SignUpGroup, () {
    late BetterAuthClient client;
    late DioAdapter adapter;

    setUp(() {
      final test = buildTestClient();
      client = test.client;
      adapter = test.adapter;
    });

    group('email', () {
      test('adopts session and hydrates when a token is returned', () async {
        stubPost(
          adapter,
          '/sign-up/email',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
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

        final result = await client.signUp.email(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthSuccess<SignUpResponse>>());
        final data = (result as AuthSuccess<SignUpResponse>).data;
        expect(data.token, equals('tok'));
        expect(data.hasSession, isTrue);
        expect(client.currentUser, isNotNull);
        expect(client.currentSession, isNotNull);
        expect(client.isAuthenticated, isTrue);
        // The bearer token adopted from the sign-up response body.
        expect(client.currentToken, equals('tok'));
        expect(client.currentSession!.token, equals('tok_123'));
      });

      test('does not hydrate when no token is returned', () async {
        stubPost(
          adapter,
          '/sign-up/email',
          body: <String, dynamic>{'user': userJson()},
        );

        final result = await client.signUp.email(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthSuccess<SignUpResponse>>());
        final data = (result as AuthSuccess<SignUpResponse>).data;
        expect(data.token, isNull);
        expect(data.hasSession, isFalse);
        expect(client.currentUser, isNull);
        expect(client.currentSession, isNull);
        expect(client.isAuthenticated, isFalse);
      });

      test('includes username, displayUsername and additionalFields '
          'in the body', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-up/email',
          body: <String, dynamic>{'user': userJson()},
        );

        final result = await capturing.client.signUp.email(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
          image: 'https://img',
          username: 'ada',
          displayUsername: 'Ada',
          callbackURL: 'https://cb',
          rememberMe: true,
          additionalFields: <String, dynamic>{'referralCode': 'XYZ'},
        );

        expect(result, isA<AuthSuccess<SignUpResponse>>());
        final body = capturing.lastBody();
        expect(body['name'], equals('Ada'));
        expect(body['image'], equals('https://img'));
        expect(body['username'], equals('ada'));
        expect(body['displayUsername'], equals('Ada'));
        expect(body['callbackURL'], equals('https://cb'));
        expect(body['rememberMe'], isTrue);
        expect(body['referralCode'], equals('XYZ'));
      });

      test('omits null optional fields from the body', () async {
        final capturing = _buildCapturingClient();
        stubPost(
          capturing.adapter,
          '/sign-up/email',
          body: <String, dynamic>{'user': userJson()},
        );

        await capturing.client.signUp.email(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );

        final body = capturing.lastBody();
        expect(body.containsKey('image'), isFalse);
        expect(body.containsKey('username'), isFalse);
        expect(body.containsKey('displayUsername'), isFalse);
        expect(body.containsKey('callbackURL'), isFalse);
        expect(body.containsKey('rememberMe'), isFalse);
      });

      test('returns AuthFailure with AuthApiException on a 400', () async {
        stubPost(
          adapter,
          '/sign-up/email',
          status: 400,
          body: <String, dynamic>{
            'message': 'Email already exists',
            'code': 'USER_ALREADY_EXISTS',
          },
        );

        final result = await client.signUp.email(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(result, isA<AuthFailure<SignUpResponse>>());
        final error = (result as AuthFailure<SignUpResponse>).error;
        expect(error, isA<AuthApiException>());
        expect(error.message, equals('Email already exists'));
        expect(client.currentUser, isNull);
      });
    });
  });

  group(BetterAuthClient, () {
    late BetterAuthClient client;
    late DioAdapter adapter;
    late InMemoryAsyncStorage storage;

    setUp(() {
      final test = buildTestClient();
      client = test.client;
      adapter = test.adapter;
      storage = test.storage;
    });

    group('initialize', () {
      test('emits initialSession with no restored session', () async {
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(events, contains(AuthChangeEvent.initialSession));
        expect(client.currentSession, isNull);
      });

      test('is a no-op on subsequent calls', () async {
        await client.initialize();
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
      });

      test(
        'restores a persisted session and hydrates in the background',
        () async {
          final snapshot = jsonEncode(<String, dynamic>{
            'token': 'tok_123',
            'cookies': <String, String>{},
            'session': sessionJson(),
            'user': userJson(),
          });
          await storage.setItem(key: kSessionStorageKey, value: snapshot);
          stubGet(
            adapter,
            '/get-session',
            body: <String, dynamic>{
              'session': sessionJson(),
              'user': userJson(),
            },
          );

          final events = <AuthChangeEvent>[];
          client.onAuthStateChange.listen((s) => events.add(s.event));
          // The background hydrate performs an HTTP round-trip, so wait for the
          // resulting refresh event before asserting.
          final refreshed = client.onAuthStateChange.firstWhere(
            (s) => s.event == AuthChangeEvent.sessionRefreshed,
          );

          await client.initialize();
          await refreshed;

          expect(client.currentSession, isNotNull);
          expect(events, contains(AuthChangeEvent.initialSession));
          expect(events, contains(AuthChangeEvent.sessionRefreshed));
        },
      );

      test('starts unauthenticated when the snapshot is corrupt', () async {
        await storage.setItem(key: kSessionStorageKey, value: 'not-json');

        await client.initialize();

        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
      });

      test('restores cookies from the snapshot map', () async {
        final snapshot = jsonEncode(<String, dynamic>{
          'token': 'tok_123',
          'cookies': <String, String>{kSessionCookieName: 'cookie-value'},
          'session': sessionJson(),
          'user': userJson(),
        });
        await storage.setItem(key: kSessionStorageKey, value: snapshot);
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final refreshed = client.onAuthStateChange.firstWhere(
          (s) => s.event == AuthChangeEvent.sessionRefreshed,
        );

        await client.initialize();
        await refreshed;

        expect(client.currentSession, isNotNull);
      });
    });

    group('signOut', () {
      test('clears local state and returns ok', () async {
        stubPost(
          adapter,
          '/sign-in/email',
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
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
        await client.signIn.email(email: 'ada@example.com', password: 'pw');
        expect(client.currentSession, isNotNull);

        stubPost(
          adapter,
          '/sign-out',
          body: <String, dynamic>{'success': true},
        );

        final result = await client.signOut();

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
      });

      test(
        'clears local state even when the server returns an error',
        () async {
          stubPost(
            adapter,
            '/sign-out',
            status: 400,
            body: <String, dynamic>{'message': 'boom', 'code': 'X'},
          );

          final result = await client.signOut();

          expect(result, isA<AuthFailure<StatusResponse>>());
          expect(client.currentSession, isNull);
        },
      );

      test('treats a non-map success body as a message-less status', () async {
        stubPost(adapter, '/sign-out', body: 'OK');

        final result = await client.signOut();

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });
    });

    group('refresh', () {
      test('re-fetches the session emitting sessionRefreshed', () async {
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.refresh();
        await Future<void>.delayed(Duration.zero);

        expect(client.currentSession, isNotNull);
        expect(events, contains(AuthChangeEvent.sessionRefreshed));
      });

      test('signs out locally when the server reports no session', () async {
        // The default stub body is literal null, mirroring an unauthenticated
        // `/get-session` response.
        stubGet(adapter, '/get-session');
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.refresh();
        await Future<void>.delayed(Duration.zero);

        expect(client.currentSession, isNull);
        expect(events, contains(AuthChangeEvent.signedOut));
      });

      test('leaves state unchanged on an error response', () async {
        stubGet(
          adapter,
          '/get-session',
          status: 400,
          body: <String, dynamic>{'message': 'nope', 'code': 'X'},
        );

        await client.refresh();

        expect(client.currentSession, isNull);
      });
    });

    group('setSession', () {
      test('adopts a fully-known session and persists it', () async {
        final session = Session.fromJson(sessionJson());
        final user = User.fromJson(userJson());
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.setSession(session: session, user: user);
        await Future<void>.delayed(Duration.zero);

        expect(client.currentSession, equals(session));
        expect(client.currentUser, equals(user));
        expect(client.currentToken, equals(session.token));
        expect(events, contains(AuthChangeEvent.signedIn));
        expect(storage.store[kSessionTokenStorageKey], equals(session.token));
      });

      test('emits the provided event', () async {
        final session = Session.fromJson(sessionJson());
        final user = User.fromJson(userJson());
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.setSession(
          session: session,
          user: user,
          event: AuthChangeEvent.userUpdated,
        );
        await Future<void>.delayed(Duration.zero);

        expect(events, contains(AuthChangeEvent.userUpdated));
      });
    });

    group('signOutLocally', () {
      test('clears credentials, storage and emits signedOut', () async {
        final session = Session.fromJson(sessionJson());
        final user = User.fromJson(userJson());
        await client.setSession(session: session, user: user);
        final events = <AuthChangeEvent>[];
        client.onAuthStateChange.listen((s) => events.add(s.event));

        await client.signOutLocally();
        await Future<void>.delayed(Duration.zero);

        expect(client.currentSession, isNull);
        expect(client.currentUser, isNull);
        expect(client.currentToken, isNull);
        expect(storage.store, isEmpty);
        expect(events, contains(AuthChangeEvent.signedOut));
      });
    });

    group('unauthorized handling', () {
      test('signs out locally and invokes onUnauthorized on a 401', () async {
        var called = false;
        final test = buildTestClient(onUnauthorized: () => called = true);
        final c = test.client;
        final a = test.adapter;

        final session = Session.fromJson(sessionJson());
        final user = User.fromJson(userJson());
        await c.setSession(session: session, user: user);

        stubGet(
          a,
          '/get-session',
          status: 401,
          body: <String, dynamic>{'message': 'expired'},
        );

        await c.refresh();
        await Future<void>.delayed(Duration.zero);

        expect(called, isTrue);
        expect(c.currentSession, isNull);
      });

      test('invokes onUnauthorized even without a local session', () async {
        var called = false;
        final test = buildTestClient(onUnauthorized: () => called = true);
        final c = test.client;
        final a = test.adapter;

        stubGet(
          a,
          '/get-session',
          status: 401,
          body: <String, dynamic>{'message': 'expired'},
        );

        await c.refresh();

        expect(called, isTrue);
      });
    });

    group('autoRefresh timer', () {
      test('schedules a proactive refresh when autoRefresh is on', () {
        fakeAsync((async) {
          final test = buildTestClient(
            options: const BetterAuthClientOptions(maxRetries: 0),
          );
          final c = test.client;
          final a = test.adapter;

          final expiresAt = DateTime.now().toUtc().add(
            const Duration(minutes: 10),
          );
          final session = Session.fromJson(
            sessionJson(expiresAt: expiresAt.toIso8601String()),
          );
          final user = User.fromJson(userJson());

          var refreshes = 0;
          c.onAuthStateChange.listen((s) {
            if (s.event == AuthChangeEvent.sessionRefreshed) refreshes++;
          });

          stubGet(
            a,
            '/get-session',
            body: <String, dynamic>{
              'session': sessionJson(expiresAt: expiresAt.toIso8601String()),
              'user': userJson(),
            },
          );

          unawaited(c.setSession(session: session, user: user));
          async
            ..flushMicrotasks()
            ..elapse(const Duration(minutes: 9, seconds: 30))
            ..flushMicrotasks();

          expect(refreshes, greaterThanOrEqualTo(1));
        });
      });

      test(
        'does not schedule when the session is already within lead time',
        () {
          fakeAsync((async) {
            final test = buildTestClient(
              options: const BetterAuthClientOptions(maxRetries: 0),
            );
            final c = test.client;

            final expiresAt = DateTime.now().toUtc().add(
              const Duration(seconds: 10),
            );
            final session = Session.fromJson(
              sessionJson(expiresAt: expiresAt.toIso8601String()),
            );
            final user = User.fromJson(userJson());

            var refreshes = 0;
            c.onAuthStateChange.listen((s) {
              if (s.event == AuthChangeEvent.sessionRefreshed) refreshes++;
            });

            unawaited(c.setSession(session: session, user: user));
            async
              ..flushMicrotasks()
              ..elapse(const Duration(minutes: 5));

            expect(refreshes, equals(0));
          });
        },
      );
    });

    group('constructor', () {
      test(
        'defaults to an in-memory store when no storage is provided',
        () async {
          final c = BetterAuthClient(
            baseUrl: Uri.parse(testBaseUrl),
            options: const BetterAuthClientOptions(
              maxRetries: 0,
              autoRefresh: false,
            ),
          );
          addTearDown(c.dispose);

          // A fresh client with the default in-memory store is signed out.
          expect(c.currentSession, isNull);
          expect(c.currentToken, isNull);
          expect(c.isAuthenticated, isFalse);
          await c.initialize();
          expect(c.currentSession, isNull);
        },
      );
    });

    group('dispose', () {
      test(
        'cancels timers, closes the stream and ignores later emits',
        () async {
          await client.dispose();

          // Emitting after close is a no-op (covers the isClosed guard).
          final session = Session.fromJson(sessionJson());
          final user = User.fromJson(userJson());
          await client.setSession(session: session, user: user);

          expect(client.currentSession, isNotNull);
        },
      );
    });
  });
}
