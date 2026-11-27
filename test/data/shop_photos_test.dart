import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/shop_photos.dart';
import 'package:fm_shop/l10n/rule_messages.dart';

void main() {
  test('the month a photo counts in is UTC, as the rules see it', () {
    // 31 Dec, 11:30 PM in India is still December in UTC... and 1 Jan,
    // 2:00 AM in India is still 31 Dec in UTC.
    expect(photoMonthKey(DateTime.utc(2026, 11, 26, 6)), '202611');
    expect(
      photoMonthKey(DateTime.parse('2027-01-01T02:00:00+05:30')),
      '202612',
    );
    expect(photoMonthKey(DateTime.utc(2027, 1, 5)), '202701');
  });

  test('the next number, and none past the limit', () {
    expect(nextPhotoSlot(0, 500), 1);
    expect(nextPhotoSlot(41, 500), 42);
    expect(nextPhotoSlot(499, 500), 500);
    expect(nextPhotoSlot(500, 500), isNull);
    expect(nextPhotoSlot(900, 500), isNull);
  });

  test('a photo is shrunk towards the target size', () async {
    final big = Uint8List(500 * 1024);
    final calls = <(int, int)>[];
    final fitted = await shrinkToFit(
      big,
      compress: (b, q, w) async {
        calls.add((q, w));
        // Reaches the target at the third try.
        return Uint8List(calls.length < 3 ? 200 * 1024 : 110 * 1024);
      },
    );
    expect(fitted!.length, 110 * 1024);
    expect(calls, [(70, 1024), (60, 1024), (55, 900)]);
  });

  test('a photo already at the target is kept as it is', () async {
    final small = Uint8List(kTargetPhotoBytes);
    expect(
      await shrinkToFit(small, compress: (_, _, _) => throw 'not called'),
      same(small),
    );
  });

  test(
    'missing the target, the smallest try under the limit is used',
    () async {
      final sizes = [260, 240, 180, 150, 170];
      var i = 0;
      final fitted = await shrinkToFit(
        Uint8List(500 * 1024),
        compress: (_, _, _) async => Uint8List(sizes[i++] * 1024),
      );
      expect(fitted!.length, 150 * 1024);
    },
  );

  test('a photo that cannot get under the limit is refused', () async {
    expect(
      await shrinkToFit(
        Uint8List(500 * 1024),
        compress: (_, _, _) async => Uint8List(kMaxPhotoBytes + 1),
      ),
      isNull,
    );
  });

  test('only shop photos show; links and placeholders do not', () {
    expect(isShopPhoto('https://example.com/a.jpg'), isFalse);
    expect(isShopPhoto('fs://shops/s1/photos/202611/3.jpg'), isTrue);
    expect(isShopPhoto('photo://taken'), isFalse);
    expect(isShopPhoto(''), isFalse);
  });

  test('the limit message is in Tamil and Hindi', () {
    expect(ruleTextIn('ta', kErrPhotoLimit), isNot(kErrPhotoLimit));
    expect(ruleTextIn('hi', kErrPhotoLimit), isNot(kErrPhotoLimit));
  });
}
