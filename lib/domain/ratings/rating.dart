/// RATINGS — "HOW DID WE DO?" ON A FINISHED JOB
///
/// FLOW §10: a public token link per finished job, and the admin reads the
/// results. The customer who rates has no account and never will, so
/// everything here is shaped by one fact: **the link is the only key**.
///
/// The rules, each held down by a test in `test/domain/rating_test.dart`:
///
/// - **Only a finished job is asked.** Completed or Returned. Asking about a
///   phone still on the bench invites a one-star "it's not ready" that is a
///   complaint about the date, not the work.
/// - **One link per job.** Asking twice gives the same link back, so a
///   customer messaged twice cannot leave two ratings and the average cannot
///   be padded by asking the happy ones again.
/// - **The token is unguessable.** 128 random bits. The token is the
///   document id and the rules only allow `get` by id — never `list` — so a
///   stranger cannot walk the collection or guess their way to someone
///   else's job.
/// - **A rating is answered once.** The first answer stands. A link forwarded
///   to a friend, or opened again a week later, shows the answer that was
///   given rather than letting it be rewritten.
/// - **Stars are 1–5 and a comment is short.** Checked here and in
///   `firestore.rules`, because the page that writes it is public.
/// - **The public copy carries no private data.** Shop name, device, the
///   customer's first name and the job number — what is printed on the job
///   card in their hand already. No phone number, no price, no IMEI, no
///   technician.
/// - **The average counts answers only.** A link that was sent and never
///   opened is not a zero-star rating.
library;

import 'dart:math';

import '../common/dates.dart';
import '../service/order_state.dart';
import '../service/service_order.dart';

/// Longest comment accepted. Matched by `firestore.rules`.
const int kRatingCommentMax = 500;

/// A rating request, and — once the customer has answered — the rating.
class Rating {
  const Rating({
    required this.token,
    required this.shopId,
    required this.orderId,
    this.orderNumber = '',
    this.shopName = '',
    this.device = '',
    this.customerFirstName = '',
    this.createdAt,
    this.stars,
    this.comment = '',
    this.ratedAt,
  });

  /// The unguessable id in the link, and the document id.
  final String token;
  final String shopId;
  final String orderId;
  final String orderNumber;
  final String shopName;
  final String device;

  /// First name only: the page is public.
  final String customerFirstName;
  final DateTime? createdAt;

  /// Null until answered.
  final int? stars;
  final String comment;
  final DateTime? ratedAt;

  bool get answered => stars != null;

  factory Rating.fromMap(String token, Map<String, dynamic> m) {
    final rawStars = m['stars'];
    final stars = rawStars is num ? rawStars.toInt() : null;
    return Rating(
      token: token,
      shopId: (m['shopId'] ?? '').toString(),
      orderId: (m['orderId'] ?? '').toString(),
      orderNumber: (m['orderNumber'] ?? '').toString(),
      shopName: (m['shopName'] ?? '').toString(),
      device: (m['device'] ?? '').toString(),
      customerFirstName: (m['customerFirstName'] ?? '').toString(),
      createdAt: normalizeDate(m['createdAt']),
      // A value outside 1–5 can only come from a bad write; it is shown as
      // unanswered rather than dragging the average somewhere impossible.
      stars: stars != null && stars >= 1 && stars <= 5 ? stars : null,
      comment: (m['comment'] ?? '').toString(),
      ratedAt: normalizeDate(m['ratedAt']),
    );
  }

  /// What the shop writes when it asks. The answer fields start empty.
  Map<String, dynamic> toRequestMap() => {
    'shopId': shopId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'shopName': shopName,
    'device': device,
    'customerFirstName': customerFirstName,
    'createdAt': createdAt?.toIso8601String(),
    'stars': null,
    'comment': '',
    'ratedAt': null,
  };

  Rating answeredWith(int stars, String comment, DateTime at) => Rating(
    token: token,
    shopId: shopId,
    orderId: orderId,
    orderNumber: orderNumber,
    shopName: shopName,
    device: device,
    customerFirstName: customerFirstName,
    createdAt: createdAt,
    stars: stars,
    comment: comment,
    ratedAt: at,
  );
}

