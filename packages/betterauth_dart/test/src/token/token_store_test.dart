import 'package:betterauth_dart/src/token/cookie_store.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
import 'package:test/test.dart';

void main() {
  group(TokenStore, () {
    late TokenStore store;

    setUp(() {
      store = TokenStore();
    });

    test('creates its own CookieStore when none is provided', () {
      expect(store.cookies, isA<CookieStore>());
      expect(store.token, isNull);
    });

    test('composes a provided CookieStore', () {
      final cookies = CookieStore();

      final tokenStore = TokenStore(cookies: cookies);

      expect(tokenStore.cookies, same(cookies));
    });

    test('token can be set and read', () {
      store.token = 'abc';

      expect(store.token, equals('abc'));
    });

    group('hasToken', () {
      test('is false when token is null', () {
        expect(store.hasToken, isFalse);
      });

      test('is false when token is an empty string', () {
        store.token = '';

        expect(store.hasToken, isFalse);
      });

      test('is true when token is non-empty', () {
        store.token = 'abc';

        expect(store.hasToken, isTrue);
      });
    });

    group('clear', () {
      test('clears the token', () {
        store
          ..token = 'abc'
          ..clear();

        expect(store.token, isNull);
        expect(store.hasToken, isFalse);
      });

      test('clears the cookies', () {
        store.cookies.storeFromSetCookie(['a=1; Path=/']);

        store.clear();

        expect(store.cookies.isEmpty, isTrue);
      });

      test('clears both token and the provided cookie store', () {
        final cookies = CookieStore()..storeFromSetCookie(['a=1; Path=/']);
        final tokenStore = TokenStore(cookies: cookies)
          ..token = 'abc'
          ..clear();

        expect(tokenStore.token, isNull);
        expect(cookies.isEmpty, isTrue);
      });
    });
  });
}
