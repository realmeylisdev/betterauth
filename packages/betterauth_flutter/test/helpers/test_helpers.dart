import 'package:betterauth_flutter/betterauth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

export 'package:http_mock_adapter/http_mock_adapter.dart' show Matchers;

/// Base URL used across tests.
const String testBaseUrl = 'https://api.test/api/auth';

/// Builds a URL under [testBaseUrl] for registering mock routes.
String testUrl(String path) => '$testBaseUrl$path';

/// A client wired to a mocked Dio for tests.
typedef TestClient = ({
  BetterAuthClient client,
  DioAdapter adapter,
  InMemoryAsyncStorage storage,
});

/// Builds a [BetterAuthClient] backed by a [DioAdapter], with retries and the
/// proactive refresh timer disabled by default for deterministic tests.
TestClient buildTestClient({
  BetterAuthClientOptions? options,
  InMemoryAsyncStorage? storage,
  void Function()? onUnauthorized,
}) {
  final dio = Dio();
  final adapter = DioAdapter(dio: dio);
  final store = storage ?? InMemoryAsyncStorage();
  final client = BetterAuthClient(
    baseUrl: Uri.parse(testBaseUrl),
    options:
        options ??
        const BetterAuthClientOptions(maxRetries: 0, autoRefresh: false),
    storage: store,
    dio: dio,
    onUnauthorized: onUnauthorized,
  );
  return (client: client, adapter: adapter, storage: store);
}

/// Registers a POST stub for [path] matching any body, replying with [status]
/// and [body] (and optional response [headers]; content-type is always set).
void stubPost(
  DioAdapter adapter,
  String path, {
  int status = 200,
  Object? body,
  Map<String, List<String>>? headers,
}) {
  adapter.onPost(
    testUrl(path),
    (server) => server.reply(
      status,
      body,
      headers: <String, List<String>>{
        'content-type': const ['application/json'],
        ...?headers,
      },
    ),
    data: Matchers.any,
  );
}

/// Registers a GET stub for [path].
void stubGet(
  DioAdapter adapter,
  String path, {
  int status = 200,
  Object? body,
  Map<String, List<String>>? headers,
}) {
  adapter.onGet(
    testUrl(path),
    (server) => server.reply(
      status,
      body,
      headers: <String, List<String>>{
        'content-type': const ['application/json'],
        ...?headers,
      },
    ),
  );
}

/// A canonical user JSON map.
Map<String, dynamic> userJson({
  String id = 'user_1',
  String name = 'Ada',
  String email = 'ada@example.com',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'email': email,
  'emailVerified': true,
  'image': null,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
};

/// A canonical session JSON map.
Map<String, dynamic> sessionJson({
  String token = 'tok_123',
  String expiresAt = '2027-01-01T00:00:00.000Z',
}) => <String, dynamic>{
  'id': 'sess_1',
  'userId': 'user_1',
  'token': token,
  'expiresAt': expiresAt,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'ipAddress': '127.0.0.1',
  'userAgent': 'test',
};
