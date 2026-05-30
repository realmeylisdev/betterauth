import 'package:betterauth_dart/src/storage/async_storage.dart';
import 'package:test/test.dart';

void main() {
  group(InMemoryAsyncStorage, () {
    late InMemoryAsyncStorage storage;

    setUp(() {
      storage = InMemoryAsyncStorage();
    });

    test('setItem stores the value under the key', () async {
      await storage.setItem(key: 'k', value: 'v');

      expect(storage.store['k'], equals('v'));
    });

    test('getItem returns the stored value', () async {
      await storage.setItem(key: 'k', value: 'v');

      expect(await storage.getItem(key: 'k'), equals('v'));
    });

    test('getItem returns null when the key is absent', () async {
      expect(await storage.getItem(key: 'missing'), isNull);
    });

    test('setItem overwrites an existing value', () async {
      await storage.setItem(key: 'k', value: 'v1');
      await storage.setItem(key: 'k', value: 'v2');

      expect(await storage.getItem(key: 'k'), equals('v2'));
    });

    test('removeItem deletes the stored value', () async {
      await storage.setItem(key: 'k', value: 'v');

      await storage.removeItem(key: 'k');

      expect(await storage.getItem(key: 'k'), isNull);
    });

    test('removeItem is a no-op when the key is absent', () async {
      await storage.removeItem(key: 'missing');

      expect(storage.store, isEmpty);
    });

    test('store is empty on construction', () {
      expect(storage.store, isEmpty);
    });
  });
}
