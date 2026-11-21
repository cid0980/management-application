import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/sale.dart';

void main() {
  group('an empty Paid box means paid in full', () {
    test('nothing typed: the whole bill is paid', () {
      expect(amountPaidFrom('', total: 350), 350);
      expect(amountPaidFrom('   ', total: 350), 350);
    });

    test('less what the wallet covered', () {
      expect(amountPaidFrom('', total: 1000, walletUsed: 200), 800);
      expect(amountPaidFrom('', total: 100, walletUsed: 200), 0);
    });

    test('0 typed is a credit sale, and a part payment stays a part payment',
        () {
      expect(amountPaidFrom('0', total: 350), 0);
      expect(amountPaidFrom('200', total: 350), 200);
    });
  });
}
