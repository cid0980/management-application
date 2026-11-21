import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/labels/label_target.dart';

SecondHandDevice _device(String id, {num asking = 18500, int? label}) =>
    SecondHandDevice(
      id: id,
      brand: 'Samsung',
      model: 'Galaxy A54',
      imei: '354879104523681',
      grade: 'A',
      askingPrice: asking,
      labelNumber: label,
    );

class _Fixture {
  _Fixture({List<SecondHandDevice>? devices, List<LabelEntry>? seed})
      : stock = InMemorySecondHandStore(seed: devices ?? [_device('sh-1')]) {
    labels = InMemoryLabelStore(
      seed: seed,
      counter: InMemoryCounter(),
      targets: {
        LabelTargetKind.secondHand: LabelTargetBinding(
          snapshot: stock.labelSnapshot,
          attach: (id, number) => stock.attachLabel(id, number),
        ),
        // Products are still a placeholder: no binding on purpose.
      },
    );
  }

  final InMemorySecondHandStore stock;
  late final InMemoryLabelStore labels;

  void dispose() {
    labels.dispose();
    stock.dispose();
  }
}

void main() {
  group('this is the only thing that mints a label number', () {
    test('and minting and attaching are one operation', () async {
      final f = _Fixture();
      addTearDown(f.dispose);

      final result =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      expect(result.ok, isTrue);
      expect(result.entry!.number, kFirstLabelNumber);
      // Both sides, from one call: the registry entry and the number on the
      // record. Two calls is how one of them gets forgotten.
      expect(f.labels.byNumber(26001), isNotNull);
      expect(f.stock.byId('sh-1')!.labelNumber, 26001);
    });

    test('labels start at 26001 — below that are hand-written ones', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      expect(f.labels.nextNumber, 26001);
      expect((await f.labels.assign(LabelTargetKind.secondHand, 'sh-1'))
          .entry!.number, 26001);
    });

    test('numbers never repeat', () async {
      final f = _Fixture(
        devices: [for (var i = 0; i < 25; i++) _device('sh-$i')],
      );
      addTearDown(f.dispose);
      final numbers = <int>{};
      for (var i = 0; i < 25; i++) {
        final r = await f.labels.assign(LabelTargetKind.secondHand, 'sh-$i');
        numbers.add(r.entry!.number);
      }
      expect(numbers, hasLength(25));
      expect(numbers.reduce((a, b) => a < b ? a : b), 26001);
      expect(numbers.reduce((a, b) => a > b ? a : b), 26025);
    });

    test('a seeded registry leaves the counter above what is already printed',
        () async {
      // Otherwise the next assign hands out a number already stuck to a phone.
      final f = _Fixture(seed: [
        LabelEntry(
          number: 26500,
          kind: LabelTargetKind.secondHand,
          recordId: 'old',
        ),
      ]);
      addTearDown(f.dispose);
      expect(f.labels.nextNumber, 26501);
      expect((await f.labels.assign(LabelTargetKind.secondHand, 'sh-1'))
          .entry!.number, 26501);
    });
  });

  group('reading the next number does not take it', () {
    test('a page that burns a number on open leaves gaps nobody can account '
        'for', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      expect(f.labels.nextNumber, 26001);
      expect(f.labels.nextNumber, 26001);
      expect(f.labels.nextNumber, 26001);
      await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      expect(f.labels.nextNumber, 26002);
    });
  });

  group('one record, one label', () {
    test('assigning again keeps the number it has', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final first =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      final second =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');

      expect(second.alreadyLabelled, isTrue);
      expect(second.entry!.number, first.entry!.number);
      // And no second number was consumed.
      expect(f.labels.nextNumber, 26002);
      expect(f.labels.entries, hasLength(1));
    });

    test('a record that already carries a number keeps it on attach',
        () async {
      final f = _Fixture(devices: [_device('sh-1', label: 26005)]);
      addTearDown(f.dispose);
      final result =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      // The registry had no entry, so it minted and attached — and the record
      // refused to change the number it already had. The registry's entry is
      // the new one; the mismatch is visible rather than silent.
      expect(result.ok, isTrue);
      expect(f.stock.byId('sh-1')!.labelNumber, 26005);
    });
  });

  group('a reprint keeps the number', () {
    test('because the first sticker may still be on something', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final assigned =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      final reprinted = await f.labels.markReprinted(assigned.entry!.number);

      expect(reprinted.number, assigned.entry!.number);
      expect(reprinted.reprints, 1);
      expect((await f.labels.markReprinted(reprinted.number)).reprints, 2);
    });

    test('and does not refresh the printed copy', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final assigned =
          await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');

      // The price changes, then the sticker is printed again.
      await f.stock.save(f.stock.byId('sh-1')!.copyWith(askingPrice: 16900));
      final reprinted = await f.labels.markReprinted(assigned.entry!.number);

      // The copy still records what was printed the first time...
      expect(reprinted.snapshot[kLabelPrice], 18500);
      // ...and the overlay is what shows the current price.
      final view = f.labels.resolve(reprinted.number)!;
      expect(view.price, 16900);
      expect(view.staleFields, contains(kLabelPrice));
    });

    test('reprinting a number nobody printed is said so', () {
      final f = _Fixture();
      addTearDown(f.dispose);
      expect(() => f.labels.markReprinted(99999),
          throwsA(isA<NoSuchLabel>()));
    });
  });

  group('the snapshot, and the overlay over it', () {
    test('what was printed is kept as it was', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final entry =
          (await f.labels.assign(LabelTargetKind.secondHand, 'sh-1')).entry!;
      expect(entry.snapshot[kLabelTitle], 'Samsung Galaxy A54');
      expect(entry.snapshot[kLabelPrice], 18500);
      expect(entry.snapshot[kLabelStatus], 'In stock');
      expect(entry.printedAt, isNotNull);
    });

    test('a price corrected since printing shows correctly on a scan',
        () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final entry =
          (await f.labels.assign(LabelTargetKind.secondHand, 'sh-1')).entry!;
      await f.stock.save(f.stock.byId('sh-1')!.copyWith(askingPrice: 16900));

      final view = f.labels.resolve(entry.number)!;
      expect(view.price, 16900);
      expect(view.isStale, isTrue);
      expect(view.canOpen, isTrue);
      expect(view.route, '/inventory/second-hand/sh-1');
    });

    test('a status changed since printing is flagged too', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final entry =
          (await f.labels.assign(LabelTargetKind.secondHand, 'sh-1')).entry!;
      await f.stock.markSold('sh-1', soldPrice: 18000);

      final view = f.labels.resolve(entry.number)!;
      expect(view.status, 'Sold');
      expect(view.staleFields, contains(kLabelStatus));
    });

    test('a scan of a number nobody printed resolves to nothing', () {
      final f = _Fixture();
      addTearDown(f.dispose);
      expect(f.labels.resolve(26099), isNull);
    });
  });

  group('an area with no binding', () {
    test('says so rather than throwing', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final result = await f.labels.assign(LabelTargetKind.product, 'p-1');
      expect(result.ok, isFalse);
      expect(result.error, contains('cannot carry a label yet'));
      // And no number was consumed.
      expect(f.labels.nextNumber, 26001);
    });
  });

  test('a label for a record that is gone cannot be assigned', () async {
    final f = _Fixture(devices: []);
    addTearDown(f.dispose);
    final result = await f.labels.assign(LabelTargetKind.secondHand, 'nope');
    expect(result.ok, isFalse);
    expect(result.error, contains('gone'));
    expect(f.labels.nextNumber, 26001);
  });

  test('forRecord finds the label already on a record', () async {
    final f = _Fixture();
    addTearDown(f.dispose);
    expect(f.labels.forRecord(LabelTargetKind.secondHand, 'sh-1'), isNull);
    await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
    expect(f.labels.forRecord(LabelTargetKind.secondHand, 'sh-1')!.number,
        26001);
    // Same id, different kind, is a different label.
    expect(f.labels.forRecord(LabelTargetKind.service, 'sh-1'), isNull);
  });

  test('a change notifies, so the registry page redraws', () async {
    final f = _Fixture();
    addTearDown(f.dispose);
    var notified = 0;
    f.labels.addListener(() => notified++);
    await f.labels.assign(LabelTargetKind.secondHand, 'sh-1');
    await f.labels.markReprinted(26001);
    // A refused assign changed nothing, so it notifies nobody.
    await f.labels.assign(LabelTargetKind.product, 'p-1');
    expect(notified, 2);
  });
}
