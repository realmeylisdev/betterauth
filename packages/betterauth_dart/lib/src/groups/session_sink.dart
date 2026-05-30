import 'package:betterauth_dart/src/models/auth_change_event.dart';
import 'package:betterauth_dart/src/models/session.dart';
import 'package:betterauth_dart/src/models/user.dart';

/// {@template session_sink}
/// The hooks a group uses to drive client auth-state transitions, persistence
/// and the `onAuthStateChange` stream — without depending on the concrete
/// client (avoiding a dependency cycle). `BetterAuthClient` implements this.
/// {@endtemplate}
abstract interface class SessionSink {
  /// Adopts [token] (when provided), fetches the full session via
  /// `/get-session`, updates the current session/user, persists, and emits
  /// [event]. If the server reports no session, this signs out locally.
  Future<void> hydrate({
    String? token,
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  });

  /// Adopts a fully-known [session]/[user] directly (used by flows that return
  /// a complete session, such as magic-link verify), persists, and emits
  /// [event].
  Future<void> setSession({
    required Session session,
    required User user,
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  });

  /// Clears the token, cookies, current session and persisted snapshot, then
  /// emits [AuthChangeEvent.signedOut].
  Future<void> signOutLocally();
}
