import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/service/checklist.dart';
import 'package:fm_shop/domain/service/order_validation.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/domain/settings/option_set.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';

ServiceOrder _order({num? finalPrice}) => ServiceOrder(
      id: 'so-1',
      customerId: 'c-1',
      customerPhone: '9876543210',
      brand: 'Samsung',
      model: 'Galaxy M14',
      complaints: const ['Not charging'],
      finalPrice: finalPrice,
      receivedAt: DateTime(2026, 3, 1),
      expectedCompletionAt: DateTime(2026, 3, 4),
    );

void main() {
  group('the pre-delivery checklist comes from settings', () {
    test('so editing it there changes what has to be ticked', () async {
      final settings = InMemorySettingsStore(
        seed: ShopSettings(
          preDeliveryChecklist: OptionSet(['Display OK']),
        ),
      );
      final service = InMemoryServiceStore(seed: [], settings: settings);
      addTearDown(settings.dispose);
      addTearDown(service.dispose);

      expect(service.checklistItems, ['Display OK']);

      await settings.setChecklist(['Display OK', 'Charging tested']);
      expect(service.checklistItems, ['Display OK', 'Charging tested']);
    });

    test('an item added in settings becomes a tick the order has to pass',
        () async {
      final settings = InMemorySettingsStore(
        seed: ShopSettings(preDeliveryChecklist: OptionSet(['Display OK'])),
      );
      final service = InMemoryServiceStore(
        seed: [_order(finalPrice: 1800)],
        settings: settings,
      );
      addTearDown(settings.dispose);
      addTearDown(service.dispose);

      // Tick the one item there is, and the order can go back.
      await service.setCheck(
        'so-1',
        checklistEntries(['Display OK']).single.key,
        ticked: true,
      );
      expect((await service.complete('so-1')).allowed, isTrue);
    });

    test('and a new item blocks an order that was ready a moment ago',
        () async {
      final settings = InMemorySettingsStore(
        seed: ShopSettings(preDeliveryChecklist: OptionSet(['Display OK'])),
      );
      final service = InMemoryServiceStore(
        seed: [_order(finalPrice: 1800)],
        settings: settings,
      );
      addTearDown(settings.dispose);
      addTearDown(service.dispose);

      await service.setCheck(
        'so-1',
        checklistEntries(['Display OK']).single.key,
        ticked: true,
      );
      // The admin adds a check while the phone is on the bench.
      await settings.setChecklist(['Display OK', 'Camera tested']);

      final check = await service.complete('so-1');
      expect(check.allowed, isFalse);
      expect(check.blocks, contains(CompletionBlock.checklistIncomplete));
      expect(check.remaining, ['Camera tested']);
    });

    test('an empty checklist in settings turns the gate off, as documented',
        () async {
      // A shop with no checklist has nothing to verify. Stated here because
      // it is a real consequence of making the list editable.
      final settings = InMemorySettingsStore(
        seed: ShopSettings(preDeliveryChecklist: OptionSet(const [])),
      );
      final service = InMemoryServiceStore(
        seed: [_order(finalPrice: 1800)],
        settings: settings,
      );
      addTearDown(settings.dispose);
      addTearDown(service.dispose);

      expect(service.checklistItems, isEmpty);
      expect((await service.complete('so-1')).allowed, isTrue);
    });

    test('a fixed list still wins, for a test about the labels themselves',
        () async {
      final settings = InMemorySettingsStore(
        seed: ShopSettings(preDeliveryChecklist: OptionSet(['From settings'])),
      );
      final service = InMemoryServiceStore(
        seed: [],
        settings: settings,
        checklist: const ['Fixed'],
      );
      addTearDown(settings.dispose);
      addTearDown(service.dispose);
      expect(service.checklistItems, ['Fixed']);
    });

    test('with no settings at all it falls back to the defaults', () {
      final service = InMemoryServiceStore(seed: []);
      addTearDown(service.dispose);
      expect(service.checklistItems, kDefaultPreDeliveryChecklist);
    });
  });
}
