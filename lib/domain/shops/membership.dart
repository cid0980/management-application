/// WHO WORKS AT A SHOP, AND WHAT THEY MAY DO
///
/// The app's two roles — admin and staff — were always per shop; they just had
/// nowhere to live while there was only one shop. A member record is what
/// makes them real: it says this uid works at this shop, with this role.
///
/// **The owner cannot be removed or demoted.** A shop whose last admin has
/// been taken off it is a shop nobody can administer, and the only fix is
/// somebody with database access. Every other member can be removed.
///
/// **An invite is keyed by email, not by uid**, because the person being
/// invited has not signed up yet — there is no uid to key on. The invite is
/// claimed on their first sign-in, which is the moment a uid first exists.
library;

import '../common/email.dart';
import '../common/dates.dart';

/// The role inside one shop. The same two the app has always had.
enum ShopRole { admin, staff }

const Map<ShopRole, String> kShopRoleLabels = {
  ShopRole.admin: 'Owner / admin',
  ShopRole.staff: 'Staff',
};

/// Read a stored role.
///
/// Anything unrecognised reads as **staff**, which is the reading that grants
/// least. A corrupt or future role value must never quietly hand somebody
/// admin over a shop's takings.
ShopRole roleFrom(Object? raw) =>
    raw?.toString() == 'admin' ? ShopRole.admin : ShopRole.staff;

class ShopMember {
  const ShopMember({
    required this.uid,
    required this.role,
    this.email = '',
    this.name = '',
    this.isOwner = false,
    this.addedAt,
  });

  final String uid;
  final ShopRole role;
  final String email;
  final String name;

  /// Created the shop. Protected — see the library note.
  final bool isOwner;

  final DateTime? addedAt;

  bool get isAdmin => role == ShopRole.admin;

  /// What to show in a members list. Never blank: somebody who signed up and
  /// has not set a name still has an email.
  String get label =>
      name.trim().isNotEmpty ? name.trim() : (email.isNotEmpty ? email : uid);

  static ShopMember fromMap(String uid, Map<String, Object?> map) => ShopMember(
    uid: uid,
    role: roleFrom(map['role']),
    email: (map['email'] ?? '').toString().trim().toLowerCase(),
    name: (map['name'] ?? '').toString().trim(),
    isOwner: map['isOwner'] == true,
    addedAt: normalizeDate(map['addedAt']),
  );

  Map<String, Object?> toMap() => {
    'role': role.name,
    'email': email,
    'name': name,
    'isOwner': isOwner,
    'addedAt': addedAt?.toIso8601String(),
  };
}

/// A staff member invited by email who has not signed up yet.
class ShopInvite {
  const ShopInvite({
    required this.email,
    required this.role,
    this.shopId = '',
    this.shopName = '',
    this.invitedBy = '',
    this.invitedAt,
  });

  final String email;
  final ShopRole role;

  /// Carried on the invite so a signing-in user can find their shop from the
  /// invite alone, without being allowed to read the whole shops collection.
  final String shopId;
  final String shopName;

  final String invitedBy;
  final DateTime? invitedAt;

  static ShopInvite fromMap(String email, Map<String, Object?> map) =>
      ShopInvite(
        email: email,
        role: roleFrom(map['role']),
        shopId: (map['shopId'] ?? '').toString(),
        shopName: (map['shopName'] ?? '').toString(),
        invitedBy: (map['invitedBy'] ?? '').toString(),
        invitedAt: normalizeDate(map['invitedAt']),
      );

  Map<String, Object?> toMap() => {
    'role': role.name,
    'shopId': shopId,
    'shopName': shopName,
    'invitedBy': invitedBy,
    'invitedAt': invitedAt?.toIso8601String(),
  };
}

/// Why a membership change was refused.
enum MembershipRefusal {
  /// Only an admin hands out or changes access.
  adminOnly,

  /// The owner is protected. A shop with no admin cannot be administered.
  cannotChangeOwner,

  /// Removing yourself as the last admin leaves the same problem.
  lastAdmin,

  /// Not an email address.
  notAnEmail,

  /// That person is already in this shop.
  alreadyMember,
}

const Map<MembershipRefusal, String> kMembershipMessages = {
  MembershipRefusal.adminOnly: 'Only an admin can change who works here',
  MembershipRefusal.cannotChangeOwner:
      "The shop's owner cannot be removed or changed to staff",
  MembershipRefusal.lastAdmin:
      'That would leave the shop with no admin — make somebody else an admin '
      'first',
  MembershipRefusal.notAnEmail: 'That is not an email address',
  MembershipRefusal.alreadyMember: 'That person already works here',
};

/// Whether [actor] may invite somebody at [email].
MembershipRefusal? inviteBlockFor({
  required ShopMember? actor,
  required String email,
  required Iterable<ShopMember> existing,
}) {
  if (actor == null || !actor.isAdmin) return MembershipRefusal.adminOnly;
  if (!looksLikeEmail(email)) return MembershipRefusal.notAnEmail;
  final key = email.trim().toLowerCase();
  if (existing.any((m) => m.email == key)) {
    return MembershipRefusal.alreadyMember;
  }
  return null;
}

/// Whether [actor] may remove [target] from the shop.
MembershipRefusal? removeBlockFor({
  required ShopMember? actor,
  required ShopMember target,
  required Iterable<ShopMember> allMembers,
}) {
  if (actor == null || !actor.isAdmin) return MembershipRefusal.adminOnly;
  if (target.isOwner) return MembershipRefusal.cannotChangeOwner;
  if (target.isAdmin && _adminCount(allMembers) <= 1) {
    return MembershipRefusal.lastAdmin;
  }
  return null;
}

/// Whether [me] may leave the shop by deleting their own account.
///
/// Google Play requires that anybody who can sign up can delete their account
/// from inside the app. The one thing that must not happen on the way out is
/// a shop left with staff and no admin — nobody could invite, change roles or
/// read the reports again. So the last admin of a shop that still has other
/// people in it is asked to make somebody else an admin first. The last person
/// of all may leave: there is nobody left to strand.
MembershipRefusal? leaveBlockFor({
  required ShopMember me,
  required Iterable<ShopMember> allMembers,
}) {
  final others = allMembers.where((m) => m.uid != me.uid);
  if (me.isAdmin && others.isNotEmpty && !others.any((m) => m.isAdmin)) {
    return MembershipRefusal.lastAdmin;
  }
  return null;
}

/// Whether [actor] may change [target]'s role to [role].
MembershipRefusal? roleChangeBlockFor({
  required ShopMember? actor,
  required ShopMember target,
  required ShopRole role,
  required Iterable<ShopMember> allMembers,
}) {
  if (actor == null || !actor.isAdmin) return MembershipRefusal.adminOnly;
  if (target.isOwner) return MembershipRefusal.cannotChangeOwner;
  // Demoting the only remaining admin is the same problem as removing them.
  if (target.isAdmin &&
      role == ShopRole.staff &&
      _adminCount(allMembers) <= 1) {
    return MembershipRefusal.lastAdmin;
  }
  return null;
}

int _adminCount(Iterable<ShopMember> members) =>
    members.where((m) => m.isAdmin).length;

/// Whether this could be an email — the app's one rule (common/email.dart),
/// the same as a customer's email.
bool looksLikeEmail(String? value) => isEmailAddress(value);
