// const constructors run before the tests execute, which can break coverage
// of the constructor bodies, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';
import 'package:test/test.dart';

void main() {
  group(AuthSuccess, () {
    late AuthResult<int> result;

    setUp(() {
      result = AuthSuccess<int>(42);
    });

    test('isSuccess is true and isFailure is false', () {
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('dataOrNull returns the data', () {
      expect(result.dataOrNull, equals(42));
    });

    test('errorOrNull returns null', () {
      expect(result.errorOrNull, isNull);
    });

    test('when invokes the success arm with the data', () {
      final folded = result.when(
        success: (data) => 'ok:$data',
        failure: (error) => 'err:$error',
      );
      expect(folded, equals('ok:42'));
    });

    test('map transforms the success data', () {
      final mapped = result.map((data) => data.toString());

      expect(mapped, isA<AuthSuccess<String>>());
      expect(mapped.dataOrNull, equals('42'));
    });

    test('equal instances compare equal and share a hashCode', () {
      final other = AuthSuccess<int>(42);
      expect(result, equals(other));
      expect(result.hashCode, equals(other.hashCode));
    });

    test('is equal to itself (identical short-circuit)', () {
      expect(result == result, isTrue);
    });

    test('differing data compares unequal', () {
      expect(result, isNot(equals(AuthSuccess<int>(7))));
    });

    test('is not equal to a non-AuthSuccess value', () {
      const Object other = 42;
      expect(result == other, isFalse);
    });

    test('toString includes the type and data', () {
      expect(result.toString(), equals('AuthSuccess<int>(42)'));
    });
  });

  group(AuthFailure, () {
    late AuthException error;
    late AuthResult<int> result;

    setUp(() {
      error = AuthApiException('boom', code: AuthErrorCode.invalidEmail);
      result = AuthFailure<int>(error);
    });

    test('isSuccess is false and isFailure is true', () {
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test('dataOrNull returns null', () {
      expect(result.dataOrNull, isNull);
    });

    test('errorOrNull returns the error', () {
      expect(result.errorOrNull, same(error));
    });

    test('when invokes the failure arm with the error', () {
      final folded = result.when(
        success: (data) => 'ok:$data',
        failure: (e) => 'err:${e.message}',
      );
      expect(folded, equals('err:boom'));
    });

    test('map passes the failure through unchanged with the new type', () {
      final mapped = result.map((data) => data.toString());

      expect(mapped, isA<AuthFailure<String>>());
      expect(mapped.errorOrNull, same(error));
    });

    test('equal instances compare equal and share a hashCode', () {
      final other = AuthFailure<int>(
        AuthApiException('boom', code: AuthErrorCode.invalidEmail),
      );
      expect(result, equals(other));
      expect(result.hashCode, equals(other.hashCode));
    });

    test('is equal to itself (identical short-circuit)', () {
      expect(result == result, isTrue);
    });

    test('differing error compares unequal', () {
      final other = AuthFailure<int>(AuthApiException('other'));
      expect(result, isNot(equals(other)));
    });

    test('is not equal to a non-AuthFailure value', () {
      const Object other = 'nope';
      expect(result == other, isFalse);
    });

    test('toString includes the type and error', () {
      expect(result.toString(), contains('AuthFailure<int>('));
      expect(result.toString(), contains('boom'));
    });
  });
}
