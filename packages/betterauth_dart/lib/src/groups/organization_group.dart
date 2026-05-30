import 'package:betterauth_dart/src/groups/base_group.dart';
import 'package:betterauth_dart/src/models/models.dart';
import 'package:betterauth_dart/src/result/auth_result.dart';

/// {@template organization_group}
/// Organization, member, invitation and team methods, exposed as
/// `client.organization`. Requires the organization plugin (team methods
/// require the teams feature). Where `organizationId` is omitted the server
/// uses the session's active organization.
/// {@endtemplate}
final class OrganizationGroup extends BetterAuthGroup {
  /// {@macro organization_group}
  OrganizationGroup(super.http, super.sink);

  // --- Organizations ---

  /// Creates an organization (`POST /organization/create`).
  Future<AuthResult<Organization>> create({
    required String name,
    required String slug,
    String? logo,
    Map<String, dynamic>? metadata,
    bool? keepCurrentActiveOrganization,
  }) async {
    final raw = await http.request(
      '/organization/create',
      method: 'POST',
      body: body(<String, dynamic>{
        'name': name,
        'slug': slug,
        'logo': logo,
        'metadata': metadata,
        'keepCurrentActiveOrganization': keepCurrentActiveOrganization,
      }),
    );
    return decodeObject(raw, Organization.fromJson);
  }

  /// Updates an organization (`POST /organization/update`).
  Future<AuthResult<Organization>> update({
    String? name,
    String? slug,
    String? logo,
    Map<String, dynamic>? metadata,
    String? organizationId,
  }) async {
    final data = body(<String, dynamic>{
      'name': name,
      'slug': slug,
      'logo': logo,
      'metadata': metadata,
    });
    final raw = await http.request(
      '/organization/update',
      method: 'POST',
      body: <String, dynamic>{'data': data, 'organizationId': ?organizationId},
    );
    return decodeObject(raw, Organization.fromJson);
  }

  /// Deletes an organization (`POST /organization/delete`).
  Future<AuthResult<Organization>> delete({
    required String organizationId,
  }) async {
    final raw = await http.request(
      '/organization/delete',
      method: 'POST',
      body: <String, dynamic>{'organizationId': organizationId},
    );
    return decodeObject(raw, Organization.fromJson);
  }

  /// Lists the organizations the current user belongs to
  /// (`GET /organization/list`).
  Future<AuthResult<List<Organization>>> list() async {
    final raw = await http.request('/organization/list', method: 'GET');
    return decodeList(raw, Organization.fromJson);
  }

  /// Sets (or clears) the active organization (`POST /organization/set-active`).
  ///
  /// Pass neither argument to clear it; returns `null` when cleared.
  Future<AuthResult<Organization?>> setActive({
    String? organizationId,
    String? organizationSlug,
  }) async {
    final raw = await http.request(
      '/organization/set-active',
      method: 'POST',
      body: <String, dynamic>{
        'organizationId': ?organizationId,
        'organizationSlug': ?organizationSlug,
      },
    );
    return decodeNullableObject(raw, Organization.fromJson);
  }

  /// Fetches an organization with its members, invitations and teams
  /// (`GET /organization/get-full-organization`).
  Future<AuthResult<Organization?>> getFullOrganization({
    String? organizationId,
    String? organizationSlug,
    int? membersLimit,
  }) async {
    final raw = await http.request(
      '/organization/get-full-organization',
      method: 'GET',
      query: <String, dynamic>{
        'organizationId': ?organizationId,
        'organizationSlug': ?organizationSlug,
        'membersLimit': ?membersLimit,
      },
    );
    return decodeNullableObject(raw, Organization.fromJson);
  }

  /// Checks whether a slug is available (`POST /organization/check-slug`).
  Future<AuthResult<StatusResponse>> checkSlug({
    required String slug,
  }) async {
    final raw = await http.request(
      '/organization/check-slug',
      method: 'POST',
      body: <String, dynamic>{'slug': slug},
    );
    return decodeStatus(raw);
  }

  // --- Members ---

