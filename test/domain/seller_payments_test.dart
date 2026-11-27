import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/reports/seller_payments.dart';

void main() {
  final day = DateTime(2026, 11, 20, 11);
  SecondHandDevice phone({List<SellerPayment>? paid}) => SecondHandDevice(
    id: 'p',
    brand: 'Vivo',
    model: 'Y20',
    purchasePrice: 8000,
    purchasedAt: day,
    sellerPayments: paid,
  );

  test('an old record was paid in full, in cash, the day it was bought', () {
    final d = phone();
    expect(d.paidToSeller, 8000);
    expect(d.owedToSeller, 0);
  });

  test('an advance leaves the rest owed, and paying it clears it', () {
    final d = phone(
      paid: [SellerPayment(amount: 3000, method: 'UPI', at: day)],
    );
    expect(d.owedToSeller, 5000);
    final later = d.copyWith(
      sellerPayments: [
        ...d.paymentsToSeller,
        SellerPayment(
          amount: 5000,
          method: 'Cash',
          at: day.add(const Duration(days: 3)),
        ),
      ],
    );
    expect(later.owedToSeller, 0);
  });

  test('round-trips through a document', () {
    final d = phone(
      paid: [SellerPayment(amount: 3000, method: 'UPI', at: day)],
    );
    final back = SecondHandDevice.fromMap('p', d.toMap());
    expect(back.paidToSeller, 3000);
    expect(back.paymentsToSeller.single.method, 'UPI');
  });

  test('reports: each payment on its own day, cash apart', () {
    final d = phone(
      paid: [
        SellerPayment(amount: 3000, method: 'UPI', at: day),
        SellerPayment(
          amount: 5000,
          method: 'Cash',
          at: day.add(const Duration(days: 3)),
        ),
      ],
    );
    final first = sellerPaymentsIn([d], DateRange.day(day));
    expect(first.total, 3000);
    expect(first.cash, 0);
    final later = sellerPaymentsIn([
      d,
    ], DateRange.day(day.add(const Duration(days: 3))));
    expect(later.total, 5000);
    expect(later.cash, 5000);
  });
}
