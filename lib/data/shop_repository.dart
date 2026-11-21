/// CREATING A SHOP, AND DECIDING WHO WORKS THERE
///
/// This is the only file that writes outside a single shop's document, because
/// creating one and inviting somebody to one are the two things that cannot be
/// done from inside it.
///
/// **A shop is created in one batch.** The shop document, the owner's
/// membership and the owner's user pointer are written together. Separately,
/// a failure halfway leaves a shop nobody is a member of — invisible to its
/// own creator and impossible to fix from the app.
///
/// **An invite is written twice, on purpose.** The shop keeps its own copy so
/// the owner can see who is outstanding; a pointer at `invites/{email}` is
/// what the invited person can actually find, because on their first sign-in
/// they know their email and nothing else. See `firestore_paths.dart`.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/shops/membership.dart';
import '../domain/shops/shop.dart';
import 'firestore_paths.dart';

class ShopResult {
  const ShopResult.ok(this.shop) : error = null, refusal = null;

  const ShopResult.failed(this.error) : shop = null, refusal = null;

  ShopResult.refused(MembershipRefusal this.refusal)
    : shop = null,
      error = null;

  final Shop? shop;
  final String? error;
  final MembershipRefusal? refusal;

  bool get ok => shop != null;
  String? get message =>
      error ?? (refusal == null ? null : kMembershipMessages[refusal]);
}

class MemberResult {
  const MemberResult.ok() : refusal = null, error = null;
  MemberResult.refused(MembershipRefusal this.refusal) : error = null;
  const MemberResult.failed(this.error) : refusal = null;

  final MembershipRefusal? refusal;
  final String? error;

  bool get ok => refusal == null && error == null;
  String? get message =>
      error ?? (refusal == null ? null : kMembershipMessages[refusal]);
}

abstract class ShopRepository extends ChangeNotifier {
  /// Create a shop and make [ownerUid] its admin.
  Future<ShopResult> createShop({
    required Shop shop,
    required String ownerUid,
    required String ownerEmail,
    String ownerName,
  });

  Future<Shop?> load(String shopId);

  Future<ShopResult> updateShop(Shop shop);

  /// Everyone who works at this shop.
  Stream<List<ShopMember>> watchMembers(String shopId);

  /// Invites sent but not yet claimed.
  Stream<List<ShopInvite>> watchInvites(String shopId);

  Future<MemberResult> invite({
    required String shopId,
    required String shopName,
    required String email,
    required ShopRole role,
    required ShopMember? actor,
    required List<ShopMember> existing,
  });

  Future<MemberResult> withdrawInvite({
    required String shopId,
    required String email,
    required ShopMember? actor,
  });

  Future<MemberResult> setRole({
    required String shopId,
    required ShopMember target,
    required ShopRole role,
    required ShopMember? actor,
    required List<ShopMember> allMembers,
  });

  Future<MemberResult> removeMember({
    required String shopId,
    required ShopMember target,
    required ShopMember? actor,
    required List<ShopMember> allMembers,
  });
}

