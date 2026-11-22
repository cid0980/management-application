import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/settings/option_learning.dart';
import 'package:fm_shop/domain/settings/option_set.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';

InMemorySettingsStore _store({
  List<String> brands = const ['Samsung'],
  Map<String, List<String>> models = const {
    'samsung': ['Galaxy A54'],
  },
  List<String> colours = const ['Black'],
  List<String> checklist = const ['Display OK', 'Charging tested'],
}) =>
    InMemorySettingsStore(
      seed: ShopSettings(
        lists: {
          OptionKind.brands: OptionSet(brands),
          OptionKind.colours: OptionSet(colours),
        },
        modelsByBrand: {
          for (final e in models.entries) e.key: OptionSet(e.value),
        },
        preDeliveryChecklist: OptionSet(checklist),
      ),
    );

void main() {
  group('a value typed into a form joins the list', () {
    test('a new brand and its model, from one save', () async {
      final store = _store();
      addTearDown(store.dispose);
      final result = await store.learn(
        purchaseValues(brand: 'Infinix', model: 'Hot 30'),
      );
      expect(result.ok, isTrue);
      expect(result.added, 2);
      expect(store.settings.list(OptionKind.brands).contains('Infinix'),
          isTrue);
      expect(store.settings.modelsFor('Infinix').values, ['Hot 30']);
    });

    test('a model under a brand that had none before', () async {
      // The one case that cannot be an append to something already there.
      final store = _store(models: const {});
      addTearDown(store.dispose);
      await store.learn(purchaseValues(brand: 'Samsung', model: 'Galaxy S24'));
      expect(store.settings.modelsFor('Samsung').values, ['Galaxy S24']);
    });

    test('nothing new writes nothing', () async {
      final store = _store();
      addTearDown(store.dispose);
      final result = await store.learn(
        purchaseValues(brand: 'Samsung', model: 'Galaxy A54'),
      );
      expect(result.ok, isTrue);
      expect(result.wroteSomething, isFalse);
      expect(result.added, 0);
    });

    test('the same value typed twice files once', () async {
      final store = _store(colours: const []);
      addTearDown(store.dispose);
      await store.learn(const TypedValues(values: {
        OptionKind.colours: ['Awesome Violet', 'awesome violet'],
      }));
      expect(store.settings.list(OptionKind.colours).values,
          ['Awesome Violet']);
    });
  });

  group('union-append, never a whole-document write', () {
    test('two staff adding a brand in the same minute both succeed',
        () async {
      // A whole-document write means the second read the list before the
      // first's brand was on it and wrote it back without — so one brand
      // silently vanished.
      final store = _store();
      addTearDown(store.dispose);

      // Both decide against the same starting state, as two tills would.
      final before = store.settings;
      final first = pendingAdditions(before, purchaseValues(brand: 'Infinix'));
      final second = pendingAdditions(before, purchaseValues(brand: 'Lava'));

      await store.append(first);
      await store.append(second);

      final brands = store.settings.list(OptionKind.brands);
      expect(brands.contains('Infinix'), isTrue);
      expect(brands.contains('Lava'), isTrue);
      expect(brands.contains('Samsung'), isTrue);
    });

    test('and two models under the same brand both survive', () async {
      final store = _store();
      addTearDown(store.dispose);
      final before = store.settings;
      await store.append(
        pendingAdditions(before, purchaseValues(brand: 'Samsung', model: 'A')),
      );
      await store.append(
        pendingAdditions(before, purchaseValues(brand: 'Samsung', model: 'B')),
      );
      expect(store.settings.modelsFor('Samsung').values,
          ['Galaxy A54', 'A', 'B']);
    });
  });

  group('filing must never fail what caused it', () {
    test('a failed append comes back as a result, never thrown', () async {
      // The sale is already saved. A failed filing is a dropdown that is
      // briefly out of date.
      final store = _store();
      addTearDown(store.dispose);
      store.failWith = 'The shop network is down';

      final result = await store.learn(purchaseValues(brand: 'Infinix'));
      expect(result.ok, isFalse);
      expect(result.error, 'The shop network is down');
      // And the list is untouched rather than half-written.
      expect(store.settings.list(OptionKind.brands).contains('Infinix'),
          isFalse);
    });

    test('an empty append is a no-op, not an error', () async {
      final store = _store();
      addTearDown(store.dispose);
      final result = await store.append(const OptionAdditions());
      expect(result.ok, isTrue);
      expect(result.added, 0);
    });
  });

  group('the settings page edits', () {
    test('adds one value', () async {
      final store = _store();
      addTearDown(store.dispose);
      expect((await store.addOption(OptionKind.brands, 'Nokia')).added, 1);
      expect((await store.addOption(OptionKind.brands, 'nokia')).added, 0);
      expect(store.settings.list(OptionKind.brands).values,
          ['Samsung', 'Nokia']);
    });

    test('adds a model, and the brand with it if the brand is new', () async {
      // A model can never sit under a brand the dropdown does not offer.
      final store = _store();
      addTearDown(store.dispose);
      await store.addModel('Tecno', 'Spark 10');
      expect(store.settings.list(OptionKind.brands).contains('Tecno'), isTrue);
      expect(store.settings.modelsFor('Tecno').values, ['Spark 10']);
    });

    test('a model with no brand is refused with a reason', () async {
      final store = _store();
      addTearDown(store.dispose);
      final result = await store.addModel('  ', 'Spark 10');
      expect(result.ok, isFalse);
      expect(result.error, contains('Pick a brand'));
    });

    test('removes a value, leaving records alone', () async {
      // A brand removed from the list is still the brand on two hundred
      // handsets; rewriting those is not a settings change.
      final store = _store(brands: const ['Samsung', 'Nokia']);
      addTearDown(store.dispose);
      expect((await store.removeOption(OptionKind.brands, 'nokia')).added, 1);
      expect(store.settings.list(OptionKind.brands).values, ['Samsung']);
      expect((await store.removeOption(OptionKind.brands, 'Nokia')).added, 0);
    });

    test('removes a model', () async {
      final store = _store(models: const {
        'samsung': ['Galaxy A54', 'Galaxy M14'],
      });
      addTearDown(store.dispose);
      await store.removeModel('Samsung', 'Galaxy M14');
      expect(store.settings.modelsFor('Samsung').values, ['Galaxy A54']);
      expect((await store.removeModel('Nokia', 'Anything')).added, 0);
    });
  });

  group('the pre-delivery checklist', () {
    test('is replaced whole, because the order is the value being set',
        () async {
      // An append cannot express a reorder, and it is one admin on the
      // settings page with nobody waiting.
      final store = _store();
      addTearDown(store.dispose);
      await store.setChecklist(['Charging tested', 'Display OK', 'Camera']);
      expect(store.settings.preDeliveryChecklist.values,
          ['Charging tested', 'Display OK', 'Camera']);
    });

    test('an item moves, and the rest keep their order', () async {
      final store = _store(checklist: const ['a', 'b', 'c']);
      addTearDown(store.dispose);
      expect((await store.moveChecklistItem('c', 0)).added, 1);
      expect(store.settings.preDeliveryChecklist.values, ['c', 'a', 'b']);
    });

    test('moving to where it already is changes nothing', () async {
      final store = _store(checklist: const ['a', 'b']);
      addTearDown(store.dispose);
      expect((await store.moveChecklistItem('a', 0)).added, 0);
    });

    test('a duplicate label is not added twice', () async {
      // Two labels that slug to one key would share a checkbox, which is what
      // checklist.dart resolves — but the list itself should not hold both.
      final store = _store(checklist: const ['Display OK']);
      addTearDown(store.dispose);
      await store.learn(const TypedValues(checklistItems: ['display ok']));
      expect(store.settings.preDeliveryChecklist.values, ['Display OK']);
    });
  });

  group('notifying', () {
    test('a write notifies, so every dropdown redraws', () async {
      final store = _store();
      addTearDown(store.dispose);
      var notified = 0;
      store.addListener(() => notified++);
      await store.addOption(OptionKind.brands, 'Nokia');
      await store.setRepairWarrantyDays(30);
      expect(notified, 2);
    });

    test('a write that changed nothing notifies nobody', () async {
      final store = _store();
      addTearDown(store.dispose);
      var notified = 0;
      store.addListener(() => notified++);
      await store.addOption(OptionKind.brands, 'Samsung');
      await store.removeOption(OptionKind.brands, 'Nokia');
      await store.append(const OptionAdditions());
      expect(notified, 0);
    });
  });

  test('a fresh store starts from the defaults', () {
    final store = InMemorySettingsStore();
    addTearDown(store.dispose);
    expect(store.settings.list(OptionKind.brands).contains('Samsung'), isTrue);
    expect(store.settings.preDeliveryChecklist.isNotEmpty, isTrue);
  });

  test('the seed is copied, not held', () async {
    final seed = ShopSettings(
      lists: {OptionKind.brands: OptionSet(['Samsung'])},
    );
    final store = InMemorySettingsStore(seed: seed);
    addTearDown(store.dispose);
    await store.addOption(OptionKind.brands, 'Nokia');
    expect(seed.list(OptionKind.brands).values, ['Samsung']);
  });
}
