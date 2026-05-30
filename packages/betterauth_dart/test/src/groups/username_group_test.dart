import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(UsernameGroup, () {
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

    group('isAvailable', () {
      test('returns true when available', () async {
        stubPost(
          adapter,
          '/is-username-available',
          body: <String, dynamic>{'available': true},
        );

        final result = await client.username.isAvailable(username: 'ada');

        expect(result, isA<AuthSuccess<bool>>());
        expect((result as AuthSuccess<bool>).data, isTrue);
      });

      test('returns false when not available', () async {
        stubPost(
          adapter,
          '/is-username-available',
          body: <String, dynamic>{'available': false},
        );

        final result = await client.username.isAvailable(username: 'taken');

        expect((result as AuthSuccess<bool>).data, isFalse);
      });

      test('returns AuthUnknownException on a malformed body', () async {
        stubPost(
          adapter,
          '/is-username-available',
          body: <String, dynamic>{'available': 'nope'},
        );

        final result = await client.username.isAvailable(username: 'ada');

        expect(result, isA<AuthFailure<bool>>());
        expect(
          (result as AuthFailure<bool>).error,
          isA<AuthUnknownException>(),
        );
      });

      test('returns AuthApiException on a 400', () async {
        stubPost(
          adapter,
          '/is-username-available',
          status: 400,
          body: <String, dynamic>{'message': 'bad', 'code': 'BAD'},
        );

        final result = await client.username.isAvailable(username: 'ada');

        expect(
          (result as AuthFailure<bool>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
