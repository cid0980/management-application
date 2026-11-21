import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/payment_methods.dart';

void main() {
  test('a financed sale leaves the customer owing nothing', () {
    // The customer paid a 2,000 down payment on a 20,000 handset; the
    // financier owes the rest, and that is a different ledger.
    expect(
        balanceDueFor(total: 20000, paid: 2000, method: 'Bajaj Finance'), 0);
  });

  test('paying short in cash leaves a balance', () {
    expect(balanceDueFor(total: 20000, paid: 15000, method: 'Cash'), 5000);
  });

  test('overpaying is not a negative balance', () {
    expect(balanceDueFor(total: 1000, paid: 1200, method: 'UPI'), 0);
  });

  test('finance providers are finance, direct methods are not', () {
    expect(isFinanceMethod('TVS Credit'), isTrue);
    expect(isFinanceMethod('Split'), isFalse);
    expect(isFinanceMethod(null), isFalse);
  });
}
