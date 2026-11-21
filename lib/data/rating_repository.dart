/// WHERE RATINGS COME FROM
///
/// Two sides, because two different people use them:
///
/// - [RatingRepository] is the shop's: ask for a rating on a finished job,
///   and read the answers. Belongs to one shop, built and thrown away with it.
/// - [PublicRatings] is the customer's: open one rating by its token and
///   answer it. No account, no shop — it lives above the shop in the app.
///
/// The rules are in `domain/ratings/rating.dart`; both sides go through them,
/// and `firestore.rules` says the same again for anybody who skips the app.
library;

import 'package:flutter/foundation.dart';

import '../domain/ratings/rating.dart';
import '../domain/service/service_order.dart';

abstract class RatingRepository extends ChangeNotifier {
  /// This shop's ratings, answered and waiting.
  List<Rating> get ratings;
  bool get loading;
  String? get error;

  Future<void> load();

  /// The request already made for [orderId], if any.
  Rating? forOrder(String orderId);

  /// Ask for a rating on [order]. One link per job: asking again returns the
  /// request already made. Throws [RatingNotAllowed] for a job not finished.
  Future<Rating> requestFor(ServiceOrder order, {required String shopName});
}

/// The customer's side: one rating, by token.
abstract class PublicRatings {
  /// Null when there is no rating under [token].
  Future<Rating?> fetch(String token);

  /// Null when saved; otherwise why not.
  Future<RatingRefusal?> answer(String token, int? stars, String comment);
}

class RatingNotAllowed implements Exception {
  const RatingNotAllowed(this.status);
  final String status;
  @override
  String toString() =>
      'A job that is "$status" is not finished, so it '
      'cannot be rated yet.';
}

/// Both sides in memory, sharing one list — what the tests drive, and what
/// the app uses when there is no shop or no Firebase.
class InMemoryRatingStore extends ChangeNotifier
    implements RatingRepository, PublicRatings {
  InMemoryRatingStore({
    this.shopId = 'local',
    List<Rating>? seed,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _ratings = [...?seed];
  }

  final String shopId;
  final DateTime Function() _clock;

  /// The customer's side of this store, as a plain object. Provided on its
  /// own because `Provider` will not hand out a listenable as a plain value.
  late final PublicRatings public = _InMemoryPublic(this);
  late List<Rating> _ratings;

  @override
  List<Rating> get ratings =>
      List.unmodifiable(_ratings.where((r) => r.shopId == shopId));

  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  Future<void> load() async {}

  @override
  Rating? forOrder(String orderId) {
    for (final r in _ratings) {
      if (r.shopId == shopId && r.orderId == orderId) return r;
    }
    return null;
  }

  @override
  Future<Rating> requestFor(
    ServiceOrder order, {
    required String shopName,
  }) async {
    if (!canRequestRating(order)) throw RatingNotAllowed(order.status);
    final existing = forOrder(order.id);
    if (existing != null) return existing;
    final r = ratingRequestFor(
      order: order,
      shopId: shopId,
      shopName: shopName,
      now: _clock(),
    );
    _ratings = [..._ratings, r];
    notifyListeners();
    return r;
  }

  @override
  Future<Rating?> fetch(String token) async {
    for (final r in _ratings) {
      if (r.token == token) return r;
    }
    return null;
  }

  @override
  Future<RatingRefusal?> answer(
    String token,
    int? stars,
    String comment,
  ) async {
    final i = _ratings.indexWhere((r) => r.token == token);
    if (i < 0) return RatingRefusal.alreadyAnswered;
    final refusal = validateAnswer(_ratings[i], stars, comment);
    if (refusal != null) return refusal;
    _ratings = [..._ratings]
      ..[i] = _ratings[i].answeredWith(stars!, comment.trim(), _clock());
    notifyListeners();
    return null;
  }
}

class _InMemoryPublic implements PublicRatings {
  _InMemoryPublic(this._store);
  final InMemoryRatingStore _store;

  @override
  Future<Rating?> fetch(String token) => _store.fetch(token);

  @override
  Future<RatingRefusal?> answer(String token, int? stars, String comment) =>
      _store.answer(token, stars, comment);
}
