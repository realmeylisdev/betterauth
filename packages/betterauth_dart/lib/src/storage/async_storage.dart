import 'package:meta/meta.dart';

/// {@template async_storage}
/// A minimal asynchronous key-value store used by the client to persist the
/// session token (and an optimistic session snapshot).
///
/// The pure-Dart core ships only [InMemoryAsyncStorage]. Platform-backed
/// implementations — for example a `flutter_secure_storage` adapter — live in
/// `betterauth_flutter` so the core stays free of platform dependencies.
/// {@endtemplate}
abstract class AsyncStorage {
  /// {@macro async_storage}
  const AsyncStorage();

  /// Returns the value stored under [key], or `null` if absent.
  Future<String?> getItem({required String key});

  /// Stores [value] under [key], overwriting any existing value.
  Future<void> setItem({required String key, required String value});

  /// Removes any value stored under [key]. A no-op if nothing is stored.
  Future<void> removeItem({required String key});
}

/// {@template in_memory_async_storage}
/// An [AsyncStorage] backed by an in-memory [Map].
///
/// This is the default store: it requires no platform support and is ideal for
/// tests and ephemeral, non-persistent sessions. Data does not survive a
/// process restart.
/// {@endtemplate}
class InMemoryAsyncStorage extends AsyncStorage {
  /// {@macro in_memory_async_storage}
  InMemoryAsyncStorage();

  /// The backing map. Exposed only for assertions in tests.
  @visibleForTesting
  final Map<String, String> store = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => store[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    store[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    store.remove(key);
  }
}
