import 'package:betterauth_dart/src/models/auth_change_event.dart';
import 'package:betterauth_dart/src/models/session.dart';
import 'package:betterauth_dart/src/models/user.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template auth_state}
/// A snapshot of authentication state emitted on
/// `BetterAuthClient.onAuthStateChange`.
///
/// Carries the [event] that triggered the change and the current [session] and
/// [user] (both `null` when signed out).
/// {@endtemplate}
@immutable
class AuthState extends Equatable {
  /// {@macro auth_state}
  const AuthState(this.event, {this.session, this.user});

  /// The transition that produced this state.
  final AuthChangeEvent event;

  /// The current session, or `null` when signed out.
  final Session? session;

  /// The current user, or `null` when signed out.
  final User? user;

  /// Whether a non-null [session] is present.
  bool get isAuthenticated => session != null;

  @override
  List<Object?> get props => [event, session, user];

  @override
  String toString() =>
      'AuthState(event: $event, authenticated: $isAuthenticated)';
}
