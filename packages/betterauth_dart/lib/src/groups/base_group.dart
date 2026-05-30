import 'package:betterauth_dart/src/exceptions/auth_exception.dart';
import 'package:betterauth_dart/src/groups/session_sink.dart';
import 'package:betterauth_dart/src/http/better_auth_http.dart';
import 'package:betterauth_dart/src/models/responses.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';
import 'package:meta/meta.dart';

/// {@template better_auth_group}
/// Base class for the namespaced method groups (`signIn`, `session`, …).
///
/// Holds the shared transport ([http]) and the [sink] used to drive auth-state
/// transitions, and provides decode helpers that turn a raw
/// `AuthResult<Object?>` into a typed result, converting parse failures into an
/// [AuthUnknownException].
/// {@endtemplate}
abstract base class BetterAuthGroup {
  /// {@macro better_auth_group}
  const BetterAuthGroup(this.http, this.sink);

  /// The shared transport.
  @protected
  final BetterAuthHttp http;

  /// The hook used to apply auth-state transitions.
  @protected
  final SessionSink sink;

  /// Decodes a single JSON object response into [T].
  @protected
  AuthResult<T> decodeObject<T>(
    AuthResult<Object?> raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    switch (raw) {
      case AuthFailure<Object?>(:final error):
        return AuthFailure<T>(error);
      case AuthSuccess<Object?>(:final data):
        if (data is Map) {
          try {
            return AuthSuccess<T>(fromJson(Map<String, dynamic>.from(data)));
          } on Object catch (e) {
            return AuthFailure<T>(
              AuthUnknownException(
                'Failed to parse response: $e',
                originalError: e,
              ),
            );
          }
        }
        return AuthFailure<T>(
          AuthUnknownException(
            'Expected a JSON object response.',
            originalError: raw,
          ),
        );
    }
  }

  /// Decodes a nullable JSON object response into `T?` (e.g. `/get-session`,
  /// which returns literal `null` when unauthenticated).
  @protected
  AuthResult<T?> decodeNullableObject<T>(
    AuthResult<Object?> raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    switch (raw) {
      case AuthFailure<Object?>(:final error):
        return AuthFailure<T?>(error);
      case AuthSuccess<Object?>(:final data):
        if (data == null) return const AuthSuccess(null);
        if (data is Map) {
          try {
            return AuthSuccess<T?>(fromJson(Map<String, dynamic>.from(data)));
          } on Object catch (e) {
            return AuthFailure<T?>(
              AuthUnknownException(
                'Failed to parse response: $e',
                originalError: e,
              ),
            );
          }
        }
        return AuthFailure<T?>(
          AuthUnknownException(
            'Expected a JSON object or null response.',
            originalError: raw,
          ),
        );
    }
  }

  /// Decodes a JSON array response into a `List<T>`.
  @protected
  AuthResult<List<T>> decodeList<T>(
    AuthResult<Object?> raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    switch (raw) {
      case AuthFailure<Object?>(:final error):
        return AuthFailure<List<T>>(error);
      case AuthSuccess<Object?>(:final data):
        if (data is List) {
          try {
            return AuthSuccess<List<T>>(
              data.map((dynamic e) {
                return fromJson(Map<String, dynamic>.from(e as Map));
              }).toList(),
            );
          } on Object catch (e) {
            return AuthFailure<List<T>>(
              AuthUnknownException(
                'Failed to parse list response: $e',
                originalError: e,
              ),
            );
          }
        }
        return AuthFailure<List<T>>(
          AuthUnknownException(
            'Expected a JSON array response.',
            originalError: raw,
          ),
        );
    }
  }

  /// Decodes any confirmation response into a [StatusResponse]. A 2xx body that
  /// is not a JSON object is treated as a successful, message-less status.
  @protected
  AuthResult<StatusResponse> decodeStatus(AuthResult<Object?> raw) {
    switch (raw) {
      case AuthFailure<Object?>(:final error):
        return AuthFailure<StatusResponse>(error);
      case AuthSuccess<Object?>(:final data):
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        return AuthSuccess<StatusResponse>(StatusResponse.fromJson(map));
    }
  }

  /// Strips `null` values from a request body map so optional fields are
  /// omitted from the wire entirely.
  @protected
  Map<String, dynamic> body(Map<String, dynamic> fields) {
    return <String, dynamic>{
      for (final entry in fields.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }
}
