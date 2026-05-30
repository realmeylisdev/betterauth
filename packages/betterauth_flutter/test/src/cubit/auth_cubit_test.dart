import 'dart:async';

import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(AuthCubitState, () {
    test('default constructor has unknown status and empty fields', () {
      const state = AuthCubitState();

      expect(state.status, AuthStatus.unknown);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.error, isNull);
      expect(state.twoFactorMethods, isEmpty);
      expect(state.isSubmitting, isFalse);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is true when status is authenticated', () {
      const state = AuthCubitState(status: AuthStatus.authenticated);

      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated is false when status is not authenticated', () {
      const state = AuthCubitState(status: AuthStatus.unauthenticated);

      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith replaces every field', () {
      const initial = AuthCubitState();
      final user = User.fromJson(userJson());
      final session = Session.fromJson(sessionJson());
      const error = AuthApiException('boom');

      final updated = initial.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        session: session,
        error: error,
        twoFactorMethods: const ['totp'],
        isSubmitting: true,
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.user, user);
      expect(updated.session, session);
      expect(updated.error, error);
      expect(updated.twoFactorMethods, const ['totp']);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith without arguments preserves all fields', () {
      final user = User.fromJson(userJson());
      final session = Session.fromJson(sessionJson());
      const error = AuthApiException('boom');
      final initial = AuthCubitState(
        status: AuthStatus.authenticated,
        user: user,
        session: session,
        error: error,
        twoFactorMethods: const ['totp'],
        isSubmitting: true,
      );

      final copy = initial.copyWith();

      expect(copy, initial);
    });

    test('copyWith with clearError true drops the error', () {
      const error = AuthApiException('boom');
      const initial = AuthCubitState(error: error);

      final cleared = initial.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith with clearError false keeps the existing error', () {
      const error = AuthApiException('boom');
      const initial = AuthCubitState(error: error);

      final kept = initial.copyWith();

      expect(kept.error, error);
    });

    test('copyWith with clearError true ignores a provided error', () {
      const initial = AuthCubitState();

      final cleared = initial.copyWith(
        error: const AuthApiException('boom'),
        clearError: true,
      );

      expect(cleared.error, isNull);
    });

    test('props equality holds for identical field values', () {
      const a = AuthCubitState(status: AuthStatus.unauthenticated);
      const b = AuthCubitState(status: AuthStatus.unauthenticated);

      expect(a, b);
      expect(a.props, b.props);
    });

    test('props inequality holds for differing field values', () {
      const a = AuthCubitState(status: AuthStatus.unauthenticated);
      const b = AuthCubitState(status: AuthStatus.authenticated);

      expect(a, isNot(b));
    });
  });

  group(AuthCubit, () {
    late TestClient h;

    setUp(() {
      h = buildTestClient();
    });

    void stubSession() {
      stubGet(
        h.adapter,
        '/get-session',
        body: <String, dynamic>{
          'session': sessionJson(),
          'user': userJson(),
        },
      );
    }

    void stubError(String path) {
      stubPost(
        h.adapter,
        path,
        status: 400,
        body: <String, dynamic>{'message': 'nope', 'code': 'BAD'},
      );
    }

    group('initial state', () {
      test('is unauthenticated when the client has no session', () {
        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        expect(cubit.state.status, AuthStatus.unauthenticated);
      });

      test('is authenticated when the client already has a session', () async {
        stubPost(
          h.adapter,
          '/sign-in/email',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        await h.client.signIn.email(email: 'ada@example.com', password: 'pw');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.session, isNotNull);
        expect(cubit.state.user, isNotNull);
      });
    });

    group('stream reactions', () {
      test('reflects a sign-in completed elsewhere', () async {
        stubPost(
          h.adapter,
          '/sign-in/email',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await h.client.signIn.email(email: 'ada@example.com', password: 'pw');
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.session, isNotNull);
      });

      test('reflects a local sign-out', () async {
        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await h.client.signOutLocally();
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.unauthenticated);
        expect(cubit.state.session, isNull);
      });
    });

    group('signUpEmail', () {
      test('becomes authenticated when a token is returned', () async {
        stubPost(
          h.adapter,
          '/sign-up/email',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signUpEmail(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
        expect(cubit.state.error, isNull);
      });

      test('sets isSubmitting true while in flight', () async {
        stubPost(
          h.adapter,
          '/sign-up/email',
          body: <String, dynamic>{'user': userJson()},
        );

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        unawaited(
          expectLater(
            cubit.stream,
            emitsThrough(
              predicate<AuthCubitState>((s) => s.isSubmitting),
            ),
          ),
        );

        await cubit.signUpEmail(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );
      });

      test('records the error on a 400 failure', () async {
        stubError('/sign-up/email');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signUpEmail(
          name: 'Ada',
          email: 'ada@example.com',
          password: 'pw',
        );

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
        expect(cubit.state.status, AuthStatus.unauthenticated);
      });
    });

    group('signInEmail', () {
      test('becomes authenticated on a SignedIn response', () async {
        stubPost(
          h.adapter,
          '/sign-in/email',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInEmail(email: 'ada@example.com', password: 'pw');
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('enters twoFactorRequired on a 2FA redirect', () async {
        stubPost(
          h.adapter,
          '/sign-in/email',
          body: <String, dynamic>{
            'twoFactorRedirect': true,
            'twoFactorMethods': <String>['totp'],
          },
        );

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInEmail(email: 'ada@example.com', password: 'pw');

        expect(cubit.state.status, AuthStatus.twoFactorRequired);
        expect(cubit.state.twoFactorMethods, const ['totp']);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/sign-in/email');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInEmail(email: 'ada@example.com', password: 'pw');

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('signInUsername', () {
      test('becomes authenticated on success', () async {
        stubPost(
          h.adapter,
          '/sign-in/username',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInUsername(username: 'ada', password: 'pw');
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/sign-in/username');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInUsername(username: 'ada', password: 'pw');

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('signInEmailOtp', () {
      test('becomes authenticated on success', () async {
        stubPost(
          h.adapter,
          '/sign-in/email-otp',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInEmailOtp(email: 'ada@example.com', otp: '123456');
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/sign-in/email-otp');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInEmailOtp(email: 'ada@example.com', otp: '000000');

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('signInAnonymously', () {
      test('becomes authenticated on success', () async {
        stubPost(
          h.adapter,
          '/sign-in/anonymous',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInAnonymously();
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/sign-in/anonymous');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signInAnonymously();

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('verifyTotp', () {
      test('becomes authenticated on success', () async {
        stubPost(
          h.adapter,
          '/two-factor/verify-totp',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.verifyTotp(code: '123456', trustDevice: true);
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/two-factor/verify-totp');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.verifyTotp(code: '000000');

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('verifyTwoFactorOtp', () {
      test('becomes authenticated on success', () async {
        stubPost(
          h.adapter,
          '/two-factor/verify-otp',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.verifyTwoFactorOtp(code: '123456', trustDevice: false);
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });

      test('records the error on a 400 failure', () async {
        stubError('/two-factor/verify-otp');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.verifyTwoFactorOtp(code: '000000');

        expect(cubit.state.error, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('signOut', () {
      test('becomes unauthenticated and clears isSubmitting', () async {
        stubPost(
          h.adapter,
          '/sign-in/email',
          headers: <String, List<String>>{
            'set-auth-token': const ['tok'],
          },
          body: <String, dynamic>{'token': 'tok', 'user': userJson()},
        );
        stubSession();
        stubPost(
          h.adapter,
          '/sign-out',
          body: <String, dynamic>{'success': true},
        );

        await h.client.signIn.email(email: 'ada@example.com', password: 'pw');

        final cubit = AuthCubit(h.client);
        addTearDown(cubit.close);

        await cubit.signOut();
        await pumpEventQueue();

        expect(cubit.state.status, AuthStatus.unauthenticated);
        expect(cubit.state.isSubmitting, isFalse);
      });
    });

    group('close', () {
      test('cancels the subscription so later events are ignored', () async {
        final cubit = AuthCubit(h.client);

        await cubit.close();

        // Emitting on the client after close must not throw.
        await h.client.signOutLocally();
        await pumpEventQueue();

        expect(cubit.isClosed, isTrue);
      });
    });
  });
}
