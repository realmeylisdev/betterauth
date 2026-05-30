import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// A canonical passkey JSON map for stubbing responses.
Map<String, dynamic> passkeyJson({
  String id = 'pk_1',
  String credentialId = 'cred_1',
  String userId = 'user_1',
  String name = 'My Passkey',
}) => <String, dynamic>{
  'id': id,
  'credentialID': credentialId,
  'userId': userId,
  'name': name,
  'deviceType': 'platform',
  'backedUp': true,
  'transports': <String>['internal'],
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
};

void main() {
  group(PasskeyGroup, () {
    late TestClient ctx;

    setUp(() {
      ctx = buildTestClient();
    });

    group('generateRegisterOptions', () {
      test('returns the raw options map on success', () async {
        // authenticatorAttachment is appended as a query parameter, so match
        // the path with an optional trailing query string.
        ctx.adapter.onGet(
          RegExp(r'.*/passkey/generate-register-options(\?.*)?$'),
          (server) => server.reply(
            200,
            <String, dynamic>{
              'challenge': 'abc123',
              'rp': <String, dynamic>{'id': 'example.com', 'name': 'Example'},
            },
            headers: <String, List<String>>{
              'content-type': const <String>['application/json'],
            },
          ),
        );

        final result = await ctx.client.passkey.generateRegisterOptions(
          authenticatorAttachment: 'platform',
        );

        expect(result, isA<AuthSuccess<Map<String, dynamic>>>());
        final data = (result as AuthSuccess<Map<String, dynamic>>).data;
        expect(data['challenge'], equals('abc123'));
      });

      test('fails with AuthApiException on a 400', () async {
        stubGet(
          ctx.adapter,
          '/passkey/generate-register-options',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await ctx.client.passkey.generateRegisterOptions();

        expect(result, isA<AuthFailure<Map<String, dynamic>>>());
        expect(
          (result as AuthFailure<Map<String, dynamic>>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('verifyRegistration', () {
      test('returns a Passkey from a bare passkey body', () async {
        stubPost(
          ctx.adapter,
          '/passkey/verify-registration',
          body: passkeyJson(),
        );

        final result = await ctx.client.passkey.verifyRegistration(
          response: <String, dynamic>{'id': 'cred', 'rawId': 'raw'},
          name: 'My Passkey',
        );

        expect(result, isA<AuthSuccess<Passkey>>());
        final data = (result as AuthSuccess<Passkey>).data;
        expect(data.id, equals('pk_1'));
        expect(data.credentialId, equals('cred_1'));
      });

      test('returns a Passkey from a {passkey: {...}} wrapped body', () async {
        stubPost(
          ctx.adapter,
          '/passkey/verify-registration',
          body: <String, dynamic>{'passkey': passkeyJson(id: 'pk_2')},
        );

        final result = await ctx.client.passkey.verifyRegistration(
          response: <String, dynamic>{'id': 'cred', 'rawId': 'raw'},
        );

        expect(result, isA<AuthSuccess<Passkey>>());
        expect((result as AuthSuccess<Passkey>).data.id, equals('pk_2'));
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/passkey/verify-registration',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await ctx.client.passkey.verifyRegistration(
          response: <String, dynamic>{'id': 'cred'},
        );

        expect(result, isA<AuthFailure<Passkey>>());
        expect(
          (result as AuthFailure<Passkey>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('generateAuthenticateOptions', () {
      test('returns the raw options map on success', () async {
        // email is appended as a query parameter, so match the path with an
        // optional trailing query string.
        ctx.adapter.onGet(
          RegExp(r'.*/passkey/generate-authenticate-options(\?.*)?$'),
          (server) => server.reply(
            200,
            <String, dynamic>{
              'challenge': 'auth123',
              'rpId': 'example.com',
            },
            headers: <String, List<String>>{
              'content-type': const <String>['application/json'],
            },
          ),
        );

        final result = await ctx.client.passkey.generateAuthenticateOptions(
          email: 'ada@example.com',
        );

        expect(result, isA<AuthSuccess<Map<String, dynamic>>>());
        final data = (result as AuthSuccess<Map<String, dynamic>>).data;
        expect(data['challenge'], equals('auth123'));
      });

      test('fails with AuthApiException on a 400', () async {
        stubGet(
          ctx.adapter,
          '/passkey/generate-authenticate-options',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await ctx.client.passkey.generateAuthenticateOptions();

        expect(result, isA<AuthFailure<Map<String, dynamic>>>());
        expect(
          (result as AuthFailure<Map<String, dynamic>>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('listUserPasskeys', () {
      test('returns a list of passkeys on success', () async {
        stubGet(
          ctx.adapter,
          '/passkey/list-user-passkeys',
          body: <Map<String, dynamic>>[
            passkeyJson(),
            passkeyJson(id: 'pk_2'),
          ],
        );

        final result = await ctx.client.passkey.listUserPasskeys();

        expect(result, isA<AuthSuccess<List<Passkey>>>());
        expect((result as AuthSuccess<List<Passkey>>).data, hasLength(2));
      });

      test(
        'fails with AuthUnknownException when the body is not an array',
        () async {
          stubGet(
            ctx.adapter,
            '/passkey/list-user-passkeys',
            body: <String, dynamic>{'not': 'a list'},
          );

          final result = await ctx.client.passkey.listUserPasskeys();

          expect(result, isA<AuthFailure<List<Passkey>>>());
          expect(
            (result as AuthFailure<List<Passkey>>).error,
            isA<AuthUnknownException>(),
          );
        },
      );
    });

    group('updatePasskey', () {
      test('returns the updated Passkey on success', () async {
        stubPost(
          ctx.adapter,
          '/passkey/update-passkey',
          body: passkeyJson(name: 'Renamed'),
        );

        final result = await ctx.client.passkey.updatePasskey(
          id: 'pk_1',
          name: 'Renamed',
        );

        expect(result, isA<AuthSuccess<Passkey>>());
        expect((result as AuthSuccess<Passkey>).data.name, equals('Renamed'));
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/passkey/update-passkey',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await ctx.client.passkey.updatePasskey(
          id: 'pk_1',
          name: 'Renamed',
        );

        expect(result, isA<AuthFailure<Passkey>>());
        expect(
          (result as AuthFailure<Passkey>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('deletePasskey', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/passkey/delete-passkey',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.passkey.deletePasskey(id: 'pk_1');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/passkey/delete-passkey',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'X'},
        );

        final result = await ctx.client.passkey.deletePasskey(id: 'pk_1');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
