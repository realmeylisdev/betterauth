import 'dart:async';

import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:betterauth_flutter/src/authenticators.dart';
import 'package:betterauth_flutter/src/lifecycle_observer.dart';
import 'package:betterauth_flutter/src/secure_storage_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// {@template better_auth}
/// The Flutter entry point: a singleton wrapper around [BetterAuthClient] that
/// adds secure storage, lifecycle-driven refresh and native social sign-in.
///
/// Call [BetterAuth.initialize] once at startup, then use
/// [BetterAuth.instance].
/// {@endtemplate}
class BetterAuth {
  BetterAuth._({
    required this.client,
    required GoogleAuthenticator google,
    required AppleAuthenticator apple,
    required WebAuthenticator web,
    required PasskeyRegistrar passkeyRegistrar,
    required PasskeyAssertor passkeyAssertor,
  }) : _google = google,
       _apple = apple,
       _web = web,
       _passkeyRegistrar = passkeyRegistrar,
       _passkeyAssertor = passkeyAssertor;

  /// The underlying pure-Dart client.
  final BetterAuthClient client;

  final GoogleAuthenticator _google;
  final AppleAuthenticator _apple;
  final WebAuthenticator _web;
  final PasskeyRegistrar _passkeyRegistrar;
  final PasskeyAssertor _passkeyAssertor;
  LifecycleObserver? _observer;

  static BetterAuth? _instance;

  /// The initialized singleton. Throws a [StateError] if [initialize] has not
  /// been called.
  static BetterAuth get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'BetterAuth.initialize() must be called before accessing instance.',
      );
    }
    return instance;
  }

  /// Whether [initialize] has been called.
  static bool get isInitialized => _instance != null;

  /// Initializes the singleton against the server at [baseUrl].
  ///
  /// Persists to secure storage by default; pass [storage] to override. Set
  /// [refreshOnResume] to re-validate the session when the app foregrounds.
  /// The `*Authenticator` parameters exist for testing.
  static Future<BetterAuth> initialize({
    required Uri baseUrl,
    AsyncStorage? storage,
    BetterAuthClientOptions options = const BetterAuthClientOptions(),
    Dio? dio,
    List<Interceptor>? interceptors,
    void Function()? onUnauthorized,
    void Function(String message)? logger,
    bool refreshOnResume = true,
    BetterAuthClient? client,
    GoogleAuthenticator google = defaultGoogleAuthenticator,
    AppleAuthenticator apple = defaultAppleAuthenticator,
    WebAuthenticator web = defaultWebAuthenticator,
    PasskeyRegistrar passkeyRegistrar = defaultPasskeyRegistrar,
    PasskeyAssertor passkeyAssertor = defaultPasskeyAssertor,
  }) async {
    final resolvedClient =
        client ??
        BetterAuthClient(
          baseUrl: baseUrl,
          storage: storage ?? SecureStorageAdapter(),
          options: options,
          dio: dio,
          interceptors: interceptors,
          onUnauthorized: onUnauthorized,
          logger: logger,
        );
    final instance = BetterAuth._(
      client: resolvedClient,
      google: google,
      apple: apple,
      web: web,
      passkeyRegistrar: passkeyRegistrar,
      passkeyAssertor: passkeyAssertor,
    );
    await resolvedClient.initialize();
    if (refreshOnResume) {
      final observer = LifecycleObserver(
        () => unawaited(resolvedClient.refresh()),
      );
      instance._observer = observer;
      WidgetsBinding.instance.addObserver(observer);
    }
    _instance = instance;
    return instance;
  }

  /// Signs in with Google using the native flow, exchanging the id token via
  /// `/sign-in/social`.
  Future<AuthResult<SocialSignInResponse>> signInWithGoogle({
    List<String>? scopes,
  }) async {
    final idToken = await _google(scopes: scopes);
    if (idToken == null) {
      return AuthFailure(_cancelled('Google'));
    }
    return client.signIn.social(provider: 'google', idToken: idToken);
  }

  /// Signs in with Apple using the native flow, exchanging the id token via
  /// `/sign-in/social`.
  Future<AuthResult<SocialSignInResponse>> signInWithApple({
    List<String>? scopes,
  }) async {
    final idToken = await _apple(scopes: scopes);
    if (idToken == null) {
      return AuthFailure(_cancelled('Apple'));
    }
    return client.signIn.social(provider: 'apple', idToken: idToken);
  }

  /// Signs in with a social [provider] via a browser redirect.
  ///
  /// Opens the provider's authorization page in an ephemeral browser session,
  /// then adopts the resulting session. Requires the server to redirect back to
  /// `<callbackUrlScheme>://...` carrying the session token, or to expose the
  /// session to a subsequent `/get-session`.
  Future<AuthResult<SocialSignInResponse>> signInWithProvider({
    required String provider,
    required String callbackUrlScheme,
    List<String>? scopes,
  }) async {
    final start = await client.signIn.social(
      provider: provider,
      callbackURL: '$callbackUrlScheme://callback',
      scopes: scopes,
    );
    final data = start.dataOrNull;
    if (start is AuthFailure<SocialSignInResponse> || data is! SocialRedirect) {
      return start;
    }

    final callback = await _web(
      url: data.url,
      callbackUrlScheme: callbackUrlScheme,
    );
    final token =
        callback.queryParameters['token'] ??
        callback.queryParameters['session_token'];
    if (token != null) {
      await client.hydrate(token: token);
    } else {
      await client.refresh();
    }

    final session = client.currentSession;
    final user = client.currentUser;
    if (session != null && user != null) {
      return AuthSuccess(SocialSignedIn(token: session.token, user: user));
    }
    return const AuthFailure(
      AuthApiException('Social sign-in did not establish a session.'),
    );
  }

  /// Signs in anonymously (requires the anonymous plugin).
  Future<AuthResult<AuthSession>> signInAnonymously() =>
      client.signIn.anonymous();

  /// Registers a new passkey for the signed-in user via the native ceremony,
  /// returning the created [Passkey].
  ///
  /// Fetches creation options, runs the platform registrar, then verifies with
  /// the server. Returns an [AuthFailure] if the user cancels.
  Future<AuthResult<Passkey>> registerPasskey({String? name}) async {
    final optionsResult = await client.passkey.generateRegisterOptions();
    if (optionsResult case AuthFailure<Map<String, dynamic>>(:final error)) {
      return AuthFailure(error);
    }
    final attestation = await _passkeyRegistrar(optionsResult.dataOrNull!);
    if (attestation == null) {
      return AuthFailure(_cancelled('Passkey'));
    }
    return client.passkey.verifyRegistration(response: attestation, name: name);
  }

  /// Signs in with a passkey via the native ceremony (requires the passkey
  /// plugin). Pass [email] to scope credential selection.
  Future<AuthResult<AuthSession>> signInWithPasskey({String? email}) async {
    final optionsResult = await client.passkey.generateAuthenticateOptions(
      email: email,
    );
    if (optionsResult case AuthFailure<Map<String, dynamic>>(:final error)) {
      return AuthFailure(error);
    }
    final assertion = await _passkeyAssertor(optionsResult.dataOrNull!);
    if (assertion == null) {
      return AuthFailure(_cancelled('Passkey'));
    }
    return client.signIn.passkey(response: assertion);
  }

  /// Disposes the client, removes the lifecycle observer and clears the
  /// singleton.
  Future<void> dispose() async {
    final observer = _observer;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
      _observer = null;
    }
    await client.dispose();
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  static AuthApiException _cancelled(String provider) =>
      AuthApiException('$provider sign-in was cancelled.');
}
