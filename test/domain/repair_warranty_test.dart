import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/service/service_order.dart';

ServiceOrder _done(String id, {int days = 30, String status = 'Completed'}) =>
    ServiceOrder(
      id: id,
      orderNumber: 'SO-$id',
      imei: '356789012345678',
      status: status,
      warrantyDays: days,
      completedAt: DateTime(2026, 11, 1, 15),
    );

void main() {
  group("the shop's repair warranty", () {
    test('runs from the day it was handed back, through its last day', () {
      final o = _done('a');
      expect(o.warrantyUntil, DateTime(2026, 12, 1));
      expect(o.underWarrantyAt(DateTime(2026, 12, 1, 20)), isTrue);
      expect(o.underWarrantyAt(DateTime(2026, 12, 2, 0, 1)), isFalse);
    });

    test('no warranty given, or returned unrepaired, means none', () {
      expect(_done('a', days: 0).warrantyUntil, isNull);
      expect(_done('a', status: 'Returned').warrantyUntil, isNull);
    });

    test('a returning IMEI under warranty is found; an expired one is not',
        () {
      final orders = [_done('old', days: 7), _done('new')];
      final hit = warrantyMatch(orders, '35678 90123 45678',
          now: DateTime(2026, 11, 20));
      expect(hit!.id, 'new');
      expect(
        warrantyMatch(orders, '356789012345678', now: DateTime(2027, 1, 1)),
        isNull,
      );
    });

    test('the job being edited does not match itself', () {
      expect(
        warrantyMatch([_done('a')], '356789012345678',
            now: DateTime(2026, 11, 5), excludeId: 'a'),
        isNull,
      );
    });

    test('it round-trips, and old jobs read as none', () {
      expect(ServiceOrder.fromMap('a', _done('a').toMap()).warrantyDays, 30);
      expect(ServiceOrder.fromMap('a', const {}).warrantyDays, 0);
    });
  });

  test('handing a phone back stamps the policy as it stands then', () async {
    final settings = InMemorySettingsStore();
    await settings.setChecklist(const []);
    await settings.setRepairWarrantyDays(15);
    final store = InMemoryServiceStore(
      seed: [
        ServiceOrder(
          id: 'o1',
          status: 'Ready',
          finalPrice: 1500,
          receivedAt: DateTime(2026, 11, 1),
          expectedCompletionAt: DateTime(2026, 11, 3),
        ),
      ],
      settings: settings,
    );
    final check = await store.complete('o1');
    expect(check.allowed, isTrue);
    expect(store.byId('o1')!.warrantyDays, 15);

    // A later change of policy does not rewrite the bill already given.
    await settings.setRepairWarrantyDays(90);
    expect(store.byId('o1')!.warrantyDays, 15);
  });
}
