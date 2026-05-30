import 'dart:async';
import 'dart:convert';

import 'package:betterauth_dart/src/client_options.dart';
import 'package:betterauth_dart/src/groups/account_group.dart';
import 'package:betterauth_dart/src/groups/anonymous_group.dart';
import 'package:betterauth_dart/src/groups/email_otp_group.dart';
import 'package:betterauth_dart/src/groups/email_verification_group.dart';
import 'package:betterauth_dart/src/groups/magic_link_group.dart';
import 'package:betterauth_dart/src/groups/organization_group.dart';
import 'package:betterauth_dart/src/groups/passkey_group.dart';
import 'package:betterauth_dart/src/groups/password_group.dart';
import 'package:betterauth_dart/src/groups/phone_number_group.dart';
import 'package:betterauth_dart/src/groups/session_group.dart';
import 'package:betterauth_dart/src/groups/session_sink.dart';
import 'package:betterauth_dart/src/groups/sign_in_group.dart';
import 'package:betterauth_dart/src/groups/sign_up_group.dart';
import 'package:betterauth_dart/src/groups/two_factor_group.dart';
import 'package:betterauth_dart/src/groups/user_group.dart';
import 'package:betterauth_dart/src/groups/username_group.dart';
import 'package:betterauth_dart/src/http/better_auth_http.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';
import 'package:betterauth_dart/src/storage/async_storage.dart';
import 'package:betterauth_dart/src/token/token_store.dart';
import 'package:dio/dio.dart';

/// {@template better_auth_client}
/// A pure-Dart client for a better-auth server.
///
/// Exposes the API as namespaced groups (`signUp`, `signIn`, `session`,
/// `user`, `account`, `password`, `emailVerification`, `emailOtp`, `magicLink`,
/// `phoneNumber`, `username`, `twoFactor`), maintains the current session, and
/// broadcasts changes on [onAuthStateChange]. Every call returns an
/// [AuthResult] and never throws.
///
/// In Flutter apps, prefer the `betterauth_flutter` package which wires secure
/// storage, lifecycle-driven refresh and a `BetterAuth` singleton on top of
/// this client.
/// {@endtemplate}
class BetterAuthClient implements SessionSink {
  /// {@macro better_auth_client}
  ///
  /// [baseUrl] is the full base URL of the server's auth routes, e.g.
  /// `https://api.example.com/api/auth`. Provide a [storage] to persist the
  /// session (the default is in-memory and does not survive a restart). Pass a
  /// [dio] instance and/or extra [interceptors] to customise transport, and
  /// [onUnauthorized] to react to a 401 (the client also signs out locally).
  BetterAuthClient({
    required Uri baseUrl,
    this.options = const BetterAuthClientOptions(),
    AsyncStorage? storage,
    Dio? dio,
    List<Interceptor>? interceptors,
    void Function()? onUnauthorized,
    void Function(String message)? logger,
  }) : _storage = storage ?? InMemoryAsyncStorage(),
       _onUnauthorized = onUnauthorized {
    _tokenStore = TokenStore();
    _http = BetterAuthHttp(
      baseUrl: baseUrl,
      options: options,
      tokenStore: _tokenStore,
      dio: dio,
      interceptors: interceptors,
      onUnauthorized: _handleUnauthorized,
      logger: logger,
    );
    signUp = SignUpGroup(_http, this);
    signIn = SignInGroup(_http, this);
    session = SessionGroup(_http, this);
    user = UserGroup(_http, this);
    account = AccountGroup(_http, this);
    password = PasswordGroup(_http, this);
    emailVerification = EmailVerificationGroup(_http, this);
    emailOtp = EmailOtpGroup(_http, this);
    magicLink = MagicLinkGroup(_http, this);
    phoneNumber = PhoneNumberGroup(_http, this);
    username = UsernameGroup(_http, this);
    twoFactor = TwoFactorGroup(_http, this);
    anonymous = AnonymousGroup(_http, this);
    passkey = PasskeyGroup(_http, this);
    organization = OrganizationGroup(_http, this);
  }

  /// The configuration in effect.
  final BetterAuthClientOptions options;

  final AsyncStorage _storage;
  final void Function()? _onUnauthorized;
  late final TokenStore _tokenStore;
  late final BetterAuthHttp _http;

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  Session? _currentSession;
  User? _currentUser;
  Timer? _refreshTimer;
  bool _initialized = false;

  /// Account creation (`POST /sign-up/*`).
  late final SignUpGroup signUp;

  /// Sign-in flows (`POST /sign-in/*`).
  late final SignInGroup signIn;

  /// Session inspection and revocation.
  late final SessionGroup session;

  /// Current-user mutations.
  late final UserGroup user;

  /// Linked accounts.
  late final AccountGroup account;

  /// Password reset and change.
  late final PasswordGroup password;

  /// Email verification.
  late final EmailVerificationGroup emailVerification;

  /// Email one-time-password flows.
  late final EmailOtpGroup emailOtp;

  /// Magic-link verification.
  late final MagicLinkGroup magicLink;

  /// Phone-number OTP flows.
  late final PhoneNumberGroup phoneNumber;

  /// Username utilities.
  late final UsernameGroup username;

  /// Two-factor authentication.
  late final TwoFactorGroup twoFactor;

  /// Anonymous-user actions (`client.anonymous`).
  late final AnonymousGroup anonymous;

