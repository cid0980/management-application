import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/products/stock_movement.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  test("a part's cost counts in the job's costs and profit", () {
    const job = ServiceOrder(
      id: 'o',
      estimatedPrice: 2500,
      rawMaterialCost: 100,
      partsUsed: [
        PartUse(productId: 'p', name: 'Battery', quantity: 1, unitCost: 900),
      ],
    );
    expect(job.partsCost, 900);
    expect(job.costs, 1000);
    expect(job.estimatedProfit, 1500);
  });

  test('parts round-trip, and old jobs read as none', () {
    const job = ServiceOrder(
      id: 'o',
      partsUsed: [
        PartUse(productId: 'p', name: 'Display', quantity: 2, unitCost: 1500),
      ],
    );
    final back = ServiceOrder.fromMap('o', job.toMap());
    expect(back.partsUsed.single.quantity, 2);
    expect(back.partsCost, 3000);
    expect(ServiceOrder.fromMap('o', const {}).partsUsed, isEmpty);
  });

  test('used on a repair takes stock off the shelf', () {
    expect(stockMoveSign(StockMoveKind.usedOnRepair), -1);
  });
}
