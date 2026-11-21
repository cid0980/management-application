import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/products/product_list.dart';
import 'package:fm_shop/domain/products/product_validation.dart';
import 'package:fm_shop/domain/products/stock_level.dart';

Product _p(
  String id, {
  String name = 'Tempered glass',
  String brand = 'Spigen',
  String category = 'Screen guard',
  String variant = '',
  String colour = '',
  String sku = '',
  num cost = 45,
  num selling = 199,
  num mrp = 299,
  int count = 10,
  int reorder = 4,
  List<String> photos = const ['photo://front'],
}) =>
    Product(
      id: id,
      name: name,
      brand: brand,
      category: category,
      variant: variant,
      colour: colour,
      sku: sku,
      costPrice: cost,
      sellingPrice: selling,
      mrp: mrp,
      stockCount: count,
      reorderLevel: reorder,
      photos: photos,
    );

void main() {
  group('a product is a count, not a status', () {
    test('it is sellable while any are left', () {
      expect(_p('a', count: 1).isSellable, isTrue);
      expect(_p('a', count: 0).isSellable, isFalse);
    });

    test('and its level comes from its own reorder level', () {
      expect(_p('a', count: 10, reorder: 4).level, StockLevel.inStock);
      expect(_p('a', count: 4, reorder: 4).level, StockLevel.low);
      expect(_p('a', count: 0, reorder: 4).level, StockLevel.outOfStock);
      expect(_p('a', count: 1, reorder: 0).level, StockLevel.inStock);
    });
  });

  group('money', () {
    test('profit per unit, and what the shelf is worth', () {
      final product = _p('a', cost: 45, selling: 199, count: 10);
      expect(product.unitProfit, 154);
      expect(product.stockCost, 450);
      expect(product.stockValue, 1990);
    });

    test('a loss leader is flagged, not refused', () {
      expect(_p('a', cost: 200, selling: 199).soldAtALoss, isTrue);
      expect(_p('a', cost: 45, selling: 199).soldAtALoss, isFalse);
    });

    test('pricing above the printed maximum is flagged', () {
      // The kind of thing a customer photographs.
      expect(_p('a', selling: 399, mrp: 299).aboveMrp, isTrue);
      expect(_p('a', selling: 199, mrp: 299).aboveMrp, isFalse);
      // No MRP recorded is not a breach of one.
      expect(_p('a', selling: 399, mrp: 0).aboveMrp, isFalse);
    });
  });

  group('every read normalizes', () {
    test('a count written as a string reads as a number', () {
      expect(Product.fromMap('a', {'stock': '7'}).stockCount, 7);
      expect(Product.fromMap('a', {'quantity': 7.0}).stockCount, 7);
    });

    test('a negative count reads as zero', () {
      // Carrying it forward would let a sale succeed against stock that does
      // not exist.
      expect(Product.fromMap('a', {'stockCount': -4}).stockCount, 0);
    });

    test('the keys older builds wrote are still read', () {
      final product = Product.fromMap('a', {
        'price': 1899,
        'purchasePrice': 1150,
        'stock': '7',
        'lowStockThreshold': 3,
        'color': 'Black',
      });
      expect(product.sellingPrice, 1899);
      expect(product.costPrice, 1150);
      expect(product.stockCount, 7);
      expect(product.reorderLevel, 3);
      expect(product.colour, 'Black');
    });

    test('an empty document does not throw', () {
      final product = Product.fromMap('a', const {});
      expect(product.stockCount, 0);
      expect(product.reorderLevel, 0);
      expect(product.photos, isEmpty);
      expect(product.level, StockLevel.outOfStock);
    });

    test('a record written here reads back the same', () {
      final product = _p('a', sku: 'SG-A54', count: 48);
      final back = Product.fromMap('a', product.toMap());
      expect(back.name, product.name);
      expect(back.sku, 'SG-A54');
      expect(back.stockCount, 48);
      expect(back.reorderLevel, 4);
    });
  });

  test('the title skips the parts that are not filled in', () {
    expect(_p('a', brand: '', variant: '', colour: '').title,
        'Tempered glass');
    expect(
      _p('a', brand: 'Spigen', variant: 'A54', colour: 'Clear').title,
      'Spigen Tempered glass A54 Clear',
    );
  });

  group('validation', () {
    test('a complete product saves', () {
      expect(validateProduct(_p('a')).isValid, isTrue);
    });

    test('a name is needed — it is what the counter searches for', () {
      expect(validateProduct(_p('a', name: '')).errors, contains('name'));
    });

    test('a selling price is needed', () {
      expect(
        validateProduct(_p('a', selling: 0)).errors,
        contains('sellingPrice'),
      );
    });

    test('a negative price or reorder level is refused', () {
      expect(validateProduct(_p('a', cost: -1)).errors, contains('costPrice'));
      expect(
        validateProduct(Product(
          id: 'a',
          name: 'X',
          sellingPrice: 10,
          reorderLevel: -1,
        )).errors,
        contains('reorderLevel'),
      );
    });

    test('there is no stock field to be wrong', () {
      // A count typed into a form has no history behind it.
      final result = validateProduct(_p('a', count: 999999));
      expect(result.isValid, isTrue);
    });

    group('two records for one thing', () {
      test('are refused, naming the one already on the list', () {
        final existing = [_p('a', variant: 'A54', colour: 'Clear')];
        final result = validateProduct(
          _p('new', variant: 'A54', colour: 'Clear'),
          existing: existing,
        );
        expect(result.errors['name'], contains('Already on the list'));
      });

      test('but a different variant is a different product', () {
        final existing = [_p('a', variant: 'A54')];
        expect(
          validateProduct(_p('new', variant: 'A34'), existing: existing)
              .isValid,
          isTrue,
        );
      });

      test('and editing a record does not clash with itself', () {
        final existing = [_p('a', variant: 'A54')];
        expect(
          validateProduct(_p('a', variant: 'A54', selling: 249),
                  existing: existing)
              .isValid,
          isTrue,
        );
      });
    });

    test('a shared SKU is refused — the code exists to be unique', () {
      final existing = [_p('a', sku: 'SG-A54')];
      final result = validateProduct(
        _p('new', name: 'Something else', sku: 'sg-a54'),
        existing: existing,
      );
      expect(result.errors['sku'], contains('already on'));
    });

    group('warnings the shop may overrule', () {
      test('no reorder level says what that means', () {
        final result = validateProduct(_p('a', reorder: 0));
        expect(result.isValid, isTrue);
        expect(result.warnings['reorderLevel'], contains('only as out of'));
      });

      test('no cost price means no margin can be worked out', () {
        expect(
          validateProduct(_p('a', cost: 0)).warnings,
          contains('costPrice'),
        );
      });

      test('a loss leader and an above-MRP price are both flagged', () {
        expect(validateProduct(_p('a', cost: 300, selling: 199, mrp: 0))
            .warnings, contains('sellingPrice'));
        expect(validateProduct(_p('a', selling: 399, mrp: 299)).warnings,
            contains('sellingPrice'));
      });

      test('no photo and no category are worth saying, not refusing', () {
        final result =
            validateProduct(_p('a', photos: const [], category: ''));
        expect(result.isValid, isTrue);
        expect(result.warnings, contains('photos'));
        expect(result.warnings, contains('category'));
      });
    });
  });

  group('the list', () {
    final all = [
      _p('plenty', name: 'Glass', count: 48, reorder: 10),
      _p('low', name: 'Charger', count: 4, reorder: 4),
      _p('out', name: 'Cable', count: 0, reorder: 12),
      _p('nolevel', name: 'Holder', count: 3, reorder: 0),
    ];

    test('problems come first: out of stock, then low', () {
      // Then alphabetically within each level — "Spigen Glass" before
      // "Spigen Holder".
      expect(
        productRows(all).map((p) => p.id),
        ['out', 'low', 'plenty', 'nolevel'],
      );
    });

    test('To order holds low and out together', () {
      expect(
        productRows(all, tab: ProductTab.toOrder).map((p) => p.id),
        ['out', 'low'],
      );
    });

    test('Out of stock is only the empty ones', () {
      expect(
        productRows(all, tab: ProductTab.outOfStock).map((p) => p.id),
        ['out'],
      );
    });

    test('counts are against the same query the list is showing', () {
      final counts = productTabCounts(all, query: 'charger');
      expect(counts[ProductTab.all], 1);
      expect(counts[ProductTab.toOrder], 1);
      expect(counts[ProductTab.outOfStock], 0);
    });

    test('with no query the counts cover everything', () {
      final counts = productTabCounts(all);
      expect(counts[ProductTab.all], 4);
      expect(counts[ProductTab.toOrder], 2);
      expect(counts[ProductTab.outOfStock], 1);
    });

    test('search covers name, brand, category, SKU and supplier', () {
      final rows = [
        _p('a', name: 'Glass', sku: 'SG-A54',
            category: 'Screen guard'),
      ];
      for (final q in ['glass', 'spigen', 'screen guard', 'SG-A54']) {
        expect(productRows(rows, query: q), hasLength(1), reason: q);
      }
      expect(productRows(rows, query: 'iphone'), isEmpty);
    });

    test('only what is on the shelf reaches the sale picker', () {
      expect(sellableProducts(all).map((p) => p.id),
          ['plenty', 'low', 'nolevel']);
      // The rest is still loaded, so an out-of-stock product can say so.
      expect(all, hasLength(4));
    });

    test('lines and units are different numbers', () {
      final value = productStockValue(all);
      expect(value.lines, 4);
      expect(value.units, 55);
      expect(value.cost, 45 * 55);
      expect(value.retail, 199 * 55);
      expect(value.expectedProfit, 154 * 55);
    });

    test('the dashboard tile counts the rows worth acting on', () {
      expect(lowStockAlerts(all).map((p) => p.id), ['out', 'low']);
    });

    test('grouping by category keeps uncategorised visible', () {
      final groups = byCategory([
        _p('a', category: 'Charger'),
        _p('b', category: ''),
      ]);
      expect(groups.keys, containsAll(['Charger', 'Uncategorised']));
    });
  });

  test('the default category list has no duplicates', () {
    expect(kProductCategories.toSet(), hasLength(kProductCategories.length));
  });
}
