import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// {@template secure_storage_adapter}
/// An [AsyncStorage] backed by `flutter_secure_storage`, persisting the session
/// token and snapshot in the platform keystore (iOS Keychain / Android
/// EncryptedSharedPreferences).
/// {@endtemplate}
class SecureStorageAdapter extends AsyncStorage {
  /// {@macro secure_storage_adapter}
  ///
  /// Inject a [storage] to customise options or to substitute a fake in tests.
  SecureStorageAdapter({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: key);
}
