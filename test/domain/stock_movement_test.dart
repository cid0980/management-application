import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/products/stock_movement.dart';

StockMovement _move(
  StockMoveKind kind, {
  int quantity = 5,
  String reason = 'Delivery from Chennai Mobile Traders',
}) =>
    StockMovement(kind: kind, quantity: quantity, reason: reason);

void main() {
  group('the amount is positive; the direction is the kind', () {
    test('deliveries and returns go up', () {
      expect(_move(StockMoveKind.received).signed, 5);
      expect(_move(StockMoveKind.returned).signed, 5);
      expect(_move(StockMoveKind.adjustedUp).signed, 5);
    });

    test('sales, write-offs and corrections down go down', () {
      expect(_move(StockMoveKind.sold).signed, -5);
      expect(_move(StockMoveKind.damaged).signed, -5);
      expect(_move(StockMoveKind.adjustedDown).signed, -5);
    });

    test('a correction gets two kinds rather than a signed amount', () {
      // A ledger with both negative receipts and positive sales in it cannot
      // be added up.
      expect(stockMoveSign(StockMoveKind.adjustedUp), 1);
      expect(stockMoveSign(StockMoveKind.adjustedDown), -1);
    });
  });

  group('a count can never go below zero', () {
    test('taking more off than is there is refused, not clamped', () {
      // A count is what the shop believes it has, and a negative count is a
      // belief that is certainly wrong. Clamping hides the discrepancy.
      final result = applyStockMove(2, _move(StockMoveKind.sold, quantity: 3));
      expect(result.allowed, isFalse);
      expect(result.refusal, StockRefusal.insufficientStock);
      expect(result.newCount, 2);
      expect(result.message, contains('not that much on the shelf'));
    });

    test('taking exactly what is there is allowed, down to zero', () {
      final result = applyStockMove(3, _move(StockMoveKind.sold, quantity: 3));
      expect(result.allowed, isTrue);
      expect(result.newCount, 0);
    });

    test('an empty shelf cannot be sold from at all', () {
      expect(
        applyStockMove(0, _move(StockMoveKind.sold, quantity: 1)).allowed,
        isFalse,
      );
    });
  });

  group('a movement has to be a movement', () {
    test('zero is a mistake, not a no-op', () {
      final result =
          applyStockMove(10, _move(StockMoveKind.received, quantity: 0));
      expect(result.refusal, StockRefusal.notAQuantity);
    });

    test('a negative quantity is refused — the kind carries the direction',
        () {
      expect(
        applyStockMove(10, _move(StockMoveKind.received, quantity: -5)).allowed,
        isFalse,
      );
    });

    test('an unexplained movement is refused', () {
      // "Why is the count three" has no answer if the lines do not say.
      final result =
          applyStockMove(10, _move(StockMoveKind.damaged, reason: '  '));
      expect(result.refusal, StockRefusal.noReason);
    });
  });

  test('a delivery goes on the shelf', () {
    expect(applyStockMove(10, _move(StockMoveKind.received)).newCount, 15);
  });

  group('the history should add up to the stored count', () {
    test('an empty history is zero', () {
      expect(countFromMovements(const []), 0);
    });

    test('ups and downs net out', () {
      expect(
        countFromMovements([
          _move(StockMoveKind.received, quantity: 50),
          _move(StockMoveKind.sold, quantity: 12),
          _move(StockMoveKind.damaged, quantity: 2),
          _move(StockMoveKind.returned, quantity: 1),
        ]),
        37,
      );
    });
  });

  group('a stock-take records the difference, not the new count', () {
    test('more on the shelf than recorded is an adjustment up', () {
      final move = stockTakeMovement(
        recorded: 3,
        counted: 5,
        reason: 'Counted 5',
      )!;
      expect(move.kind, StockMoveKind.adjustedUp);
      expect(move.quantity, 2);
    });

    test('fewer is an adjustment down', () {
      final move = stockTakeMovement(
        recorded: 5,
        counted: 3,
        reason: 'Counted 3',
      )!;
      expect(move.kind, StockMoveKind.adjustedDown);
      expect(move.quantity, 2);
    });

    test('a count that already matched records nothing', () {
      // A zero-quantity line in the history would look as though something
      // had moved.
      expect(
        stockTakeMovement(recorded: 5, counted: 5, reason: 'Counted 5'),
        isNull,
      );
    });

    test('counting zero against a recorded five is a real adjustment', () {
      final move =
          stockTakeMovement(recorded: 5, counted: 0, reason: 'None left')!;
      expect(move.kind, StockMoveKind.adjustedDown);
      expect(move.quantity, 5);
    });
  });

  group('reading a stored movement', () {
    test('a movement written here reads back the same', () {
      final move = StockMovement(
        kind: StockMoveKind.sold,
        quantity: 3,
        reason: 'Sold on s-1',
        reference: 's-1',
        at: DateTime.utc(2026, 3, 4, 10),
      );
      final back = StockMovement.fromMap(move.toMap());
      expect(back.kind, StockMoveKind.sold);
      expect(back.quantity, 3);
      expect(back.reference, 's-1');
      expect(back.at, DateTime.utc(2026, 3, 4, 10));
    });

    test('a quantity written as a string reads as a number', () {
      expect(StockMovement.fromMap({'quantity': '7'}).quantity, 7);
    });

    test('an unrecognised kind reads as a correction, not a sale', () {
      // It is the kind that claims least about why the count moved.
      expect(
        StockMovement.fromMap({'kind': 'teleported'}).kind,
        StockMoveKind.adjustedUp,
      );
    });

    test('an empty document does not throw', () {
      final move = StockMovement.fromMap(const {});
      expect(move.quantity, 0);
      expect(move.reason, '');
    });
  });

  test('every kind has a label, so a history line is never blank', () {
    for (final kind in StockMoveKind.values) {
      expect(kStockMoveLabels[kind], isNotNull);
    }
  });
}
