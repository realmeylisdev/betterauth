import 'dart:async';

import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// High-level authentication status surfaced to the UI.
enum AuthStatus {
  /// Initial state before the first auth event.
  unknown,

  /// A valid session is present.
  authenticated,

  /// No session is present.
  unauthenticated,

  /// A password sign-in succeeded but a second factor is required.
  twoFactorRequired,
}

/// {@template auth_cubit_state}
/// Immutable state exposed by [AuthCubit].
/// {@endtemplate}
class AuthCubitState extends Equatable {
  /// {@macro auth_cubit_state}
  const AuthCubitState({
    this.status = AuthStatus.unknown,
    this.user,
    this.session,
    this.error,
    this.twoFactorMethods = const [],
    this.isSubmitting = false,
  });

  /// The current high-level status.
  final AuthStatus status;

  /// The authenticated user, if any.
  final User? user;

  /// The current session, if any.
  final Session? session;

  /// The most recent error, cleared on the next request.
  final AuthException? error;

  /// Available second-factor methods when [status] is
  /// [AuthStatus.twoFactorRequired].
  final List<String> twoFactorMethods;

  /// Whether a request is in flight.
  final bool isSubmitting;

  /// Whether the user is authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Returns a copy with the given fields replaced. Set [clearError] to drop
  /// the current [error].
  AuthCubitState copyWith({
    AuthStatus? status,
    User? user,
    Session? session,
    AuthException? error,
    bool clearError = false,
    List<String>? twoFactorMethods,
    bool? isSubmitting,
  }) {
    return AuthCubitState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
      twoFactorMethods: twoFactorMethods ?? this.twoFactorMethods,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    session,
    error,
    twoFactorMethods,
    isSubmitting,
  ];
}

/// {@template auth_cubit}
/// A [Cubit] that exposes authentication state and actions over a
/// [BetterAuthClient].
///
/// It seeds from the client's current session and then mirrors
/// [BetterAuthClient.onAuthStateChange], so sign-ins completed elsewhere (for
/// example native social sign-in via `BetterAuth`) are reflected automatically.
/// {@endtemplate}
class AuthCubit extends Cubit<AuthCubitState> {
  /// {@macro auth_cubit}
  AuthCubit(this._client) : super(_initialState(_client)) {
    _subscription = _client.onAuthStateChange.listen(_onAuthStateChange);
  }

  final BetterAuthClient _client;
  late final StreamSubscription<AuthState> _subscription;

  static AuthCubitState _initialState(BetterAuthClient client) {
    final session = client.currentSession;
    if (session != null) {
      return AuthCubitState(
        status: AuthStatus.authenticated,
        session: session,
        user: client.currentUser,
      );
    }
    return const AuthCubitState(status: AuthStatus.unauthenticated);
  }

  void _onAuthStateChange(AuthState authState) {
    if (authState.session != null) {
      emit(
        AuthCubitState(
          status: AuthStatus.authenticated,
          session: authState.session,
          user: authState.user,
        ),
      );
    } else {
      emit(const AuthCubitState(status: AuthStatus.unauthenticated));
    }
  }

  /// Signs up with email and password.
  Future<void> signUpEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _client.signUp.email(
      name: name,
      email: email,
      password: password,
    );
    _settle(result);
  }

  /// Signs in with email and password, handling a two-factor challenge.
  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settleSignIn(
      await _client.signIn.email(email: email, password: password),
    );
  }

  /// Signs in with username and password.
  Future<void> signInUsername({
    required String username,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settleSignIn(
      await _client.signIn.username(username: username, password: password),
    );
  }

  /// Signs in with an email OTP.
  Future<void> signInEmailOtp({
    required String email,
    required String otp,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settle(await _client.signIn.emailOtp(email: email, otp: otp));
  }

  /// Signs in anonymously (requires the anonymous plugin).
  Future<void> signInAnonymously() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settle(await _client.signIn.anonymous());
  }

  /// Completes a two-factor TOTP challenge.
  Future<void> verifyTotp({required String code, bool? trustDevice}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settle(
      await _client.twoFactor.verifyTotp(code: code, trustDevice: trustDevice),
    );
  }

  /// Completes a two-factor OTP challenge.
  Future<void> verifyTwoFactorOtp({
    required String code,
    bool? trustDevice,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    _settle(
      await _client.twoFactor.verifyOtp(code: code, trustDevice: trustDevice),
    );
  }

  /// Signs the user out.
  Future<void> signOut() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    await _client.signOut();
    emit(state.copyWith(isSubmitting: false));
  }

  void _settleSignIn(AuthResult<SignInResponse> result) {
    switch (result) {
      case AuthSuccess<SignInResponse>(:final data):
        if (data is TwoFactorRequired) {
          emit(
            state.copyWith(
              status: AuthStatus.twoFactorRequired,
              isSubmitting: false,
              twoFactorMethods: data.methods,
            ),
          );
        } else {
          emit(state.copyWith(isSubmitting: false));
        }
      case AuthFailure<SignInResponse>(:final error):
        emit(state.copyWith(isSubmitting: false, error: error));
    }
  }

  void _settle<T>(AuthResult<T> result) {
    if (result case AuthFailure<T>(:final error)) {
      emit(state.copyWith(isSubmitting: false, error: error));
    } else {
      emit(state.copyWith(isSubmitting: false));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
