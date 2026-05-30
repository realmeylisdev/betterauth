import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(SecureStorageAdapter, () {
    late _MockSecureStorage storage;
    late SecureStorageAdapter adapter;

    setUp(() {
      storage = _MockSecureStorage();
      adapter = SecureStorageAdapter(storage: storage);
    });

    test('is an AsyncStorage', () {
      expect(adapter, isA<AsyncStorage>());
    });

    test('default constructor builds an AsyncStorage without args', () {
      expect(SecureStorageAdapter(), isA<AsyncStorage>());
    });

    test('getItem delegates to read and returns the value', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'value');

      final result = await adapter.getItem(key: 'session');

      expect(result, 'value');
      verify(() => storage.read(key: 'session')).called(1);
    });

    test('getItem returns null when read returns null', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await adapter.getItem(key: 'missing');

      expect(result, isNull);
      verify(() => storage.read(key: 'missing')).called(1);
    });

    test('setItem delegates to write with key and value', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await adapter.setItem(key: 'session', value: 'tok');

      verify(() => storage.write(key: 'session', value: 'tok')).called(1);
    });

    test('removeItem delegates to delete with key', () async {
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await adapter.removeItem(key: 'session');

      verify(() => storage.delete(key: 'session')).called(1);
    });
  });
}
