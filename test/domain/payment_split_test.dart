import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/reports/sales_breakdown.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

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
}
