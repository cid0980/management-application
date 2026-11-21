import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/shops/membership.dart';
import 'package:fm_shop/domain/shops/shop.dart';

ShopMember _m(
  String uid, {
  ShopRole role = ShopRole.staff,
  bool owner = false,
  String email = '',
}) =>
    ShopMember(uid: uid, role: role, isOwner: owner, email: email);

final _owner = _m('u-owner', role: ShopRole.admin, owner: true,
    email: 'owner@shop.com');
final _admin = _m('u-admin', role: ShopRole.admin, email: 'admin@shop.com');
final _staff = _m('u-staff', email: 'staff@shop.com');

void main() {
  group('an unrecognised role grants least', () {
    test('because a corrupt value must not hand over the takings', () {
      expect(roleFrom('admin'), ShopRole.admin);
      expect(roleFrom('staff'), ShopRole.staff);
      expect(roleFrom('superuser'), ShopRole.staff);
      expect(roleFrom(null), ShopRole.staff);
      expect(roleFrom(''), ShopRole.staff);
    });
  });

  group('only an admin changes who works here', () {
    test('staff cannot invite', () {
      expect(
        inviteBlockFor(actor: _staff, email: 'new@shop.com', existing: const []),
        MembershipRefusal.adminOnly,
      );
    });

    test('staff cannot remove or change a role', () {
      expect(
        removeBlockFor(actor: _staff, target: _admin, allMembers: [_admin]),
        MembershipRefusal.adminOnly,
      );
      expect(
        roleChangeBlockFor(
          actor: _staff,
          target: _staff,
          role: ShopRole.admin,
          allMembers: [_owner, _staff],
        ),
        MembershipRefusal.adminOnly,
      );
    });

    test('nobody signed in cannot either', () {
      expect(
        inviteBlockFor(actor: null, email: 'a@b.com', existing: const []),
        MembershipRefusal.adminOnly,
      );
    });

    test('an admin can', () {
      expect(
        inviteBlockFor(actor: _admin, email: 'new@shop.com', existing: const []),
        isNull,
      );
    });
  });

  group('the owner is protected', () {
    test('because a shop with no admin cannot be administered', () {
      expect(
        removeBlockFor(
          actor: _admin,
          target: _owner,
          allMembers: [_owner, _admin],
        ),
        MembershipRefusal.cannotChangeOwner,
      );
    });

    test('and cannot be demoted to staff', () {
      expect(
        roleChangeBlockFor(
          actor: _admin,
          target: _owner,
          role: ShopRole.staff,
          allMembers: [_owner, _admin],
        ),
        MembershipRefusal.cannotChangeOwner,
      );
    });

    test('not even by themselves', () {
      expect(
        removeBlockFor(
          actor: _owner,
          target: _owner,
          allMembers: [_owner],
        ),
        MembershipRefusal.cannotChangeOwner,
      );
    });
  });

  group('the last admin cannot be removed or demoted', () {
    // Same problem as removing the owner, reached a different way.
    final soleAdmin = _m('u-only', role: ShopRole.admin);

    test('removing them is refused', () {
      expect(
        removeBlockFor(
          actor: soleAdmin,
          target: soleAdmin,
          allMembers: [soleAdmin, _staff],
        ),
        MembershipRefusal.lastAdmin,
      );
    });

    test('demoting them is refused', () {
      expect(
        roleChangeBlockFor(
          actor: soleAdmin,
          target: soleAdmin,
          role: ShopRole.staff,
          allMembers: [soleAdmin, _staff],
        ),
        MembershipRefusal.lastAdmin,
      );
    });

    test('but with a second admin it is allowed', () {
      expect(
        removeBlockFor(
          actor: _owner,
          target: _admin,
          allMembers: [_owner, _admin],
        ),
        isNull,
      );
      expect(
        roleChangeBlockFor(
          actor: _owner,
          target: _admin,
          role: ShopRole.staff,
          allMembers: [_owner, _admin],
        ),
        isNull,
      );
    });

    test('and removing staff is never blocked by it', () {
      expect(
        removeBlockFor(
          actor: _admin,
          target: _staff,
          allMembers: [_admin, _staff],
        ),
        isNull,
      );
    });
  });

  group('inviting', () {
    test('somebody already here is refused', () {
      expect(
        inviteBlockFor(
          actor: _admin,
          email: 'STAFF@shop.com',
          existing: [_staff],
        ),
        MembershipRefusal.alreadyMember,
      );
    });

    test('a non-email is refused', () {
      for (final bad in ['', 'nope', 'a b@c.com', '@shop.com', 'a@', 'a@b@c']) {
        expect(
          inviteBlockFor(actor: _admin, email: bad, existing: const []),
          MembershipRefusal.notAnEmail,
          reason: bad,
        );
      }
    });

    test('the email check is loose on purpose', () {
      // A pattern strict enough to be interesting locks somebody out of their
      // own shop.
      for (final ok in ['a@b.c', 'ramesh+shop@gmail.com', 'x_y@sub.domain.in']) {
        expect(looksLikeEmail(ok), isTrue, reason: ok);
      }
    });
  });

  group('a member is never shown blank', () {
    test('name, then email, then uid', () {
      expect(_m('u', email: 'a@b.com').label, 'a@b.com');
      expect(
        const ShopMember(uid: 'u', role: ShopRole.staff, name: 'Suresh')
            .label,
        'Suresh',
      );
      expect(const ShopMember(uid: 'u-123', role: ShopRole.staff).label,
          'u-123');
    });
  });

  group('reading stored records', () {
    test('a member reads back the same', () {
      final member = ShopMember(
        uid: 'u',
        role: ShopRole.admin,
        email: 'a@b.com',
        name: 'Suresh',
        isOwner: true,
        addedAt: DateTime.utc(2026, 3, 4),
      );
      final back = ShopMember.fromMap('u', member.toMap());
      expect(back.role, ShopRole.admin);
      expect(back.isOwner, isTrue);
      expect(back.email, 'a@b.com');
      expect(back.addedAt, DateTime.utc(2026, 3, 4));
    });

    test('an invite carries its shop, so it can be found without a search', () {
      final invite = ShopInvite(
        email: 'new@shop.com',
        role: ShopRole.staff,
        shopId: 'sri-balaji-mobiles-4f2a',
        shopName: 'Sri Balaji Mobiles',
        invitedAt: DateTime.utc(2026, 3, 4),
      );
      final back = ShopInvite.fromMap('new@shop.com', invite.toMap());
      expect(back.shopId, 'sri-balaji-mobiles-4f2a');
      expect(back.shopName, 'Sri Balaji Mobiles');
      expect(back.role, ShopRole.staff);
    });

    test('an empty member document reads as staff, not admin', () {
      expect(ShopMember.fromMap('u', const {}).role, ShopRole.staff);
      expect(ShopMember.fromMap('u', const {}).isOwner, isFalse);
    });
  });

  group('the shop itself', () {
    test('needs a name, because it goes on every bill', () {
      expect(validateShop(const Shop(id: 's', name: '')).errors,
          contains('name'));
      expect(validateShop(const Shop(id: 's', name: 'A')).errors,
          contains('name'));
      expect(validateShop(const Shop(id: 's', name: 'Sri Balaji Mobiles'))
          .isValid, isTrue);
    });

    test('a bad phone is refused, a missing one only warns', () {
      expect(
        validateShop(const Shop(id: 's', name: 'Shop', phone: '12345')).errors,
        contains('phone'),
      );
      final noPhone = validateShop(const Shop(id: 's', name: 'Shop'));
      expect(noPhone.isValid, isTrue);
      expect(noPhone.warnings, contains('phone'));
    });

    test('a GSTIN of the wrong length warns rather than refusing', () {
      // Verifying one is the tax portal's job; refusing a real one would stop
      // the shop printing.
      final result = validateShop(
        const Shop(id: 's', name: 'Shop', gstin: '33ABCDE1234F'),
      );
      expect(result.isValid, isTrue);
      expect(result.warnings['gstin'], contains('15 characters'));
    });

    test('the id is readable, because it shows up in support conversations',
        () {
      expect(
        shopIdFrom('Sri Balaji Mobiles', suffix: '4f2a'),
        'sri-balaji-mobiles-4f2a',
      );
      expect(shopIdFrom("Ram's Mobile & Repair", suffix: 'ab12'),
          'ram-s-mobile-repair-ab12');
      expect(shopIdFrom('', suffix: 'ab12'), 'shop-ab12');
    });

    test('a very long name does not push the suffix past the id limit', () {
      final id = shopIdFrom('A' * 200, suffix: 'ab12');
      expect(id.endsWith('-ab12'), isTrue);
      expect(id.length, lessThan(60));
    });
  });
}
