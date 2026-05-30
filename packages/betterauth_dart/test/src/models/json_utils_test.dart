import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:test/test.dart';

void main() {
  group('parseRequiredDate', () {
    test('parses a valid ISO-8601 string into a UTC DateTime', () {
      final result = parseRequiredDate('2026-01-01T00:00:00.000Z');

      expect(result, equals(DateTime.utc(2026)));
      expect(result.isUtc, isTrue);
    });

    test('converts a non-UTC string to UTC', () {
      final result = parseRequiredDate('2026-01-01T05:00:00.000+05:00');

      expect(result, equals(DateTime.utc(2026)));
      expect(result.isUtc, isTrue);
    });

    test('throws a FormatException when value is null', () {
      expect(
        () => parseRequiredDate(null),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws a FormatException when value is an invalid string', () {
      expect(
        () => parseRequiredDate('not-a-date'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws a FormatException when value is a non-string type', () {
      expect(
        () => parseRequiredDate(42),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('parseOptionalDate', () {
    test('returns null when value is null', () {
      expect(parseOptionalDate(null), isNull);
    });

    test('returns the UTC form of a DateTime value', () {
      final local = DateTime(2026, 1, 1, 5);
      final result = parseOptionalDate(local);

      expect(result, equals(local.toUtc()));
      expect(result!.isUtc, isTrue);
    });

    test('parses a valid ISO-8601 string into a UTC DateTime', () {
      final result = parseOptionalDate('2026-06-15T12:30:00.000Z');

      expect(result, equals(DateTime.utc(2026, 6, 15, 12, 30)));
      expect(result!.isUtc, isTrue);
    });

    test('returns null for an unparseable string', () {
      expect(parseOptionalDate('definitely-not-a-date'), isNull);
    });

    test('returns null for a non-string, non-DateTime value', () {
      expect(parseOptionalDate(123), isNull);
    });
  });

  group('encodeDate', () {
    test('serializes a UTC DateTime to an ISO-8601 string', () {
      final result = encodeDate(DateTime.utc(2026));

      expect(result, equals('2026-01-01T00:00:00.000Z'));
    });

    test('converts a local DateTime to UTC before serializing', () {
      final local = DateTime(2026, 1, 1, 5);
      final result = encodeDate(local);

      expect(result, equals(local.toUtc().toIso8601String()));
    });
  });

  group('extractAdditionalFields', () {
    test('returns only keys not present in knownKeys', () {
      final json = <String, dynamic>{
        'id': 'x',
        'name': 'y',
        'extra': 1,
        'plugin': true,
      };

      final result = extractAdditionalFields(json, const {'id', 'name'});

      expect(
        result,
        equals(<String, Object?>{'extra': 1, 'plugin': true}),
      );
    });

    test('returns an empty map when all keys are known', () {
      final json = <String, dynamic>{'id': 'x', 'name': 'y'};

      final result = extractAdditionalFields(json, const {'id', 'name'});

      expect(result, isEmpty);
    });

    test('returns an empty map for an empty json input', () {
      final result = extractAdditionalFields(
        <String, dynamic>{},
        const {'id'},
      );

      expect(result, isEmpty);
    });

    test('preserves null values for unknown keys', () {
      final json = <String, dynamic>{'id': 'x', 'nullable': null};

      final result = extractAdditionalFields(json, const {'id'});

      expect(result, equals(<String, Object?>{'nullable': null}));
      expect(result.containsKey('nullable'), isTrue);
    });
  });
}
