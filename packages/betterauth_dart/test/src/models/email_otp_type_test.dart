import 'package:betterauth_dart/src/models/email_otp_type.dart';
import 'package:test/test.dart';

void main() {
  group(EmailOtpType, () {
    test('signIn has the expected wire value', () {
      expect(EmailOtpType.signIn.wire, equals('sign-in'));
    });

    test('emailVerification has the expected wire value', () {
      expect(EmailOtpType.emailVerification.wire, equals('email-verification'));
    });

    test('forgetPassword has the expected wire value', () {
      expect(EmailOtpType.forgetPassword.wire, equals('forget-password'));
    });

    test('exposes exactly three values', () {
      expect(EmailOtpType.values, hasLength(3));
      expect(
        EmailOtpType.values,
        equals(<EmailOtpType>[
          EmailOtpType.signIn,
          EmailOtpType.emailVerification,
          EmailOtpType.forgetPassword,
        ]),
      );
    });
  });
}
