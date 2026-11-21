/// EVERY PATH INTO FIRESTORE, IN ONE PLACE
///
/// This app is sold to many shops. Shop 1 must never see Shop 2's stock,
/// customers, sales or takings — and the way that goes wrong is not a dramatic
/// bug, it is one repository that says `collection('customers')` instead of
/// going through the shop. That one line would read every shop's customers at
/// once, and nothing about it looks wrong on the page.
///
/// So no repository is allowed to name a collection. They are handed a
/// [ShopScope], and the only thing a scope can produce is a path **underneath
/// one shop's document**. There is no method here that returns a top-level
/// collection of shop data, which means the mistake cannot be typed.
///
/// The layout:
///
///     shops/{shopId}                       the shop itself
///     shops/{shopId}/members/{uid}         who works there, and their role
///     shops/{shopId}/invites/{email}       staff invited but not signed up yet
///     shops/{shopId}/second_hand_mobiles   …and every other area, the same
///     shops/{shopId}/counters/{name}       label and invoice numbers, per shop
///     shops/{shopId}/settings/options      that shop's own vocabulary
///     users/{uid}                          which shop a signed-in person is in
///
/// Counters are per shop on purpose. One counter across all shops would print
/// label 26001 in two different shops, and a scanned sticker would open
/// somebody else's handset.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level collections. There are exactly three, and none holds shop data.
const String kShopsCollection = 'shops';
const String kUsersCollection = 'users';

/// Pending invites, keyed by the invited email.
///
/// Top-level on purpose, and this is the only place in the app where that is
/// the right answer. Somebody invited to a shop has no account yet, so on
/// their first sign-in they know their own email and nothing else — not the
/// shop id, not anything they are allowed to read inside it. They need one
/// document at a path they can compute from their own address.
///
/// The rules let a signed-in user read exactly the one whose id is their own
/// email, so this leaks nothing: you can look up an invite addressed to you,
/// and no other.
///
/// The shop keeps its own copy under `shops/{shopId}/invites/{email}` so the
/// owner can see who is outstanding. The repository writes both, and deletes
/// both when an invite is claimed or withdrawn.
const String kPendingInvites = 'invites';

/// Customer ratings, keyed by an unguessable token.
///
/// The second top-level exception, for the same reason as invites: the
/// customer who answers has no account and no shop, only the link. A shop
/// reads its own through [ShopScope.ratings], which is a query filtered to
/// that shop — the rules refuse a list that is not.
const String kRatings = 'ratings';

/// The collection names under a shop, named once so a typo cannot quietly
/// create a second, empty collection.
const String kMembers = 'members';
const String kInvites = 'invites';
const String kSecondHand = 'second_hand_mobiles';
const String kCustomers = 'customers';
const String kProducts = 'products';
const String kServiceOrders = 'service_orders';
const String kSales = 'sales';
const String kEnquiries = 'enquiries';
const String kTasks = 'tasks';
const String kLabelRegistry = 'label_registry';
const String kCounters = 'counters';
const String kSettings = 'settings';

/// Sub-collections, one level further down.
///
/// A wallet move belongs to one customer and a stock movement to one product,
/// so they live under that record rather than in a shop-wide ledger that every
/// detail page would have to filter. Named here for the same reason as the
/// rest: a repository never spells a collection name itself.
const String kWalletMoves = 'wallet_moves';
const String kStockMovements = 'stock_movements';

/// The single settings document under a shop. One document rather than a
/// collection, because the shop's vocabulary is one thing that is read whole.
const String kSettingsDoc = 'options';

/// A handle on exactly one shop's data.
///
/// Everything a repository can reach goes through here, so a repository has no
/// way to ask for another shop — or for all of them.
class ShopScope {
  const ShopScope({required this.shopId, required this.firestore});

  final String shopId;
  final FirebaseFirestore firestore;

  /// The shop's own document.
  DocumentReference<Map<String, dynamic>> get shop =>
      firestore.collection(kShopsCollection).doc(shopId);

