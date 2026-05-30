import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Registers a GET stub for [path] that tolerates a trailing query string,
/// replying with [status] and [body]. The plain [stubGet] helper matches the
/// path exactly, which fails once query parameters are appended to the URI.
void stubGetQuery(
  DioAdapter adapter,
  String path, {
  int status = 200,
  Object? body,
}) {
  adapter.onGet(
    RegExp('${RegExp.escape(testUrl(path))}(\\?.*)?\$'),
    (server) => server.reply(
      status,
      body,
      headers: <String, List<String>>{
        'content-type': const <String>['application/json'],
      },
    ),
  );
}

/// A canonical organization JSON map for stubbing responses.
Map<String, dynamic> orgJson({
  String id = 'org_1',
  String name = 'Acme',
  String slug = 'acme',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'slug': slug,
  'logo': null,
  'metadata': <String, dynamic>{'tier': 'pro'},
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
};

/// A canonical member JSON map for stubbing responses.
Map<String, dynamic> memberJson({
  String id = 'mem_1',
  String organizationId = 'org_1',
  String userId = 'user_1',
  String role = 'member',
}) => <String, dynamic>{
  'id': id,
  'organizationId': organizationId,
  'userId': userId,
  'role': role,
};

/// A canonical invitation JSON map for stubbing responses.
Map<String, dynamic> invitationJson({
  String id = 'inv_1',
  String email = 'invitee@example.com',
  String role = 'member',
  String organizationId = 'org_1',
  String status = 'pending',
}) => <String, dynamic>{
  'id': id,
  'email': email,
  'role': role,
  'organizationId': organizationId,
  'status': status,
};

/// A canonical team JSON map for stubbing responses.
Map<String, dynamic> teamJson({
  String id = 'team_1',
  String name = 'Engineering',
  String organizationId = 'org_1',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'organizationId': organizationId,
};

/// A canonical team-member JSON map for stubbing responses.
Map<String, dynamic> teamMemberJson({
  String id = 'tm_1',
  String teamId = 'team_1',
  String userId = 'user_1',
}) => <String, dynamic>{
  'id': id,
  'teamId': teamId,
  'userId': userId,
};

void main() {
  group(OrganizationGroup, () {
    late TestClient ctx;

    setUp(() {
      ctx = buildTestClient();
    });

    // --- Organizations ---

    group('create', () {
      test('returns an Organization on success', () async {
        stubPost(ctx.adapter, '/organization/create', body: orgJson());

        final result = await ctx.client.organization.create(
          name: 'Acme',
          slug: 'acme',
          logo: 'https://logo',
          metadata: <String, dynamic>{'tier': 'pro'},
          keepCurrentActiveOrganization: true,
        );

        expect(result, isA<AuthSuccess<Organization>>());
        final data = (result as AuthSuccess<Organization>).data;
        expect(data.id, equals('org_1'));
        expect(data.slug, equals('acme'));
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/organization/create',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.organization.create(
          name: 'Acme',
          slug: 'acme',
        );

        expect(result, isA<AuthFailure<Organization>>());
        expect(
          (result as AuthFailure<Organization>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('update', () {
      test('returns an Organization on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/update',
          body: orgJson(name: 'Renamed'),
        );

        final result = await ctx.client.organization.update(
          name: 'Renamed',
          slug: 'acme',
          logo: 'https://logo',
          metadata: <String, dynamic>{'tier': 'pro'},
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Organization>>());
        expect((result as AuthSuccess<Organization>).data.name, 'Renamed');
      });

      test('omits organizationId when not provided', () async {
        stubPost(ctx.adapter, '/organization/update', body: orgJson());

        final result = await ctx.client.organization.update(name: 'Renamed');

        expect(result, isA<AuthSuccess<Organization>>());
      });
    });

    group('delete', () {
      test('returns an Organization on success', () async {
        stubPost(ctx.adapter, '/organization/delete', body: orgJson());

        final result = await ctx.client.organization.delete(
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Organization>>());
        expect((result as AuthSuccess<Organization>).data.id, 'org_1');
      });
    });

    group('list', () {
      test('returns a list of organizations on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list',
          body: <Map<String, dynamic>>[
            orgJson(),
            orgJson(id: 'org_2'),
          ],
        );

        final result = await ctx.client.organization.list();

        expect(result, isA<AuthSuccess<List<Organization>>>());
        expect(
          (result as AuthSuccess<List<Organization>>).data,
          hasLength(2),
        );
      });

      test('fails with AuthUnknownException when body is not a list', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list',
          body: <String, dynamic>{'not': 'a list'},
        );

        final result = await ctx.client.organization.list();

        expect(result, isA<AuthFailure<List<Organization>>>());
        expect(
          (result as AuthFailure<List<Organization>>).error,
          isA<AuthUnknownException>(),
        );
      });
    });

    group('setActive', () {
      test('returns an Organization when set', () async {
        stubPost(ctx.adapter, '/organization/set-active', body: orgJson());

        final result = await ctx.client.organization.setActive(
          organizationId: 'org_1',
          organizationSlug: 'acme',
        );

        expect(result, isA<AuthSuccess<Organization?>>());
        expect((result as AuthSuccess<Organization?>).data, isNotNull);
      });

      test('returns null when cleared (null body)', () async {
        // No body argument -> the stub replies with a literal null body.
        stubPost(ctx.adapter, '/organization/set-active');

        final result = await ctx.client.organization.setActive();

        expect(result, isA<AuthSuccess<Organization?>>());
        expect((result as AuthSuccess<Organization?>).data, isNull);
      });
    });

    group('getFullOrganization', () {
      test('returns an Organization with nested data', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/get-full-organization',
          body: <String, dynamic>{
            ...orgJson(),
            'members': <Map<String, dynamic>>[memberJson()],
            'invitations': <Map<String, dynamic>>[invitationJson()],
            'teams': <Map<String, dynamic>>[teamJson()],
          },
        );

        final result = await ctx.client.organization.getFullOrganization(
          organizationId: 'org_1',
          organizationSlug: 'acme',
          membersLimit: 50,
        );

        expect(result, isA<AuthSuccess<Organization?>>());
        final data = (result as AuthSuccess<Organization?>).data;
        expect(data, isNotNull);
        expect(data!.members, hasLength(1));
        expect(data.invitations, hasLength(1));
        expect(data.teams, hasLength(1));
      });

      test('returns null when body is null', () async {
        stubGetQuery(ctx.adapter, '/organization/get-full-organization');

        final result = await ctx.client.organization.getFullOrganization();

        expect(result, isA<AuthSuccess<Organization?>>());
        expect((result as AuthSuccess<Organization?>).data, isNull);
      });
    });

    group('checkSlug', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/check-slug',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.organization.checkSlug(slug: 'acme');

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/organization/check-slug',
          status: 400,
          body: <String, dynamic>{'message': 'Taken', 'code': 'SLUG_TAKEN'},
        );

        final result = await ctx.client.organization.checkSlug(slug: 'acme');

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    // --- Members ---

    group('listMembers', () {
      test('returns a MemberList on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-members',
          body: <String, dynamic>{
            'members': <Map<String, dynamic>>[memberJson()],
            'total': 1,
          },
        );

        final result = await ctx.client.organization.listMembers(
          organizationId: 'org_1',
          organizationSlug: 'acme',
          limit: 10,
          offset: 0,
          sortBy: 'createdAt',
          sortDirection: 'asc',
        );

        expect(result, isA<AuthSuccess<MemberList>>());
        final data = (result as AuthSuccess<MemberList>).data;
        expect(data.members, hasLength(1));
        expect(data.total, equals(1));
      });

      test('omits optional query params when not provided', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-members',
          body: <String, dynamic>{
            'members': <Map<String, dynamic>>[],
            'total': 0,
          },
        );

        final result = await ctx.client.organization.listMembers();

        expect(result, isA<AuthSuccess<MemberList>>());
        expect((result as AuthSuccess<MemberList>).data.members, isEmpty);
      });
    });

    group('getActiveMember', () {
      test('returns a Member on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/get-active-member',
          body: memberJson(role: 'owner'),
        );

        final result = await ctx.client.organization.getActiveMember();

        expect(result, isA<AuthSuccess<Member>>());
        expect((result as AuthSuccess<Member>).data.role, equals('owner'));
      });

      test('fails with AuthUnknownException on non-object body', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/get-active-member',
          body: <dynamic>[1, 2, 3],
        );

        final result = await ctx.client.organization.getActiveMember();

        expect(result, isA<AuthFailure<Member>>());
        expect(
          (result as AuthFailure<Member>).error,
          isA<AuthUnknownException>(),
        );
      });
    });

    group('removeMember', () {
      test('returns a Member when wrapped in {member: {...}}', () async {
        stubPost(
          ctx.adapter,
          '/organization/remove-member',
          body: <String, dynamic>{'member': memberJson()},
        );

        final result = await ctx.client.organization.removeMember(
          memberIdOrEmail: 'mem_1',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Member>>());
        expect((result as AuthSuccess<Member>).data.id, equals('mem_1'));
      });

      test('returns a Member from a bare body', () async {
        stubPost(
          ctx.adapter,
          '/organization/remove-member',
          body: memberJson(id: 'mem_bare'),
        );

        final result = await ctx.client.organization.removeMember(
          memberIdOrEmail: 'invitee@example.com',
        );

        expect(result, isA<AuthSuccess<Member>>());
        expect((result as AuthSuccess<Member>).data.id, equals('mem_bare'));
      });
    });

    group('updateMemberRole', () {
      test('returns a Member (wrapped) on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/update-member-role',
          body: <String, dynamic>{'member': memberJson(role: 'admin')},
        );

        final result = await ctx.client.organization.updateMemberRole(
          memberId: 'mem_1',
          role: 'admin',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Member>>());
        expect((result as AuthSuccess<Member>).data.role, equals('admin'));
      });
    });

    group('leaveOrganization', () {
      test('returns a Member on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/leave',
          body: memberJson(),
        );

        final result = await ctx.client.organization.leaveOrganization(
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Member>>());
        expect((result as AuthSuccess<Member>).data.userId, equals('user_1'));
      });
    });

    // --- Invitations ---

    group('inviteMember', () {
      test('returns an Invitation on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/invite-member',
          body: invitationJson(),
        );

        final result = await ctx.client.organization.inviteMember(
          email: 'invitee@example.com',
          role: 'member',
          organizationId: 'org_1',
          resend: true,
          teamId: 'team_1',
        );

        expect(result, isA<AuthSuccess<Invitation>>());
        expect(
          (result as AuthSuccess<Invitation>).data.email,
          equals('invitee@example.com'),
        );
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/organization/invite-member',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.organization.inviteMember(
          email: 'invitee@example.com',
          role: 'member',
        );

        expect(result, isA<AuthFailure<Invitation>>());
        expect(
          (result as AuthFailure<Invitation>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('acceptInvitation', () {
      test('returns an AcceptInvitationResult on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/accept-invitation',
          body: <String, dynamic>{
            'invitation': invitationJson(status: 'accepted'),
            'member': memberJson(),
          },
        );

        final result = await ctx.client.organization.acceptInvitation(
          invitationId: 'inv_1',
        );

        expect(result, isA<AuthSuccess<AcceptInvitationResult>>());
        final data = (result as AuthSuccess<AcceptInvitationResult>).data;
        expect(data.invitation, isNotNull);
        expect(data.member, isNotNull);
      });
    });

    group('rejectInvitation', () {
      test('returns an AcceptInvitationResult on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/reject-invitation',
          body: <String, dynamic>{
            'invitation': invitationJson(status: 'rejected'),
          },
        );

        final result = await ctx.client.organization.rejectInvitation(
          invitationId: 'inv_1',
        );

        expect(result, isA<AuthSuccess<AcceptInvitationResult>>());
        final data = (result as AuthSuccess<AcceptInvitationResult>).data;
        expect(data.invitation, isNotNull);
        expect(data.invitation!.status, equals('rejected'));
      });
    });

    group('cancelInvitation', () {
      test('returns an Invitation when wrapped in invitation key', () async {
        stubPost(
          ctx.adapter,
          '/organization/cancel-invitation',
          body: <String, dynamic>{
            'invitation': invitationJson(status: 'canceled'),
          },
        );

        final result = await ctx.client.organization.cancelInvitation(
          invitationId: 'inv_1',
        );

        expect(result, isA<AuthSuccess<Invitation>>());
        expect(
          (result as AuthSuccess<Invitation>).data.status,
          equals('canceled'),
        );
      });

      test('returns an Invitation from a bare body', () async {
        stubPost(
          ctx.adapter,
          '/organization/cancel-invitation',
          body: invitationJson(id: 'inv_bare', status: 'canceled'),
        );

        final result = await ctx.client.organization.cancelInvitation(
          invitationId: 'inv_bare',
        );

        expect(result, isA<AuthSuccess<Invitation>>());
        expect((result as AuthSuccess<Invitation>).data.id, equals('inv_bare'));
      });
    });

    group('getInvitation', () {
      test('returns an Invitation on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/get-invitation',
          body: invitationJson(),
        );

        final result = await ctx.client.organization.getInvitation(
          id: 'inv_1',
        );

        expect(result, isA<AuthSuccess<Invitation>>());
        expect((result as AuthSuccess<Invitation>).data.id, equals('inv_1'));
      });
    });

    group('listInvitations', () {
      test('returns a list of invitations on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-invitations',
          body: <Map<String, dynamic>>[
            invitationJson(),
            invitationJson(id: 'inv_2'),
          ],
        );

        final result = await ctx.client.organization.listInvitations(
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<List<Invitation>>>());
        expect(
          (result as AuthSuccess<List<Invitation>>).data,
          hasLength(2),
        );
      });

      test('omits organizationId when not provided', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-invitations',
          body: <Map<String, dynamic>>[],
        );

        final result = await ctx.client.organization.listInvitations();

        expect(result, isA<AuthSuccess<List<Invitation>>>());
        expect((result as AuthSuccess<List<Invitation>>).data, isEmpty);
      });
    });

    // --- Teams ---

    group('createTeam', () {
      test('returns a Team on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/create-team',
          body: teamJson(),
        );

        final result = await ctx.client.organization.createTeam(
          name: 'Engineering',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<Team>>());
        expect((result as AuthSuccess<Team>).data.name, equals('Engineering'));
      });

      test('omits organizationId when not provided', () async {
        stubPost(
          ctx.adapter,
          '/organization/create-team',
          body: teamJson(),
        );

        final result = await ctx.client.organization.createTeam(
          name: 'Engineering',
        );

        expect(result, isA<AuthSuccess<Team>>());
      });
    });

    group('listTeams', () {
      test('returns a list of teams on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-teams',
          body: <Map<String, dynamic>>[
            teamJson(),
            teamJson(id: 'team_2'),
          ],
        );

        final result = await ctx.client.organization.listTeams(
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<List<Team>>>());
        expect((result as AuthSuccess<List<Team>>).data, hasLength(2));
      });
    });

    group('updateTeam', () {
      test('returns a Team on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/update-team',
          body: teamJson(name: 'Platform'),
        );

        final result = await ctx.client.organization.updateTeam(
          teamId: 'team_1',
          name: 'Platform',
        );

        expect(result, isA<AuthSuccess<Team>>());
        expect((result as AuthSuccess<Team>).data.name, equals('Platform'));
      });
    });

    group('removeTeam', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/remove-team',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.organization.removeTeam(
          teamId: 'team_1',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });

      test('fails with AuthApiException on a 400', () async {
        stubPost(
          ctx.adapter,
          '/organization/remove-team',
          status: 400,
          body: <String, dynamic>{'message': 'Bad', 'code': 'BAD'},
        );

        final result = await ctx.client.organization.removeTeam(
          teamId: 'team_1',
        );

        expect(result, isA<AuthFailure<StatusResponse>>());
        expect(
          (result as AuthFailure<StatusResponse>).error,
          isA<AuthApiException>(),
        );
      });
    });

    group('setActiveTeam', () {
      test('returns a Team when set', () async {
        stubPost(
          ctx.adapter,
          '/organization/set-active-team',
          body: teamJson(),
        );

        final result = await ctx.client.organization.setActiveTeam(
          teamId: 'team_1',
        );

        expect(result, isA<AuthSuccess<Team?>>());
        expect((result as AuthSuccess<Team?>).data, isNotNull);
      });

      test('returns null when cleared (null body)', () async {
        stubPost(ctx.adapter, '/organization/set-active-team');

        final result = await ctx.client.organization.setActiveTeam();

        expect(result, isA<AuthSuccess<Team?>>());
        expect((result as AuthSuccess<Team?>).data, isNull);
      });
    });

    group('listUserTeams', () {
      test('returns a list of teams on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-user-teams',
          body: <Map<String, dynamic>>[teamJson()],
        );

        final result = await ctx.client.organization.listUserTeams();

        expect(result, isA<AuthSuccess<List<Team>>>());
        expect((result as AuthSuccess<List<Team>>).data, hasLength(1));
      });
    });

    group('listTeamMembers', () {
      test('returns a list of team members on success', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-team-members',
          body: <Map<String, dynamic>>[
            teamMemberJson(),
            teamMemberJson(id: 'tm_2'),
          ],
        );

        final result = await ctx.client.organization.listTeamMembers(
          teamId: 'team_1',
        );

        expect(result, isA<AuthSuccess<List<TeamMember>>>());
        expect(
          (result as AuthSuccess<List<TeamMember>>).data,
          hasLength(2),
        );
      });

      test('omits teamId when not provided', () async {
        stubGetQuery(
          ctx.adapter,
          '/organization/list-team-members',
          body: <Map<String, dynamic>>[],
        );

        final result = await ctx.client.organization.listTeamMembers();

        expect(result, isA<AuthSuccess<List<TeamMember>>>());
        expect((result as AuthSuccess<List<TeamMember>>).data, isEmpty);
      });
    });

    group('addTeamMember', () {
      test('returns a TeamMember on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/add-team-member',
          body: teamMemberJson(),
        );

        final result = await ctx.client.organization.addTeamMember(
          teamId: 'team_1',
          userId: 'user_1',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<TeamMember>>());
        expect(
          (result as AuthSuccess<TeamMember>).data.userId,
          equals('user_1'),
        );
      });
    });

    group('removeTeamMember', () {
      test('returns a StatusResponse on success', () async {
        stubPost(
          ctx.adapter,
          '/organization/remove-team-member',
          body: <String, dynamic>{'status': true},
        );

        final result = await ctx.client.organization.removeTeamMember(
          teamId: 'team_1',
          userId: 'user_1',
          organizationId: 'org_1',
        );

        expect(result, isA<AuthSuccess<StatusResponse>>());
        expect((result as AuthSuccess<StatusResponse>).data.ok, isTrue);
      });
    });
  });
}
