import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/ratings/rating.dart';
import 'package:fm_shop/domain/service/service_order.dart';

ServiceOrder _order({
  String status = 'Completed',
  String name = 'Ravi Kumar',
}) => ServiceOrder(
  id: 'o1',
  orderNumber: 'SO-20261121-004',
  customerName: name,
  customerPhone: '9876543210',
  brand: 'Apple',
  model: 'iPhone 11',
  imei: '356789012345678',
  status: status,
  estimatedPrice: 2500,
);

Rating _request() => ratingRequestFor(
  order: _order(),
  shopId: 'shop1',
  shopName: 'French Mobiles',
  now: DateTime(2026, 11, 21, 12),
  token: 'tok',
);

void main() {
  group('only a finished job is asked', () {
    test('Completed and Returned may be asked', () {
      expect(canRequestRating(_order(status: 'Completed')), isTrue);
      expect(canRequestRating(_order(status: 'Returned')), isTrue);
    });

    test('a phone still on the bench may not', () {
      for (final s in ['Received', 'In Progress', 'Parts Awaiting']) {
        expect(canRequestRating(_order(status: s)), isFalse, reason: s);
      }
    });
  });

  group('the token is unguessable', () {
    test('22 URL-safe characters', () {
      final t = newRatingToken();
      expect(t.length, 22);
      expect(RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(t), isTrue);
    });

    test('two tokens are not the same', () {
      final seen = {for (var i = 0; i < 1000; i++) newRatingToken()};
      expect(seen.length, 1000);
    });

    test(
      'a seeded generator is repeatable, so the alphabet is what is used',
      () {
        expect(newRatingToken(Random(1)), newRatingToken(Random(1)));
      },
    );
  });

  group('the public copy carries no private data', () {
    test('first name, device, job number and shop name only', () {
      final m = _request().toRequestMap();
      expect(m['customerFirstName'], 'Ravi');
      expect(m['device'], 'Apple iPhone 11');
      expect(m['orderNumber'], 'SO-20261121-004');
      expect(m['shopName'], 'French Mobiles');
      final all = m.values.map((v) => '$v').join(' ');
      expect(all, isNot(contains('9876543210')));
      expect(all, isNot(contains('356789012345678')));
      expect(all, isNot(contains('Kumar')));
      expect(all, isNot(contains('2500')));
    });

    test('a request starts unanswered', () {
      final r = Rating.fromMap('tok', _request().toRequestMap());
      expect(r.answered, isFalse);
      expect(r.stars, isNull);
    });

    test('a customer with no name gets a plain hello', () {
      expect(firstNameOf('   '), '');
      expect(
        ratingMessage(
          shopName: 'French Mobiles',
          firstName: '',
          device: '',
          link: Uri.parse('https://x.web.app/rate/tok'),
        ),
        startsWith(
          'Hello, thank you for trusting French Mobiles with your phone',
        ),
      );
    });
  });

  group('a rating is answered once, 1 to 5 stars, short comment', () {
    test('a good answer passes', () {
      expect(validateAnswer(_request(), 5, 'Quick and honest'), isNull);
    });

    test('no stars, or stars outside 1–5, are refused', () {
      expect(validateAnswer(_request(), null, ''), RatingRefusal.noStars);
      expect(validateAnswer(_request(), 0, ''), RatingRefusal.badStars);
      expect(validateAnswer(_request(), 6, ''), RatingRefusal.badStars);
    });

    test('a comment over the limit is refused', () {
      expect(
        validateAnswer(_request(), 4, 'x' * (kRatingCommentMax + 1)),
        RatingRefusal.commentTooLong,
      );
    });

    test('the first answer stands', () {
      final done = _request().answeredWith(5, '', DateTime(2026, 11, 22));
      expect(
        validateAnswer(done, 1, 'changed my mind'),
        RatingRefusal.alreadyAnswered,
      );
    });

    test('a stored value outside 1–5 reads as unanswered, not as a rating', () {
      final m = _request().toRequestMap()..['stars'] = 9;
      expect(Rating.fromMap('tok', m).answered, isFalse);
    });
  });

  group('the link', () {
    test('built from the shop\'s public address', () {
      expect(
        ratingLink('https://fm-shop.web.app', 'tok').toString(),
        'https://fm-shop.web.app/rate/tok',
      );
      expect(
        ratingLink('https://fm-shop.web.app/', 'tok').toString(),
        'https://fm-shop.web.app/rate/tok',
      );
    });

    test('no address, or not a web address, gives no link', () {
      expect(ratingLink(null, 'tok'), isNull);
      expect(ratingLink('  ', 'tok'), isNull);
      expect(ratingLink('fm-shop', 'tok'), isNull);
    });
  });

  group('the average counts answers only', () {
    test('unopened links are not zero stars', () {
      final r = _request();
      final s = summarize([
        r.answeredWith(5, '', DateTime(2026, 11, 22)),
        r.answeredWith(3, '', DateTime(2026, 11, 22)),
        r,
        r,
      ]);
      expect(s.sent, 4);
      expect(s.answered, 2);
      expect(s.average, 4.0);
      expect(s.responseRate, 0.5);
      expect(s.byStars, [0, 0, 1, 0, 1]);
    });

    test('nothing answered has no average, not zero', () {
      expect(summarize([_request()]).average, isNull);
      expect(summarize(const []).responseRate, isNull);
    });
  });

  test('admin list: newest answers first, then waiting requests', () {
    final base = _request();
    final old = base.answeredWith(4, '', DateTime(2026, 11, 1));
    final recent = base.answeredWith(2, '', DateTime(2026, 11, 20));
    final sorted = sortedForAdmin([base, old, recent]);
    expect(sorted.map((r) => r.stars), [2, 4, null]);
  });
}
