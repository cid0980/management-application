import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/purchase_costing.dart';

void main() {
  group('amounts off a form', () {
    test('a text field keeps its commas and its rupee sign', () {
      expect(asAmount('1,400'), 1400);
      expect(asAmount('₹1400'), 1400);
      expect(asAmount('1400.50'), 1400.5);
    });

    test('a blank cost field is nothing spent, not a broken margin', () {
      expect(asAmount(''), 0);
      expect(asAmount(null), 0);
      expect(asAmount('abc'), 0);
    });
  });

  test('repairs are in the cost, which is the whole point of costing them here',
      () {
    final costing = costingOf(
      purchasePrice: 6200,
      repairs: const [
        RepairCost(description: 'Display', amount: 2400),
        RepairCost(description: 'Battery', amount: 650),
      ],
      otherCost: 150,
      askingPrice: 11500,
    );
    expect(costing.repairTotal, 3050);
    expect(costing.totalCost, 9400);
    expect(costing.expectedProfit, 2100);
  });

  group('a device still in stock has no realised profit', () {
    test('null, not zero', () {
      final costing = costingOf(purchasePrice: 6000, askingPrice: 9000);
      expect(costing.realisedProfit, isNull);
    });

    test('a sold device realises against what it actually went out at', () {
      final costing = costingOf(
        purchasePrice: 19000,
        askingPrice: 25000,
        soldPrice: 24000,
      );
      expect(costing.expectedProfit, 6000);
      expect(costing.realisedProfit, 5000);
    });

    test('given away for nothing is a realised loss, not an unsold device', () {
      final costing = costingOf(purchasePrice: 5000, soldPrice: 0);
      expect(costing.realisedProfit, -5000);
    });
  });

  group('margin', () {
    test('no asking price means no margin to compute', () {
      expect(costingOf(purchasePrice: 5000).expectedMargin, isNull);
      expect(costingOf(purchasePrice: 5000).atALoss, isFalse);
    });

    test('priced at or below cost is flagged, not refused', () {
      final costing = costingOf(
        purchasePrice: 9000,
        repairs: const [RepairCost(description: 'Display', amount: 1000)],
        askingPrice: 9500,
      );
      expect(costing.atALoss, isTrue);
      expect(costing.expectedProfit, -500);
    });

    test('a healthy margin is a fraction of the asking price', () {
      final costing = costingOf(purchasePrice: 7500, askingPrice: 10000);
      expect(costing.expectedMargin, 0.25);
    });
  });
}
