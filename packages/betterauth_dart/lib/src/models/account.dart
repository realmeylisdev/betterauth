import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template account}
/// A linked authentication account (a credential account or a social provider
/// account) belonging to a user, as returned by `/list-accounts`.
/// {@endtemplate}
@immutable
class Account extends Equatable {
  /// {@macro account}
  const Account({
    required this.id,
    required this.providerId,
    required this.accountId,
    required this.userId,
    this.scopes = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [Account] from a decoded JSON map.
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      accountId: json['accountId'] as String,
      userId: json['userId'] as String,
      scopes:
          (json['scopes'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const [],
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
    );
  }

  /// The unique account id.
  final String id;

  /// The provider id (for example `credential`, `google`, `github`).
  final String providerId;

  /// The provider-specific account id.
  final String accountId;

  /// The id of the user this account belongs to.
  final String userId;

  /// The OAuth scopes granted to this account.
  final List<String> scopes;

  /// When the account was linked, if known.
  final DateTime? createdAt;

  /// When the account was last updated, if known.
  final DateTime? updatedAt;

  /// Serializes this account back to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'providerId': providerId,
    'accountId': accountId,
    'userId': userId,
    'scopes': scopes,
    if (createdAt != null) 'createdAt': encodeDate(createdAt!),
    if (updatedAt != null) 'updatedAt': encodeDate(updatedAt!),
  };

  /// Returns a copy of this account with the given fields replaced.
  Account copyWith({
    String? id,
    String? providerId,
    String? accountId,
    String? userId,
    List<String>? scopes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      scopes: scopes ?? this.scopes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    providerId,
    accountId,
    userId,
    scopes,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'Account(id: $id, providerId: $providerId)';
}