class FirestoreShopStore extends ChangeNotifier implements ShopRepository {
  FirestoreShopStore({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  ShopScope _scope(String shopId) => ShopScope(shopId: shopId, firestore: _db);

  @override
  Future<ShopResult> createShop({
    required Shop shop,
    required String ownerUid,
    required String ownerEmail,
    String ownerName = '',
  }) async {
    final validation = validateShop(shop);
    if (!validation.isValid) {
      return ShopResult.failed(validation.errors.values.first);
    }

    // A readable id with a short unique suffix. Readable because it turns up
    // in support conversations and in the console.
    final suffix = _db.collection(kShopsCollection).doc().id.substring(0, 5);
    final shopId = shopIdFrom(shop.name, suffix: suffix.toLowerCase());
    final scope = _scope(shopId);
    final now = DateTime.now();

    final stored = Shop(
      id: shopId,
      name: shop.name.trim(),
      ownerUid: ownerUid,
      phone: shop.phone,
      address: shop.address,
      gstin: shop.gstin,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // One batch. Half of this would be a shop its own creator cannot see.
      final batch = _db.batch();
      batch.set(scope.shop, stored.toMap());
      batch.set(
        scope.members.doc(ownerUid),
        ShopMember(
          uid: ownerUid,
          role: ShopRole.admin,
          email: normalizeEmail(ownerEmail),
          name: ownerName.trim(),
          // Protected from here on: the shop cannot be left without an admin.
          isOwner: true,
          addedAt: now,
        ).toMap(),
      );
      batch.set(userDoc(_db, ownerUid), {
        'shopId': shopId,
        'email': normalizeEmail(ownerEmail),
        'joinedAt': now.toIso8601String(),
      });
      await batch.commit();
      return ShopResult.ok(stored);
    } catch (e) {
      return ShopResult.failed('Could not create the shop: $e');
    }
  }

  @override
  Future<Shop?> load(String shopId) async {
    final doc = await _scope(shopId).shop.get();
    return doc.exists ? Shop.fromMap(shopId, doc.data()!) : null;
  }

  @override
  Future<ShopResult> updateShop(Shop shop) async {
    final validation = validateShop(shop);
    if (!validation.isValid) {
      return ShopResult.failed(validation.errors.values.first);
    }
    try {
      final updated = shop.copyWith(updatedAt: DateTime.now());
      // Merged, so the owner and createdAt written at creation survive an
      // edit that does not mention them.
      await _scope(shop.id).shop.set(updated.toMap(), SetOptions(merge: true));
      return ShopResult.ok(updated);
    } catch (e) {
      return ShopResult.failed('Could not save the shop: $e');
    }
  }

  @override
  Stream<List<ShopMember>> watchMembers(String shopId) => _scope(shopId).members
      .snapshots()
      .map(
        (s) => [
          for (final doc in s.docs) ShopMember.fromMap(doc.id, doc.data()),
        ],
      );

  @override
  Stream<List<ShopInvite>> watchInvites(String shopId) => _scope(shopId).invites
      .snapshots()
      .map(
        (s) => [
          for (final doc in s.docs) ShopInvite.fromMap(doc.id, doc.data()),
        ],
      );

  @override
  Future<MemberResult> invite({
    required String shopId,
    required String shopName,
    required String email,
    required ShopRole role,
    required ShopMember? actor,
    required List<ShopMember> existing,
  }) async {
    final block = inviteBlockFor(
      actor: actor,
      email: email,
      existing: existing,
    );
    if (block != null) return MemberResult.refused(block);

    final key = normalizeEmail(email);
    final invite = ShopInvite(
      email: key,
      role: role,
      shopId: shopId,
      shopName: shopName,
      invitedBy: actor?.uid ?? '',
      invitedAt: DateTime.now(),
    );

    try {
      // Both copies, in one batch — see the library note on why there are two.
      final batch = _db.batch();
      batch.set(_scope(shopId).invite(key), invite.toMap());
      batch.set(pendingInvite(_db, key), invite.toMap());
      await batch.commit();
      return const MemberResult.ok();
    } catch (e) {
      return MemberResult.failed('Could not send the invite: $e');
    }
  }

  @override
  Future<MemberResult> withdrawInvite({
    required String shopId,
    required String email,
    required ShopMember? actor,
  }) async {
    if (actor == null || !actor.isAdmin) {
      return MemberResult.refused(MembershipRefusal.adminOnly);
    }
    final key = normalizeEmail(email);
    try {
      final batch = _db.batch();
      batch.delete(_scope(shopId).invite(key));
      // The pointer especially: left behind, it would still let that address
      // join after the owner thought they had withdrawn it.
      batch.delete(pendingInvite(_db, key));
      await batch.commit();
      return const MemberResult.ok();
    } catch (e) {
      return MemberResult.failed('Could not withdraw the invite: $e');
    }
  }

  @override
  Future<MemberResult> setRole({
    required String shopId,
    required ShopMember target,
    required ShopRole role,
    required ShopMember? actor,
    required List<ShopMember> allMembers,
  }) async {
    final block = roleChangeBlockFor(
      actor: actor,
      target: target,
      role: role,
      allMembers: allMembers,
    );
    if (block != null) return MemberResult.refused(block);
    try {
      await _scope(shopId).members.doc(target.uid).update({'role': role.name});
      return const MemberResult.ok();
    } catch (e) {
      return MemberResult.failed('Could not change the role: $e');
    }
  }

  @override
  Future<MemberResult> removeMember({
    required String shopId,
    required ShopMember target,
    required ShopMember? actor,
    required List<ShopMember> allMembers,
  }) async {
    final block = removeBlockFor(
      actor: actor,
      target: target,
      allMembers: allMembers,
    );
    if (block != null) return MemberResult.refused(block);
    try {
      final batch = _db.batch();
      batch.delete(_scope(shopId).members.doc(target.uid));
      // Their pointer goes too, or their next sign-in sends them back into a
      // shop they have been removed from.
      batch.delete(userDoc(_db, target.uid));
      await batch.commit();
      return const MemberResult.ok();
    } catch (e) {
      return MemberResult.failed('Could not remove them: $e');
    }
  }
}
