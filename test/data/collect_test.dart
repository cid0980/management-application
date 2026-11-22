import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

void main() {
  test('collecting a balance records how much, how, and when', () async {
    final store = InMemorySalesStore(
      seed: [
        Sale(
          id: 's1',
          status: SaleStatus.completed,
          amountPaid: 400,
          completedAt: DateTime(2026, 11, 15),
          items: const [SaleItem(description: 'x', unitPrice: 1000)],
        ),
      ],
      stock: InMemorySecondHandStore(seed: const []),
      products: InMemoryProductStore(seed: const []),
      customers: InMemoryCustomerStore(seed: const []),
    );
    final check = await store.collect('s1', 600, isAdmin: true, method: 'UPI');
    expect(check.isAllowed, isTrue);
    final sale = store.byId('s1')!;
    expect(sale.amountPaid, 1000);
    expect(sale.balanceDue, 0);
    expect(sale.collections.single.amount, 600);
    expect(sale.collections.single.method, 'UPI');
    expect(sale.collections.single.at, isNotNull);
    // And it survives the document.
    expect(Sale.fromMap('s1', sale.toMap()).collections.single.method, 'UPI');
  });
}
