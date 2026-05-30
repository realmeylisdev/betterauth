import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:betterauth_dart/src/constants.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';

void main() {
  group(Session, () {
    late Session session;

    setUp(() {
      session = Session(
        id: 'sess_1',
        userId: 'user_1',
        token: 'tok_123',
        expiresAt: DateTime.utc(2027),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
        ipAddress: '127.0.0.1',
        userAgent: 'test',
        additionalFields: const {'plan': 'pro'},
      );
    });

    group('fromJson', () {
      test('parses a full JSON map', () {
        final json = <String, dynamic>{
          'id': 'sess_1',
          'userId': 'user_1',
          'token': 'tok_123',
          'expiresAt': '2027-01-01T00:00:00.000Z',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'ipAddress': '127.0.0.1',
          'userAgent': 'test',
        };

        final result = Session.fromJson(json);

        expect(result.id, equals('sess_1'));
        expect(result.userId, equals('user_1'));
        expect(result.token, equals('tok_123'));
        expect(result.expiresAt, equals(DateTime.utc(2027)));
        expect(result.createdAt, equals(DateTime.utc(2026)));
        expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
        expect(result.ipAddress, equals('127.0.0.1'));
        expect(result.userAgent, equals('test'));
        expect(result.additionalFields, isEmpty);
      });

      test('parses a trimmed JSON map with nullable fields absent', () {
        final json = <String, dynamic>{
          'userId': 'user_1',
          'token': 'tok_123',
          'expiresAt': '2027-01-01T00:00:00.000Z',
        };

        final result = Session.fromJson(json);

        expect(result.id, isNull);
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
        expect(result.ipAddress, isNull);
        expect(result.userAgent, isNull);
        expect(result.additionalFields, isEmpty);
      });

      test('captures unmodelled keys in additionalFields', () {
        final json = <String, dynamic>{
          'userId': 'user_1',
          'token': 'tok_123',
          'expiresAt': '2027-01-01T00:00:00.000Z',
          'plan': 'pro',
        };

        expect(
          Session.fromJson(json).additionalFields,
          equals(<String, Object?>{'plan': 'pro'}),
        );
      });

      test('throws when expiresAt is missing', () {
        final json = <String, dynamic>{
          'userId': 'user_1',
          'token': 'tok_123',
        };

        expect(
          () => Session.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('isExpired', () {
      test('is false when expiry is well in the future', () {
        withClock(Clock.fixed(DateTime.utc(2026, 6)), () {
          expect(session.isExpired, isFalse);
        });
      });

      test('is true when expiry is in the past', () {
        withClock(Clock.fixed(DateTime.utc(2028)), () {
          expect(session.isExpired, isTrue);
        });
      });

      test('is true exactly at the expiry margin boundary', () {
        // now == expiresAt - margin, and isAfter is strictly greater, so the
        // exact boundary is treated as NOT expired.
        final boundary = session.expiresAt.subtract(kExpiryMargin);
        withClock(Clock.fixed(boundary), () {
          expect(session.isExpired, isFalse);
        });
      });

      test('is true one microsecond past the expiry margin boundary', () {
        final boundary = session.expiresAt.subtract(kExpiryMargin);
        withClock(
          Clock.fixed(boundary.add(const Duration(microseconds: 1))),
          () {
            expect(session.isExpired, isTrue);
          },
        );
      });

      test('uses the margin: just inside the margin window is expired', () {
        // now is within the last 30s before expiresAt, so margin makes it
        // expired even though raw expiresAt has not yet passed.
        final justBeforeExpiry = session.expiresAt.subtract(
          const Duration(seconds: 10),
        );
        withClock(Clock.fixed(justBeforeExpiry), () {
          expect(session.isExpired, isTrue);
        });
      });
    });

    group('toJson', () {
      test('round-trips with all optional fields present', () {
        final json = session.toJson();

        expect(json['id'], equals('sess_1'));
        expect(json['userId'], equals('user_1'));
        expect(json['token'], equals('tok_123'));
        expect(json['expiresAt'], equals('2027-01-01T00:00:00.000Z'));
        expect(json['createdAt'], equals('2026-01-01T00:00:00.000Z'));
        expect(json['updatedAt'], equals('2026-01-02T00:00:00.000Z'));
        expect(json['ipAddress'], equals('127.0.0.1'));
        expect(json['userAgent'], equals('test'));
        expect(json['plan'], equals('pro'));
      });

      test('omits optional fields when null', () {
        final trimmed = Session(
          userId: 'user_1',
          token: 'tok_123',
          expiresAt: DateTime.utc(2027),
        );

        final json = trimmed.toJson();

        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('createdAt'), isFalse);
        expect(json.containsKey('updatedAt'), isFalse);
        expect(json.containsKey('ipAddress'), isFalse);
        expect(json.containsKey('userAgent'), isFalse);
        expect(json['userId'], equals('user_1'));
        expect(json['token'], equals('tok_123'));
      });

      test('produces a map that re-parses to an equal Session', () {
        expect(Session.fromJson(session.toJson()), equals(session));
      });
    });

    group('copyWith', () {
      test('returns an equal instance when no arguments are given', () {
        expect(session.copyWith(), equals(session));
      });

      test('replaces every provided field', () {
        final updated = session.copyWith(
          id: 'sess_2',
          userId: 'user_2',
          token: 'tok_456',
          expiresAt: DateTime.utc(2028),
          createdAt: DateTime.utc(2026, 2),
          updatedAt: DateTime.utc(2026, 2, 2),
          ipAddress: '10.0.0.1',
          userAgent: 'agent',
          additionalFields: const {'plan': 'free'},
        );

        expect(updated.id, equals('sess_2'));
        expect(updated.userId, equals('user_2'));
        expect(updated.token, equals('tok_456'));
        expect(updated.expiresAt, equals(DateTime.utc(2028)));
        expect(updated.createdAt, equals(DateTime.utc(2026, 2)));
        expect(updated.updatedAt, equals(DateTime.utc(2026, 2, 2)));
        expect(updated.ipAddress, equals('10.0.0.1'));
        expect(updated.userAgent, equals('agent'));
        expect(updated.additionalFields, equals(const {'plan': 'free'}));
      });

      test('preserves unspecified fields', () {
        final updated = session.copyWith(token: 'changed');

        expect(updated.token, equals('changed'));
        expect(updated.id, equals(session.id));
        expect(updated.userId, equals(session.userId));
        expect(updated.expiresAt, equals(session.expiresAt));
      });
    });

    group('equality', () {
      test('two sessions with identical fields are equal', () {
        expect(session, equals(session.copyWith()));
        expect(session.hashCode, equals(session.copyWith().hashCode));
      });

      test('sessions differing in a field are not equal', () {
        expect(session, isNot(equals(session.copyWith(token: 'other'))));
      });

      test('exposes all fields via props', () {
        expect(
          session.props,
          equals(<Object?>[
            session.id,
            session.userId,
            session.token,
            session.expiresAt,
            session.createdAt,
            session.updatedAt,
            session.ipAddress,
            session.userAgent,
            session.additionalFields,
          ]),
        );
      });
    });

    test('toString includes id, userId and expiresAt', () {
      expect(
        session.toString(),
        equals(
          'Session(id: sess_1, userId: user_1, '
          'expiresAt: ${session.expiresAt})',
        ),
      );
    });
  });
}
