import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

void main() {
  group('a used handset is one of one', () {
    test('a quantity on a second-hand line is ignored', () {
      const line = SaleItem(
        description: 'Samsung A54',
        unitPrice: 18500,
        quantity: 3,
        source: LineSource.secondHand,
      );
      expect(line.effectiveQuantity, 1);
      expect(line.total, 18500);
    });

    test('a product line uses its quantity', () {
      const line = SaleItem(
        description: 'Screen guard',
        unitPrice: 150,
        quantity: 3,
        source: LineSource.product,
      );
      expect(line.effectiveQuantity, 3);
      expect(line.total, 450);
    });

    test('a quantity below one is corrected to one', () {
      const line = SaleItem(description: 'Cable', unitPrice: 200, quantity: 0);
      expect(line.effectiveQuantity, 1);
      expect(line.total, 200);
    });
  });

  group('a discount cannot pay the customer', () {
    test('a discount larger than the line caps at zero, and is flagged', () {
      const line =
          SaleItem(description: 'Cable', unitPrice: 200, discount: 500);
      expect(line.total, 0);
      expect(line.discountExceedsLine, isTrue);
    });

    test('an ordinary discount comes off the line', () {
      const line =
          SaleItem(description: 'Cable', unitPrice: 200, discount: 50);
      expect(line.total, 150);
      expect(line.discountExceedsLine, isFalse);
    });
  });

  group('which lines move stock', () {
    test('a handset and a product do; a typed line does not', () {
      expect(
        const SaleItem(
                description: 'a', unitPrice: 1, source: LineSource.secondHand)
            .movesStock,
        isTrue,
      );
      expect(
        const SaleItem(description: 'a', unitPrice: 1, source: LineSource.product)
            .movesStock,
        isTrue,
      );
      // A fitting charge, a round-off, a guard out of the drawer nobody counts.
      expect(const SaleItem(description: 'Fitting', unitPrice: 100).movesStock,
          isFalse);
    });
  });

  group('the bill adds up', () {
    test('gross, discount as it actually applied, and the total', () {
      final totals = billTotals(const [
        SaleItem(description: 'Handset', unitPrice: 18500,
            source: LineSource.secondHand),
        SaleItem(description: 'Guard', unitPrice: 150, quantity: 2,
            discount: 50),
        // A discount bigger than its line must not take money off the rest of
        // the bill.
        SaleItem(description: 'Cable', unitPrice: 200, discount: 500),
      ]);
      expect(totals.gross, 19000);
      expect(totals.discount, 250);
      expect(totals.total, 18750);
      expect(totals.lineCount, 3);
    });

    test('an empty bill is zero, not an error', () {
      final totals = billTotals(const []);
      expect(totals.total, 0);
      expect(totals.lineCount, 0);
    });
  });

  group('every read normalizes', () {
    test('a price written as a string reads as a number', () {
      expect(SaleItem.fromMap({'unitPrice': '18,500'}).unitPrice, 18500);
      // The web app wrote `price` where this build writes `unitPrice`.
      expect(SaleItem.fromMap({'price': 150}).unitPrice, 150);
    });

    test('a source this build has never seen is a manual line', () {
      // Manual is the safe reading: it moves no stock.
      expect(SaleItem.fromMap({'source': 'whatever'}).source,
          LineSource.manual);
      expect(SaleItem.fromMap(const {}).source, LineSource.manual);
      expect(SaleItem.fromMap({'source': 'second_hand'}).source,
          LineSource.secondHand);
    });

    test('a missing quantity is one', () {
      expect(SaleItem.fromMap(const {}).quantity, 1);
    });

    test('a line written here reads back the same', () {
      const line = SaleItem(
        description: 'Samsung A54',
        unitPrice: 18500,
        source: LineSource.secondHand,
        recordId: 'sh-1',
        imei: '354879104523681',
        labelNumber: 26001,
      );
      final back = SaleItem.fromMap(line.toMap());
      expect(back.description, line.description);
      expect(back.source, LineSource.secondHand);
      expect(back.recordId, 'sh-1');
      expect(back.imei, '354879104523681');
      expect(back.labelNumber, 26001);
    });
  });
}
