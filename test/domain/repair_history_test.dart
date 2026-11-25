import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/service/repair_history.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  tearDown(() => HistoryActor.set('', ''));

  ServiceOrder fresh() => ServiceOrder(
    id: 'j1',
    brand: 'Xiaomi',
    model: 'Redmi 12',
    customerPhone: '9876543210',
    receivedAt: DateTime(2026, 11, 25, 10),
    expectedCompletionAt: DateTime(2026, 11, 27, 18),
  );

  test('the store writes who did what, on every change', () async {
    final store = InMemoryServiceStore(seed: const []);
    addTearDown(store.dispose);

    HistoryActor.set('owner', 'Asen');
    await store.save(fresh());
    expect(store.byId('j1')!.history.map((e) => e.kind), ['received']);
    expect(store.byId('j1')!.history.single.byName, 'Asen');

    await store.save(
      store.byId('j1')!.copyWith(technician: 'Suresh', technicianUid: 's1'),
    );
    HistoryActor.set('s1', 'Suresh');
    await store.setStatus('j1', 'In Progress', isAdmin: false);
    await store.setStatus('j1', 'Ready', isAdmin: false);

    final h = store.byId('j1')!.history;
    expect(h.map((e) => e.kind), [
      'received',
      'technician',
      'status',
      'status',
    ]);
    expect(h[1].detail, 'Suresh');
    expect(h[1].byName, 'Asen');
    expect(h.last.detail, 'Ready');
    expect(h.last.byName, 'Suresh');
  });

  test('an edit that changes nothing tracked adds nothing', () async {
    final store = InMemoryServiceStore(seed: const []);
    addTearDown(store.dispose);
    await store.save(fresh());
    await store.save(store.byId('j1')!.copyWith(complaintNotes: 'Cracked'));
    expect(store.byId('j1')!.history, hasLength(1));
  });

  test('handed back, returned, final price', () {
    final at = DateTime(2026, 11, 26);
    final before = fresh().copyWith(status: 'Ready');
    expect(
      historyEvents(
        before,
        before.copyWith(status: 'Completed'),
        at,
      ).single.kind,
      'handedBack',
    );
    expect(
      historyEvents(
        before,
        before.copyWith(status: 'Returned'),
        at,
      ).single.kind,
      'returned',
    );
    final priced = historyEvents(before, before.copyWith(finalPrice: 1500), at);
    expect(priced.single.kind, 'price');
    expect(priced.single.detail, '1500');
  });

  test('kept small: the oldest go past the limit', () {
    var o = fresh();
    for (var i = 0; i < kHistoryLimit + 10; i++) {
      o = withHistory(
        o,
        o.copyWith(status: i.isEven ? 'In Progress' : 'Parts Awaiting'),
        DateTime(2026, 11, 25, 10, i),
      );
    }
    expect(o.history, hasLength(kHistoryLimit));
  });

  test('survives a save and a read', () {
    final o = withHistory(null, fresh(), DateTime(2026, 11, 25, 10));
    final back = ServiceOrder.fromMap('j1', o.toMap());
    expect(back.history.single.kind, 'received');
    expect(back.history.single.at, DateTime(2026, 11, 25, 10));
  });
}
