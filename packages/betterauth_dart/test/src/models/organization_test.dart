// Models are constructed with literal fields in these tests; const would make
// the assertions less readable, so opt out of the const-constructor lint.
// ignore_for_file: prefer_const_constructors

import 'package:betterauth_dart/betterauth_dart.dart';
import 'package:test/test.dart';

void main() {
  group(Organization, () {
    test('parses a full JSON map with nested members/invitations/teams', () {
      final json = <String, dynamic>{
        'id': 'org_1',
        'name': 'Acme',
        'slug': 'acme',
        'logo': 'https://example.com/logo.png',
        'metadata': <String, dynamic>{'plan': 'pro'},
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'members': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'm_1',
            'organizationId': 'org_1',
            'userId': 'user_1',
            'role': 'owner',
          },
        ],
        'invitations': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'inv_1',
            'email': 'a@example.com',
            'role': 'member',
            'organizationId': 'org_1',
          },
        ],
        'teams': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'team_1',
            'name': 'Eng',
            'organizationId': 'org_1',
          },
        ],
      };

      final result = Organization.fromJson(json);

      expect(result.id, equals('org_1'));
      expect(result.name, equals('Acme'));
      expect(result.slug, equals('acme'));
      expect(result.logo, equals('https://example.com/logo.png'));
      expect(result.metadata, equals(<String, Object?>{'plan': 'pro'}));
      expect(result.createdAt, equals(DateTime.utc(2026)));
      expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
      expect(result.members, hasLength(1));
      expect(result.members.first.role, equals('owner'));
      expect(result.invitations, hasLength(1));
      expect(result.invitations.first.email, equals('a@example.com'));
      expect(result.teams, hasLength(1));
      expect(result.teams.first.name, equals('Eng'));
    });

    test('parses a bare JSON map without nested collections', () {
      final json = <String, dynamic>{
        'id': 'org_1',
        'name': 'Acme',
        'slug': 'acme',
      };

      final result = Organization.fromJson(json);

      expect(result.logo, isNull);
      expect(result.metadata, isNull);
      expect(result.createdAt, isNull);
      expect(result.updatedAt, isNull);
      expect(result.members, isEmpty);
      expect(result.invitations, isEmpty);
      expect(result.teams, isEmpty);
    });

    test('maps metadata to null when it is not a Map', () {
      final json = <String, dynamic>{
        'id': 'org_1',
        'name': 'Acme',
        'slug': 'acme',
        'metadata': 'not-a-map',
      };

      expect(Organization.fromJson(json).metadata, isNull);
    });

    test('_list skips elements that are not Maps', () {
      final json = <String, dynamic>{
        'id': 'org_1',
        'name': 'Acme',
        'slug': 'acme',
        'members': <dynamic>[
          'not-a-map',
          <String, dynamic>{
            'id': 'm_1',
            'organizationId': 'org_1',
            'userId': 'user_1',
            'role': 'member',
          },
        ],
      };

      final result = Organization.fromJson(json);

      expect(result.members, hasLength(1));
      expect(result.members.first.id, equals('m_1'));
    });

    test('_list returns empty when the value is not a List', () {
      final json = <String, dynamic>{
        'id': 'org_1',
        'name': 'Acme',
        'slug': 'acme',
        'members': <String, dynamic>{'not': 'a list'},
      };

      expect(Organization.fromJson(json).members, isEmpty);
    });

    test('exposes all fields via props', () {
      final org = Organization(
        id: 'org_1',
        name: 'Acme',
        slug: 'acme',
        logo: 'logo',
        metadata: const {'k': 'v'},
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        org.props,
        equals(<Object?>[
          org.id,
          org.name,
          org.slug,
          org.logo,
          org.metadata,
          org.createdAt,
          org.updatedAt,
          org.members,
          org.invitations,
          org.teams,
        ]),
      );
    });

    test('equality and toString', () {
      final a = Organization(id: 'org_1', name: 'Acme', slug: 'acme');
      final b = Organization(id: 'org_1', name: 'Acme', slug: 'acme');
      final c = Organization(id: 'org_2', name: 'Acme', slug: 'acme');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.toString(), equals('Organization(id: org_1, slug: acme)'));
    });
  });

  group(MemberUser, () {
    test('parses a full JSON map', () {
      final json = <String, dynamic>{
        'id': 'user_1',
        'name': 'Ada',
        'email': 'ada@example.com',
        'image': 'https://example.com/a.png',
      };

      final result = MemberUser.fromJson(json);

      expect(result.id, equals('user_1'));
      expect(result.name, equals('Ada'));
      expect(result.email, equals('ada@example.com'));
      expect(result.image, equals('https://example.com/a.png'));
    });

    test('parses a minimal JSON map with nullable fields', () {
      final result = MemberUser.fromJson(
        const <String, dynamic>{'id': 'user_1'},
      );

      expect(result.id, equals('user_1'));
      expect(result.name, isNull);
      expect(result.email, isNull);
      expect(result.image, isNull);
    });

    test('exposes all fields via props', () {
      final mu = MemberUser(id: 'user_1', name: 'Ada');

      expect(mu.props, equals(<Object?>[mu.id, mu.name, mu.email, mu.image]));
    });
  });

  group(Member, () {
    test('parses a JSON map with an embedded user and teamId', () {
      final json = <String, dynamic>{
        'id': 'm_1',
        'organizationId': 'org_1',
        'userId': 'user_1',
        'role': 'admin',
        'user': <String, dynamic>{'id': 'user_1', 'name': 'Ada'},
        'teamId': 'team_1',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      };

      final result = Member.fromJson(json);

      expect(result.id, equals('m_1'));
      expect(result.organizationId, equals('org_1'));
      expect(result.userId, equals('user_1'));
      expect(result.role, equals('admin'));
      expect(result.user, isNotNull);
      expect(result.user!.name, equals('Ada'));
      expect(result.teamId, equals('team_1'));
      expect(result.createdAt, equals(DateTime.utc(2026)));
      expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
    });

    test('parses a JSON map without an embedded user', () {
      final json = <String, dynamic>{
        'id': 'm_1',
        'organizationId': 'org_1',
        'userId': 'user_1',
        'role': 'member',
      };

      final result = Member.fromJson(json);

      expect(result.user, isNull);
      expect(result.teamId, isNull);
      expect(result.createdAt, isNull);
      expect(result.updatedAt, isNull);
    });

    test('exposes all fields via props and toString', () {
      final m = Member(
        id: 'm_1',
        organizationId: 'org_1',
        userId: 'user_1',
        role: 'member',
      );

      expect(
        m.props,
        equals(<Object?>[
          m.id,
          m.organizationId,
          m.userId,
          m.role,
          m.user,
          m.teamId,
          m.createdAt,
          m.updatedAt,
        ]),
      );
      expect(m.toString(), equals('Member(id: m_1, role: member)'));
    });
  });

  group(Invitation, () {
    test('parses a full JSON map', () {
      final json = <String, dynamic>{
        'id': 'inv_1',
        'email': 'a@example.com',
        'role': 'member',
        'organizationId': 'org_1',
        'status': 'accepted',
        'inviterId': 'm_1',
        'teamId': 'team_1',
        'expiresAt': '2026-02-01T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final result = Invitation.fromJson(json);

      expect(result.id, equals('inv_1'));
      expect(result.email, equals('a@example.com'));
      expect(result.role, equals('member'));
      expect(result.organizationId, equals('org_1'));
      expect(result.status, equals('accepted'));
      expect(result.inviterId, equals('m_1'));
      expect(result.teamId, equals('team_1'));
      expect(result.expiresAt, equals(DateTime.utc(2026, 2)));
      expect(result.createdAt, equals(DateTime.utc(2026)));
    });

    test('defaults status to pending when absent', () {
      final json = <String, dynamic>{
        'id': 'inv_1',
        'email': 'a@example.com',
        'role': 'member',
        'organizationId': 'org_1',
      };

      final result = Invitation.fromJson(json);

      expect(result.status, equals('pending'));
      expect(result.inviterId, isNull);
      expect(result.teamId, isNull);
      expect(result.expiresAt, isNull);
      expect(result.createdAt, isNull);
    });

    test('exposes all fields via props and toString', () {
      final inv = Invitation(
        id: 'inv_1',
        email: 'a@example.com',
        role: 'member',
        organizationId: 'org_1',
        status: 'pending',
      );

      expect(
        inv.props,
        equals(<Object?>[
          inv.id,
          inv.email,
          inv.role,
          inv.organizationId,
          inv.status,
          inv.inviterId,
          inv.teamId,
          inv.expiresAt,
          inv.createdAt,
        ]),
      );
      expect(
        inv.toString(),
        equals('Invitation(id: inv_1, email: a@example.com, status: pending)'),
      );
    });
  });

  group(Team, () {
    test('parses a full JSON map', () {
      final json = <String, dynamic>{
        'id': 'team_1',
        'name': 'Eng',
        'organizationId': 'org_1',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      };

      final result = Team.fromJson(json);

      expect(result.id, equals('team_1'));
      expect(result.name, equals('Eng'));
      expect(result.organizationId, equals('org_1'));
      expect(result.createdAt, equals(DateTime.utc(2026)));
      expect(result.updatedAt, equals(DateTime.utc(2026, 1, 2)));
    });

    test('parses a minimal JSON map with nullable dates', () {
      final result = Team.fromJson(const <String, dynamic>{
        'id': 'team_1',
        'name': 'Eng',
        'organizationId': 'org_1',
      });

      expect(result.createdAt, isNull);
      expect(result.updatedAt, isNull);
    });

    test('exposes all fields via props and toString', () {
      final team = Team(id: 'team_1', name: 'Eng', organizationId: 'org_1');

      expect(
        team.props,
        equals(<Object?>[
          team.id,
          team.name,
          team.organizationId,
          team.createdAt,
          team.updatedAt,
        ]),
      );
      expect(team.toString(), equals('Team(id: team_1, name: Eng)'));
    });
  });

  group(TeamMember, () {
    test('parses a full JSON map', () {
      final json = <String, dynamic>{
        'id': 'tm_1',
        'teamId': 'team_1',
        'userId': 'user_1',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final result = TeamMember.fromJson(json);

      expect(result.id, equals('tm_1'));
      expect(result.teamId, equals('team_1'));
      expect(result.userId, equals('user_1'));
      expect(result.createdAt, equals(DateTime.utc(2026)));
    });

    test('parses a minimal JSON map with a null createdAt', () {
      final result = TeamMember.fromJson(const <String, dynamic>{
        'id': 'tm_1',
        'teamId': 'team_1',
        'userId': 'user_1',
      });

      expect(result.createdAt, isNull);
    });

    test('exposes all fields via props and toString', () {
      final tm = TeamMember(id: 'tm_1', teamId: 'team_1', userId: 'user_1');

      expect(
        tm.props,
        equals(<Object?>[tm.id, tm.teamId, tm.userId, tm.createdAt]),
      );
      expect(tm.toString(), equals('TeamMember(id: tm_1, userId: user_1)'));
    });
  });

  group(MemberList, () {
    test('parses members and total', () {
      final json = <String, dynamic>{
        'members': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'm_1',
            'organizationId': 'org_1',
            'userId': 'user_1',
            'role': 'member',
          },
        ],
        'total': 5,
      };

      final result = MemberList.fromJson(json);

      expect(result.members, hasLength(1));
      expect(result.total, equals(5));
    });

    test('applies defaults when fields are absent', () {
      final result = MemberList.fromJson(const <String, dynamic>{});

      expect(result.members, isEmpty);
      expect(result.total, equals(0));
    });

    test('exposes all fields via props', () {
      final list = MemberList(total: 2);

      expect(list.props, equals(<Object?>[list.members, list.total]));
    });
  });

  group(AcceptInvitationResult, () {
    test('parses an invitation and member when both are present', () {
      final json = <String, dynamic>{
        'invitation': <String, dynamic>{
          'id': 'inv_1',
          'email': 'a@example.com',
          'role': 'member',
          'organizationId': 'org_1',
        },
        'member': <String, dynamic>{
          'id': 'm_1',
          'organizationId': 'org_1',
          'userId': 'user_1',
          'role': 'member',
        },
      };

      final result = AcceptInvitationResult.fromJson(json);

      expect(result.invitation, isNotNull);
      expect(result.invitation!.id, equals('inv_1'));
      expect(result.member, isNotNull);
      expect(result.member!.id, equals('m_1'));
    });

    test('maps invitation and member to null when both are absent', () {
      final result = AcceptInvitationResult.fromJson(const <String, dynamic>{});

      expect(result.invitation, isNull);
      expect(result.member, isNull);
    });

    test('exposes all fields via props', () {
      const result = AcceptInvitationResult();

      expect(result.props, equals(<Object?>[null, null]));
    });
  });
}
