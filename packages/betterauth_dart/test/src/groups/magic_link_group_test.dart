import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(MagicLinkGroup, () {
    late BetterAuthClient client;
    late DioAdapter adapter;

    setUp(() {
      final harness = buildTestClient();
      client = harness.client;
      adapter = harness.adapter;
    });

    tearDown(() async {
      await client.dispose();
    });

    group('verify', () {
      test('adopts the returned session on success', () async {
        // The verify endpoint is a GET; the token travels in the query string
        // and the default FullHttpRequestMatcher matches on the full URL.
        stubGet(
          adapter,
          '/magic-link/verify?token=tok',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final events = <AuthChangeEvent>[];
        final sub = client.onAuthStateChange.listen((s) => events.add(s.event));

        final result = await client.magicLink.verify(token: 'tok');
        await pumpEventQueue();

        expect(result, isA<AuthSuccess<SessionResponse>>());
        expect(client.currentSession, isNotNull);
        expect(client.currentToken, equals('tok_123'));
        expect(client.currentSession!.token, equals('tok_123'));
        expect(client.isAuthenticated, isTrue);
        expect(events, contains(AuthChangeEvent.signedIn));
        await sub.cancel();
      });

      test('passes callbackURL through when provided', () async {
        stubGet(
          adapter,
          '/magic-link/verify?token=tok'
          '&callbackURL=https%3A%2F%2Fapp%2Fcallback',
          body: <String, dynamic>{
            'session': sessionJson(),
            'user': userJson(),
          },
        );

        final result = await client.magicLink.verify(
          token: 'tok',
          callbackURL: 'https://app/callback',
        );

        expect(result, isA<AuthSuccess<SessionResponse>>());
      });

      test('returns AuthApiException on a 400 and adopts no session', () async {
        stubGet(
          adapter,
          '/magic-link/verify?token=bad',
          status: 400,
          body: <String, dynamic>{
            'message': 'Invalid token',
            'code': 'INVALID_TOKEN',
          },
        );

        final result = await client.magicLink.verify(token: 'bad');

        expect(result, isA<AuthFailure<SessionResponse>>());
        expect(
          (result as AuthFailure<SessionResponse>).error,
          isA<AuthApiException>(),
        );
        expect(client.currentSession, isNull);
        expect(client.currentToken, isNull);
      });

      test('returns AuthUnknownException on a malformed body', () async {
        stubGet(
          adapter,
          '/magic-link/verify?token=tok',
          body: <String, dynamic>{'unexpected': true},
        );

        final result = await client.magicLink.verify(token: 'tok');

        expect(result, isA<AuthFailure<SessionResponse>>());
        expect(
          (result as AuthFailure<SessionResponse>).error,
          isA<AuthUnknownException>(),
        );
        expect(client.currentSession, isNull);
      });

      test('returns AuthUnknownException when body is not an object', () async {
        stubGet(
          adapter,
          '/magic-link/verify?token=tok',
          body: <dynamic>[1, 2, 3],
        );

        final result = await client.magicLink.verify(token: 'tok');

        expect(
          (result as AuthFailure<SessionResponse>).error,
          isA<AuthUnknownException>(),
        );
      });
    });
  });
}
