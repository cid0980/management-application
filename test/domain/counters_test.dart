import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/counters.dart';

void main() {
  group('a counter never hands out the same number twice', () {
    test('an absent counter starts at the start', () {
      expect(nextCounterValue(null), 1);
      expect(nextCounterValue(null, start: kFirstLabelNumber), 26001);
      expect(nextCounterValue('', start: 26001), 26001);
      expect(nextCounterValue('nonsense', start: 26001), 26001);
    });

    test('it increments from what it holds', () {
      expect(nextCounterValue(26001, start: 26001), 26002);
      expect(nextCounterValue('412'), 413);
      expect(nextCounterValue(412.0), 413);
    });

    test('it never goes backwards below the start', () {
      // Handing out 5 when 26001 labels have been printed is worse than
      // skipping numbers: a label is stuck to a phone and handed over.
      expect(nextCounterValue(4, start: 26001), 26001);
    });

    test('consecutive calls on one key are all different', () async {
      final counter = InMemoryCounter();
      final seen = <int>{};
      for (var i = 0; i < 50; i++) {
        seen.add(await counter.next('labels', start: 26001));
      }
      expect(seen, hasLength(50));
      expect(seen.first, 26001);
      expect(counter.peek('labels'), 26050);
    });

    test('different keys do not contend', () async {
      final counter = InMemoryCounter();
      expect(await counter.next('a'), 1);
      expect(await counter.next('b'), 1);
      expect(await counter.next('a'), 2);
    });
  });

  group('document numbers', () {
    test('an invoice is INV-YYYYMMDD-NNN', () {
      expect(invoiceNumber(DateTime(2026, 3, 4), 7), 'INV-20260304-007');
      expect(serviceOrderNumber(DateTime(2026, 12, 31), 42), 'SO-20261231-042');
    });

    test('a day past 999 keeps counting rather than wrapping', () {
      // A wrong number that is unique beats a tidy one that is not.
      expect(invoiceNumber(DateTime(2026, 3, 4), 1004), 'INV-20260304-1004');
    });

    test('the sequence resets per day without anyone resetting it', () {
      expect(dailyCounterKey('invoice', DateTime(2026, 3, 4)),
          'invoice-20260304');
      expect(
        dailyCounterKey('invoice', DateTime(2026, 3, 5)),
        isNot(dailyCounterKey('invoice', DateTime(2026, 3, 4))),
      );
    });

    test('a per-day counter starts over on the next day', () async {
      final counter = InMemoryCounter();
      final day1 = DateTime(2026, 3, 4);
      final day2 = DateTime(2026, 3, 5);
      expect(await counter.next(dailyCounterKey('invoice', day1)), 1);
      expect(await counter.next(dailyCounterKey('invoice', day1)), 2);
      expect(await counter.next(dailyCounterKey('invoice', day2)), 1);
    });
  });
}
