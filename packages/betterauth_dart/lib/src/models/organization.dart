import 'package:betterauth_dart/src/models/json_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template organization}
/// A better-auth organization.
/// {@endtemplate}
@immutable
class Organization extends Equatable {
  /// {@macro organization}
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.members = const [],
    this.invitations = const [],
    this.teams = const [],
  });

  /// Creates an [Organization] from a decoded JSON map.
  ///
  /// [members], [invitations] and [teams] are populated only by
  /// `getFullOrganization`/`create`; list endpoints omit them.
  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, Object?>.from(json['metadata'] as Map)
          : null,
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
      members: _list(json['members'], Member.fromJson),
      invitations: _list(json['invitations'], Invitation.fromJson),
      teams: _list(json['teams'], Team.fromJson),
    );
  }

  /// The unique organization id.
  final String id;

  /// The organization name.
  final String name;

  /// The unique slug.
  final String slug;

  /// An optional logo URL.
  final String? logo;

  /// Arbitrary server metadata.
  final Map<String, Object?>? metadata;

  /// When the organization was created, if known.
  final DateTime? createdAt;

  /// When the organization was last updated, if known.
  final DateTime? updatedAt;

  /// Members (populated by full-organization responses).
  final List<Member> members;

  /// Pending invitations (populated by full-organization responses).
  final List<Invitation> invitations;

  /// Teams (populated when the teams feature is enabled).
  final List<Team> teams;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    logo,
    metadata,
    createdAt,
    updatedAt,
    members,
    invitations,
    teams,
  ];

  @override
  String toString() => 'Organization(id: $id, slug: $slug)';
}

/// {@template member_user}
/// The minimal user summary embedded in a [Member].
/// {@endtemplate}
@immutable
class MemberUser extends Equatable {
  /// {@macro member_user}
  const MemberUser({required this.id, this.name, this.email, this.image});

  /// Creates a [MemberUser] from a decoded JSON map.
  factory MemberUser.fromJson(Map<String, dynamic> json) {
    return MemberUser(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
    );
  }

  /// The user id.
  final String id;

  /// The user's display name, if present.
  final String? name;

  /// The user's email, if present.
  final String? email;

  /// The user's avatar URL, if present.
  final String? image;

  @override
  List<Object?> get props => [id, name, email, image];
}

/// {@template member}
/// A member of an organization.
/// {@endtemplate}
@immutable
class Member extends Equatable {
  /// {@macro member}
  const Member({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.user,
    this.teamId,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Member] from a decoded JSON map.
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      user: json['user'] is Map
          ? MemberUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      teamId: json['teamId'] as String?,
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
    );
  }

  /// The member id.
  final String id;

  /// The organization this membership belongs to.
  final String organizationId;

  /// The user id of the member.
  final String userId;

  /// The member's role (for example `owner`, `admin`, `member`, or custom).
  final String role;

  /// The embedded user summary, if returned.
  final MemberUser? user;

  /// The team id, when the teams feature is enabled.
  final String? teamId;

  /// When the membership was created, if known.
  final DateTime? createdAt;

  /// When the membership was last updated, if known.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    organizationId,
    userId,
    role,
    user,
    teamId,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'Member(id: $id, role: $role)';
}

