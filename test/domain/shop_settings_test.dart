import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/settings/option_learning.dart';
import 'package:fm_shop/domain/settings/option_set.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';

ShopSettings _settings({
  List<String> brands = const ['Samsung', 'Apple'],
  Map<String, List<String>> models = const {
    'samsung': ['Galaxy A54'],
  },
  List<String> colours = const ['Black'],
  List<String> complaints = const ['Not charging'],
  List<String> checklist = const ['Display OK'],
}) =>
    ShopSettings(
      lists: {
        OptionKind.brands: OptionSet(brands),
        OptionKind.colours: OptionSet(colours),
        OptionKind.complaintTypes: OptionSet(complaints),
      },
      modelsByBrand: {
        for (final e in models.entries) e.key: OptionSet(e.value),
      },
      preDeliveryChecklist: OptionSet(checklist),
    );

void main() {
  group('models hang off brands', () {
    test('asking for a brand gives only its models', () {
      final settings = _settings(models: const {
        'samsung': ['Galaxy A54', 'Galaxy M14'],
        'apple': ['iPhone 11'],
      });
      expect(settings.modelsFor('Samsung').values,
          ['Galaxy A54', 'Galaxy M14']);
      expect(settings.modelsFor('Apple').values, ['iPhone 11']);
    });

    test('however the brand was cased', () {
      expect(_settings().modelsFor('SAMSUNG').values, ['Galaxy A54']);
    });

    test('a brand with no models gives an empty list, not every model', () {
      // The alternative is "Galaxy A54" offered under Apple.
      expect(_settings().modelsFor('Apple').isEmpty, isTrue);
      expect(_settings().modelsFor('Nokia').isEmpty, isTrue);
      expect(_settings().modelsFor(null).isEmpty, isTrue);
    });

    test('brandsWithModels names only the brands that have any', () {
      final settings = _settings(models: const {
        'samsung': ['Galaxy A54'],
        'apple': <String>[],
      });
      expect(settings.brandsWithModels, ['Samsung']);
      expect(settings.modelCount, 1);
    });
  });

  group('a fresh shop starts with defaults', () {
    final initial = ShopSettings.initial();

    test('every list has something in it, except suppliers', () {
      for (final kind in OptionKind.values) {
        if (kind == OptionKind.suppliers) continue;
        expect(initial.list(kind).isNotEmpty, isTrue, reason: kind.name);
      }
      // Suppliers are each shop's own: a new shop must not start with
      // another shop's traders.
      expect(initial.list(OptionKind.suppliers).isEmpty, isTrue);
      expect(initial.preDeliveryChecklist.isNotEmpty, isTrue);
    });

    test('and some models, so day one is useful', () {
      expect(initial.modelsFor('Samsung').isNotEmpty, isTrue);
      expect(initial.modelCount, greaterThan(10));
    });

    test('with no duplicates anywhere', () {
      for (final kind in OptionKind.values) {
        final values = initial.list(kind).values;
        final keys = values.map(normalizeOption).toSet();
        expect(keys, hasLength(values.length), reason: kind.name);
      }
    });
  });

  group('the defaults are a starting point, not a floor', () {
    test('a stored document with an empty list reads as empty', () {
      // A shop that removed a complaint type meant to remove it. Restoring it
      // on the next load would make the setting impossible to change.
      final settings = ShopSettings.fromMap({
        'brands': ['Samsung'],
        'complaintTypes': <String>[],
      });
      expect(settings.list(OptionKind.complaintTypes).isEmpty, isTrue);
      expect(settings.list(OptionKind.brands).values, ['Samsung']);
    });

    test('a completely empty document is completely empty', () {
      final settings = ShopSettings.fromMap(const {});
      for (final kind in OptionKind.values) {
        // Expense types came later: a document from before them has no
        // such key, which is "never set" (see the next test).
        if (kind == OptionKind.expenseKinds) continue;
        expect(settings.list(kind).isEmpty, isTrue, reason: kind.name);
      }
      expect(settings.preDeliveryChecklist.isEmpty, isTrue);
    });

    test('expense types: never saved gets the usual ones; emptied stays '
        'empty', () {
      expect(
        ShopSettings.fromMap(const {}).list(OptionKind.expenseKinds).values,
        contains('Tea & food'),
      );
      expect(
        ShopSettings.fromMap(const {
          'expenseKinds': <String>[],
        }).list(OptionKind.expenseKinds).isEmpty,
        isTrue,
      );
      expect(
        ShopSettings.fromMap(const {
          'expenseKinds': ['Internet'],
        }).list(OptionKind.expenseKinds).values,
        ['Internet'],
      );
    });
  });

  group('reading and writing the document', () {
    test('what is written reads back the same', () {
      final settings = ShopSettings(
        lists: {OptionKind.brands: OptionSet(['Samsung', 'Nokia'])},
        modelsByBrand: {'samsung': OptionSet(['Galaxy A54'])},
        preDeliveryChecklist: OptionSet(['Display OK', 'Charging tested']),
      );
      final back = ShopSettings.fromMap(settings.toMap());
      expect(back.list(OptionKind.brands).values, ['Samsung', 'Nokia']);
      expect(back.modelsFor('Samsung').values, ['Galaxy A54']);
      expect(back.preDeliveryChecklist.values,
          ['Display OK', 'Charging tested']);
    });

    test('the checklist keeps its order through a round trip', () {
      // Order is the order somebody works through a phone.
      final items = ['Third', 'First', 'Second'];
      final back = ShopSettings.fromMap(
        ShopSettings(preDeliveryChecklist: OptionSet(items)).toMap(),
      );
      expect(back.preDeliveryChecklist.values, items);
    });

    test('the older key for the checklist is still read', () {
      final settings = ShopSettings.fromMap({
        'checklist': ['Display OK'],
      });
      expect(settings.preDeliveryChecklist.values, ['Display OK']);
    });

    test('blank entries in a stored list are dropped', () {
      final settings = ShopSettings.fromMap({
        'brands': ['Samsung', '', '  ', null],
      });
      expect(settings.list(OptionKind.brands).values, ['Samsung']);
    });
  });

  group('a copy does not share state', () {
    test('mutating a copy leaves the original alone', () {
      final original = _settings();
      final copy = original.mutableCopy();
      copy.list(OptionKind.brands).add('Nokia');
      copy.modelsFor('Samsung').add('Galaxy S23');
      copy.preDeliveryChecklist.add('Extra');

      expect(original.list(OptionKind.brands).contains('Nokia'), isFalse);
      expect(original.modelsFor('Samsung').values, ['Galaxy A54']);
      expect(original.preDeliveryChecklist.values, ['Display OK']);
    });
  });

  group('deciding what a form adds', () {
    test('an intake files a new brand, its model, and a new complaint', () {
      final additions = pendingAdditions(
        _settings(),
        serviceIntakeValues(
          brand: 'Infinix',
          model: 'Hot 30',
          complaints: const ['Not charging', 'Camera fogged'],
        ),
      );
      expect(additions.values[OptionKind.brands], ['Infinix']);
      expect(additions.values[OptionKind.complaintTypes], ['Camera fogged']);
      expect(additions.modelsByBrand['infinix'], ['Hot 30']);
      expect(additions.isNotEmpty, isTrue);
      expect(additions.count, 3);
    });

    test('a form that typed nothing new files nothing', () {
      // Which is most saves.
      final additions = pendingAdditions(
        _settings(),
        serviceIntakeValues(
          brand: 'Samsung',
          model: 'Galaxy A54',
          complaints: const ['Not charging'],
        ),
      );
      expect(additions.isEmpty, isTrue);
      expect(additions.summary, isNull);
    });

    test('a model with no brand to sit under is dropped', () {
      // A model filed under nothing is how one brand's model is offered for
      // every brand in the shop.
      final additions = pendingAdditions(
        _settings(),
        const TypedValues(models: ['Galaxy S24']),
      );
      expect(additions.modelsByBrand, isEmpty);
    });

    test('a known brand with a new model files only the model', () {
      final additions = pendingAdditions(
        _settings(),
        purchaseValues(brand: 'Samsung', model: 'Galaxy S24'),
      );
      expect(additions.values, isEmpty);
      expect(additions.modelsByBrand['samsung'], ['Galaxy S24']);
    });

    test('a purchase files a new colour', () {
      final additions = pendingAdditions(
        _settings(),
        purchaseValues(brand: 'Samsung', colour: 'Awesome Violet'),
      );
      expect(additions.values[OptionKind.colours], ['Awesome Violet']);
    });

    test('a product files a category and a supplier', () {
      final additions = pendingAdditions(
        _settings(),
        productValues(category: 'Tripod', supplier: 'Madurai Wholesale'),
      );
      expect(additions.values[OptionKind.categories], ['Tripod']);
      expect(additions.values[OptionKind.suppliers], ['Madurai Wholesale']);
    });

    test('and deciding writes nothing', () {
      final settings = _settings();
      pendingAdditions(settings, purchaseValues(brand: 'Infinix'));
      expect(settings.list(OptionKind.brands).contains('Infinix'), isFalse);
    });

    test('the summary names what was filed', () {
      final additions = pendingAdditions(
        _settings(),
        purchaseValues(brand: 'Infinix', colour: 'Awesome Violet'),
      );
      expect(additions.summary, contains('Infinix'));
      expect(additions.summary, contains('Awesome Violet'));
    });
  });

  test('every kind has a label and a hint, so a section is never blank', () {
    for (final kind in OptionKind.values) {
      expect(kOptionKindLabels[kind], isNotNull);
      expect(kOptionKindHints[kind], isNotNull);
    }
  });
}
