import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:test/test.dart';

void main() {
  group(AuthApiException, () {
    test('exposes the supplied fields', () {
      const exception = AuthApiException(
        'bad request',
        statusCode: 400,
        code: AuthErrorCode.invalidEmailOrPassword,
        rawCode: 'INVALID_EMAIL_OR_PASSWORD',
        details: {'extra': 'info'},
      );

      expect(exception.message, equals('bad request'));
      expect(exception.statusCode, equals(400));
      expect(exception.code, equals(AuthErrorCode.invalidEmailOrPassword));
      expect(exception.rawCode, equals('INVALID_EMAIL_OR_PASSWORD'));
      expect(exception.details, equals({'extra': 'info'}));
    });

    test('defaults code to unknown when omitted', () {
      const exception = AuthApiException('boom');

      expect(exception.code, equals(AuthErrorCode.unknown));
      expect(exception.statusCode, isNull);
      expect(exception.rawCode, isNull);
      expect(exception.details, isNull);
    });

    test('is an Exception', () {
      const exception = AuthApiException('boom');
      expect(exception, isA<Exception>());
    });

    test('equal instances compare equal and share a hashCode', () {
      const a = AuthApiException('boom', statusCode: 400);
      const b = AuthApiException('boom', statusCode: 400);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing instances compare unequal', () {
      const a = AuthApiException('boom', statusCode: 400);
      const b = AuthApiException('boom', statusCode: 401);

      expect(a, isNot(equals(b)));
    });

    test('toString contains the message via stringify', () {
      const exception = AuthApiException('boom', statusCode: 400);
      expect(exception.toString(), contains('boom'));
      expect(exception.toString(), contains('400'));
    });
  });

  group(AuthRetryableFetchException, () {
    test('exposes the supplied fields', () {
      const exception = AuthRetryableFetchException(
        'network down',
        statusCode: 500,
        code: AuthErrorCode.unexpectedError,
        rawCode: 'UNEXPECTED_ERROR',
        details: {'tries': 3},
      );

      expect(exception.message, equals('network down'));
      expect(exception.statusCode, equals(500));
      expect(exception.code, equals(AuthErrorCode.unexpectedError));
      expect(exception.rawCode, equals('UNEXPECTED_ERROR'));
      expect(exception.details, equals({'tries': 3}));
    });

    test('defaults code to unknown when omitted', () {
      const exception = AuthRetryableFetchException('timeout');
      expect(exception.code, equals(AuthErrorCode.unknown));
    });

    test('equal instances compare equal', () {
      const a = AuthRetryableFetchException('timeout');
      const b = AuthRetryableFetchException('timeout');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString contains the message', () {
      const exception = AuthRetryableFetchException('timeout');
      expect(exception.toString(), contains('timeout'));
    });
  });

  group(AuthSessionMissingException, () {
    test('uses the default message, 401 status, and sessionExpired code', () {
      const exception = AuthSessionMissingException();

      expect(exception.message, equals('No active session.'));
      expect(exception.statusCode, equals(401));
      expect(exception.code, equals(AuthErrorCode.sessionExpired));
      expect(exception.rawCode, isNull);
      expect(exception.details, isNull);
    });

    test('accepts a custom message while keeping status and code', () {
      const exception = AuthSessionMissingException('gone');

      expect(exception.message, equals('gone'));
      expect(exception.statusCode, equals(401));
      expect(exception.code, equals(AuthErrorCode.sessionExpired));
    });

    test('equal instances compare equal', () {
      const a = AuthSessionMissingException();
      const b = AuthSessionMissingException();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString contains the message', () {
      const exception = AuthSessionMissingException();
      expect(exception.toString(), contains('No active session.'));
    });
  });

  group(AuthUnknownException, () {
    test('exposes the supplied fields including originalError', () {
      final cause = Exception('root cause');
      final exception = AuthUnknownException(
        'something odd',
        originalError: cause,
        statusCode: 502,
      );

      expect(exception.message, equals('something odd'));
      expect(exception.statusCode, equals(502));
      expect(exception.code, equals(AuthErrorCode.unknown));
      expect(exception.originalError, same(cause));
    });

    test('includes originalError in props for equality', () {
      const cause = 'cause';
      const a = AuthUnknownException('odd', originalError: cause);
      const b = AuthUnknownException('odd', originalError: cause);
      const c = AuthUnknownException('odd', originalError: 'other');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString contains the message and original error', () {
      const exception = AuthUnknownException('odd', originalError: 'cause');
      expect(exception.toString(), contains('odd'));
      expect(exception.toString(), contains('cause'));
    });
  });

  group('cross-subtype distinction', () {
    test('subtypes with identical fields are not equal (runtimeType)', () {
      const api = AuthApiException(
        'boom',
        statusCode: 401,
        code: AuthErrorCode.sessionExpired,
      );
      const session = AuthSessionMissingException('boom');

      // Both share message/statusCode/code/rawCode/details, but Equatable
      // distinguishes by runtimeType.
      expect(api.props, equals(session.props));
      expect(api, isNot(equals(session)));
    });

    test('retryable and api with identical fields are not equal', () {
      const api = AuthApiException('boom');
      const retryable = AuthRetryableFetchException('boom');

      expect(api.props, equals(retryable.props));
      expect(api, isNot(equals(retryable)));
    });
  });
}
