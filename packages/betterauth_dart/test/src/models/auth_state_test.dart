// const constructors run before the tests execute, which can break coverage
// of the constructor bodies, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/models/auth_change_event.dart';
import 'package:betterauth_dart/src/models/auth_state.dart';
import 'package:betterauth_dart/src/models/session.dart';
import 'package:betterauth_dart/src/models/user.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(AuthState, () {
    late Session session;
    late User user;

    setUp(() {
      session = Session.fromJson(sessionJson());
      user = User.fromJson(userJson());
    });

    test('isAuthenticated is true when session is present', () {
      final state = AuthState(
        AuthChangeEvent.signedIn,
        session: session,
        user: user,
      );
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated is false when session is null', () {
      final state = AuthState(AuthChangeEvent.signedOut);
      expect(state.isAuthenticated, isFalse);
      expect(state.session, isNull);
      expect(state.user, isNull);
    });

    test('props reflect equality', () {
      final a = AuthState(
        AuthChangeEvent.signedIn,
        session: session,
        user: user,
      );
      final b = AuthState(
        AuthChangeEvent.signedIn,
        session: session,
        user: user,
      );
      expect(a, equals(b));
      expect(
        a.props,
        equals(<Object?>[AuthChangeEvent.signedIn, session, user]),
      );
    });

    test('differs when event differs', () {
      expect(
        AuthState(AuthChangeEvent.signedIn),
        isNot(equals(AuthState(AuthChangeEvent.signedOut))),
      );
    });

    test('toString reports event and authenticated when authenticated', () {
      final state = AuthState(
        AuthChangeEvent.initialSession,
        session: session,
        user: user,
      );
      expect(
        state.toString(),
        equals(
          'AuthState(event: AuthChangeEvent.initialSession, '
          'authenticated: true)',
        ),
      );
    });

    test('toString reports authenticated false when no session', () {
      final state = AuthState(AuthChangeEvent.signedOut);
      expect(
        state.toString(),
        equals(
          'AuthState(event: AuthChangeEvent.signedOut, authenticated: false)',
        ),
      );
    });
  });
}
