/// RATINGS, OUT OF FIRESTORE
///
/// `ratings/{token}`, top-level — see `kRatings` for why. The shop's side
/// listens to its own through `ShopScope.ratings`; the customer's side reads
/// and answers exactly one document by its token.
///
/// **One link per job.** Asking checks this shop's ratings for the order
/// first, both the list already loaded and a fresh query, so a second tap or
/// a second till gets the same link back.
///
/// **The answer is written once, by the server's clock.** The read and the
/// write are one transaction, and `firestore.rules` refuses a second answer
/// even from a client that skips this code.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/ratings/rating.dart';
import '../domain/service/service_order.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'rating_repository.dart';

class FirestoreRatingStore extends ChangeNotifier implements RatingRepository {
  FirestoreRatingStore({required this.scope});

  final ShopScope scope;

  List<Rating> _ratings = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  List<Rating> get ratings => List.unmodifiable(_ratings);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _subscription = scope.ratings.snapshots().listen(
      (snapshot) {
        _ratings = [
          for (final doc in snapshot.docs) Rating.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'ratings');
        notifyListeners();
      },
    );
  }

  @override
  Rating? forOrder(String orderId) {
    for (final r in _ratings) {
      if (r.orderId == orderId) return r;
    }
    return null;
  }

  @override
  Future<Rating> requestFor(
    ServiceOrder order, {
    required String shopName,
  }) async {
    if (!canRequestRating(order)) throw RatingNotAllowed(order.status);
    final loaded = forOrder(order.id);
    if (loaded != null) return loaded;
    final existing = await scope.ratings
        .where('orderId', isEqualTo: order.id)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final d = existing.docs.first;
      return Rating.fromMap(d.id, d.data());
    }
    final request = ratingRequestFor(
      order: order,
      shopId: scope.shopId,
      shopName: shopName,
      now: DateTime.now(),
    );
    await localWrite(scope.rating(request.token).set(request.toRequestMap()));
    return request;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class FirestorePublicRatings implements PublicRatings {
  FirestorePublicRatings({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Future<Rating?> fetch(String token) async {
    final snap = await publicRating(firestore, token).get();
    final data = snap.data();
    return data == null ? null : Rating.fromMap(snap.id, data);
  }

  @override
  Future<RatingRefusal?> answer(String token, int? stars, String comment) {
    final ref = publicRating(firestore, token);
    return firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) return RatingRefusal.alreadyAnswered;
      final refusal = validateAnswer(
        Rating.fromMap(snap.id, data),
        stars,
        comment,
      );
      if (refusal != null) return refusal;
      tx.update(ref, {
        'stars': stars,
        'comment': comment.trim(),
        'ratedAt': FieldValue.serverTimestamp(),
      });
      return null;
    });
  }
}
