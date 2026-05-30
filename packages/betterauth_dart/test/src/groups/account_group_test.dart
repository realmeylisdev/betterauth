import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(AccountGroup, () {
    late TestClient ctx;

    setUp(() {
      ctx = buildTestClient();
    });

    group('list', () {
      test('returns a list of accounts on success', () async {
        stubGet(
          ctx.adapter,
          '/list-accounts',
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'acc_1',
              'providerId': 'google',
              'accountId': 'g_1',
              'userId': 'user_1',
              'scopes': <String>['email'],
              'createdAt': '2026-01-01T00:00:00.000Z',
              'updatedAt': '2026-01-02T00:00:00.000Z',
            },
            <String, dynamic>{
              'id': 'acc_2',
              'providerId': 'credential',
              'accountId': 'c_1',
              'userId': 'user_1',
            },
          ],
        );

        final result = await ctx.client.account.list();

        expect(result, isA<AuthSuccess<List<Account>>>());
        final data = (result as AuthSuccess<List<Account>>).data;
        expect(data, hasLength(2));
        expect(data.first.providerId, equals('google'));
        expect(data.first.scopes, equals(<String>['email']));
        expect(data[1].providerId, equals('credential'));
      });

      test('returns an empty list when the server returns []', () async {
        stubGet(ctx.adapter, '/list-accounts', body: <dynamic>[]);

        final result = await ctx.client.account.list();

        expect(result, isA<AuthSuccess<List<Account>>>());
        expect((result as AuthSuccess<List<Account>>).data, isEmpty);
      });

      test('fails with AuthApiException on a 400 response', () async {
        stubGet(
          ctx.adapter,
          '/list-accounts',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.account.list();

        expect(result, isA<AuthFailure<List<Account>>>());
        expect(
          (result as AuthFailure<List<Account>>).error,
          isA<AuthApiException>(),
        );
      });

      test(
        'fails with AuthUnknownException when the body is not a list',
        () async {
          stubGet(
            ctx.adapter,
            '/list-accounts',
            body: <String, dynamic>{'not': 'a list'},
          );

          final result = await ctx.client.account.list();

          expect(result, isA<AuthFailure<List<Account>>>());
          expect(
            (result as AuthFailure<List<Account>>).error,
            isA<AuthUnknownException>(),
          );
        },
      );

      test(
        'fails with AuthUnknownException when a list element is malformed',
        () async {
          stubGet(
            ctx.adapter,
            '/list-accounts',
            body: <Map<String, dynamic>>[
              <String, dynamic>{'providerId': 'google'},
            ],
          );

          final result = await ctx.client.account.list();

          expect(result, isA<AuthFailure<List<Account>>>());
          expect(
            (result as AuthFailure<List<Account>>).error,
            isA<AuthUnknownException>(),
          );
        },
      );
    });

    group('unlink', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/unlink-account',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.account.unlink(providerId: 'google');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('returns a StatusResponse when accountId is provided', () async {
        stubPost(
          ctx.adapter,
          '/unlink-account',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.account.unlink(
          providerId: 'google',
          accountId: 'g_1',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
      });

      test('fails with AuthApiException on a 400 response', () async {
        stubPost(
          ctx.adapter,
          '/unlink-account',
          status: 400,
          body: <String, dynamic>{'message': 'Nope', 'code': 'NOPE'},
        );

        final result = await ctx.client.account.unlink(providerId: 'google');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('linkSocial', () {
      test('returns the authorization url on success', () async {
        stubPost(
          ctx.adapter,
          '/link-social',
          body: <String, dynamic>{'url': 'https://auth.test/redirect'},
        );

        final result = await ctx.client.account.linkSocial(provider: 'google');

        expect(result, isA<AuthSuccess<String>>());
        expect(
          (result as AuthSuccess<String>).data,
          equals('https://auth.test/redirect'),
        );
      });

      test('sends all optional fields, including the id token', () async {
        stubPost(
          ctx.adapter,
          '/link-social',
          body: <String, dynamic>{'url': 'https://auth.test/redirect'},
        );

        final result = await ctx.client.account.linkSocial(
          provider: 'google',
          callbackURL: 'https://app.test/cb',
          scopes: const <String>['email', 'profile'],
          errorCallbackURL: 'https://app.test/err',
          disableRedirect: true,
          requestSignUp: false,
          idToken: const IdToken(token: 'id_tok'),
        );

        expect(result, isA<AuthSuccess<String>>());
      });

      test(
        'fails with AuthUnknownException when the url field is missing',
        () async {
          stubPost(
            ctx.adapter,
            '/link-social',
            body: <String, dynamic>{'noUrl': true},
          );

          final result = await ctx.client.account.linkSocial(
            provider: 'google',
          );

          expect(result, isA<AuthFailure<String>>());
          expect(
            (result as AuthFailure<String>).error,
            isA<AuthUnknownException>(),
          );
        },
      );

      test(
        'fails with AuthUnknownException when the body is not an object',
        () async {
          stubPost(ctx.adapter, '/link-social', body: 'plain text');

          final result = await ctx.client.account.linkSocial(
            provider: 'google',
          );

          expect(result, isA<AuthFailure<String>>());
          expect(
            (result as AuthFailure<String>).error,
            isA<AuthUnknownException>(),
          );
        },
      );

      test('fails with AuthApiException on a 400 response', () async {
        stubPost(
          ctx.adapter,
          '/link-social',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.account.linkSocial(provider: 'google');

        expect(result, isA<AuthFailure<String>>());
        expect(
          (result as AuthFailure<String>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
