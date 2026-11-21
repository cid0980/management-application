import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

SecondHandDevice _d(String id, {String status = kAvailable, int? label}) =>
    SecondHandDevice(
      id: id,
      brand: 'Samsung',
      model: 'Galaxy A54',
      status: status,
      labelNumber: label,
      purchasePrice: 6000,
      askingPrice: 9000,
    );

void main() {
  group('saving', () {
    test('a new record is added, an existing one replaced', () async {
      final store = InMemorySecondHandStore(seed: []);
      await store.save(_d('a'));
      expect(store.devices, hasLength(1));
      await store.save(_d('a').copyWith(askingPrice: 9500));
      expect(store.devices, hasLength(1));
      expect(store.byId('a')!.askingPrice, 9500);
    });

    test('a save stamps updatedAt, which is how other tills learn', () async {
      final store = InMemorySecondHandStore(seed: []);
      final saved = await store.save(_d('a'));
      expect(saved.updatedAt, isNotNull);
    });

    test('an edit cannot put a sold handset back on the shelf', () async {
      final store = InMemorySecondHandStore(seed: [_d('a', status: kSold)]);
      final saved = await store.save(_d('a', status: kAvailable));
      expect(saved.status, kSold);
      expect(store.byId('a')!.isSold, isTrue);
    });

    test('neither can an edit send a sold handset to the bench', () async {
      final store = InMemorySecondHandStore(seed: [_d('a', status: kSold)]);
      final saved = await store.save(_d('a', status: kRepairing));
      expect(saved.status, kSold);
    });

    test('a finished repair saved as available returns to stock', () async {
      final store = InMemorySecondHandStore(seed: [_d('a', status: kRepairing)]);
      final saved = await store.save(_d('a', status: kAvailable));
      expect(saved.status, kAvailable);
    });
  });

  group('the bench', () {
    test('a handset goes on and comes off', () async {
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      expect((await store.setRepairing('a', repairing: true)).isBeingRepaired,
          isTrue);
      expect((await store.setRepairing('a', repairing: false)).isSellable,
          isTrue);
    });

    test('a sold handset is not in the shop to repair', () async {
      final store = InMemorySecondHandStore(seed: [_d('a', status: kSold)]);
      expect(
        () => store.setRepairing('a', repairing: true),
        throwsA(isA<SoldDeviceLocked>()),
      );
    });

    test('a device on the bench is out of the sale picker', () async {
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      await store.setRepairing('a', repairing: true);
      expect(store.byId('a')!.isSellable, isFalse);
    });
  });

  group('going out', () {
    test('marking sold records what it actually went for', () async {
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      final sold = await store.markSold('a', soldPrice: 8800);
      expect(sold.isSold, isTrue);
      expect(sold.soldPrice, 8800);
      expect(sold.soldAt, isNotNull);
      expect(sold.costing.realisedProfit, 2800);
    });

    test('a handset sold twice keeps the first date', () async {
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      final first = await store.markSold('a', soldPrice: 8800);
      final second = await store.markSold('a', soldPrice: 9000);
      expect(second.soldAt, first.soldAt);
      expect(second.soldPrice, 9000);
    });
  });

  group('labels', () {
    test('this store attaches a number, it does not choose one', () async {
      // It used to choose, with a counter of its own. Every area that prints
      // labels would then have had one — four counters over one number space,
      // and label 26042 on two different phones.
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      expect((await store.attachLabel('a', 26042)).labelNumber, 26042);
    });

    test('a device that already has a label keeps it', () async {
      final store = InMemorySecondHandStore(seed: [_d('a', label: 26005)]);
      expect((await store.attachLabel('a', 26099)).labelNumber, 26005);
    });

    test('the label snapshot carries what goes on the sticker', () {
      final store = InMemorySecondHandStore(seed: [_d('a')]);
      final snapshot = store.labelSnapshot('a')!;
      expect(snapshot[kLabelTitle], 'Samsung Galaxy A54');
      // The asking price, because that is what a sticker on a shelf is for.
      expect(snapshot[kLabelPrice], 9000);
      expect(snapshot[kLabelStatus], 'In stock');
    });

    test('no snapshot for a record that is gone', () {
      expect(InMemorySecondHandStore(seed: []).labelSnapshot('nope'), isNull);
    });

    test('a missing device is said so, not silently ignored', () {
      final store = InMemorySecondHandStore(seed: []);
      expect(() => store.attachLabel('nope', 1),
          throwsA(isA<NoSuchDevice>()));
      expect(() => store.markSold('nope', soldPrice: 1),
          throwsA(isA<NoSuchDevice>()));
    });
  });

  test('the seed holds the shapes that have gone wrong before', () {
    final store = InMemorySecondHandStore();
    expect(store.devices.any((d) => d.isBeingRepaired), isTrue,
        reason: 'one on the bench');
    expect(store.devices.any((d) => d.isSold), isTrue, reason: 'one sold');
    // The record written with a status this build has never heard of still
    // reads as stock, rather than vanishing from every tab.
    expect(store.byId('sh-4')!.isSellable, isTrue);
    expect(store.byId('sh-4')!.purchasePrice, 7500);
  });

  test('a change notifies, so the list redraws without being told', () async {
    final store = InMemorySecondHandStore(seed: [_d('a')]);
    var notified = 0;
    store.addListener(() => notified++);
    await store.save(_d('b'));
    await store.setRepairing('a', repairing: true);
    expect(notified, 2);
  });
}
