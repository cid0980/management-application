import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/reports/sales_breakdown.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

/// The cases from the 23 Nov phone test, as the rule that fixes them.
void main() {
  group('what a bill records as paid', () {
    test('Rs 9,999 handed over for a Rs 750 bill records 750 (FM #1)', () {
      final p = settleBill(total: 750, method: 'Cash', typed: '9999');
      expect(p.amountPaid, 750);
      expect(p.paidBy, {'Cash': 750});
      expect(p.change, 9249);
    });

    test('wallet 100 + empty box pays a 300 bill in full (FM #2)', () {
      final p = settleBill(total: 300, method: 'Cash', typed: '', wallet: 100);
      expect(p.amountPaid, 300);
      expect(p.paidBy, {'Cash': 200});
      expect(p.change, 0);
    });

    test('0 typed is a credit sale, recorded under no method (FM #30)', () {
      final p = settleBill(total: 300, method: 'Cash', typed: '0');
      expect(p.amountPaid, 0);
      expect(p.paidBy, isEmpty);
    });

    test('Split adds each way; change comes out of cash (FM #5)', () {
      final p = settleBill(
        total: 444,
        method: 'Split',
        typed: '',
        splitTyped: const {'Cash': '300', 'UPI': '200', 'Card': ''},
      );
      expect(p.amountPaid, 444);
      expect(p.paidBy, {'Cash': 244, 'UPI': 200});
      expect(p.change, 56);
    });

    test('a finance down payment is counter money (FM #6)', () {
      final p = settleBill(
        total: 555,
        method: 'Bajaj Finance',
        typed: '100',
        downPaymentMethod: 'UPI',
      );
      expect(p.amountPaid, 100);
      expect(p.paidBy, {'UPI': 100});
      // Empty: no down payment at all.
      final none = settleBill(total: 555, method: 'Bajaj Finance', typed: '');
      expect(none.amountPaid, 0);
      expect(none.paidBy, isEmpty);
    });
  });

  group('Reports read it', () {
    final day = DateRange.day(DateTime(2026, 11, 23));
    Sale bill(String method, num total, BillPayment p, {num wallet = 0}) =>
        Sale(
          id: method,
          status: SaleStatus.completed,
          paymentMethod: method,
          items: [SaleItem(description: 'x', unitPrice: total)],
          amountPaid: p.amountPaid,
          paidBy: p.paidBy,
          walletUsed: wallet,
          completedAt: DateTime(2026, 11, 23, 11),
        );
    num row(PaymentSplit s, String m) => s.methods
        .where((x) => x.method == m)
        .fold<num>(0, (a, b) => a + b.collected);

    test('over-payment adds only the bill to Cash', () {
      final s = paymentSplit([
        bill(
          'Cash',
          750,
          settleBill(total: 750, method: 'Cash', typed: '9999'),
        ),
      ], day);
      expect(row(s, 'Cash'), 750);
    });

    test('split cash is in the Cash row; finance down payment too', () {
      final s = paymentSplit([
        bill(
          'Split',
          444,
          settleBill(
            total: 444,
            method: 'Split',
            typed: '',
            splitTyped: const {'Cash': '244', 'UPI': '200'},
          ),
        ),
        bill(
          'Bajaj Finance',
          555,
          settleBill(total: 555, method: 'Bajaj Finance', typed: '100'),
        ),
      ], day);
      expect(row(s, 'Cash'), 344);
      expect(row(s, 'UPI'), 200);
      expect(row(s, 'Bajaj Finance'), 455);
      expect(row(s, 'Split'), 0);
    });

    test('wallet money is not counted as cash', () {
      final s = paymentSplit([
        bill(
          'Cash',
          300,
          settleBill(total: 300, method: 'Cash', typed: '', wallet: 100),
          wallet: 100,
        ),
      ], day);
      expect(row(s, 'Cash'), 200);
      expect(s.wallet, 100);
      expect(s.owed, 0);
    });
  });

  test('a cancelled bill: its money stays on its day, the refund comes off '
      'on the day it went back (FM #10)', () {
    final sold = DateTime(2026, 11, 20, 11);
    final back = DateTime(2026, 11, 23, 12);
    final bill = Sale(
      id: 'c',
      status: SaleStatus.cancelled,
      paymentMethod: 'Cash',
      items: const [SaleItem(description: 'x', unitPrice: 500)],
      amountPaid: 500,
      paidBy: const {'Cash': 500},
      completedAt: sold,
      refund: Collection(amount: 500, method: 'Cash', at: back),
    );
    num cash(DateTime d) => paymentSplit([bill], DateRange.day(d)).methods
        .where((m) => m.method == 'Cash')
        .fold<num>(0, (a, b) => a + b.collected);
    expect(cash(sold), 500);
    expect(cash(back), -500);
  });
}
