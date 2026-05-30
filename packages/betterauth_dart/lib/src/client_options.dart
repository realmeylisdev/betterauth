import 'package:betterauth_dart/src/constants.dart';

/// How the client authenticates requests against the server.
enum AuthTransportMode {
  /// Send the session token as `Authorization: Bearer <token>` and read it from
  /// the `set-auth-token` response header. Requires the server `bearer` plugin.
  bearer,

  /// Capture the `Set-Cookie` session cookie and replay it as a `Cookie`
  /// request header. Works against any better-auth server.
  cookie,
}

/// {@template better_auth_client_options}
/// Tunable configuration for a `BetterAuthClient`.
/// {@endtemplate}
class BetterAuthClientOptions {
  /// {@macro better_auth_client_options}
  const BetterAuthClientOptions({
    this.transportMode = AuthTransportMode.bearer,
    this.timeout = kDefaultTimeout,
    this.maxRetries = kDefaultMaxRetries,
    this.enableLogging,
    this.autoRefresh = true,
    this.refreshLeadTime = const Duration(minutes: 1),
    this.sessionTokenStorageKey = kSessionTokenStorageKey,
    this.sessionStorageKey = kSessionStorageKey,
  });

  /// How requests are authenticated. Defaults to [AuthTransportMode.bearer].
  final AuthTransportMode transportMode;

  /// Connect/send/receive timeout. Defaults to [kDefaultTimeout] (30s).
  final Duration timeout;

  /// Maximum retry attempts for transient failures. Defaults to
  /// [kDefaultMaxRetries] (3). Set to `0` to disable retries.
  final int maxRetries;

  /// Whether the redacting request/response logger is enabled.
  ///
  /// `null` (the default) enables it automatically in debug builds and disables
  /// it in release builds. Set explicitly to force on or off.
  final bool? enableLogging;

  /// Whether to proactively re-fetch the session on a timer before it expires.
  /// Defaults to `true`.
  final bool autoRefresh;

  /// How far before `Session.expiresAt` the proactive refresh fires. Defaults
  /// to one minute.
  final Duration refreshLeadTime;

  /// Storage key for the persisted session token.
  final String sessionTokenStorageKey;

  /// Storage key for the persisted session snapshot (optimistic restore).
  final String sessionStorageKey;

  /// Returns a copy with the given fields replaced.
  BetterAuthClientOptions copyWith({
    AuthTransportMode? transportMode,
    Duration? timeout,
    int? maxRetries,
    bool? enableLogging,
    bool? autoRefresh,
    Duration? refreshLeadTime,
    String? sessionTokenStorageKey,
    String? sessionStorageKey,
  }) {
    return BetterAuthClientOptions(
      transportMode: transportMode ?? this.transportMode,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      enableLogging: enableLogging ?? this.enableLogging,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshLeadTime: refreshLeadTime ?? this.refreshLeadTime,
      sessionTokenStorageKey:
          sessionTokenStorageKey ?? this.sessionTokenStorageKey,
      sessionStorageKey: sessionStorageKey ?? this.sessionStorageKey,
    );
  }
}