  /// WebAuthn passkey actions (`client.passkey`).
  late final PasskeyGroup passkey;

  /// Organization, member, invitation and team actions
  /// (`client.organization`).
  late final OrganizationGroup organization;

  /// A broadcast stream of auth-state transitions. Late subscribers do not
  /// receive prior events; read [currentSession]/[currentUser] for the current
  /// value and listen for subsequent changes.
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  /// The current session, or `null` when signed out.
  Session? get currentSession => _currentSession;

  /// The current user, or `null` when signed out.
  User? get currentUser => _currentUser;

  /// The current bearer token, or `null`.
  String? get currentToken => _tokenStore.token;

  /// Whether there is a non-expired session.
  bool get isAuthenticated =>
      _currentSession != null && !_currentSession!.isExpired;

  /// Restores any persisted session, emits [AuthChangeEvent.initialSession],
  /// then validates the session against the server in the background.
  ///
  /// Safe to call once; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _restoreFromStorage();
    _emit(AuthChangeEvent.initialSession);
    if (_currentSession != null) {
      _scheduleRefresh();
      unawaited(hydrate(event: AuthChangeEvent.sessionRefreshed));
    }
  }

  /// Signs the current user out (`POST /sign-out`) and clears local state
  /// regardless of the server response.
  Future<AuthResult<StatusResponse>> signOut() async {
    final raw = await _http.request('/sign-out', method: 'POST');
    await signOutLocally();
    return switch (raw) {
      AuthFailure<Object?>(:final error) => AuthFailure<StatusResponse>(error),
      AuthSuccess<Object?>(:final data) => AuthSuccess<StatusResponse>(
        StatusResponse.fromJson(
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
        ),
      ),
    };
  }

  /// Manually re-fetches the session, emitting
  /// [AuthChangeEvent.sessionRefreshed] on success.
  Future<void> refresh() => hydrate(event: AuthChangeEvent.sessionRefreshed);

  @override
  Future<void> hydrate({
    String? token,
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  }) async {
    if (token != null) _tokenStore.token = token;
    final result = await session.get();
    if (result case AuthSuccess<SessionResponse?>(:final data)) {
      if (data == null) {
        await signOutLocally();
        return;
      }
      _currentSession = data.session;
      _currentUser = data.user;
      await _persist();
      _scheduleRefresh();
      _emit(event);
    }
  }

  @override
  Future<void> setSession({
    required Session session,
    required User user,
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  }) async {
    _tokenStore.token = session.token;
    _currentSession = session;
    _currentUser = user;
    await _persist();
    _scheduleRefresh();
    _emit(event);
  }

  @override
  Future<void> signOutLocally() async {
    _tokenStore.clear();
    _currentSession = null;
    _currentUser = null;
    _cancelRefresh();
    await _clearStorage();
    _emit(AuthChangeEvent.signedOut);
  }

  /// Releases resources: cancels the refresh timer, closes the auth-state
  /// stream and the underlying HTTP client.
  Future<void> dispose() async {
    _cancelRefresh();
    await _authStateController.close();
    _http.close();
  }

  void _handleUnauthorized() {
    if (_currentSession != null || _tokenStore.hasToken) {
      unawaited(signOutLocally());
    }
    _onUnauthorized?.call();
  }

  void _emit(AuthChangeEvent event) {
    if (_authStateController.isClosed) return;
    _authStateController.add(
      AuthState(event, session: _currentSession, user: _currentUser),
    );
  }

  void _scheduleRefresh() {
    _cancelRefresh();
    if (!options.autoRefresh) return;
    final expiresAt = _currentSession?.expiresAt;
    if (expiresAt == null) return;
    final fireAt = expiresAt.subtract(options.refreshLeadTime);
    final delay = fireAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) return;
    _refreshTimer = Timer(delay, () {
      unawaited(hydrate(event: AuthChangeEvent.sessionRefreshed));
    });
  }

  void _cancelRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _persist() async {
    final snapshot = jsonEncode(<String, dynamic>{
      'token': _tokenStore.token,
      'cookies': _tokenStore.cookies.cookies,
      'session': _currentSession?.toJson(),
      'user': _currentUser?.toJson(),
    });
    await _storage.setItem(key: options.sessionStorageKey, value: snapshot);
    final token = _tokenStore.token;
    if (token != null) {
      await _storage.setItem(
        key: options.sessionTokenStorageKey,
        value: token,
      );
    }
  }

  Future<void> _clearStorage() async {
    await _storage.removeItem(key: options.sessionStorageKey);
    await _storage.removeItem(key: options.sessionTokenStorageKey);
  }

  Future<void> _restoreFromStorage() async {
    final raw = await _storage.getItem(key: options.sessionStorageKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final token = map['token'] as String?;
      if (token != null) _tokenStore.token = token;
      final cookies = map['cookies'];
      if (cookies is Map) {
        _tokenStore.cookies.loadFromMap(
          cookies.map((key, value) => MapEntry('$key', '$value')),
        );
      }
      final session = map['session'];
      if (session is Map) {
        _currentSession = Session.fromJson(Map<String, dynamic>.from(session));
      }
      final user = map['user'];
      if (user is Map) {
        _currentUser = User.fromJson(Map<String, dynamic>.from(user));
      }
    } on Object {
      // Corrupt snapshot — start unauthenticated.
      _tokenStore.clear();
      _currentSession = null;
      _currentUser = null;
    }
  }
}
