import 'dart:async';
import 'dart:convert';

import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:betterauth_dart/src/groups/session_sink.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group(BetterAuthClientOptions, () {
    test('uses documented defaults', () {
      const options = BetterAuthClientOptions();

      expect(options.transportMode, equals(AuthTransportMode.bearer));
      expect(options.timeout, equals(const Duration(seconds: 30)));
      expect(options.maxRetries, equals(3));
      expect(options.enableLogging, isNull);
      expect(options.autoRefresh, isTrue);
      expect(options.refreshLeadTime, equals(const Duration(minutes: 1)));
      expect(
        options.sessionTokenStorageKey,
        equals('betterauth.session_token'),
      );
      expect(options.sessionStorageKey, equals('betterauth.session'));
    });

    test('copyWith replaces every field', () {
      const base = BetterAuthClientOptions();

      final copy = base.copyWith(
        transportMode: AuthTransportMode.cookie,
        timeout: const Duration(seconds: 5),
        maxRetries: 7,
        enableLogging: true,
        autoRefresh: false,
        refreshLeadTime: const Duration(seconds: 10),
        sessionTokenStorageKey: 'tk',
        sessionStorageKey: 'sk',
      );

      expect(copy.transportMode, equals(AuthTransportMode.cookie));
      expect(copy.timeout, equals(const Duration(seconds: 5)));
      expect(copy.maxRetries, equals(7));
      expect(copy.enableLogging, isTrue);
      expect(copy.autoRefresh, isFalse);
      expect(copy.refreshLeadTime, equals(const Duration(seconds: 10)));
      expect(copy.sessionTokenStorageKey, equals('tk'));
      expect(copy.sessionStorageKey, equals('sk'));
    });

    test('copyWith with no arguments preserves every field', () {
      const base = BetterAuthClientOptions(
        transportMode: AuthTransportMode.cookie,
        timeout: Duration(seconds: 5),
        maxRetries: 7,
        enableLogging: false,
        autoRefresh: false,
        refreshLeadTime: Duration(seconds: 10),
        sessionTokenStorageKey: 'tk',
        sessionStorageKey: 'sk',
      );

      final copy = base.copyWith();

      expect(copy.transportMode, equals(base.transportMode));
      expect(copy.timeout, equals(base.timeout));
      expect(copy.maxRetries, equals(base.maxRetries));
      expect(copy.enableLogging, equals(base.enableLogging));
      expect(copy.autoRefresh, equals(base.autoRefresh));
      expect(copy.refreshLeadTime, equals(base.refreshLeadTime));
      expect(copy.sessionTokenStorageKey, equals(base.sessionTokenStorageKey));
      expect(copy.sessionStorageKey, equals(base.sessionStorageKey));
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

    tearDown(() async {
      await client.dispose();
    });

    /// Builds a JSON snapshot identical to the one persisted by the client.
    String snapshotJson({
      String token = 'tok_123',
      Map<String, dynamic>? session,
      Map<String, dynamic>? user,
      Object? cookies,
    }) => jsonEncode(<String, dynamic>{
      'token': token,
      'cookies': cookies ?? <String, dynamic>{},
      'session': session ?? sessionJson(),
      'user': user ?? userJson(),
    });

    group('initial state', () {
      test('starts signed out', () {
        expect(client.currentSession, isNull);
        expect(client.currentUser, isNull);
        expect(client.currentToken, isNull);
        expect(client.isAuthenticated, isFalse);
      });

      test('exposes the configured options', () {
        expect(client.options, isA<BetterAuthClientOptions>());
        expect(client.options.maxRetries, equals(0));
        expect(client.options.autoRefresh, isFalse);
      });

      test('exposes a broadcast auth-state stream', () {
        expect(client.onAuthStateChange.isBroadcast, isTrue);
      });

      test('defaults to in-memory storage when none is supplied', () async {
        final c = BetterAuthClient(
          baseUrl: Uri.parse(testBaseUrl),
          options: const BetterAuthClientOptions(
            maxRetries: 0,
            autoRefresh: false,
          ),
        );
        addTearDown(c.dispose);

        // No storage was provided, so the default in-memory store is used and
        // there is nothing to restore.
        await c.initialize();

        expect(c.currentSession, isNull);
        expect(c.isAuthenticated, isFalse);
      });
    });

    group('initialize', () {
      test(
        'emits initialSession with null when no snapshot is stored',
        () async {
          final events = <AuthState>[];
          client.onAuthStateChange.listen(events.add);

          await client.initialize();
          await pumpEventQueue();

          expect(events, hasLength(1));
          expect(events.single.event, equals(AuthChangeEvent.initialSession));
          expect(events.single.session, isNull);
          expect(events.single.user, isNull);
          expect(client.isAuthenticated, isFalse);
        },
      );

      test('is idempotent: a second call is a no-op', () async {
        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.initialize();
        await client.initialize();
        await pumpEventQueue();

        expect(events, hasLength(1));
      });

      test('restores a persisted snapshot and emits initialSession', () async {
        final seeded = InMemoryAsyncStorage();
        seeded.store['betterauth.session'] = snapshotJson(
          cookies: <String, dynamic>{'better-auth.session_token': 'cookie_v'},
        );
        final test = buildTestClient(storage: seeded);
        final restored = test.client;
        // autoRefresh is off by default in buildTestClient, so no timer/hydrate.
        addTearDown(restored.dispose);

        final events = <AuthState>[];
        restored.onAuthStateChange.listen(events.add);

        await restored.initialize();
        await pumpEventQueue();

        expect(events, hasLength(1));
        expect(events.single.event, equals(AuthChangeEvent.initialSession));
        expect(restored.currentSession, isNotNull);
        expect(restored.currentUser, isNotNull);
        expect(restored.currentToken, equals('tok_123'));
        expect(restored.currentSession!.userId, equals('user_1'));
      });

      test(
        'with autoRefresh on, restoring a snapshot hydrates in the background',
        () async {
          final seeded = InMemoryAsyncStorage();
          seeded.store['betterauth.session'] = snapshotJson();
          final test = buildTestClient(
            storage: seeded,
            options: const BetterAuthClientOptions(
              maxRetries: 0,
            ),
          );
          final restored = test.client;
          addTearDown(restored.dispose);

          stubGet(
            test.adapter,
            '/get-session',
            body: <String, dynamic>{
              'session': sessionJson(),
              'user': userJson(name: 'Refreshed'),
            },
          );

          final events = <AuthState>[];
          restored.onAuthStateChange.listen(events.add);

          await restored.initialize();
          await pumpEventQueue();

          expect(events.first.event, equals(AuthChangeEvent.initialSession));
          expect(
            events.map((e) => e.event),
            contains(AuthChangeEvent.sessionRefreshed),
          );
          expect(restored.currentUser!.name, equals('Refreshed'));
        },
      );

      test(
        'starts unauthenticated when the snapshot is invalid JSON',
        () async {
          final seeded = InMemoryAsyncStorage();
          seeded.store['betterauth.session'] = 'not-json{';
          final test = buildTestClient(storage: seeded);
          final restored = test.client;
          addTearDown(restored.dispose);

          await restored.initialize();
          await pumpEventQueue();

          expect(restored.currentSession, isNull);
          expect(restored.currentUser, isNull);
          expect(restored.currentToken, isNull);
          expect(restored.isAuthenticated, isFalse);
        },
      );

      test('starts unauthenticated when the snapshot is wrong-typed', () async {
        final seeded = InMemoryAsyncStorage();
        // `session` present but malformed (missing required fields) -> throws
        // inside fromJson and is caught.
        seeded.store['betterauth.session'] = jsonEncode(<String, dynamic>{
          'token': 'tok_123',
          'cookies': <String, dynamic>{},
          'session': <String, dynamic>{'bogus': true},
          'user': userJson(),
        });
        final test = buildTestClient(storage: seeded);
        final restored = test.client;
        addTearDown(restored.dispose);

        await restored.initialize();
        await pumpEventQueue();

        expect(restored.currentSession, isNull);
        expect(restored.currentUser, isNull);
        expect(restored.currentToken, isNull);
      });

      test(
        'ignores a snapshot whose token/session/user fields are absent',
        () async {
          final seeded = InMemoryAsyncStorage();
          seeded.store['betterauth.session'] = jsonEncode(<String, dynamic>{
            'cookies': 'not-a-map',
          });
          final test = buildTestClient(storage: seeded);
          final restored = test.client;
          addTearDown(restored.dispose);

          await restored.initialize();
          await pumpEventQueue();

          expect(restored.currentToken, isNull);
          expect(restored.currentSession, isNull);
          expect(restored.currentUser, isNull);
        },
      );
    });

    group('sign-in persistence and events', () {
      test(
        'signing in persists a snapshot, the token, and emits signedIn',
        () async {
          stubPost(
            adapter,
            '/sign-in/email',
            body: <String, dynamic>{
              'token': 'tok_123',
              'user': userJson(),
            },
            headers: <String, List<String>>{
              'set-auth-token': const ['tok_123'],
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

          final events = <AuthState>[];
          client.onAuthStateChange.listen(events.add);

          final result = await client.signIn.email(
            email: 'ada@example.com',
            password: 'pw',
          );
          await pumpEventQueue();

          expect(result.isSuccess, isTrue);
          expect(events.single.event, equals(AuthChangeEvent.signedIn));
          expect(client.isAuthenticated, isTrue);
          expect(client.currentToken, equals('tok_123'));

          final snapshot = storage.store['betterauth.session'];
          expect(snapshot, isNotNull);
          final decoded = jsonDecode(snapshot!) as Map<String, dynamic>;
          expect(decoded['token'], equals('tok_123'));
          expect(decoded['session'], isA<Map<String, dynamic>>());
          expect(decoded['user'], isA<Map<String, dynamic>>());
          expect(decoded['cookies'], isA<Map<String, dynamic>>());

          expect(
            storage.store['betterauth.session_token'],
            equals('tok_123'),
          );
        },
      );
    });

    group('signOut', () {
      test(
        'clears state and emits signedOut on a successful server call',
        () async {
          await _signIn(client, adapter);
          final events = <AuthState>[];
          client.onAuthStateChange.listen(events.add);

          stubPost(
            adapter,
            '/sign-out',
            body: <String, dynamic>{'success': true},
          );

          final result = await client.signOut();
          await pumpEventQueue();

          expect(result.isSuccess, isTrue);
          expect(result.dataOrNull!.ok, isTrue);
          expect(client.currentSession, isNull);
          expect(client.currentUser, isNull);
          expect(client.currentToken, isNull);
          expect(storage.store, isEmpty);
          expect(
            events.map((e) => e.event),
            contains(AuthChangeEvent.signedOut),
          );
        },
      );

      test('still clears locally when the server returns 400', () async {
        await _signIn(client, adapter);

        stubPost(
          adapter,
          '/sign-out',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.signOut();

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<AuthApiException>());
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
        expect(storage.store, isEmpty);
      });

      test('still clears locally when the server returns 500', () async {
        await _signIn(client, adapter);

        stubPost(
          adapter,
          '/sign-out',
          status: 500,
          body: <String, dynamic>{'message': 'boom'},
        );

        final result = await client.signOut();

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<AuthRetryableFetchException>());
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
      });

      test(
        'returns ok:true when the server replies with an empty body',
        () async {
          await _signIn(client, adapter);
          stubPost(adapter, '/sign-out');

          final result = await client.signOut();

          expect(result.isSuccess, isTrue);
          expect(result.dataOrNull!.ok, isTrue);
        },
      );
    });

    group('signOutLocally', () {
      test('clears token, session and storage and emits signedOut', () async {
        await _signIn(client, adapter);
        expect(client.isAuthenticated, isTrue);

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.signOutLocally();
        await pumpEventQueue();

        expect(client.currentSession, isNull);
        expect(client.currentUser, isNull);
        expect(client.currentToken, isNull);
        expect(storage.store, isEmpty);
        expect(events.single.event, equals(AuthChangeEvent.signedOut));
      });
    });

    group('hydrate', () {
      test('adopts the bearer token passed in and refreshes', () async {
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        await client.hydrate(token: 'injected_token');

        expect(client.currentToken, equals('injected_token'));
        expect(client.currentSession, isNotNull);
      });

      test('signs out locally when the server reports no session', () async {
        await _signIn(client, adapter);

        // Replace /get-session with a null body for the hydrate triggered here.
        stubGet(adapter, '/get-session');

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.hydrate();
        await pumpEventQueue();

        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
        expect(
          events.map((e) => e.event),
          contains(AuthChangeEvent.signedOut),
        );
      });

      test('keeps state and does not emit on a failed fetch', () async {
        await _signIn(client, adapter);
        final sessionBefore = client.currentSession;

        stubGet(
          adapter,
          '/get-session',
          status: 400,
          body: <String, dynamic>{'message': 'nope', 'code': 'NOPE'},
        );

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.hydrate();
        await pumpEventQueue();

        expect(client.currentSession, equals(sessionBefore));
        expect(client.currentToken, equals('tok_123'));
        expect(events, isEmpty);
      });

      test('emits the supplied event on success', () async {
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.hydrate(event: AuthChangeEvent.userUpdated);
        await pumpEventQueue();

        expect(events.single.event, equals(AuthChangeEvent.userUpdated));
      });
    });

    group('refresh', () {
      test('manual refresh emits sessionRefreshed', () async {
        stubGet(
          adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(name: 'Updated'),
          },
        );

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.refresh();
        await pumpEventQueue();

        expect(events.single.event, equals(AuthChangeEvent.sessionRefreshed));
        expect(client.currentUser!.name, equals('Updated'));
      });
    });

    group('setSession', () {
      test('adopts the session token, persists, and emits', () async {
        final session = Session.fromJson(sessionJson(token: 'set_tok'));
        final user = User.fromJson(userJson());

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.setSession(session: session, user: user);
        await pumpEventQueue();

        expect(client.currentToken, equals('set_tok'));
        expect(client.currentSession, equals(session));
        expect(client.currentUser, equals(user));
        expect(events.single.event, equals(AuthChangeEvent.signedIn));
        expect(storage.store['betterauth.session_token'], equals('set_tok'));
      });

      test('emits the supplied event', () async {
        final session = Session.fromJson(sessionJson());
        final user = User.fromJson(userJson());

        final events = <AuthState>[];
        client.onAuthStateChange.listen(events.add);

        await client.setSession(
          session: session,
          user: user,
          event: AuthChangeEvent.userUpdated,
        );
        await pumpEventQueue();

        expect(events.single.event, equals(AuthChangeEvent.userUpdated));
      });
    });

    group('401 handling', () {
      test(
        'signs out locally and calls onUnauthorized when authenticated',
        () async {
          var unauthorizedCalls = 0;
          final test = buildTestClient(
            onUnauthorized: () => unauthorizedCalls++,
          );
          final c = test.client;
          addTearDown(c.dispose);

          await _signIn(c, test.adapter);
          expect(c.isAuthenticated, isTrue);

          stubGet(test.adapter, '/list-sessions', status: 401);

          final events = <AuthState>[];
          c.onAuthStateChange.listen(events.add);

          final result = await c.session.list();
          await pumpEventQueue();

          expect(result.isFailure, isTrue);
          expect(result.errorOrNull, isA<AuthSessionMissingException>());
          expect(unauthorizedCalls, equals(1));
          expect(c.currentSession, isNull);
          expect(
            events.map((e) => e.event),
            contains(AuthChangeEvent.signedOut),
          );
        },
      );

      test(
        'calls onUnauthorized without a redundant signedOut when signed out',
        () async {
          var unauthorizedCalls = 0;
          final test = buildTestClient(
            onUnauthorized: () => unauthorizedCalls++,
          );
          final c = test.client;
          addTearDown(c.dispose);

          stubGet(test.adapter, '/list-sessions', status: 401);

          final events = <AuthState>[];
          c.onAuthStateChange.listen(events.add);

          final result = await c.session.list();
          await pumpEventQueue();

          expect(result.isFailure, isTrue);
          expect(unauthorizedCalls, equals(1));
          expect(events, isEmpty);
        },
      );

      test('works when no onUnauthorized callback is provided', () async {
        await _signIn(client, adapter);
        stubGet(adapter, '/list-sessions', status: 401);

        final result = await client.session.list();
        await pumpEventQueue();

        expect(result.isFailure, isTrue);
        expect(client.currentSession, isNull);
      });
    });

    group('proactive refresh timer', () {
      test(
        're-fetches the session when autoRefresh is on and expiry is near',
        () {
          fakeAsync((async) {
            final test = buildTestClient(
              options: const BetterAuthClientOptions(maxRetries: 0),
            );
            final c = test.client;

            // expiresAt 2 minutes out -> timer fires after ~1 minute
            // (expiresAt - leadTime).
            final expiresAt = DateTime.now().toUtc().add(
              const Duration(minutes: 2),
            );
            final expiresAtIso = expiresAt.toIso8601String();
            final session = Session.fromJson(
              sessionJson(token: 'tok_timer', expiresAt: expiresAtIso),
            );
            final user = User.fromJson(userJson());

            stubGet(
              test.adapter,
              '/get-session',
              body: <String, dynamic>{
                'session': sessionJson(
                  token: 'tok_timer',
                  expiresAt: expiresAtIso,
                ),
                'user': userJson(name: 'TimerRefreshed'),
              },
            );

            final events = <AuthState>[];
            c.onAuthStateChange.listen(events.add);

            unawaited(c.setSession(session: session, user: user));
            async
              ..flushMicrotasks()
              ..elapse(const Duration(minutes: 1, seconds: 5))
              ..flushMicrotasks();

            expect(
              events.map((e) => e.event),
              contains(AuthChangeEvent.sessionRefreshed),
            );
            expect(c.currentUser!.name, equals('TimerRefreshed'));

            unawaited(c.dispose());
          });
        },
      );

      test('does not schedule a timer when autoRefresh is off', () {
        fakeAsync((async) {
          final test = buildTestClient();
          final c = test.client;

          final session = Session.fromJson(
            sessionJson(
              expiresAt: DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 2))
                  .toIso8601String(),
            ),
          );
          final user = User.fromJson(userJson());

          final events = <AuthState>[];
          c.onAuthStateChange.listen(events.add);

          unawaited(c.setSession(session: session, user: user));
          async
            ..flushMicrotasks()
            ..elapse(const Duration(minutes: 5))
            ..flushMicrotasks();

          expect(
            events.where((e) => e.event == AuthChangeEvent.sessionRefreshed),
            isEmpty,
          );

          unawaited(c.dispose());
        });
      });

      test('does not schedule a timer when expiresAt is in the past', () {
        fakeAsync((async) {
          final test = buildTestClient(
            options: const BetterAuthClientOptions(maxRetries: 0),
          );
          final c = test.client;

          final session = Session.fromJson(
            sessionJson(
              expiresAt: DateTime.now()
                  .toUtc()
                  .subtract(const Duration(minutes: 5))
                  .toIso8601String(),
            ),
          );
          final user = User.fromJson(userJson());

          final events = <AuthState>[];
          c.onAuthStateChange.listen(events.add);

          unawaited(c.setSession(session: session, user: user));
          async
            ..flushMicrotasks()
            ..elapse(const Duration(minutes: 10))
            ..flushMicrotasks();

          expect(
            events.where((e) => e.event == AuthChangeEvent.sessionRefreshed),
            isEmpty,
          );

          unawaited(c.dispose());
        });
      });
    });

    group('dispose', () {
      test('closes the stream so later emits are no-ops', () async {
        await _signIn(client, adapter);

        await client.dispose();

        // Emitting after dispose must not throw (the _emit guard).
        await client.signOutLocally();

        // No assertion failure / exception means the guard held.
        expect(client.currentSession, isNull);
      });

      test('cancels a scheduled refresh timer', () {
        fakeAsync((async) {
          final test = buildTestClient(
            options: const BetterAuthClientOptions(maxRetries: 0),
          );
          final c = test.client;

          final session = Session.fromJson(
            sessionJson(
              expiresAt: DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 2))
                  .toIso8601String(),
            ),
          );

          stubGet(
            test.adapter,
            '/get-session',
            body: <String, dynamic>{
              'session': sessionJson(),
              'user': userJson(),
            },
          );

          unawaited(
            c.setSession(session: session, user: User.fromJson(userJson())),
          );
          async.flushMicrotasks();

          // Dispose cancels the timer before it can fire.
          unawaited(c.dispose());

          final events = <AuthState>[];
          // Stream is closed; listening yields a done event but no data.
          c.onAuthStateChange.listen(events.add);

          async
            ..elapse(const Duration(minutes: 5))
            ..flushMicrotasks();

          expect(events, isEmpty);
        });
      });
    });
  });

  group(SessionSink, () {
    test('BetterAuthClient is a SessionSink', () {
      final test = buildTestClient();
      addTearDown(test.client.dispose);

      expect(test.client, isA<SessionSink>());
    });
  });

  group('Session.isExpired drives isAuthenticated', () {
    test(
      'isAuthenticated is false when the current session is expired',
      () async {
        final test = buildTestClient();
        final c = test.client;
        addTearDown(c.dispose);

        final session = Session.fromJson(
          sessionJson(expiresAt: '2030-01-01T00:00:00.000Z'),
        );
        await c.setSession(session: session, user: User.fromJson(userJson()));

        // Far-future "now" makes the session expired.
        final expired = withClock(
          Clock.fixed(DateTime.utc(2031)),
          () => c.isAuthenticated,
        );
        expect(expired, isFalse);
      },
    );
  });
}

/// Signs [client] in via `/sign-in/email`, stubbing both the sign-in route
/// (which surfaces the bearer token via the `set-auth-token` header) and the
/// `/get-session` hydrate that follows.
Future<void> _signIn(BetterAuthClient client, DioAdapter adapter) async {
  stubPost(
    adapter,
    '/sign-in/email',
    body: <String, dynamic>{
      'token': 'tok_123',
      'user': userJson(),
    },
    headers: <String, List<String>>{
      'set-auth-token': const ['tok_123'],
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
}
