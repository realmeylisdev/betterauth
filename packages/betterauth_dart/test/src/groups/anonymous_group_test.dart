import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group(AnonymousGroup, () {
    late TestClient ctx;

    setUp(() {
      ctx = buildTestClient();
    });

    group('deleteUser', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/delete-anonymous-user',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.anonymous.deleteUser();

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/delete-anonymous-user',
          status: 400,
          body: <String, dynamic>{
            'message': 'Not anonymous',
            'code': 'USER_IS_NOT_ANONYMOUS',
          },
        );

        final result = await ctx.client.anonymous.deleteUser();

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });
  });
}
