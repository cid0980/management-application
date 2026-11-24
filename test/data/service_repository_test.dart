import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/service/checklist.dart';
import 'package:fm_shop/domain/service/order_validation.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/domain/sales/sale.dart' show Collection;

const _checklist = ['Display OK', 'Charging tested'];

ServiceOrder _o(
  String id, {
  String status = 'In Progress',
  String orderNumber = '',
  Map<String, bool>? checklist,
  num? finalPrice,
}) => ServiceOrder(
  id: id,
  orderNumber: orderNumber,
  customerId: 'c-1',
  customerPhone: '9876543210',
  brand: 'Samsung',
  model: 'Galaxy M14',
  complaints: const ['Not charging'],
  status: status,
  finalPrice: finalPrice,
  checklist: checklist ?? const {},
  receivedAt: DateTime(2026, 3, 1),
  expectedCompletionAt: DateTime(2026, 3, 4),
);

InMemoryServiceStore _store({List<ServiceOrder>? seed}) => InMemoryServiceStore(
  seed: seed ?? [],
  checklist: _checklist,
  counter: InMemoryCounter(),
  today: DateTime(2026, 3, 4),
);

Map<String, bool> _allTicked() => {
  for (final e in checklistEntries(_checklist)) e.key: true,
};

void main() {
  group('the order number comes off a counter', () {
    test('assigned on first save, in the shop format', () async {
      final store = _store();
      expect((await store.save(_o('a'))).orderNumber, 'SO-20260304-001');
      expect((await store.save(_o('b'))).orderNumber, 'SO-20260304-002');
    });

    test('never reissued — an edit keeps the number it was given', () async {
      final store = _store();
      final first = await store.save(_o('a'));
      final again = await store.save(_o('a'));
      expect(again.orderNumber, first.orderNumber);
      // And the counter was not consumed again.
      expect((await store.save(_o('b'))).orderNumber, 'SO-20260304-002');
    });

    test('two saves never collide, which counting documents did', () async {
      final store = _store();
      final numbers = <String>{};
      for (var i = 0; i < 20; i++) {
        numbers.add((await store.save(_o('o$i'))).orderNumber);
      }
      expect(numbers, hasLength(20));
    });

    test('a number the record already carries is left alone', () async {
      final store = _store();
      final saved = await store.save(_o('a', orderNumber: 'SO-20250101-099'));
      expect(saved.orderNumber, 'SO-20250101-099');
    });
  });

  group('a screen cannot write Completed', () {
    test('a save carrying it keeps whatever the order actually is', () async {
      final store = _store(seed: [_o('a', status: 'Parts Awaiting')]);
      final saved = await store.save(_o('a', status: 'Completed'));
      expect(saved.status, 'Parts Awaiting');
      expect(saved.closed, isFalse);
    });

    test('a new order saved as Completed comes in as Received', () async {
      final store = _store();
      expect(
        (await store.save(_o('a', status: 'Completed'))).status,
        'Received',
      );
    });

    test('setStatus refuses it, and says where the door is', () async {
      final store = _store(seed: [_o('a')]);
      await expectLater(
        () => store.setStatus('a', 'Completed', isAdmin: true),
        throwsA(
          isA<StatusNotAllowed>().having(
            (e) => e.becauseCompletion,
            'becauseCompletion',
            isTrue,
          ),
        ),
      );
      expect(store.byId('a')!.closed, isFalse);
    });
  });

  group('status changes stay within what the role allows', () {
    test('staff cannot put an order back to Received', () async {
      final store = _store(seed: [_o('a', status: 'In Progress')]);
      expect(
        () => store.setStatus('a', 'Received', isAdmin: false),
        throwsA(isA<StatusNotAllowed>()),
      );
      expect(store.byId('a')!.status, 'In Progress');
    });

    test('an admin may', () async {
      final store = _store(seed: [_o('a', status: 'In Progress')]);
      expect(
        (await store.setStatus('a', 'Received', isAdmin: true)).status,
        'Received',
      );
    });

    test('an ordinary step is allowed either way', () async {
      final store = _store(seed: [_o('a')]);
      expect(
        (await store.setStatus('a', 'Parts Awaiting', isAdmin: false)).status,
        'Parts Awaiting',
      );
    });

    test('a status nobody offers is refused', () async {
      final store = _store(seed: [_o('a')]);
      expect(
        () => store.setStatus('a', 'Teleported', isAdmin: true),
        throwsA(isA<StatusNotAllowed>()),
      );
    });
  });

  group('completion', () {
    test('a full list and a price hands the phone back', () async {
      final store = _store(
        seed: [_o('a', checklist: _allTicked(), finalPrice: 1800)],
      );
      final check = await store.complete('a');
      expect(check.allowed, isTrue);
      expect(store.byId('a')!.status, 'Completed');
      expect(store.byId('a')!.completedAt, isNotNull);
    });

    test(
      'a half-ticked list is refused, and the order does not move',
      () async {
        final store = _store(seed: [_o('a', finalPrice: 1800)]);
        final check = await store.complete('a');
        expect(check.allowed, isFalse);
        expect(check.remaining, _checklist);
        expect(store.byId('a')!.status, 'In Progress');
      },
    );

    test(
      'ticking the list through the repository then completing works',
      () async {
        final store = _store(seed: [_o('a', finalPrice: 1800)]);
        for (final e in checklistEntries(_checklist)) {
          await store.setCheck('a', e.key, ticked: true);
        }
        expect((await store.complete('a')).allowed, isTrue);
        expect(store.byId('a')!.closed, isTrue);
      },
    );

    test('unticking one puts it back out of reach', () async {
      final store = _store(seed: [_o('a', finalPrice: 1800)]);
      for (final e in checklistEntries(_checklist)) {
        await store.setCheck('a', e.key, ticked: true);
      }
      await store.setCheck(
        'a',
        checklistEntries(_checklist).first.key,
        ticked: false,
      );
      final check = await store.complete('a');
      expect(check.allowed, isFalse);
      expect(check.remaining, ['Display OK']);
    });

    test('nothing charged is refused', () async {
      final store = _store(seed: [_o('a', checklist: _allTicked())]);
      final check = await store.complete('a');
      expect(check.blocks, contains(CompletionBlock.noFinalPrice));
    });

    test('a charge of zero passes — a goodwill repair is a decision', () async {
      final store = _store(seed: [_o('a', checklist: _allTicked())]);
      await store.setFinalPrice('a', 0);
      expect((await store.complete('a')).allowed, isTrue);
    });

    test('completing twice keeps the first time it went out', () async {
      final store = _store(
        seed: [_o('a', checklist: _allTicked(), finalPrice: 1800)],
      );
      await store.complete('a');
      final first = store.byId('a')!.completedAt;
      final second = await store.complete('a');
      expect(second.allowed, isFalse, reason: 'already closed');
      expect(store.byId('a')!.completedAt, first);
    });
  });

  group('returned unrepaired', () {
    test('closes the order with no checklist to pass', () async {
      // There is nothing to verify on a phone nobody worked on.
      final store = _store(seed: [_o('a')]);
      final returned = await store.markReturned('a', reason: 'Beyond repair');
      expect(returned.status, 'Returned');
      expect(returned.closed, isTrue);
      expect(returned.complaintNotes, contains('Beyond repair'));
    });

    test('a reason is required (FM #12)', () async {
      final store = _store(seed: [_o('a')]);
      expect(
        () => store.markReturned('a', reason: ' '),
        throwsA(isA<String>()),
      );
      expect(store.byId('a')!.closed, isFalse);
    });
  });

  group('the checklist follows settings, not the order', () {
    test('ticks for items no longer on the list are dropped on save', () async {
      final store = _store();
      final saved = await store.save(
        _o(
          'a',
          checklist: const {'display_ok': true, 'some_removed_item': true},
        ),
      );
      expect(
        saved.checklist.keys,
        checklistEntries(_checklist).map((e) => e.key),
      );
      expect(saved.checklist['display_ok'], isTrue);
    });

    test('a new item arrives unticked rather than inheriting a pass', () async {
      final store = _store();
      final saved = await store.save(_o('a', checklist: const {}));
      expect(saved.checklist.values.every((v) => v == false), isTrue);
    });
  });

  test('a missing order is said so, not silently ignored', () {
    final store = _store();
    expect(() => store.complete('nope'), throwsA(isA<NoSuchOrder>()));
    expect(() => store.setFinalPrice('nope', 1), throwsA(isA<NoSuchOrder>()));
    expect(
      () => store.setCheck('nope', 'k', ticked: true),
      throwsA(isA<NoSuchOrder>()),
    );
    expect(
      () => store.setStatus('nope', 'In Progress', isAdmin: true),
      throwsA(isA<NoSuchOrder>()),
    );
  });

  test('a change notifies, so the list redraws without being told', () async {
    final store = _store(seed: [_o('a')]);
    var notified = 0;
    store.addListener(() => notified++);
    await store.setStatus('a', 'Parts Awaiting', isAdmin: false);
    await store.setCheck('a', 'display_ok', ticked: true);
    expect(notified, 2);
  });

  test('the seed holds the states the list has to get right', () {
    final store = InMemoryServiceStore();
    final now = DateTime.now();
    expect(store.orders.any((o) => o.isOverdueAt(now)), isTrue);
    expect(store.orders.any((o) => o.isDueTodayAt(now)), isTrue);
    expect(store.orders.any((o) => o.closed), isTrue);
    // The order written with a status this build has never heard of keeps it,
    // and is not overdue because its promised date has not passed.
    expect(store.byId('so-4')!.status, 'Waiting For Spare');
    expect(store.byId('so-4')!.closed, isFalse);
    // A job finished last month is not an alarm.
    expect(store.byId('so-3')!.isOverdueAt(now), isFalse);
  });

  group('repair money from the 23 Nov phone test', () {
    num cash(ServiceOrder o) =>
        repairPayments(o)
            .where((p) => p.method == 'Cash')
            .fold<num>(0, (a, b) => a + b.amount);

    test('an advance edited from 120 to 20 is a 100 refund, dated (FM #7)', () {
      final day1 = DateTime(2026, 11, 22, 10);
      final day2 = DateTime(2026, 11, 23, 10);
      final first = ServiceOrder(
        id: 'a',
        advancePaid: 120,
        payments: advanceAfterEdit(null, 120, 'Cash', day1),
      );
      final edited = first.copyWith(
        advancePaid: 20,
        payments: advanceAfterEdit(first, 20, 'Cash', day2),
      );
      final ledger = advanceLedger(edited);
      expect(ledger.map((p) => p.amount), [120, -100]);
      expect(ledger.last.at, day2);
      expect(cash(edited), 20);
    });

    test('advance 77, charged 5: 72 goes back at hand-over (FM #1)', () async {
      final store = _store(
        seed: [
          _o('a', finalPrice: 5, checklist: _allTicked()).copyWith(
            advancePaid: 77,
            payments: [
              Collection(amount: 77, method: 'Cash', at: DateTime(2026, 3, 1)),
            ],
          ),
        ],
      );
      final check = await store.complete('a');
      expect(check.allowed, isTrue);
      final done = store.byId('a')!;
      expect(done.pickupPayment, isNull);
      expect(cash(done), 5);
    });

    test('returned unrepaired: the advance given back, or kept as the fee '
        '(FM #12)', () async {
      ServiceOrder withAdvance(String id) => _o(id).copyWith(
        advancePaid: 50,
        payments: [
          Collection(amount: 50, method: 'Cash', at: DateTime(2026, 3, 1)),
        ],
      );
      final store = _store(seed: [withAdvance('a'), withAdvance('b')]);
      final refunded = await store.markReturned('a', reason: 'No parts');
      expect(cash(refunded), 0);
      final kept = await store.markReturned(
        'b',
        reason: 'Checked, not worth it',
        refundAdvance: false,
      );
      expect(cash(kept), 50);
      expect(kept.finalPrice, 50);
    });

    test('a new job cannot come in on a day still to come (FM #7)', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final order = _o('n').copyWith(
        receivedAt: tomorrow,
        expectedCompletionAt: tomorrow.add(const Duration(days: 2)),
      );
      expect(validateOrder(order).errors, contains('receivedAt'));
    });
  });
}
