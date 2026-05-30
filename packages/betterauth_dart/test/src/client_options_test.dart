// Const constructors run before tests and can skew coverage of the unit under
// test, so they are disallowed here.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group(AuthTransportMode, () {
    test('exposes bearer and cookie in declaration order', () {
      expect(
        AuthTransportMode.values,
        equals([AuthTransportMode.bearer, AuthTransportMode.cookie]),
      );
    });
  });

  group(BetterAuthClientOptions, () {
    group('defaults', () {
      late BetterAuthClientOptions options;

      setUp(() {
        options = BetterAuthClientOptions();
      });

      test('transportMode defaults to bearer', () {
        expect(options.transportMode, equals(AuthTransportMode.bearer));
      });

      test('timeout defaults to kDefaultTimeout', () {
        expect(options.timeout, equals(kDefaultTimeout));
      });

      test('maxRetries defaults to kDefaultMaxRetries', () {
        expect(options.maxRetries, equals(kDefaultMaxRetries));
      });

      test('enableLogging defaults to null', () {
        expect(options.enableLogging, isNull);
      });

      test('autoRefresh defaults to true', () {
        expect(options.autoRefresh, isTrue);
      });

      test('refreshLeadTime defaults to one minute', () {
        expect(options.refreshLeadTime, equals(const Duration(minutes: 1)));
      });

      test('sessionTokenStorageKey defaults to kSessionTokenStorageKey', () {
        expect(
          options.sessionTokenStorageKey,
          equals(kSessionTokenStorageKey),
        );
      });

      test('sessionStorageKey defaults to kSessionStorageKey', () {
        expect(options.sessionStorageKey, equals(kSessionStorageKey));
      });
    });

    group('copyWith', () {
      late BetterAuthClientOptions base;

      setUp(() {
        base = BetterAuthClientOptions();
      });

      test('with no arguments preserves all field values', () {
        final original = BetterAuthClientOptions(
          transportMode: AuthTransportMode.cookie,
          timeout: const Duration(seconds: 5),
          maxRetries: 7,
          enableLogging: true,
          autoRefresh: false,
          refreshLeadTime: const Duration(seconds: 42),
          sessionTokenStorageKey: 'tk',
          sessionStorageKey: 'sk',
        );

        final copy = original.copyWith();

        expect(copy.transportMode, equals(AuthTransportMode.cookie));
        expect(copy.timeout, equals(const Duration(seconds: 5)));
        expect(copy.maxRetries, equals(7));
        expect(copy.enableLogging, isTrue);
        expect(copy.autoRefresh, isFalse);
        expect(copy.refreshLeadTime, equals(const Duration(seconds: 42)));
        expect(copy.sessionTokenStorageKey, equals('tk'));
        expect(copy.sessionStorageKey, equals('sk'));
      });

      test('replaces transportMode and leaves others unchanged', () {
        final copy = base.copyWith(transportMode: AuthTransportMode.cookie);
        expect(copy.transportMode, equals(AuthTransportMode.cookie));
        expect(copy.timeout, equals(base.timeout));
      });

      test('replaces timeout and leaves others unchanged', () {
        final copy = base.copyWith(timeout: const Duration(seconds: 5));
        expect(copy.timeout, equals(const Duration(seconds: 5)));
        expect(copy.transportMode, equals(base.transportMode));
      });

      test('replaces maxRetries and leaves others unchanged', () {
        final copy = base.copyWith(maxRetries: 7);
        expect(copy.maxRetries, equals(7));
        expect(copy.timeout, equals(base.timeout));
      });

      test('replaces enableLogging and leaves others unchanged', () {
        final copy = base.copyWith(enableLogging: true);
        expect(copy.enableLogging, isTrue);
        expect(copy.maxRetries, equals(base.maxRetries));
      });

      test('replaces autoRefresh and leaves others unchanged', () {
        final copy = base.copyWith(autoRefresh: false);
        expect(copy.autoRefresh, isFalse);
        expect(copy.enableLogging, equals(base.enableLogging));
      });

      test('replaces refreshLeadTime and leaves others unchanged', () {
        final copy = base.copyWith(
          refreshLeadTime: const Duration(seconds: 30),
        );
        expect(copy.refreshLeadTime, equals(const Duration(seconds: 30)));
        expect(copy.autoRefresh, equals(base.autoRefresh));
      });

      test('replaces sessionTokenStorageKey and leaves others unchanged', () {
        final copy = base.copyWith(sessionTokenStorageKey: 'custom.token');
        expect(copy.sessionTokenStorageKey, equals('custom.token'));
        expect(copy.sessionStorageKey, equals(base.sessionStorageKey));
      });

      test('replaces sessionStorageKey and leaves others unchanged', () {
        final copy = base.copyWith(sessionStorageKey: 'custom.session');
        expect(copy.sessionStorageKey, equals('custom.session'));
        expect(
          copy.sessionTokenStorageKey,
          equals(base.sessionTokenStorageKey),
        );
      });

      test('replaces every field at once', () {
        final copy = base.copyWith(
          transportMode: AuthTransportMode.cookie,
          timeout: const Duration(seconds: 1),
          maxRetries: 0,
          enableLogging: false,
          autoRefresh: false,
          refreshLeadTime: const Duration(seconds: 2),
          sessionTokenStorageKey: 'tk',
          sessionStorageKey: 'sk',
        );
        expect(copy.transportMode, equals(AuthTransportMode.cookie));
        expect(copy.timeout, equals(const Duration(seconds: 1)));
        expect(copy.maxRetries, equals(0));
        expect(copy.enableLogging, isFalse);
        expect(copy.autoRefresh, isFalse);
        expect(copy.refreshLeadTime, equals(const Duration(seconds: 2)));
        expect(copy.sessionTokenStorageKey, equals('tk'));
        expect(copy.sessionStorageKey, equals('sk'));
      });

      test('keeps a non-null enableLogging when not overridden', () {
        final withLogging = base.copyWith(enableLogging: true);
        final copy = withLogging.copyWith(maxRetries: 2);
        expect(copy.enableLogging, isTrue);
        expect(copy.maxRetries, equals(2));
      });
    });
  });
}
