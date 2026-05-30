import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:meta/meta.dart';

/// {@template auth_result}
/// The outcome of a `BetterAuthClient` call: either an [AuthSuccess] carrying
/// the typed data, or an [AuthFailure] carrying an [AuthException].
///
/// The client never throws across its public API — expected failures (invalid
/// credentials, expired sessions, network errors) are returned as an
/// [AuthFailure] so callers can exhaustively pattern-match:
///
/// ```dart
/// final result = await client.signIn.email(email: e, password: p);
/// switch (result) {
///   case AuthSuccess(:final data):
///     // use data
///   case AuthFailure(:final error):
///     // inspect error.code / error.message
/// }
/// ```
/// {@endtemplate}
@immutable
sealed class AuthResult<T> {
  /// {@macro auth_result}
  const AuthResult();

  /// Whether this result is an [AuthSuccess].
  bool get isSuccess => this is AuthSuccess<T>;

  /// Whether this result is an [AuthFailure].
  bool get isFailure => this is AuthFailure<T>;

  /// The data when this is an [AuthSuccess], otherwise `null`.
  T? get dataOrNull => switch (this) {
    AuthSuccess<T>(:final data) => data,
    AuthFailure<T>() => null,
  };

  /// The error when this is an [AuthFailure], otherwise `null`.
  AuthException? get errorOrNull => switch (this) {
    AuthSuccess<T>() => null,
    AuthFailure<T>(:final error) => error,
  };

  /// Folds both cases into a single value of type [R].
  R when<R>({
    required R Function(T data) success,
    required R Function(AuthException error) failure,
  }) => switch (this) {
    AuthSuccess<T>(:final data) => success(data),
    AuthFailure<T>(:final error) => failure(error),
  };

  /// Returns a new result with [transform] applied to the success data.
  ///
  /// A failure is passed through unchanged.
  AuthResult<R> map<R>(R Function(T data) transform) => switch (this) {
    AuthSuccess<T>(:final data) => AuthSuccess<R>(transform(data)),
    AuthFailure<T>(:final error) => AuthFailure<R>(error),
  };
}

/// {@template auth_success}
/// A successful [AuthResult] holding the returned [data].
/// {@endtemplate}
@immutable
final class AuthSuccess<T> extends AuthResult<T> {
  /// {@macro auth_success}
  const AuthSuccess(this.data);

  /// The value produced by the call.
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthSuccess<T> && other.data == data;

  @override
  int get hashCode => Object.hash(AuthSuccess<T>, data);

  @override
  String toString() => 'AuthSuccess<$T>($data)';
}

/// {@template auth_failure}
/// A failed [AuthResult] holding the [error] that occurred.
/// {@endtemplate}
@immutable
final class AuthFailure<T> extends AuthResult<T> {
  /// {@macro auth_failure}
  const AuthFailure(this.error);

  /// The error describing why the call failed.
  final AuthException error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthFailure<T> && other.error == error;

  @override
  int get hashCode => Object.hash(AuthFailure<T>, error);

  @override
  String toString() => 'AuthFailure<$T>($error)';
}
