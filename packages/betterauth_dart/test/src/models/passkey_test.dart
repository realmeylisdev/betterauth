import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

void main() {
  group(Passkey, () {
    late Passkey passkey;

    setUp(() {
      passkey = Passkey(
        id: 'pk_1',
        credentialId: 'cred_1',
        userId: 'user_1',
        name: 'My key',
        publicKey: 'pub',
        counter: 3,
        deviceType: 'platform',
        backedUp: true,
        transports: const ['internal', 'hybrid'],
        aaguid: 'aaguid_1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
    });

    group('fromJson', () {
      test('parses a full JSON map', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
          'name': 'My key',
          'publicKey': 'pub',
          'counter': 3,
          'deviceType': 'platform',
          'backedUp': true,
          'transports': <String>['internal', 'hybrid'],
          'aaguid': 'aaguid_1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        };

        final result = Passkey.fromJson(json);

        expect(result.id, equals('pk_1'));
        expect(result.credentialId, equals('cred_1'));
        expect(result.userId, equals('user_1'));
        expect(result.name, equals('My key'));
        expect(result.publicKey, equals('pub'));
        expect(result.counter, equals(3));
        expect(result.deviceType, equals('platform'));
        expect(result.backedUp, isTrue);
        expect(result.transports, equals(<String>['internal', 'hybrid']));
        expect(result.aaguid, equals('aaguid_1'));
        expect(result.createdAt, equals(DateTime.utc(2026)));
        expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
      });

      test('parses a minimal JSON map applying defaults', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
        };

        final result = Passkey.fromJson(json);

        expect(result.id, equals('pk_1'));
        expect(result.credentialId, equals('cred_1'));
        expect(result.userId, equals('user_1'));
        expect(result.name, isNull);
        expect(result.publicKey, isNull);
        expect(result.counter, isNull);
        expect(result.deviceType, isNull);
        expect(result.backedUp, isNull);
        expect(result.transports, isEmpty);
        expect(result.aaguid, isNull);
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });

      test('falls back to credentialId when credentialID is absent', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialId': 'fallback_cred',
          'userId': 'user_1',
        };

        expect(Passkey.fromJson(json).credentialId, equals('fallback_cred'));
      });

      test('parses transports from a List', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
          'transports': <dynamic>['usb', 'nfc'],
        };

        expect(
          Passkey.fromJson(json).transports,
          equals(<String>['usb', 'nfc']),
        );
      });

      test('parses transports from a comma-separated String', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
          'transports': 'internal, hybrid ,usb',
        };

        expect(
          Passkey.fromJson(json).transports,
          equals(<String>['internal', 'hybrid', 'usb']),
        );
      });

      test('returns an empty transports list when the field is absent', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
        };

        expect(Passkey.fromJson(json).transports, isEmpty);
      });

      test('returns an empty transports list for an empty String', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
          'transports': '',
        };

        expect(Passkey.fromJson(json).transports, isEmpty);
      });

      test('parses counter from a num (double)', () {
        final json = <String, dynamic>{
          'id': 'pk_1',
          'credentialID': 'cred_1',
          'userId': 'user_1',
          'counter': 7.0,
        };

        expect(Passkey.fromJson(json).counter, equals(7));
      });
    });

    group('copyWith', () {
      test('returns an equal instance when no arguments are given', () {
        expect(passkey.copyWith(), equals(passkey));
      });

      test('replaces every provided field', () {
        final updated = passkey.copyWith(
          id: 'pk_2',
          credentialId: 'cred_2',
          userId: 'user_2',
          name: 'Other key',
          publicKey: 'pub2',
          counter: 9,
          deviceType: 'cross-platform',
          backedUp: false,
          transports: const ['usb'],
          aaguid: 'aaguid_2',
          createdAt: DateTime.utc(2027),
          updatedAt: DateTime.utc(2027, 1, 2),
        );

        expect(updated.id, equals('pk_2'));
        expect(updated.credentialId, equals('cred_2'));
        expect(updated.userId, equals('user_2'));
        expect(updated.name, equals('Other key'));
        expect(updated.publicKey, equals('pub2'));
        expect(updated.counter, equals(9));
        expect(updated.deviceType, equals('cross-platform'));
        expect(updated.backedUp, isFalse);
        expect(updated.transports, equals(<String>['usb']));
        expect(updated.aaguid, equals('aaguid_2'));
        expect(updated.createdAt, equals(DateTime.utc(2027)));
        expect(updated.updatedAt, equals(DateTime.utc(2027, 1, 2)));
      });

      test('preserves unspecified fields', () {
        final updated = passkey.copyWith(name: 'Renamed');

        expect(updated.name, equals('Renamed'));
        expect(updated.id, equals(passkey.id));
        expect(updated.credentialId, equals(passkey.credentialId));
        expect(updated.userId, equals(passkey.userId));
        expect(updated.transports, equals(passkey.transports));
      });
    });

    group('equality', () {
      test('two passkeys with identical fields are equal', () {
        expect(passkey, equals(passkey.copyWith()));
        expect(passkey.hashCode, equals(passkey.copyWith().hashCode));
      });

      test('passkeys differing in a field are not equal', () {
        expect(passkey, isNot(equals(passkey.copyWith(id: 'other'))));
      });

      test('exposes all fields via props', () {
        expect(
          passkey.props,
          equals(<Object?>[
            passkey.id,
            passkey.credentialId,
            passkey.userId,
            passkey.name,
            passkey.publicKey,
            passkey.counter,
            passkey.deviceType,
            passkey.backedUp,
            passkey.transports,
            passkey.aaguid,
            passkey.createdAt,
            passkey.updatedAt,
          ]),
        );
      });
    });

    test('toString includes id and name', () {
      expect(passkey.toString(), equals('Passkey(id: pk_1, name: My key)'));
    });
  });
}
