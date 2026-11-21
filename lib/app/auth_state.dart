import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/firestore_paths.dart';
import '../domain/shops/membership.dart';

/// WHO IS SIGNED IN, AND WHICH SHOP THEY ARE IN
///
/// The app is sold to many mobile shops, so "signed in" is only half the
/// question. A person with an account but no shop can see nothing: every
/// collection in this app lives under one shop, and until we know which, there
/// is nothing to show them. That is why [shopId] sits beside [signedIn] here
/// rather than somewhere deeper — the router needs both to decide where
/// somebody lands.
///
/// **Resolving the shop is part of loading.** The router must not bounce
/// somebody to "create a shop" in the half-second between Firebase restoring
/// their session and Firestore saying which shop they belong to. [loading]
/// stays true across both.
///
/// **An invite is claimed on sign-in.** A shop owner invites staff by email
/// before that person has an account, so there is no uid to grant anything to.
/// The invite waits under the shop, keyed by email; the first time that person
/// signs in, [_resolveShop] finds it and writes their membership. That is the
/// only moment a uid and the invited email both exist.
///
/// This class keeps a **local mode** for tests and for a device that cannot
/// reach Firebase: constructed without a [FirebaseAuth], [signInLocally] works
/// exactly as it did before there was a backend, so every role rule can still
/// be walked offline.
enum Role { admin, staff }

class ShopUser {
  const ShopUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  final String uid;
  final String email;
  final String name;
  final Role role;

  bool get isAdmin => role == Role.admin;

  /// For the avatar. Two letters at most, and never empty — a user whose
  /// profile has no name still has an email.
  String get initials {
    final source = name.trim().isNotEmpty ? name.trim() : email;
    final parts = source
        .split(RegExp(r'[\s@._+-]+'))
        .where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.elementAt(1).substring(0, 1))
        .toUpperCase();
  }
}

/// Why a sign-in or sign-up was refused, in the shop's words rather than
/// Firebase's.
///
/// Anything not in this map falls through to [humanAuthMessage], which never
/// shows Firebase's own text. On a real device an unmapped failure came back
/// with `message` set to
/// `dev.flutter.pigeon.firebase_auth_platform_interface...` — a plugin channel
/// name, printed in red to a shop owner. Firebase's `message` is written for
/// whoever wrote the plugin, and is not safe to show to anybody else.
const Map<String, String> kAuthMessages = {
  'invalid-email': 'That is not an email address',
  'user-disabled': 'That account has been disabled',
  'user-not-found': 'No account with that email — sign up instead',
  'wrong-password': 'Wrong password',
  'invalid-credential': 'That email and password do not match an account',
  'email-already-in-use': 'There is already an account with that email',
  'weak-password': 'That password is too short — use at least six characters',
  'network-request-failed':
      'Could not reach the server. Check the shop\'s internet.',
  'too-many-requests': 'Too many attempts. Wait a minute and try again.',
  'missing-email': 'Enter your email',
  'missing-password': 'Enter your password',
  'internal-error': 'Something went wrong. Check the email and password.',
  'channel-error': 'Fill in every field',
  'operation-not-allowed': 'Email sign-in is not switched on for this app yet',
};

/// What to show for a Firebase code this app does not know.
///
/// Deliberately never `e.message`: see the note above [kAuthMessages]. The
/// code is appended in small print because it is the only thing that makes a
/// support conversation possible, but the sentence in front of it is the
/// part a shop owner needs.
String humanAuthMessage(String code, {required bool signingUp}) {
  final action = signingUp ? 'create the account' : 'sign in';
  return 'Could not $action. Check the email and password, then try again. '
      '($code)';
}

class AuthState extends ChangeNotifier {
  AuthState({this.auth, this.firestore}) {
    final a = auth;
    if (a != null) {
      // Starts true: the session may be restoring, and bouncing somebody to
      // the login screen in that window throws out a user who is in fact
      // signed in.
      _loading = true;
      _subscription = a.authStateChanges().listen(_onAuthChanged);
    }
  }

