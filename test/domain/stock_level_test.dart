import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/products/stock_level.dart';

void main() {
  group('out of stock is its own answer, not a shade of low', () {
    test('zero is out, whatever the reorder level says', () {
      expect(stockLevelFor(0, 10), StockLevel.outOfStock);
      expect(stockLevelFor(0, 0), StockLevel.outOfStock);
      // A count that somehow went negative is still out, not something worse.
      expect(stockLevelFor(-3, 10), StockLevel.outOfStock);
    });
  });

  group('low is a threshold per product, never one number for the shop', () {
    test('at the reorder level exactly is low, not fine', () {
      expect(stockLevelFor(4, 4), StockLevel.low);
    });

    test('one above it is in stock', () {
      expect(stockLevelFor(5, 4), StockLevel.inStock);
    });

    test('below it is low', () {
      expect(stockLevelFor(1, 10), StockLevel.low);
    });

    test('the same count is low for one product and fine for another', () {
      // Fifty screen guards a week and one car charger a month cannot share a
      // threshold.
      expect(stockLevelFor(8, 10), StockLevel.low);
      expect(stockLevelFor(8, 2), StockLevel.inStock);
    });
  });

  group('no reorder level set means no low-stock alert', () {
    test('it is in stock or out, never low', () {
      // Guessing a threshold means an alert nobody chose, which is an alert
      // nobody trusts.
      expect(stockLevelFor(1, 0), StockLevel.inStock);
      expect(stockLevelFor(1, -5), StockLevel.inStock);
      expect(stockLevelFor(0, 0), StockLevel.outOfStock);
    });
  });

  group('the dashboard tile', () {
    test('counts low and out together — out is the urgent version', () {
      expect(needsReordering(4, 4), isTrue);
      expect(needsReordering(0, 10), isTrue);
      // A tile that excluded zero would show nothing on the morning the shop
      // ran out.
      expect(needsReordering(0, 0), isTrue);
    });

    test('and leaves alone what is fine', () {
      expect(needsReordering(50, 10), isFalse);
      expect(needsReordering(1, 0), isFalse);
    });
  });

  group('how many to order', () {
    test('enough to clear the alert, not just reach the threshold', () {
      // Receiving the suggestion has to clear the warning rather than land
      // back on it.
      expect(suggestedReorderQuantity(4, 4), 1);
      expect(suggestedReorderQuantity(0, 10), 11);
      expect(suggestedReorderQuantity(3, 10), 8);
    });

    test('nothing to order when there is plenty', () {
      expect(suggestedReorderQuantity(50, 10), 0);
    });

    test('no suggestion without a reorder level to aim at', () {
      // Inventing one would put a number in front of whoever does the
      // ordering that nobody chose.
      expect(suggestedReorderQuantity(3, 0), isNull);
    });
  });

  test('every level has a label, so a chip is never blank', () {
    for (final level in StockLevel.values) {
      expect(kStockLevelLabels[level], isNotNull);
    }
  });
}
