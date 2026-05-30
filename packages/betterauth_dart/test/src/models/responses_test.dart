// const constructors run before the tests execute, which can break coverage
// of the constructor bodies, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/models/responses.dart';
import 'package:betterauth_dart/src/models/session.dart';
import 'package:betterauth_dart/src/models/user.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(StatusResponse, () {
    test('uses status when present and true', () {
      final response = StatusResponse.fromJson(const <String, dynamic>{
        'status': true,
        'message': 'done',
      });
      expect(response.ok, isTrue);
      expect(response.message, equals('done'));
    });

    test('uses status when present and false', () {
      final response = StatusResponse.fromJson(const <String, dynamic>{
        'status': false,
      });
      expect(response.ok, isFalse);
      expect(response.message, isNull);
    });

    test('falls back to success when status absent', () {
      final response = StatusResponse.fromJson(const <String, dynamic>{
        'success': true,
      });
      expect(response.ok, isTrue);
    });

    test('uses success false when status absent', () {
      final response = StatusResponse.fromJson(const <String, dynamic>{
        'success': false,
      });
      expect(response.ok, isFalse);
    });

    test('defaults ok to true when neither status nor success present', () {
      final response = StatusResponse.fromJson(const <String, dynamic>{});
      expect(response.ok, isTrue);
      expect(response.message, isNull);
    });

    test('props reflect equality', () {
      expect(
        StatusResponse(ok: true, message: 'm'),
        equals(StatusResponse(ok: true, message: 'm')),
      );
      expect(
        StatusResponse(ok: true),
        isNot(equals(StatusResponse(ok: false))),
      );
      expect(StatusResponse(ok: true).props, equals(<Object?>[true, null]));
    });
  });

  group(SessionResponse, () {
    test('parses session and user', () {
      final response = SessionResponse.fromJson(<String, dynamic>{
        'session': sessionJson(),
        'user': userJson(),
      });
      expect(response.session, isA<Session>());
      expect(response.user, isA<User>());
      expect(response.session.token, equals('tok_123'));
      expect(response.user.id, equals('user_1'));
    });

    test('props reflect equality', () {
      final a = SessionResponse.fromJson(<String, dynamic>{
        'session': sessionJson(),
        'user': userJson(),
      });
      final b = SessionResponse.fromJson(<String, dynamic>{
        'session': sessionJson(),
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.session, a.user]));
    });
  });

  group(AuthSession, () {
    test('parses token and user', () {
      final response = AuthSession.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(response.token, equals('tok'));
      expect(response.user.id, equals('user_1'));
    });

    test('props reflect equality', () {
      final a = AuthSession.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = AuthSession.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.token, a.user]));
    });
  });

  group(SignUpResponse, () {
    test('hasSession is true when token present', () {
      final response = SignUpResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(response.token, equals('tok'));
      expect(response.hasSession, isTrue);
    });

    test('hasSession is false when token absent', () {
      final response = SignUpResponse.fromJson(<String, dynamic>{
        'user': userJson(),
      });
      expect(response.token, isNull);
      expect(response.hasSession, isFalse);
    });

    test('props reflect equality', () {
      final a = SignUpResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = SignUpResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.token, a.user]));
    });
  });

  group(SignInResponse, () {
    group('fromJson', () {
      test('dispatches to SignedIn when not twoFactorRedirect', () {
        final response = SignInResponse.fromJson(<String, dynamic>{
          'token': 'tok',
          'user': userJson(),
        });
        expect(response, isA<SignedIn>());
        final signedIn = response as SignedIn;
        expect(signedIn.token, equals('tok'));
        expect(signedIn.user.id, equals('user_1'));
      });

      test('dispatches to TwoFactorRequired when twoFactorRedirect true', () {
        final response = SignInResponse.fromJson(const <String, dynamic>{
          'twoFactorRedirect': true,
          'twoFactorMethods': <dynamic>['totp', 'otp'],
        });
        expect(response, isA<TwoFactorRequired>());
        final challenge = response as TwoFactorRequired;
        expect(challenge.methods, equals(<String>['totp', 'otp']));
      });

      test('TwoFactorRequired methods default to empty when absent', () {
        final response = SignInResponse.fromJson(const <String, dynamic>{
          'twoFactorRedirect': true,
        });
        expect(response, isA<TwoFactorRequired>());
        expect((response as TwoFactorRequired).methods, isEmpty);
      });
    });

    test('SignedIn props reflect equality', () {
      final a =
          SignInResponse.fromJson(<String, dynamic>{
                'token': 'tok',
                'user': userJson(),
              })
              as SignedIn;
      final b =
          SignInResponse.fromJson(<String, dynamic>{
                'token': 'tok',
                'user': userJson(),
              })
              as SignedIn;
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.token, a.user]));
    });

    test('TwoFactorRequired props reflect equality', () {
      final a = TwoFactorRequired(methods: const ['totp']);
      final b = TwoFactorRequired(methods: const ['totp']);
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.methods]));
      expect(TwoFactorRequired().methods, isEmpty);
    });
  });

  group(SocialSignInResponse, () {
    group('fromJson', () {
      test('dispatches to SocialRedirect when redirect true', () {
        final response = SocialSignInResponse.fromJson(const <String, dynamic>{
          'redirect': true,
          'url': 'https://example.com/auth',
        });
        expect(response, isA<SocialRedirect>());
        expect(
          (response as SocialRedirect).url,
          equals('https://example.com/auth'),
        );
      });

      test('dispatches to SocialSignedIn when redirect false', () {
        final response = SocialSignInResponse.fromJson(<String, dynamic>{
          'redirect': false,
          'token': 'tok',
          'user': userJson(),
        });
        expect(response, isA<SocialSignedIn>());
        final signedIn = response as SocialSignedIn;
        expect(signedIn.token, equals('tok'));
        expect(signedIn.user.id, equals('user_1'));
      });

      test('dispatches to SocialSignedIn when redirect absent', () {
        final response = SocialSignInResponse.fromJson(<String, dynamic>{
          'token': 'tok',
          'user': userJson(),
        });
        expect(response, isA<SocialSignedIn>());
      });
    });

    test('SocialRedirect props reflect equality', () {
      final a = SocialRedirect(url: 'u');
      final b = SocialRedirect(url: 'u');
      expect(a, equals(b));
      expect(a.props, equals(<Object?>['u']));
    });

    test('SocialSignedIn props reflect equality', () {
      final a = SocialSignInResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = SocialSignInResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      final signedIn = a as SocialSignedIn;
      expect(signedIn.props, equals(<Object?>[signedIn.token, signedIn.user]));
    });
  });

  group(ChangePasswordResponse, () {
    test('parses token and user when token present', () {
      final response = ChangePasswordResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(response.token, equals('tok'));
      expect(response.user.id, equals('user_1'));
    });

    test('token is null when absent', () {
      final response = ChangePasswordResponse.fromJson(<String, dynamic>{
        'user': userJson(),
      });
      expect(response.token, isNull);
    });

    test('props reflect equality', () {
      final a = ChangePasswordResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = ChangePasswordResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.token, a.user]));
    });
  });

  group(VerifyEmailResponse, () {
    test('parses ok and user when user is a Map', () {
      final response = VerifyEmailResponse.fromJson(<String, dynamic>{
        'status': true,
        'user': userJson(),
      });
      expect(response.ok, isTrue);
      expect(response.user, isA<User>());
      expect(response.user!.id, equals('user_1'));
    });

    test('user is null when absent', () {
      final response = VerifyEmailResponse.fromJson(const <String, dynamic>{
        'status': false,
      });
      expect(response.ok, isFalse);
      expect(response.user, isNull);
    });

    test('user is null when not a Map', () {
      final response = VerifyEmailResponse.fromJson(const <String, dynamic>{
        'user': 'not-a-map',
      });
      expect(response.user, isNull);
    });

    test('ok defaults to true when status absent', () {
      final response = VerifyEmailResponse.fromJson(const <String, dynamic>{});
      expect(response.ok, isTrue);
    });

    test('props reflect equality', () {
      final a = VerifyEmailResponse.fromJson(<String, dynamic>{
        'status': true,
        'user': userJson(),
      });
      final b = VerifyEmailResponse.fromJson(<String, dynamic>{
        'status': true,
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.ok, a.user]));
    });
  });

  group(EmailOtpVerifyResponse, () {
    test('parses ok, token and user when token present', () {
      final response = EmailOtpVerifyResponse.fromJson(<String, dynamic>{
        'status': true,
        'token': 'tok',
        'user': userJson(),
      });
      expect(response.ok, isTrue);
      expect(response.token, equals('tok'));
      expect(response.user.id, equals('user_1'));
    });

    test('token is null when absent', () {
      final response = EmailOtpVerifyResponse.fromJson(<String, dynamic>{
        'user': userJson(),
      });
      expect(response.token, isNull);
      expect(response.ok, isTrue);
    });

    test('ok reflects explicit false status', () {
      final response = EmailOtpVerifyResponse.fromJson(<String, dynamic>{
        'status': false,
        'user': userJson(),
      });
      expect(response.ok, isFalse);
    });

    test('props reflect equality', () {
      final a = EmailOtpVerifyResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = EmailOtpVerifyResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.ok, a.token, a.user]));
    });
  });

  group(PhoneVerifyResponse, () {
    test('parses ok, token and user when user is a Map', () {
      final response = PhoneVerifyResponse.fromJson(<String, dynamic>{
        'status': true,
        'token': 'tok',
        'user': userJson(),
      });
      expect(response.ok, isTrue);
      expect(response.token, equals('tok'));
      expect(response.user, isA<User>());
      expect(response.user!.id, equals('user_1'));
    });

    test('user and token are null when absent', () {
      final response = PhoneVerifyResponse.fromJson(const <String, dynamic>{
        'status': true,
      });
      expect(response.user, isNull);
      expect(response.token, isNull);
    });

    test('user is null when not a Map', () {
      final response = PhoneVerifyResponse.fromJson(const <String, dynamic>{
        'user': 42,
      });
      expect(response.user, isNull);
    });

    test('ok defaults to true when status absent', () {
      final response = PhoneVerifyResponse.fromJson(const <String, dynamic>{});
      expect(response.ok, isTrue);
    });

    test('props reflect equality', () {
      final a = PhoneVerifyResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      final b = PhoneVerifyResponse.fromJson(<String, dynamic>{
        'token': 'tok',
        'user': userJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.ok, a.token, a.user]));
    });
  });

  group(TwoFactorEnableResponse, () {
    test('parses totpUri and backupCodes when present', () {
      final response = TwoFactorEnableResponse.fromJson(const <String, dynamic>{
        'totpURI': 'otpauth://x',
        'backupCodes': <dynamic>['a', 'b'],
      });
      expect(response.totpUri, equals('otpauth://x'));
      expect(response.backupCodes, equals(<String>['a', 'b']));
    });

    test('backupCodes defaults to empty when absent', () {
      final response = TwoFactorEnableResponse.fromJson(const <String, dynamic>{
        'totpURI': 'otpauth://x',
      });
      expect(response.backupCodes, isEmpty);
    });

    test('props reflect equality', () {
      final a = TwoFactorEnableResponse.fromJson(const <String, dynamic>{
        'totpURI': 'otpauth://x',
        'backupCodes': <dynamic>['a'],
      });
      final b = TwoFactorEnableResponse.fromJson(const <String, dynamic>{
        'totpURI': 'otpauth://x',
        'backupCodes': <dynamic>['a'],
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.totpUri, a.backupCodes]));
    });
  });

  group(TotpUriResponse, () {
    test('parses totpUri', () {
      final response = TotpUriResponse.fromJson(const <String, dynamic>{
        'totpURI': 'otpauth://x',
      });
      expect(response.totpUri, equals('otpauth://x'));
    });

    test('props reflect equality', () {
      final a = TotpUriResponse(totpUri: 'u');
      final b = TotpUriResponse(totpUri: 'u');
      expect(a, equals(b));
      expect(a.props, equals(<Object?>['u']));
    });
  });

  group(BackupCodesResponse, () {
    test('parses ok and backupCodes when present', () {
      final response = BackupCodesResponse.fromJson(const <String, dynamic>{
        'status': true,
        'backupCodes': <dynamic>['a', 'b'],
      });
      expect(response.ok, isTrue);
      expect(response.backupCodes, equals(<String>['a', 'b']));
    });

    test('ok defaults to true and backupCodes to empty when absent', () {
      final response = BackupCodesResponse.fromJson(const <String, dynamic>{});
      expect(response.ok, isTrue);
      expect(response.backupCodes, isEmpty);
    });

    test('ok reflects explicit false status', () {
      final response = BackupCodesResponse.fromJson(const <String, dynamic>{
        'status': false,
      });
      expect(response.ok, isFalse);
    });

    test('props reflect equality', () {
      final a = BackupCodesResponse.fromJson(const <String, dynamic>{
        'backupCodes': <dynamic>['a'],
      });
      final b = BackupCodesResponse.fromJson(const <String, dynamic>{
        'backupCodes': <dynamic>['a'],
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.ok, a.backupCodes]));
    });
  });

  group(VerifyBackupCodeResponse, () {
    test('parses user and session when session is a Map', () {
      final response = VerifyBackupCodeResponse.fromJson(<String, dynamic>{
        'user': userJson(),
        'session': sessionJson(),
      });
      expect(response.user.id, equals('user_1'));
      expect(response.session, isA<Session>());
      expect(response.session!.token, equals('tok_123'));
    });

    test('session is null when absent', () {
      final response = VerifyBackupCodeResponse.fromJson(<String, dynamic>{
        'user': userJson(),
      });
      expect(response.session, isNull);
    });

    test('session is null when not a Map', () {
      final response = VerifyBackupCodeResponse.fromJson(<String, dynamic>{
        'user': userJson(),
        'session': 'nope',
      });
      expect(response.session, isNull);
    });

    test('props reflect equality', () {
      final a = VerifyBackupCodeResponse.fromJson(<String, dynamic>{
        'user': userJson(),
        'session': sessionJson(),
      });
      final b = VerifyBackupCodeResponse.fromJson(<String, dynamic>{
        'user': userJson(),
        'session': sessionJson(),
      });
      expect(a, equals(b));
      expect(a.props, equals(<Object?>[a.user, a.session]));
    });
  });
}
