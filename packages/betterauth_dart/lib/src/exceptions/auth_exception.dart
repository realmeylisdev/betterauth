import 'package:betterauth_dart/src/exceptions/auth_error_code.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template auth_exception}
/// The base type for every failure surfaced by the betterauth client.
///
/// Instances are never thrown across the public API — they are carried by an
/// `AuthFailure`. The concrete subtypes let callers distinguish failure modes:
///
/// * [AuthApiException] — the server returned a structured error (typically
///   4xx) with a [code].
/// * [AuthRetryableFetchException] — a transient transport failure (network
///   error, timeout, or 5xx) that was (or could be) retried.
/// * [AuthSessionMissingException] — the operation required a session but none
///   was present (HTTP 401, or `/get-session` returned `null`).
/// * [AuthUnknownException] — an unexpected error (non-JSON body, parse
///   failure, or any other unhandled condition).
/// {@endtemplate}
@immutable
sealed class AuthException extends Equatable implements Exception {
  /// {@macro auth_exception}
  const AuthException(
    this.message, {
    this.statusCode,
    this.code = AuthErrorCode.unknown,
    this.rawCode,
    this.details,
  });

  /// A human-readable description of the failure (the server `message`, or a
  /// client-generated message for transport errors).
  final String message;

  /// The HTTP status code, when the failure originated from an HTTP response.
  final int? statusCode;

  /// The mapped error code, or [AuthErrorCode.unknown] when absent/unrecognised.
  final AuthErrorCode code;

  /// The raw, unmapped `code` string from the server, preserved even when
  /// [code] is [AuthErrorCode.unknown].
  final String? rawCode;

  /// Any additional fields present in the error response body.
  final Map<String, Object?>? details;

  @override
  List<Object?> get props => [message, statusCode, code, rawCode, details];

  // Equatable already distinguishes subtypes by runtimeType, so it is omitted
  // from props. stringify gives an informative toString without referencing
  // runtimeType directly.
  @override
  bool get stringify => true;
}

/// {@template auth_api_exception}
/// A structured error returned by the server (typically a 4xx), carrying a
/// mapped [AuthErrorCode].
/// {@endtemplate}
final class AuthApiException extends AuthException {
  /// {@macro auth_api_exception}
  const AuthApiException(
    super.message, {
    super.statusCode,
    super.code,
    super.rawCode,
    super.details,
  });
}

/// {@template auth_retryable_fetch_exception}
/// A transient transport failure — a network error, timeout, or 5xx response —
/// that is safe to retry.
/// {@endtemplate}
final class AuthRetryableFetchException extends AuthException {
  /// {@macro auth_retryable_fetch_exception}
  const AuthRetryableFetchException(
    super.message, {
    super.statusCode,
    super.code,
    super.rawCode,
    super.details,
  });
}

/// {@template auth_session_missing_exception}
/// The operation required an authenticated session but none was present
/// (HTTP 401, or `/get-session` returned `null`).
/// {@endtemplate}
final class AuthSessionMissingException extends AuthException {
  /// {@macro auth_session_missing_exception}
  const AuthSessionMissingException([
    super.message = 'No active session.',
  ]) : super(statusCode: 401, code: AuthErrorCode.sessionExpired);
}

/// {@template auth_unknown_exception}
/// An unexpected failure: a non-JSON body, a parse error, or any other
/// unhandled condition. The triggering error is preserved on [originalError].
/// {@endtemplate}
final class AuthUnknownException extends AuthException {
  /// {@macro auth_unknown_exception}
  const AuthUnknownException(
    super.message, {
    required this.originalError,
    super.statusCode,
  });

  /// The underlying error or exception that triggered this failure.
  final Object originalError;

  @override
  List<Object?> get props => [...super.props, originalError];
}