  /// One of this shop's collections.
  ///
  /// Private-by-construction: the only way to get a collection reference out
  /// of this class is as a child of [shop].
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      shop.collection(name);

  DocumentReference<Map<String, dynamic>> doc(
    String collectionName,
    String id,
  ) => collection(collectionName).doc(id);

  CollectionReference<Map<String, dynamic>> get members => collection(kMembers);
  CollectionReference<Map<String, dynamic>> get invites => collection(kInvites);
  CollectionReference<Map<String, dynamic>> get secondHand =>
      collection(kSecondHand);
  CollectionReference<Map<String, dynamic>> get customers =>
      collection(kCustomers);
  CollectionReference<Map<String, dynamic>> get products =>
      collection(kProducts);
  CollectionReference<Map<String, dynamic>> get serviceOrders =>
      collection(kServiceOrders);
  CollectionReference<Map<String, dynamic>> get sales => collection(kSales);
  CollectionReference<Map<String, dynamic>> get enquiries =>
      collection(kEnquiries);
  CollectionReference<Map<String, dynamic>> get tasks => collection(kTasks);
  CollectionReference<Map<String, dynamic>> get labelRegistry =>
      collection(kLabelRegistry);

  /// One customer's wallet history.
  CollectionReference<Map<String, dynamic>> walletMoves(String customerId) =>
      customers.doc(customerId).collection(kWalletMoves);

  /// One product's stock movements.
  CollectionReference<Map<String, dynamic>> stockMovements(String productId) =>
      products.doc(productId).collection(kStockMovements);

  /// This shop's ratings: the top-level collection, filtered to this shop.
  /// The filter is not optional — `firestore.rules` refuses a list without it.
  Query<Map<String, dynamic>> get ratings =>
      firestore.collection(kRatings).where('shopId', isEqualTo: shopId);

  /// One rating request, by token. Creating it is still checked by the rules
  /// against this shop.
  DocumentReference<Map<String, dynamic>> rating(String token) =>
      firestore.collection(kRatings).doc(token);

  /// This shop's own counters. See the library note on why they are not
  /// shared.
  DocumentReference<Map<String, dynamic>> counter(String name) =>
      doc(kCounters, name);

  /// This shop's vocabulary, checklist and print server.
  DocumentReference<Map<String, dynamic>> get settings =>
      doc(kSettings, kSettingsDoc);

  /// An invite is keyed by the email it was sent to, lower-cased.
  ///
  /// Keyed rather than queried because the person being invited has no account
  /// yet — there is no uid to key on, and a security rule has to be able to
  /// say "you may read the invite that matches your own email" by document id
  /// alone.
  DocumentReference<Map<String, dynamic>> invite(String email) =>
      invites.doc(normalizeEmail(email));

  @override
  String toString() => 'ShopScope($shopId)';
}

/// Where a signed-in person's shop membership is recorded.
///
/// Outside any shop, because it is read before we know which shop they are in
/// — that is the whole point of it.
DocumentReference<Map<String, dynamic>> userDoc(
  FirebaseFirestore firestore,
  String uid,
) => firestore.collection(kUsersCollection).doc(uid);

/// The invite a person can find from their own email alone, before they
/// belong to any shop.
DocumentReference<Map<String, dynamic>> pendingInvite(
  FirebaseFirestore firestore,
  String email,
) => firestore.collection(kPendingInvites).doc(normalizeEmail(email));

/// Emails are compared lower-cased and trimmed.
///
/// `Ramesh@Shop.com` and `ramesh@shop.com` are one person, and an invite that
/// did not match on case would leave somebody unable to get into the shop they
/// were invited to with no way to tell why.
String normalizeEmail(String? email) => (email ?? '').trim().toLowerCase();

/// One rating, by the token in its link — what the public page reads.
DocumentReference<Map<String, dynamic>> publicRating(
  FirebaseFirestore firestore,
  String token,
) => firestore.collection(kRatings).doc(token);
