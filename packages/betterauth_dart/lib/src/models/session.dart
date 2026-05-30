import 'package:betterauth_dart/src/constants.dart';
import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template session}
/// A better-auth session.
///
/// [userId], [token] and [expiresAt] are always present. [id], [createdAt],
/// [updatedAt], [ipAddress] and [userAgent] are modelled as nullable because
/// some plugin endpoints (magic-link verify, two-factor verify-backup-code)
/// return a trimmed session object. The canonical `/get-session` and
/// `/list-sessions` always return the full shape.
/// {@endtemplate}
@immutable
class Session extends Equatable {
  /// {@macro session}
  const Session({
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.ipAddress,
    this.userAgent,
    this.additionalFields = const {},
  });

  /// Creates a [Session] from a decoded JSON map.
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      token: json['token'] as String,
      expiresAt: parseRequiredDate(json['expiresAt']),
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      additionalFields: extractAdditionalFields(json, _knownKeys),
    );
  }

  static const Set<String> _knownKeys = {
    'id',
    'userId',
    'token',
    'expiresAt',
    'createdAt',
    'updatedAt',
    'ipAddress',
    'userAgent',
  };

  /// The session id (absent in some trimmed plugin responses).
  final String? id;

  /// The id of the user this session belongs to.
  final String userId;

  /// The session token. In bearer mode this is the value sent as
  /// `Authorization: Bearer <token>`.
  final String token;

  /// When the session expires.
  final DateTime expiresAt;

  /// When the session was created (absent in some trimmed plugin responses).
  final DateTime? createdAt;

  /// When the session was last updated (absent in some trimmed responses).
  final DateTime? updatedAt;

  /// The IP address the session was created from, if known.
  final String? ipAddress;

  /// The user agent the session was created from, if known.
  final String? userAgent;

  /// Server `additionalFields` and unmodelled plugin fields, preserved as-is.
  final Map<String, Object?> additionalFields;

  /// Whether the session is expired, applying a small safety margin
  /// ([kExpiryMargin]) so a session that is about to expire is treated as
  /// expired. Uses the ambient [clock] for testability.
  bool get isExpired =>
      clock.now().toUtc().isAfter(expiresAt.subtract(kExpiryMargin));

  /// Serializes this session back to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'userId': userId,
    'token': token,
    'expiresAt': encodeDate(expiresAt),
    if (createdAt != null) 'createdAt': encodeDate(createdAt!),
    if (updatedAt != null) 'updatedAt': encodeDate(updatedAt!),
    if (ipAddress != null) 'ipAddress': ipAddress,
    if (userAgent != null) 'userAgent': userAgent,
    ...additionalFields,
  };

  /// Returns a copy of this session with the given fields replaced.
  Session copyWith({
    String? id,
    String? userId,
    String? token,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ipAddress,
    String? userAgent,
    Map<String, Object?>? additionalFields,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      additionalFields: additionalFields ?? this.additionalFields,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    token,
    expiresAt,
    createdAt,
    updatedAt,
    ipAddress,
    userAgent,
    additionalFields,
  ];

  @override
  String toString() =>
      'Session(id: $id, userId: $userId, '
      'expiresAt: $expiresAt)';
}
