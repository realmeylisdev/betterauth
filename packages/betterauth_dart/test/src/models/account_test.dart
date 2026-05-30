import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

void main() {
  group(Account, () {
    late Account account;

    setUp(() {
      account = Account(
        id: 'acc_1',
        providerId: 'google',
        accountId: 'g_123',
        userId: 'user_1',
        scopes: const ['email', 'profile'],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
    });

    group('fromJson', () {
      test('parses a full JSON map including scopes and dates', () {
        final json = <String, dynamic>{
          'id': 'acc_1',
          'providerId': 'google',
          'accountId': 'g_123',
          'userId': 'user_1',
          'scopes': <dynamic>['email', 'profile'],
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        final result = Account.fromJson(json);

        expect(result.id, equals('acc_1'));
        expect(result.providerId, equals('google'));
        expect(result.accountId, equals('g_123'));
        expect(result.userId, equals('user_1'));
        expect(result.scopes, equals(<String>['email', 'profile']));
        expect(result.createdAt, equals(DateTime.utc(2026)));
        expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
      });

      test('defaults scopes to an empty list when absent', () {
        final json = <String, dynamic>{
          'id': 'acc_1',
          'providerId': 'credential',
          'accountId': 'c_1',
          'userId': 'user_1',
        };

        final result = Account.fromJson(json);

        expect(result.scopes, isEmpty);
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });

      test('parses an explicitly empty scopes list', () {
        final json = <String, dynamic>{
          'id': 'acc_1',
          'providerId': 'credential',
          'accountId': 'c_1',
          'userId': 'user_1',
          'scopes': <dynamic>[],
        };

        expect(Account.fromJson(json).scopes, isEmpty);
      });
    });

    group('toJson', () {
      test('round-trips with optional dates present', () {
        final json = account.toJson();

        expect(json['id'], equals('acc_1'));
        expect(json['providerId'], equals('google'));
        expect(json['accountId'], equals('g_123'));
        expect(json['userId'], equals('user_1'));
        expect(json['scopes'], equals(<String>['email', 'profile']));
        expect(json['createdAt'], equals('2026-01-01T00:00:00.000Z'));
        expect(json['updatedAt'], equals('2026-01-02T00:00:00.000Z'));
      });

      test('omits optional dates when null', () {
        const minimal = Account(
          id: 'acc_1',
          providerId: 'credential',
          accountId: 'c_1',
          userId: 'user_1',
        );

        final json = minimal.toJson();

        expect(json.containsKey('createdAt'), isFalse);
        expect(json.containsKey('updatedAt'), isFalse);
        expect(json['scopes'], isEmpty);
      });

      test('produces a map that re-parses to an equal Account', () {
        expect(Account.fromJson(account.toJson()), equals(account));
      });
    });

    group('copyWith', () {
      test('returns an equal instance when no arguments are given', () {
        expect(account.copyWith(), equals(account));
      });

      test('replaces every provided field', () {
        final updated = account.copyWith(
          id: 'acc_2',
          providerId: 'github',
          accountId: 'gh_9',
          userId: 'user_2',
          scopes: const ['repo'],
          createdAt: DateTime.utc(2027),
          updatedAt: DateTime.utc(2027, 1, 2),
        );

        expect(updated.id, equals('acc_2'));
        expect(updated.providerId, equals('github'));
        expect(updated.accountId, equals('gh_9'));
        expect(updated.userId, equals('user_2'));
        expect(updated.scopes, equals(<String>['repo']));
        expect(updated.createdAt, equals(DateTime.utc(2027)));
        expect(updated.updatedAt, equals(DateTime.utc(2027, 1, 2)));
      });

      test('preserves unspecified fields', () {
        final updated = account.copyWith(providerId: 'github');

        expect(updated.providerId, equals('github'));
        expect(updated.id, equals(account.id));
        expect(updated.scopes, equals(account.scopes));
        expect(updated.createdAt, equals(account.createdAt));
      });
    });

    group('equality', () {
      test('two accounts with identical fields are equal', () {
        expect(account, equals(account.copyWith()));
        expect(account.hashCode, equals(account.copyWith().hashCode));
      });

      test('accounts differing in a field are not equal', () {
        expect(account, isNot(equals(account.copyWith(id: 'other'))));
      });

      test('exposes all fields via props', () {
        expect(
          account.props,
          equals(<Object?>[
            account.id,
            account.providerId,
            account.accountId,
            account.userId,
            account.scopes,
            account.createdAt,
            account.updatedAt,
          ]),
        );
      });
    });

    test('toString includes id and providerId', () {
      expect(
        account.toString(),
        equals('Account(id: acc_1, providerId: google)'),
      );
    });
  });
}
