import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:test/test.dart';

void main() {
  group(AuthErrorCode, () {
    group('fromWire', () {
      test('returns userNotFound for USER_NOT_FOUND', () {
        expect(
          AuthErrorCode.fromWire('USER_NOT_FOUND'),
          equals(AuthErrorCode.userNotFound),
        );
      });

      test('returns invalidEmailOrPassword for INVALID_EMAIL_OR_PASSWORD', () {
        expect(
          AuthErrorCode.fromWire('INVALID_EMAIL_OR_PASSWORD'),
          equals(AuthErrorCode.invalidEmailOrPassword),
        );
      });

      test('returns sessionExpired for SESSION_EXPIRED', () {
        expect(
          AuthErrorCode.fromWire('SESSION_EXPIRED'),
          equals(AuthErrorCode.sessionExpired),
        );
      });

      test('returns invalidOtp for INVALID_OTP (email otp group)', () {
        expect(
          AuthErrorCode.fromWire('INVALID_OTP'),
          equals(AuthErrorCode.invalidOtp),
        );
      });

      test(
        'returns invalidPhoneNumber for INVALID_PHONE_NUMBER (phone group)',
        () {
          expect(
            AuthErrorCode.fromWire('INVALID_PHONE_NUMBER'),
            equals(AuthErrorCode.invalidPhoneNumber),
          );
        },
      );

      test('returns usernameIsAlreadyTaken for USERNAME_IS_ALREADY_TAKEN', () {
        expect(
          AuthErrorCode.fromWire('USERNAME_IS_ALREADY_TAKEN'),
          equals(AuthErrorCode.usernameIsAlreadyTaken),
        );
      });

      test(
        'returns totpNotEnabled for TOTP_NOT_ENABLED (two factor group)',
        () {
          expect(
            AuthErrorCode.fromWire('TOTP_NOT_ENABLED'),
            equals(AuthErrorCode.totpNotEnabled),
          );
        },
      );

      test('returns oauthLinkError for OAUTH_LINK_ERROR (inline group)', () {
        expect(
          AuthErrorCode.fromWire('OAUTH_LINK_ERROR'),
          equals(AuthErrorCode.oauthLinkError),
        );
      });

      test('returns unknown for null', () {
        expect(AuthErrorCode.fromWire(null), equals(AuthErrorCode.unknown));
      });

      test('returns unknown for an unrecognised string', () {
        expect(
          AuthErrorCode.fromWire('NOT_A_REAL_CODE'),
          equals(AuthErrorCode.unknown),
        );
      });

      test('returns unknown for an empty string', () {
        expect(AuthErrorCode.fromWire(''), equals(AuthErrorCode.unknown));
      });

      test('is case-sensitive and returns unknown for lowercase input', () {
        expect(
          AuthErrorCode.fromWire('user_not_found'),
          equals(AuthErrorCode.unknown),
        );
      });

      test(
        'returns organizationNotFound for ORGANIZATION_NOT_FOUND (org group)',
        () {
          expect(
            AuthErrorCode.fromWire('ORGANIZATION_NOT_FOUND'),
            equals(AuthErrorCode.organizationNotFound),
          );
        },
      );

      test(
        'returns userIsNotAnonymous for USER_IS_NOT_ANONYMOUS (anon group)',
        () {
          expect(
            AuthErrorCode.fromWire('USER_IS_NOT_ANONYMOUS'),
            equals(AuthErrorCode.userIsNotAnonymous),
          );
        },
      );

      test(
        'returns challengeNotFound for CHALLENGE_NOT_FOUND (passkey group)',
        () {
          expect(
            AuthErrorCode.fromWire('CHALLENGE_NOT_FOUND'),
            equals(AuthErrorCode.challengeNotFound),
          );
        },
      );
    });

    group('wire', () {
      test('round-trips fromWire for every enum value', () {
        for (final code in AuthErrorCode.values) {
          expect(
            AuthErrorCode.fromWire(code.wire),
            equals(code),
            reason: 'wire round-trip failed for $code (${code.wire})',
          );
        }
      });

      test('exposes the documented uppercase wire string', () {
        expect(AuthErrorCode.unknown.wire, equals('UNKNOWN'));
        expect(AuthErrorCode.userNotFound.wire, equals('USER_NOT_FOUND'));
      });

      test('exposes wire strings for the newly covered codes', () {
        expect(
          AuthErrorCode.organizationNotFound.wire,
          equals('ORGANIZATION_NOT_FOUND'),
        );
        expect(
          AuthErrorCode.userIsNotAnonymous.wire,
          equals('USER_IS_NOT_ANONYMOUS'),
        );
        expect(
          AuthErrorCode.challengeNotFound.wire,
          equals('CHALLENGE_NOT_FOUND'),
        );
      });

      test('round-trips the newly covered codes through fromWire', () {
        for (final code in <AuthErrorCode>[
          AuthErrorCode.organizationNotFound,
          AuthErrorCode.userIsNotAnonymous,
          AuthErrorCode.challengeNotFound,
        ]) {
          expect(AuthErrorCode.fromWire(code.wire), equals(code));
        }
      });
    });

    test('every enum value has a distinct wire string', () {
      final wires = AuthErrorCode.values.map((c) => c.wire).toSet();
      expect(wires, hasLength(AuthErrorCode.values.length));
    });
  });
}
