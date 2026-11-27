import '../common/dates.dart';
import '../common/money.dart';
import '../inventory/second_hand_device.dart';

/// What was handed to the sellers of bought phones in a period: every
/// advance and balance on the day it was paid, cash apart so the drawer
/// figure is right.
class SellerPaymentsSummary {
  const SellerPaymentsSummary({this.total = 0, this.cash = 0});

  final num total;
  final num cash;
}

SellerPaymentsSummary sellerPaymentsIn(
  Iterable<SecondHandDevice> stock,
  DateRange range,
) {
  num total = 0;
  num cash = 0;
  for (final d in stock) {
    for (final p in d.paymentsToSeller) {
      if (!range.contains(p.at)) continue;
      total += p.amount;
      if (p.method == 'Cash') cash += p.amount;
    }
  }
  return SellerPaymentsSummary(
    total: roundMoney(total),
    cash: roundMoney(cash),
  );
}