/// Whether this job may be asked for a rating.
bool canRequestRating(ServiceOrder order) => isClosed(order.status);

/// 128 random bits, URL-safe, 22 characters.
String newRatingToken([Random? random]) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final r = random ?? Random.secure();
  // 22 characters of a 64-letter alphabet is 132 bits.
  return List.generate(22, (_) => alphabet[r.nextInt(64)]).join();
}

/// First word of a name, for the public page. "Ravi Kumar" -> "Ravi".
String firstNameOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '';
  return t.split(RegExp(r'\s+')).first;
}

/// The request the shop writes for [order].
Rating ratingRequestFor({
  required ServiceOrder order,
  required String shopId,
  required String shopName,
  required DateTime now,
  String? token,
}) => Rating(
  token: token ?? newRatingToken(),
  shopId: shopId,
  orderId: order.id,
  orderNumber: order.orderNumber,
  shopName: shopName,
  device: [
    order.brand,
    order.model,
  ].where((s) => s.trim().isNotEmpty).join(' '),
  customerFirstName: firstNameOf(order.customerName),
  createdAt: now,
);

/// The site path of a rating link.
String ratingPath(String token) => '/rate/$token';

/// The full link, when the shop has said where its public pages live.
///
/// Null without a base: a link the customer cannot open is worse than none,
/// and the page that shares it says what to set instead.
Uri? ratingLink(String? publicBase, String token) {
  final base = (publicBase ?? '').trim();
  if (base.isEmpty) return null;
  final parsed = Uri.tryParse(base.endsWith('/') ? base : '$base/');
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) return null;
  return parsed.resolve('rate/$token');
}

/// The WhatsApp message that carries the link.
String ratingMessage({
  required String shopName,
  required String firstName,
  required String device,
  required Uri link,
}) {
  final hello = firstName.isEmpty ? 'Hello' : 'Hello $firstName';
  final shop = shopName.isEmpty ? 'us' : shopName;
  final what = device.isEmpty ? 'your phone' : 'your $device';
  return '$hello, thank you for trusting $shop with $what. '
      'How did we do? It takes ten seconds: $link';
}

/// Why an answer was refused.
enum RatingRefusal { noStars, badStars, commentTooLong, alreadyAnswered }

/// Checks an answer before it is written. Null means it may be saved.
RatingRefusal? validateAnswer(Rating current, int? stars, String comment) {
  if (current.answered) return RatingRefusal.alreadyAnswered;
  if (stars == null) return RatingRefusal.noStars;
  if (stars < 1 || stars > 5) return RatingRefusal.badStars;
  if (comment.trim().length > kRatingCommentMax) {
    return RatingRefusal.commentTooLong;
  }
  return null;
}

/// What the admin page shows at the top.
class RatingSummary {
  const RatingSummary({
    required this.sent,
    required this.answered,
    required this.average,
    required this.byStars,
  });

  final int sent;
  final int answered;

  /// Over answered ratings only; null when nobody has answered.
  final double? average;

  /// Count per star, index 0 = one star.
  final List<int> byStars;

  /// Share of links that got an answer, 0–1; null when none were sent.
  double? get responseRate => sent == 0 ? null : answered / sent;
}

RatingSummary summarize(Iterable<Rating> ratings) {
  var sent = 0;
  var total = 0;
  final byStars = List.filled(5, 0);
  for (final r in ratings) {
    sent++;
    final s = r.stars;
    if (s == null) continue;
    byStars[s - 1]++;
    total += s;
  }
  final answered = byStars.fold(0, (a, b) => a + b);
  return RatingSummary(
    sent: sent,
    answered: answered,
    average: answered == 0 ? null : total / answered,
    byStars: byStars,
  );
}

/// Newest answers first, then requests still waiting, newest first.
List<Rating> sortedForAdmin(Iterable<Rating> ratings) {
  int byTime(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));
  final answered = ratings.where((r) => r.answered).toList()
    ..sort((a, b) => byTime(a.ratedAt, b.ratedAt));
  final waiting = ratings.where((r) => !r.answered).toList()
    ..sort((a, b) => byTime(a.createdAt, b.createdAt));
  return [...answered, ...waiting];
}
