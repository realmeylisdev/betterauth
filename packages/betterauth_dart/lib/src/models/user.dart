import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template user}
/// A better-auth user.
///
/// The core fields ([id], [name], [email], [emailVerified], [image],
/// [createdAt], [updatedAt]) are always present. Plugin-added fields
/// ([username], [displayUsername], [phoneNumber], [phoneNumberVerified],
/// [twoFactorEnabled], [isAnonymous]) are present only when the corresponding
/// server plugin is enabled and are therefore nullable. Any other server
/// `additionalFields` or unmodelled plugin fields are preserved verbatim in
/// [additionalFields].
/// {@endtemplate}
@immutable
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.username,
    this.displayUsername,
    this.phoneNumber,
    this.phoneNumberVerified,
    this.twoFactorEnabled,
    this.isAnonymous,
    this.additionalFields = const {},
  });

  /// Creates a [User] from a decoded JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      image: json['image'] as String?,
      createdAt: parseRequiredDate(json['createdAt']),
      updatedAt: parseRequiredDate(json['updatedAt']),
      username: json['username'] as String?,
      displayUsername: json['displayUsername'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      phoneNumberVerified: json['phoneNumberVerified'] as bool?,
      twoFactorEnabled: json['twoFactorEnabled'] as bool?,
      isAnonymous: json['isAnonymous'] as bool?,
      additionalFields: extractAdditionalFields(json, _knownKeys),
    );
  }

  static const Set<String> _knownKeys = {
    'id',
    'name',
    'email',
    'emailVerified',
    'image',
    'createdAt',
    'updatedAt',
    'username',
    'displayUsername',
    'phoneNumber',
    'phoneNumberVerified',
    'twoFactorEnabled',
    'isAnonymous',
  };

  /// The unique user id.
  final String id;

  /// The user's display name.
  final String name;

  /// The user's email address.
  final String email;

  /// Whether the user's email has been verified.
  final bool emailVerified;

  /// An optional avatar image URL.
  final String? image;

  /// When the user was created.
  final DateTime createdAt;

  /// When the user was last updated.
  final DateTime updatedAt;

  /// The normalized (lowercase) username — username plugin only.
  final String? username;

  /// The original-case display username — username plugin only.
  final String? displayUsername;

  /// The user's phone number — phone-number plugin only.
  final String? phoneNumber;

  /// Whether the phone number is verified — phone-number plugin only.
  final bool? phoneNumberVerified;

  /// Whether two-factor authentication is enabled — two-factor plugin only.
  final bool? twoFactorEnabled;

  /// Whether this is an anonymous user — anonymous plugin only.
  final bool? isAnonymous;

  /// Server `additionalFields` and unmodelled plugin fields, preserved as-is.
  final Map<String, Object?> additionalFields;

  /// Serializes this user back to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'emailVerified': emailVerified,
    if (image != null) 'image': image,
    'createdAt': encodeDate(createdAt),
    'updatedAt': encodeDate(updatedAt),
    if (username != null) 'username': username,
    if (displayUsername != null) 'displayUsername': displayUsername,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (phoneNumberVerified != null) 'phoneNumberVerified': phoneNumberVerified,
    if (twoFactorEnabled != null) 'twoFactorEnabled': twoFactorEnabled,
    if (isAnonymous != null) 'isAnonymous': isAnonymous,
    ...additionalFields,
  };

  /// Returns a copy of this user with the given fields replaced.
  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? emailVerified,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? displayUsername,
    String? phoneNumber,
    bool? phoneNumberVerified,
    bool? twoFactorEnabled,
    bool? isAnonymous,
    Map<String, Object?>? additionalFields,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      displayUsername: displayUsername ?? this.displayUsername,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberVerified: phoneNumberVerified ?? this.phoneNumberVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      additionalFields: additionalFields ?? this.additionalFields,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    emailVerified,
    image,
    createdAt,
    updatedAt,
    username,
    displayUsername,
    phoneNumber,
    phoneNumberVerified,
    twoFactorEnabled,
    isAnonymous,
    additionalFields,
  ];

  @override
  String toString() => 'User(id: $id, email: $email)';
}