  /// Null in local mode — see the class note.
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  ShopUser? _user;
  String? _shopId;
  String? _shopName;
  bool _loading = false;
  String? _error;
  StreamSubscription<User?>? _subscription;

  ShopUser? get user => _user;
  bool get loading => _loading;
  bool get signedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Null when this person has an account but no shop yet. The router sends
  /// them to create one.
  String? get shopId => _shopId;
  String? get shopName => _shopName;

  /// Signed in, and we know which shop. The only state in which the app's
  /// screens have anything to show.
  bool get hasShop => signedIn && (_shopId ?? '').isNotEmpty;

  /// The last sign-in or sign-up failure, in the shop's words.
  String? get error => _error;

  /// True when there is no Firebase behind this — tests, and a device that
  /// could not reach it at startup.
  bool get isLocal => auth == null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _shopId = null;
      _shopName = null;
      _loading = false;
      notifyListeners();
      return;
    }

    // Still loading: we have an account but not yet a shop, and the router
    // must not act on half the answer.
    _loading = true;
    notifyListeners();

    await _resolveShop(firebaseUser);

    _loading = false;
    notifyListeners();
  }

  /// Find which shop this person belongs to, claiming an invite if one is
  /// waiting for their email.
  Future<void> _resolveShop(User firebaseUser) async {
    final db = firestore;
    if (db == null) {
      _user = _localUser(
        firebaseUser.email ?? '',
        Role.admin,
        firebaseUser.uid,
      );
      return;
    }

    try {
      final profile = await userDoc(db, firebaseUser.uid).get();
      final storedShopId = (profile.data()?['shopId'] ?? '').toString();

      if (storedShopId.isNotEmpty) {
        await _loadMembership(db, firebaseUser, storedShopId);
        return;
      }

      // No shop yet. An invite may be waiting under the email they signed up
      // with — this is the first moment a uid exists to grant it to.
      final claimed = await _claimInvite(db, firebaseUser);
      if (!claimed) {
        // An account with no shop. Real, and the router sends them to create
        // one rather than to an empty dashboard.
        _user = ShopUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          role: Role.admin,
        );
        _shopId = null;
        _shopName = null;
      }
    } catch (e) {
      // Signed in but we cannot read the membership. Treated as "no shop"
      // rather than as admin of something: guessing upwards here would hand
      // somebody access to a shop on a failed read.
      _error = 'Could not read your shop: $e';
      _user = ShopUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        role: Role.staff,
      );
      _shopId = null;
    }
  }

  Future<void> _loadMembership(
    FirebaseFirestore db,
    User firebaseUser,
    String shopId,
  ) async {
    final scope = ShopScope(shopId: shopId, firestore: db);
    final memberDoc = await scope.members.doc(firebaseUser.uid).get();
    final member = memberDoc.exists
        ? ShopMember.fromMap(firebaseUser.uid, memberDoc.data()!)
        : null;

    // A profile that points at a shop they are not a member of is a stale
    // pointer — somebody removed them. Treated as having no shop.
    if (member == null) {
      _shopId = null;
      _shopName = null;
      _user = ShopUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        role: Role.staff,
      );
      return;
    }

    final shopDoc = await scope.shop.get();
    _shopId = shopId;
    _shopName = (shopDoc.data()?['name'] ?? '').toString();
    _user = ShopUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? member.email,
      name: member.name.isNotEmpty
          ? member.name
          : (firebaseUser.displayName ?? ''),
      role: member.isAdmin ? Role.admin : Role.staff,
    );
  }

  /// Claim an invite waiting for this person's email, if there is one.
  ///
  /// Returns whether a shop was joined.
  Future<bool> _claimInvite(FirebaseFirestore db, User firebaseUser) async {
    final email = normalizeEmail(firebaseUser.email);
    if (email.isEmpty) return false;

    // Found at a path computed from their own email. Searching the shops
    // collection is not an option for somebody who may read none of it.
    final pending = await pendingInvite(db, email).get();
    if (!pending.exists) return false;

    final invite = ShopInvite.fromMap(email, pending.data()!);
    if (invite.shopId.isEmpty) return false;

    final scope = ShopScope(shopId: invite.shopId, firestore: db);
    final member = ShopMember(
      uid: firebaseUser.uid,
      role: invite.role,
      email: email,
      name: firebaseUser.displayName ?? '',
      addedAt: DateTime.now(),
    );

    await scope.members.doc(firebaseUser.uid).set(member.toMap());
    await userDoc(db, firebaseUser.uid).set({
      'shopId': invite.shopId,
      'email': email,
      'joinedAt': DateTime.now().toIso8601String(),
    });
    // Both copies have done their job. Left in place, the pointer would be
    // claimed again by anybody who later signed up with the same address.
    await pending.reference.delete();
    await scope.invite(email).delete();

    await _loadMembership(db, firebaseUser, invite.shopId);
    return true;
  }

  /// Create an account. The person then creates their shop.
  Future<bool> signUp({
    required String email,
    required String password,
    String name = '',
  }) async {
    final a = auth;
    if (a == null) return false;
    // Checked here rather than left to Firebase: the code it returns for an
    // empty field is the least useful one it has.
    final blank = _blankFieldMessage(email, password);
    if (blank != null) {
      _error = blank;
      notifyListeners();
      return false;
    }
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final credential = await a.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
      }
      // authStateChanges fires and resolves the shop; nothing more here.
      return true;
    } on FirebaseAuthException catch (e) {
      _error =
          kAuthMessages[e.code] ?? humanAuthMessage(e.code, signingUp: true);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final a = auth;
    if (a == null) return false;
    final blank = _blankFieldMessage(email, password);
    if (blank != null) {
      _error = blank;
      notifyListeners();
      return false;
    }
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      await a.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error =
          kAuthMessages[e.code] ?? humanAuthMessage(e.code, signingUp: false);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await auth?.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    final a = auth;
    if (a != null) {
      await a.signOut();
      return;
    }
    _user = null;
    _shopId = null;
    _shopName = null;
    notifyListeners();
  }

  /// The shop's name changed in Settings: show the new one everywhere at once.
  void renameShop(String name) {
    if (_shopName == name) return;
    _shopName = name;
    notifyListeners();
  }

  /// Called once a shop has been created, so the router can move on without
  /// waiting for another round trip.
  void attachShop({required String shopId, required String shopName}) {
    _shopId = shopId;
    _shopName = shopName;
    final current = _user;
    if (current != null) {
      // Whoever created the shop is its admin by definition.
      _user = ShopUser(
        uid: current.uid,
        email: current.email,
        name: current.name,
        role: Role.admin,
      );
    }
    notifyListeners();
  }

  static String? _blankFieldMessage(String email, String password) {
    if (email.trim().isEmpty && password.isEmpty) return 'Fill in every field';
    if (email.trim().isEmpty) return 'Enter your email';
    if (password.isEmpty) return 'Enter your password';
    return null;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// LOCAL MODE — no Firebase behind it.
  ///
  /// Used by the widget tests, and by a device that could not reach Firebase
  /// at startup, so every role rule can still be walked. It grants a shop id
  /// too, because otherwise the router would send a local session to the
  /// create-a-shop screen forever.
  Future<void> signInLocally({
    required String email,
    required Role role,
    String shopId = 'local-shop',
  }) async {
    _loading = true;
    notifyListeners();
    _user = _localUser(email, role, 'local-${role.name}');
    _shopId = shopId;
    _shopName = 'Local shop';
    _loading = false;
    notifyListeners();
  }

  ShopUser _localUser(String email, Role role, String uid) => ShopUser(
    uid: uid,
    email: email,
    name: email.split('@').first,
    role: role,
  );
}
