import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(UserGroup, () {
    late TestClient ctx;

    setUp(() {
      ctx = buildTestClient();
    });

    group('update', () {
      test('returns ok and hydrates + emits userUpdated on success', () async {
        stubPost(
          ctx.adapter,
          '/update-user',
          body: <String, dynamic>{'status': true},
        );
        stubGet(
          ctx.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(name: 'New Name'),
          },
        );

        final events = <AuthChangeEvent>[];
        final sub = ctx.client.onAuthStateChange.listen(
          (state) => events.add(state.event),
        );

        final result = await ctx.client.user.update(name: 'New Name');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        // hydrate ran: current user/session are populated.
        expect(ctx.client.currentUser?.name, equals('New Name'));
        expect(ctx.client.currentSession, isNotNull);
        await Future<void>.delayed(Duration.zero);
        expect(events, contains(AuthChangeEvent.userUpdated));

        await sub.cancel();
      });

      test('sends name, image and additionalFields on success', () async {
        stubPost(
          ctx.adapter,
          '/update-user',
          body: <String, dynamic>{'status': true},
        );
        stubGet(
          ctx.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await ctx.client.user.update(
          name: 'Ada',
          image: 'https://img.test/a.png',
          additionalFields: <String, dynamic>{'nickname': 'A'},
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect(ctx.client.currentUser, isNotNull);
      });

      test('does not hydrate when the server reports not ok', () async {
        stubPost(
          ctx.adapter,
          '/update-user',
          body: <String, dynamic>{'status': false},
        );
        // No /get-session stub: if hydrate ran it would fail the request.

        final result = await ctx.client.user.update(name: 'X');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isFalse);
        // hydrate did NOT run.
        expect(ctx.client.currentUser, isNull);
        expect(ctx.client.currentSession, isNull);
      });

      test('does not hydrate and returns failure on a 400 response', () async {
        stubPost(
          ctx.adapter,
          '/update-user',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.user.update(name: 'X');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
        expect(ctx.client.currentUser, isNull);
      });

      test('treats a non-object 2xx body as ok and hydrates', () async {
        stubPost(ctx.adapter, '/update-user', body: 'ok');
        stubGet(
          ctx.adapter,
          '/get-session',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await ctx.client.user.update(name: 'X');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
        expect(ctx.client.currentUser, isNotNull);
      });
    });

    group('changeEmail', () {
      test('returns a StatusResponse with a message on success', () async {
        stubPost(
          ctx.adapter,
          '/change-email',
          body: <String, dynamic>{
            'status': true,
            'message': 'Verification sent',
          },
        );

        final result = await ctx.client.user.changeEmail(
          newEmail: 'new@example.com',
          callbackURL: 'https://app.test/cb',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        final data = (result as AuthSuccess<StatusResponse>).data;
        expect(data.ok, isTrue);
        expect(data.message, equals('Verification sent'));
      });

      test('omits callbackURL when not provided', () async {
        stubPost(
          ctx.adapter,
          '/change-email',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.user.changeEmail(
          newEmail: 'new@example.com',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
      });

      test('fails with AuthApiException on a 400 response', () async {
        stubPost(
          ctx.adapter,
          '/change-email',
          status: 400,
          body: <String, dynamic>{'message': 'Taken', 'code': 'TAKEN'},
        );

        final result = await ctx.client.user.changeEmail(
          newEmail: 'new@example.com',
        );

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('delete', () {
      test('returns a StatusResponse with a message on success', () async {
        stubPost(
          ctx.adapter,
          '/delete-user',
          body: <String, dynamic>{
            'success': true,
            'message': 'Account deleted',
          },
        );

        final result = await ctx.client.user.delete(password: 'pw');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        final data = (result as AuthSuccess<StatusResponse>).data;
        expect(data.ok, isTrue);
        expect(data.message, equals('Account deleted'));
      });

      test('sends token and callbackURL when provided', () async {
        stubPost(
          ctx.adapter,
          '/delete-user',
          body: <String, dynamic>{'success': true},
        );

        final result = await ctx.client.user.delete(
          token: 'del_tok',
          callbackURL: 'https://app.test/bye',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
      });

      test('fails with AuthApiException on a 400 response', () async {
        stubPost(
          ctx.adapter,
          '/delete-user',
          status: 400,
          body: <String, dynamic>{'message': 'No', 'code': 'NO'},
        );

        final result = await ctx.client.user.delete(password: 'pw');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
