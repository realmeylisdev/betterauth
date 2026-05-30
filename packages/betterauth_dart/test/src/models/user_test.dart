import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

void main() {
  group(User, () {
    late User user;

    setUp(() {
      user = User(
        id: 'user_1',
        name: 'Ada',
        email: 'ada@example.com',
        emailVerified: true,
        image: 'https://example.com/a.png',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
        username: 'ada',
        displayUsername: 'Ada',
        phoneNumber: '+1000',
        phoneNumberVerified: true,
        twoFactorEnabled: true,
        additionalFields: const {'role': 'admin'},
      );
    });

    group('fromJson', () {
      test('parses a full JSON map including all plugin fields', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'name': 'Ada',
          'email': 'ada@example.com',
          'emailVerified': true,
          'image': 'https://example.com/a.png',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'username': 'ada',
          'displayUsername': 'Ada',
          'phoneNumber': '+1000',
          'phoneNumberVerified': true,
          'twoFactorEnabled': true,
        };

        final result = User.fromJson(json);

        expect(result.id, equals('user_1'));
        expect(result.name, equals('Ada'));
        expect(result.email, equals('ada@example.com'));
        expect(result.emailVerified, isTrue);
        expect(result.image, equals('https://example.com/a.png'));
        expect(result.createdAt, equals(DateTime.utc(2026)));
        expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
        expect(result.username, equals('ada'));
        expect(result.displayUsername, equals('Ada'));
        expect(result.phoneNumber, equals('+1000'));
        expect(result.phoneNumberVerified, isTrue);
        expect(result.twoFactorEnabled, isTrue);
        expect(result.additionalFields, isEmpty);
      });

      test('parses a minimal JSON map applying defaults', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        final result = User.fromJson(json);

        expect(result.id, equals('user_1'));
        expect(result.name, equals(''));
        expect(result.email, equals(''));
        expect(result.emailVerified, isFalse);
        expect(result.image, isNull);
        expect(result.username, isNull);
        expect(result.displayUsername, isNull);
        expect(result.phoneNumber, isNull);
        expect(result.phoneNumberVerified, isNull);
        expect(result.twoFactorEnabled, isNull);
        expect(result.additionalFields, isEmpty);
      });

      test('defaults emailVerified to false when absent', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        expect(User.fromJson(json).emailVerified, isFalse);
      });

      test('captures unmodelled keys in additionalFields', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'role': 'admin',
          'metadata': {'k': 'v'},
        };

        final result = User.fromJson(json);

        expect(
          result.additionalFields,
          equals(<String, Object?>{
            'role': 'admin',
            'metadata': {'k': 'v'},
          }),
        );
      });

      test('throws when createdAt is missing', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        expect(
          () => User.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('round-trips with all optional and plugin fields present', () {
        final json = user.toJson();

        expect(json['id'], equals('user_1'));
        expect(json['name'], equals('Ada'));
        expect(json['email'], equals('ada@example.com'));
        expect(json['emailVerified'], isTrue);
        expect(json['image'], equals('https://example.com/a.png'));
        expect(json['createdAt'], equals('2026-01-01T00:00:00.000Z'));
        expect(json['updatedAt'], equals('2026-01-02T00:00:00.000Z'));
        expect(json['username'], equals('ada'));
        expect(json['displayUsername'], equals('Ada'));
        expect(json['phoneNumber'], equals('+1000'));
        expect(json['phoneNumberVerified'], isTrue);
        expect(json['twoFactorEnabled'], isTrue);
        expect(json['role'], equals('admin'));
      });

      test('omits optional and plugin fields when null', () {
        final minimal = User(
          id: 'user_1',
          name: 'Ada',
          email: 'ada@example.com',
          emailVerified: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 1, 2),
        );

        final json = minimal.toJson();

        expect(json.containsKey('image'), isFalse);
        expect(json.containsKey('username'), isFalse);
        expect(json.containsKey('displayUsername'), isFalse);
        expect(json.containsKey('phoneNumber'), isFalse);
        expect(json.containsKey('phoneNumberVerified'), isFalse);
        expect(json.containsKey('twoFactorEnabled'), isFalse);
        expect(json['emailVerified'], isFalse);
      });

      test('produces a map that re-parses to an equal User', () {
        expect(User.fromJson(user.toJson()), equals(user));
      });
    });

    group('copyWith', () {
      test('returns an equal instance when no arguments are given', () {
        expect(user.copyWith(), equals(user));
      });

      test('replaces every provided field', () {
        final updated = user.copyWith(
          id: 'user_2',
          name: 'Bob',
          email: 'bob@example.com',
          emailVerified: false,
          image: 'https://example.com/b.png',
          createdAt: DateTime.utc(2027),
          updatedAt: DateTime.utc(2027, 1, 2),
          username: 'bob',
          displayUsername: 'Bob',
          phoneNumber: '+2000',
          phoneNumberVerified: false,
          twoFactorEnabled: false,
          additionalFields: const {'role': 'user'},
        );

        expect(updated.id, equals('user_2'));
        expect(updated.name, equals('Bob'));
        expect(updated.email, equals('bob@example.com'));
        expect(updated.emailVerified, isFalse);
        expect(updated.image, equals('https://example.com/b.png'));
        expect(updated.createdAt, equals(DateTime.utc(2027)));
        expect(updated.updatedAt, equals(DateTime.utc(2027, 1, 2)));
        expect(updated.username, equals('bob'));
        expect(updated.displayUsername, equals('Bob'));
        expect(updated.phoneNumber, equals('+2000'));
        expect(updated.phoneNumberVerified, isFalse);
        expect(updated.twoFactorEnabled, isFalse);
        expect(updated.additionalFields, equals(const {'role': 'user'}));
      });

      test('preserves unspecified fields', () {
        final updated = user.copyWith(name: 'Changed');

        expect(updated.name, equals('Changed'));
        expect(updated.id, equals(user.id));
        expect(updated.email, equals(user.email));
        expect(updated.additionalFields, equals(user.additionalFields));
      });
    });

    group('equality', () {
      test('two users with identical fields are equal', () {
        expect(user, equals(user.copyWith()));
        expect(user.hashCode, equals(user.copyWith().hashCode));
      });

      test('users differing in a field are not equal', () {
        expect(user, isNot(equals(user.copyWith(id: 'other'))));
      });

      test('exposes all fields via props', () {
        expect(
          user.props,
          equals(<Object?>[
            user.id,
            user.name,
            user.email,
            user.emailVerified,
            user.image,
            user.createdAt,
            user.updatedAt,
            user.username,
            user.displayUsername,
            user.phoneNumber,
            user.phoneNumberVerified,
            user.twoFactorEnabled,
            user.isAnonymous,
            user.additionalFields,
          ]),
        );
      });
    });

    test('toString includes id and email', () {
      expect(
        user.toString(),
        equals('User(id: user_1, email: ada@example.com)'),
      );
    });

    group('isAnonymous', () {
      test('round-trips true through fromJson and toJson', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'isAnonymous': true,
        };

        final parsed = User.fromJson(json);

        expect(parsed.isAnonymous, isTrue);
        expect(parsed.toJson()['isAnonymous'], isTrue);
      });

      test('round-trips false through fromJson and toJson', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'isAnonymous': false,
        };

        final parsed = User.fromJson(json);

        expect(parsed.isAnonymous, isFalse);
        expect(parsed.toJson()['isAnonymous'], isFalse);
      });

      test('defaults to null when absent and toJson omits it', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        final parsed = User.fromJson(json);

        expect(parsed.isAnonymous, isNull);
        expect(parsed.toJson().containsKey('isAnonymous'), isFalse);
      });

      test('copyWith sets isAnonymous', () {
        final updated = user.copyWith(isAnonymous: true);

        expect(updated.isAnonymous, isTrue);
        expect(user.isAnonymous, isNull);
      });

      test('equality differs when isAnonymous differs', () {
        final anon = user.copyWith(isAnonymous: true);
        final notAnon = user.copyWith(isAnonymous: false);

        expect(anon, isNot(equals(notAnon)));
      });

      test('is not captured in additionalFields', () {
        final json = <String, dynamic>{
          'id': 'user_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'isAnonymous': true,
        };

        final parsed = User.fromJson(json);

        expect(parsed.additionalFields.containsKey('isAnonymous'), isFalse);
        expect(parsed.additionalFields, isEmpty);
      });
    });
  });
}