  /// Lists members of an organization (`GET /organization/list-members`).
  Future<AuthResult<MemberList>> listMembers({
    String? organizationId,
    String? organizationSlug,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortDirection,
  }) async {
    final raw = await http.request(
      '/organization/list-members',
      method: 'GET',
      query: <String, dynamic>{
        'organizationId': ?organizationId,
        'organizationSlug': ?organizationSlug,
        'limit': ?limit,
        'offset': ?offset,
        'sortBy': ?sortBy,
        'sortDirection': ?sortDirection,
      },
    );
    return decodeObject(raw, MemberList.fromJson);
  }

  /// Returns the current user's membership in the active organization
  /// (`GET /organization/get-active-member`).
  Future<AuthResult<Member>> getActiveMember() async {
    final raw = await http.request(
      '/organization/get-active-member',
      method: 'GET',
    );
    return decodeObject(raw, Member.fromJson);
  }

  /// Removes a member (`POST /organization/remove-member`). [memberIdOrEmail]
  /// accepts a member id or the member's email.
  Future<AuthResult<Member>> removeMember({
    required String memberIdOrEmail,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/remove-member',
      method: 'POST',
      body: <String, dynamic>{
        'memberIdOrEmail': memberIdOrEmail,
        'organizationId': ?organizationId,
      },
    );
    return decodeObject(raw, _unwrapMember);
  }

  /// Updates a member's role (`POST /organization/update-member-role`).
  Future<AuthResult<Member>> updateMemberRole({
    required String memberId,
    required String role,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/update-member-role',
      method: 'POST',
      body: <String, dynamic>{
        'memberId': memberId,
        'role': role,
        'organizationId': ?organizationId,
      },
    );
    return decodeObject(raw, _unwrapMember);
  }

  /// Leaves an organization (`POST /organization/leave`).
  Future<AuthResult<Member>> leaveOrganization({
    required String organizationId,
  }) async {
    final raw = await http.request(
      '/organization/leave',
      method: 'POST',
      body: <String, dynamic>{'organizationId': organizationId},
    );
    return decodeObject(raw, _unwrapMember);
  }

  // --- Invitations ---

  /// Invites a member by email (`POST /organization/invite-member`).
  Future<AuthResult<Invitation>> inviteMember({
    required String email,
    required String role,
    String? organizationId,
    bool? resend,
    String? teamId,
  }) async {
    final raw = await http.request(
      '/organization/invite-member',
      method: 'POST',
      body: <String, dynamic>{
        'email': email,
        'role': role,
        'organizationId': ?organizationId,
        'resend': ?resend,
        'teamId': ?teamId,
      },
    );
    return decodeObject(raw, Invitation.fromJson);
  }

  /// Accepts an invitation (`POST /organization/accept-invitation`).
  Future<AuthResult<AcceptInvitationResult>> acceptInvitation({
    required String invitationId,
  }) async {
    final raw = await http.request(
      '/organization/accept-invitation',
      method: 'POST',
      body: <String, dynamic>{'invitationId': invitationId},
    );
    return decodeObject(raw, AcceptInvitationResult.fromJson);
  }

  /// Rejects an invitation (`POST /organization/reject-invitation`).
  Future<AuthResult<AcceptInvitationResult>> rejectInvitation({
    required String invitationId,
  }) async {
    final raw = await http.request(
      '/organization/reject-invitation',
      method: 'POST',
      body: <String, dynamic>{'invitationId': invitationId},
    );
    return decodeObject(raw, AcceptInvitationResult.fromJson);
  }

  /// Cancels a sent invitation (`POST /organization/cancel-invitation`).
  Future<AuthResult<Invitation>> cancelInvitation({
    required String invitationId,
  }) async {
    final raw = await http.request(
      '/organization/cancel-invitation',
      method: 'POST',
      body: <String, dynamic>{'invitationId': invitationId},
    );
    return decodeObject(raw, _unwrapInvitation);
  }

  /// Fetches a single invitation (`GET /organization/get-invitation`).
  Future<AuthResult<Invitation>> getInvitation({required String id}) async {
    final raw = await http.request(
      '/organization/get-invitation',
      method: 'GET',
      query: <String, dynamic>{'id': id},
    );
    return decodeObject(raw, Invitation.fromJson);
  }

