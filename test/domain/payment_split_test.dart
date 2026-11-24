import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/reports/sales_breakdown.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';

Sale _bill(
  String id,
  String method,
  num price, {
  num paid = -1,
  num wallet = 0,
  SaleStatus status = SaleStatus.completed,
  DateTime? at,
}) => Sale(
  id: id,
  status: status,
  paymentMethod: method,
  amountPaid: paid < 0 ? price - wallet : paid,
  walletUsed: wallet,
  completedAt: at ?? DateTime(2026, 11, 22, 11),
  items: [SaleItem(description: 'x', unitPrice: price)],
);

void main() {
  final today = DateRange(DateTime(2026, 11, 22), DateTime(2026, 11, 22));

  test('the drawer is counted against Cash, the bank against UPI', () {
    final s = paymentSplit([
      _bill('a', 'Cash', 350),
      _bill('b', 'Cash', 500),
      _bill('c', 'UPI', 32000),
    ], today);
    expect(s.methods.map((m) => m.method), ['UPI', 'Cash']);
    expect(s.methods.last.collected, 850);
    expect(s.methods.last.bills, 2);
  });

  test('a part payment counts what came in, and the rest is owed', () {
    final s = paymentSplit([_bill('a', 'Cash', 1000, paid: 400)], today);
    expect(s.methods.single.collected, 400);
    expect(s.owed, 600);
  });

  test('a financed bill is the financier\'s, not owed by the customer', () {
    final s = paymentSplit([_bill('a', 'Bajaj Finance', 20000, paid: 0)],
        today);
    expect(s.methods.single.collected, 20000);
    expect(s.owed, 0);
  });

  test('wallet credit is shown apart: it is no new money', () {
    final s = paymentSplit([_bill('a', 'Cash', 1000, wallet: 200)], today);
    expect(s.methods.single.collected, 800);
    expect(s.wallet, 200);
  });

  test('drafts, cancelled bills and other days are left out', () {
    final s = paymentSplit([
      _bill('a', 'Cash', 100, status: SaleStatus.draft),
      _bill('b', 'Cash', 100, status: SaleStatus.cancelled),
      _bill('c', 'Cash', 100, at: DateTime(2026, 11, 21)),
    ], today);
    expect(s.isEmpty, isTrue);
  });

  test('a balance collected later counts on its own day, by its own method',
      () {
    final lastWeek = DateTime(2026, 11, 15, 11);
    final bill = Sale(
      id: 'b',
      status: SaleStatus.completed,
      paymentMethod: 'Cash',
      // 400 at the counter last week, 600 by UPI today.
      amountPaid: 1000,
      completedAt: lastWeek,
      items: const [SaleItem(description: 'x', unitPrice: 1000)],
      collections: [
        Collection(amount: 600, method: 'UPI', at: DateTime(2026, 11, 22, 10)),
      ],
    );
    final todaySplit = paymentSplit([bill], today);
    expect(todaySplit.methods.single.method, 'UPI');
    expect(todaySplit.methods.single.collected, 600);
    // A payment of its own, counted as one.
    expect(todaySplit.methods.single.bills, 1);

    final thatDay = paymentSplit(
      [bill],
      DateRange(DateTime(2026, 11, 15), DateTime(2026, 11, 15)),
    );
    expect(thatDay.methods.single.method, 'Cash');
    expect(thatDay.methods.single.collected, 400);
  });

  test('repairs count too: the advance on intake day, the rest at pickup', () {
    final repair = ServiceOrder(
      id: 'r',
      advancePaid: 500,
      advanceMethod: 'UPI',
      receivedAt: DateTime(2026, 11, 20, 10),
      pickupPayment: Collection(
        amount: 1300,
        method: 'Cash',
        at: DateTime(2026, 11, 22, 17),
      ),
    );
    final onPickupDay = paymentSplit(const [], today, orders: [repair]);
    expect(onPickupDay.methods.single.method, 'Cash');
    expect(onPickupDay.methods.single.collected, 1300);
    final onIntakeDay = paymentSplit(
      const [],
      DateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 20)),
      orders: [repair],
    );
    expect(onIntakeDay.methods.single.method, 'UPI');
    expect(onIntakeDay.methods.single.collected, 500);
  });
}
