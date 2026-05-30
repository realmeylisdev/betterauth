// const constructors run before the tests execute, which can break coverage
// of the constructor bodies, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/models/id_token.dart';
import 'package:test/test.dart';

void main() {
  group(IdToken, () {
    group('toJson', () {
      test('includes only the token when optional fields are null', () {
        final idToken = IdToken(token: 'jwt');
        expect(idToken.toJson(), equals(<String, dynamic>{'token': 'jwt'}));
      });

      test('includes every field when all are provided', () {
        final idToken = IdToken(
          token: 'jwt',
          nonce: 'n',
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: 123,
        );
        expect(
          idToken.toJson(),
          equals(<String, dynamic>{
            'token': 'jwt',
            'nonce': 'n',
            'accessToken': 'at',
            'refreshToken': 'rt',
            'expiresAt': 123,
          }),
        );
      });
    });

    test('props reflect equality', () {
      final a = IdToken(
        token: 'jwt',
        nonce: 'n',
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: 123,
      );
      final b = IdToken(
        token: 'jwt',
        nonce: 'n',
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: 123,
      );
      expect(a, equals(b));
      expect(
        a.props,
        equals(<Object?>['jwt', 'n', 'at', 'rt', 123]),
      );
    });

    test('differs when a field differs', () {
      expect(
        IdToken(token: 'a'),
        isNot(equals(IdToken(token: 'b'))),
      );
    });
  });
}