  /// Lists invitations for an organization
  /// (`GET /organization/list-invitations`).
  Future<AuthResult<List<Invitation>>> listInvitations({
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/list-invitations',
      method: 'GET',
      query: <String, dynamic>{'organizationId': ?organizationId},
    );
    return decodeList(raw, Invitation.fromJson);
  }

  // --- Teams ---

  /// Creates a team (`POST /organization/create-team`).
  Future<AuthResult<Team>> createTeam({
    required String name,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/create-team',
      method: 'POST',
      body: <String, dynamic>{
        'name': name,
        'organizationId': ?organizationId,
      },
    );
    return decodeObject(raw, Team.fromJson);
  }

  /// Lists teams in an organization (`GET /organization/list-teams`).
  Future<AuthResult<List<Team>>> listTeams({String? organizationId}) async {
    final raw = await http.request(
      '/organization/list-teams',
      method: 'GET',
      query: <String, dynamic>{'organizationId': ?organizationId},
    );
    return decodeList(raw, Team.fromJson);
  }

  /// Renames a team (`POST /organization/update-team`).
  Future<AuthResult<Team>> updateTeam({
    required String teamId,
    required String name,
  }) async {
    final raw = await http.request(
      '/organization/update-team',
      method: 'POST',
      body: <String, dynamic>{
        'teamId': teamId,
        'data': <String, dynamic>{'name': name},
      },
    );
    return decodeObject(raw, Team.fromJson);
  }

  /// Removes a team (`POST /organization/remove-team`).
  Future<AuthResult<StatusResponse>> removeTeam({
    required String teamId,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/remove-team',
      method: 'POST',
      body: <String, dynamic>{
        'teamId': teamId,
        'organizationId': ?organizationId,
      },
    );
    return decodeStatus(raw);
  }

  /// Sets (or clears) the active team (`POST /organization/set-active-team`).
  Future<AuthResult<Team?>> setActiveTeam({String? teamId}) async {
    final raw = await http.request(
      '/organization/set-active-team',
      method: 'POST',
      body: <String, dynamic>{'teamId': ?teamId},
    );
    return decodeNullableObject(raw, Team.fromJson);
  }

  /// Lists the teams the current user belongs to
  /// (`GET /organization/list-user-teams`).
  Future<AuthResult<List<Team>>> listUserTeams() async {
    final raw = await http.request(
      '/organization/list-user-teams',
      method: 'GET',
    );
    return decodeList(raw, Team.fromJson);
  }

  /// Lists members of a team (`GET /organization/list-team-members`).
  Future<AuthResult<List<TeamMember>>> listTeamMembers({
    String? teamId,
  }) async {
    final raw = await http.request(
      '/organization/list-team-members',
      method: 'GET',
      query: <String, dynamic>{'teamId': ?teamId},
    );
    return decodeList(raw, TeamMember.fromJson);
  }

  /// Adds a user to a team (`POST /organization/add-team-member`).
  Future<AuthResult<TeamMember>> addTeamMember({
    required String teamId,
    required String userId,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/add-team-member',
      method: 'POST',
      body: <String, dynamic>{
        'teamId': teamId,
        'userId': userId,
        'organizationId': ?organizationId,
      },
    );
    return decodeObject(raw, TeamMember.fromJson);
  }

  /// Removes a user from a team (`POST /organization/remove-team-member`).
  Future<AuthResult<StatusResponse>> removeTeamMember({
    required String teamId,
    required String userId,
    String? organizationId,
  }) async {
    final raw = await http.request(
      '/organization/remove-team-member',
      method: 'POST',
      body: <String, dynamic>{
        'teamId': teamId,
        'userId': userId,
        'organizationId': ?organizationId,
      },
    );
    return decodeStatus(raw);
  }

  static Member _unwrapMember(Map<String, dynamic> json) {
    final inner = json['member'];
    return Member.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : json,
    );
  }

  static Invitation _unwrapInvitation(Map<String, dynamic> json) {
    final inner = json['invitation'];
    return Invitation.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : json,
    );
  }
}