/// {@template invitation}
/// An invitation to join an organization.
/// {@endtemplate}
@immutable
class Invitation extends Equatable {
  /// {@macro invitation}
  const Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.organizationId,
    required this.status,
    this.inviterId,
    this.teamId,
    this.expiresAt,
    this.createdAt,
  });

  /// Creates an [Invitation] from a decoded JSON map.
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      organizationId: json['organizationId'] as String,
      status: json['status'] as String? ?? 'pending',
      inviterId: json['inviterId'] as String?,
      teamId: json['teamId'] as String?,
      expiresAt: parseOptionalDate(json['expiresAt']),
      createdAt: parseOptionalDate(json['createdAt']),
    );
  }

  /// The invitation id.
  final String id;

  /// The invited email address.
  final String email;

  /// The role the invitee will receive.
  final String role;

  /// The organization the invitation is for.
  final String organizationId;

  /// The status: `pending`, `accepted`, `rejected`, or `canceled`.
  final String status;

  /// The id of the inviting member/user, if present.
  final String? inviterId;

  /// The team id, when the teams feature is enabled.
  final String? teamId;

  /// When the invitation expires, if known.
  final DateTime? expiresAt;

  /// When the invitation was created, if known.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    email,
    role,
    organizationId,
    status,
    inviterId,
    teamId,
    expiresAt,
    createdAt,
  ];

  @override
  String toString() => 'Invitation(id: $id, email: $email, status: $status)';
}

/// {@template team}
/// A team within an organization.
/// {@endtemplate}
@immutable
class Team extends Equatable {
  /// {@macro team}
  const Team({
    required this.id,
    required this.name,
    required this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Team] from a decoded JSON map.
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      organizationId: json['organizationId'] as String,
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
    );
  }

  /// The team id.
  final String id;

  /// The team name.
  final String name;

  /// The organization the team belongs to.
  final String organizationId;

  /// When the team was created, if known.
  final DateTime? createdAt;

  /// When the team was last updated, if known.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, name, organizationId, createdAt, updatedAt];

  @override
  String toString() => 'Team(id: $id, name: $name)';
}

/// {@template team_member}
/// Membership of a user in a team.
/// {@endtemplate}
@immutable
class TeamMember extends Equatable {
  /// {@macro team_member}
  const TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    this.createdAt,
  });

  /// Creates a [TeamMember] from a decoded JSON map.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      userId: json['userId'] as String,
      createdAt: parseOptionalDate(json['createdAt']),
    );
  }

  /// The team-member id.
  final String id;

  /// The team id.
  final String teamId;

  /// The user id.
  final String userId;

  /// When the team membership was created, if known.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, teamId, userId, createdAt];

  @override
  String toString() => 'TeamMember(id: $id, userId: $userId)';
}

/// {@template member_list}
/// The `{ members, total }` payload returned by `listMembers`.
/// {@endtemplate}
@immutable
class MemberList extends Equatable {
  /// {@macro member_list}
  const MemberList({this.members = const [], this.total = 0});

  /// Creates a [MemberList] from a decoded JSON map.
  factory MemberList.fromJson(Map<String, dynamic> json) {
    return MemberList(
      members: _list(json['members'], Member.fromJson),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// The members on this page.
  final List<Member> members;

  /// The total number of members.
  final int total;

  @override
  List<Object?> get props => [members, total];
}

/// {@template accept_invitation_result}
/// The `{ invitation, member }` payload returned by `acceptInvitation`.
/// {@endtemplate}
@immutable
class AcceptInvitationResult extends Equatable {
  /// {@macro accept_invitation_result}
  const AcceptInvitationResult({this.invitation, this.member});

  /// Creates an [AcceptInvitationResult] from a decoded JSON map.
  factory AcceptInvitationResult.fromJson(Map<String, dynamic> json) {
    return AcceptInvitationResult(
      invitation: json['invitation'] is Map
          ? Invitation.fromJson(
              Map<String, dynamic>.from(json['invitation'] as Map),
            )
          : null,
      member: json['member'] is Map
          ? Member.fromJson(Map<String, dynamic>.from(json['member'] as Map))
          : null,
    );
  }

  /// The updated invitation, if returned.
  final Invitation? invitation;

  /// The created membership, if returned.
  final Member? member;

  @override
  List<Object?> get props => [invitation, member];
}

List<T> _list<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return const [];
  final out = <T>[];
  for (final element in value) {
    if (element is Map) {
      out.add(fromJson(Map<String, dynamic>.from(element)));
    }
  }
  return out;
}
