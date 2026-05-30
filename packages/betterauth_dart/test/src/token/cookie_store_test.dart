import 'package:betterauth_dart/src/token/cookie_store.dart';
import 'package:test/test.dart';

void main() {
  group(CookieStore, () {
    late CookieStore store;

    setUp(() {
      store = CookieStore();
    });

    test('is empty on construction', () {
      expect(store.isEmpty, isTrue);
      expect(store.cookies, isEmpty);
      expect(store.header, isNull);
    });

    group('storeFromSetCookie', () {
      test('parses a single name=value pair ignoring attributes', () {
        store.storeFromSetCookie(['session=abc; Path=/; HttpOnly']);

        expect(store.cookies, equals({'session': 'abc'}));
        expect(store.isEmpty, isFalse);
      });

      test('captures multiple Set-Cookie headers', () {
        store.storeFromSetCookie([
          'two_factor=challenge; Path=/; HttpOnly',
          'trust_device=yes; Secure',
        ]);

        expect(
          store.cookies,
          equals({'two_factor': 'challenge', 'trust_device': 'yes'}),
        );
      });

      test('trims whitespace around name and value', () {
        store.storeFromSetCookie(['  name  =  value  ; Path=/']);

        expect(store.cookies, equals({'name': 'value'}));
      });

      test('captures a pair without attributes', () {
        store.storeFromSetCookie(['a=b']);

        expect(store.cookies, equals({'a': 'b'}));
      });

      test('captures an empty value', () {
        store.storeFromSetCookie(['empty=; Path=/']);

        expect(store.cookies, equals({'empty': ''}));
      });

      test('overwrites a cookie with the same name', () {
        store
          ..storeFromSetCookie(['session=first; Path=/'])
          ..storeFromSetCookie(['session=second; Path=/']);

        expect(store.cookies, equals({'session': 'second'}));
      });

      test('ignores entries without an equals sign', () {
        store.storeFromSetCookie(['novalue; Path=/']);

        expect(store.cookies, isEmpty);
      });

      test('ignores entries whose equals sign is at index 0', () {
        store.storeFromSetCookie(['=value; Path=/']);

        expect(store.cookies, isEmpty);
      });

      test('ignores an empty header entry', () {
        store.storeFromSetCookie(['']);

        expect(store.cookies, isEmpty);
      });

      test('keeps valid entries when one entry is malformed', () {
        store.storeFromSetCookie([
          'good=1; Path=/',
          'novalue',
          'other=2',
        ]);

        expect(store.cookies, equals({'good': '1', 'other': '2'}));
      });
    });

    group('header', () {
      test('returns null when empty', () {
        expect(store.header, isNull);
      });

      test('joins a single cookie', () {
        store.storeFromSetCookie(['a=b; Path=/']);

        expect(store.header, equals('a=b'));
      });

      test('joins all cookies with a semicolon separator', () {
        store.storeFromSetCookie([
          'a=1; Path=/',
          'b=2; Path=/',
        ]);

        expect(store.header, equals('a=1; b=2'));
      });
    });

    group('loadFromMap', () {
      test('replaces all stored cookies', () {
        store
          ..storeFromSetCookie(['old=1; Path=/'])
          ..loadFromMap({'new': '2', 'another': '3'});

        expect(store.cookies, equals({'new': '2', 'another': '3'}));
      });

      test('clears existing cookies when given an empty map', () {
        store
          ..storeFromSetCookie(['old=1; Path=/'])
          ..loadFromMap({});

        expect(store.isEmpty, isTrue);
      });
    });

    group('remove', () {
      test('removes a cookie by name', () {
        store
          ..storeFromSetCookie([
            'a=1; Path=/',
            'b=2; Path=/',
          ])
          ..remove('a');

        expect(store.cookies, equals({'b': '2'}));
      });

      test('is a no-op when the name is absent', () {
        store
          ..storeFromSetCookie(['a=1; Path=/'])
          ..remove('missing');

        expect(store.cookies, equals({'a': '1'}));
      });
    });

    group('clear', () {
      test('removes all cookies', () {
        store
          ..storeFromSetCookie([
            'a=1; Path=/',
            'b=2; Path=/',
          ])
          ..clear();

        expect(store.isEmpty, isTrue);
        expect(store.header, isNull);
      });
    });

    group('cookies', () {
      test('returns an unmodifiable view', () {
        store.storeFromSetCookie(['a=1; Path=/']);

        expect(
          () => store.cookies['b'] = '2',
          throwsUnsupportedError,
        );
      });
    });
  });
}
