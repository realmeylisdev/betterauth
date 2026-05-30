/// {@template auth_change_event}
/// The kind of transition described by an `AuthState` emitted on
/// `BetterAuthClient.onAuthStateChange`.
/// {@endtemplate}
enum AuthChangeEvent {
  /// The first event emitted after the client starts, carrying the restored
  /// session (or `null` if there was none).
  initialSession,

  /// A user signed in (or signed up with an immediate session).
  signedIn,

  /// The user signed out, or the session was revoked/expired.
  signedOut,

  /// An existing session was re-validated/extended via `/get-session`.
  sessionRefreshed,

  /// The authenticated user's profile changed (for example after
  /// `updateUser`).
  userUpdated,
}
