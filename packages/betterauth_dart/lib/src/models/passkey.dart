import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template passkey}
/// A registered WebAuthn passkey credential, as returned by
/// `/passkey/list-user-passkeys` and the verify/update endpoints.
///
/// Fields beyond [id], [credentialId] and [userId] are modelled as nullable
/// because their presence varies by authenticator and server configuration.
/// {@endtemplate}
@immutable
class Passkey extends Equatable {
  /// {@macro passkey}
  const Passkey({
    required this.id,
    required this.credentialId,
    required this.userId,
    this.name,
    this.publicKey,
    this.counter,
    this.deviceType,
    this.backedUp,
    this.transports = const [],
    this.aaguid,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Passkey] from a decoded JSON map.
  factory Passkey.fromJson(Map<String, dynamic> json) {
    return Passkey(
      id: json['id'] as String,
      credentialId: (json['credentialID'] ?? json['credentialId']) as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      publicKey: json['publicKey'] as String?,
      counter: (json['counter'] as num?)?.toInt(),
      deviceType: json['deviceType'] as String?,
      backedUp: json['backedUp'] as bool?,
      transports: _parseTransports(json['transports']),
      aaguid: json['aaguid'] as String?,
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
    );
  }

  static List<String> _parseTransports(Object? value) {
    if (value is List) {
      return value.map((dynamic e) => '$e').toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((s) => s.trim()).toList();
    }
    return const [];
  }

  /// The database id of the passkey record.
  final String id;

  /// The base64url-encoded WebAuthn credential id.
  final String credentialId;

  /// The id of the user this passkey belongs to.
  final String userId;

  /// A user-friendly name for the passkey.
  final String? name;

  /// The stored COSE/PEM public key.
  final String? publicKey;

  /// The signature counter used for clone detection.
  final int? counter;

  /// `platform` or `cross-platform`.
  final String? deviceType;

  /// Whether the credential is backed up (synced).
  final bool? backedUp;

  /// The supported transports (for example `internal`, `usb`, `hybrid`).
  final List<String> transports;

  /// The authenticator's AAGUID, if reported.
  final String? aaguid;

  /// When the passkey was registered, if known.
  final DateTime? createdAt;

  /// When the passkey was last updated, if known.
  final DateTime? updatedAt;

  /// Returns a copy of this passkey with the given fields replaced.
  Passkey copyWith({
    String? id,
    String? credentialId,
    String? userId,
    String? name,
    String? publicKey,
    int? counter,
    String? deviceType,
    bool? backedUp,
    List<String>? transports,
    String? aaguid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Passkey(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      counter: counter ?? this.counter,
      deviceType: deviceType ?? this.deviceType,
      backedUp: backedUp ?? this.backedUp,
      transports: transports ?? this.transports,
      aaguid: aaguid ?? this.aaguid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    credentialId,
    userId,
    name,
    publicKey,
    counter,
    deviceType,
    backedUp,
    transports,
    aaguid,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'Passkey(id: $id, name: $name)';
}
