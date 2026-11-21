import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/due_payments.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

Sale _s(
  String id, {
  num total = 1000,
  num paid = 0,
  String method = 'Cash',
  SaleStatus status = SaleStatus.completed,
  String? customerId = 'c-1',
  String customerName = 'Ramesh K',
  String customerPhone = '9876543210',
  DateTime? completedAt,
}) =>
    Sale(
      id: id,
      invoiceNumber: 'INV-$id',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: [SaleItem(description: 'Handset', unitPrice: total)],
      paymentMethod: method,
      amountPaid: paid,
      status: status,
      completedAt: completedAt ?? DateTime(2026, 3, 1),
    );

void main() {
  group('a financed sale is never in Due Payments', () {
    test('however little was paid at the counter', () {
      // Customers were rung and chased for money they did not owe, over a
      // settlement the financier had not sent yet.
      final all = [_s('fin', method: 'Bajaj Finance', paid: 0)];
      expect(unpaidSales(all), isEmpty);
      expect(dueAccounts(all), isEmpty);
      expect(totalOutstanding(all), 0);
    });

    test('while a direct sale with the same numbers is', () {
      final all = [_s('cash', method: 'Cash', paid: 0)];
      expect(unpaidSales(all), hasLength(1));
      expect(totalOutstanding(all), 1000);
    });
  });

  group('only completed sales are debts', () {
    test('a draft never asked anyone for anything', () {
      expect(
        unpaidSales([_s('d', status: SaleStatus.draft, paid: 0)]),
        isEmpty,
      );
    });

    test('a cancelled bill is not a debt either', () {
      expect(
        unpaidSales([_s('c', status: SaleStatus.cancelled, paid: 0)]),
        isEmpty,
      );
    });

    test('a settled bill is not on the list', () {
      expect(unpaidSales([_s('p', total: 1000, paid: 1000)]), isEmpty);
    });
  });

  group('grouped by customer, not by bill', () {
    test('one customer with three bills is one row', () {
      // Ringing them three times is how the shop annoyed the people who
      // actually pay.
      final accounts = dueAccounts([
        _s('a', total: 1000, paid: 0),
        _s('b', total: 500, paid: 100),
        _s('c', total: 300, paid: 0),
      ]);
      expect(accounts, hasLength(1));
      expect(accounts.single.sales, hasLength(3));
      expect(accounts.single.outstanding, 1700);
    });

    test('most owed first', () {
      final accounts = dueAccounts([
        _s('small', customerId: 'c-1', total: 100, paid: 0),
        _s('big', customerId: 'c-2', customerName: 'Priya S',
            customerPhone: '9123456780', total: 5000, paid: 0),
      ]);
      expect(accounts.map((a) => a.customerId), ['c-2', 'c-1']);
    });

    test('a walk-in with no record is grouped by number', () {
      final accounts = dueAccounts([
        _s('a', customerId: null, customerName: '', total: 100, paid: 0),
        _s('b', customerId: null, customerName: '', total: 200, paid: 0),
      ]);
      expect(accounts, hasLength(1));
      expect(accounts.single.outstanding, 300);
      expect(accounts.single.customerId, isNull);
    });

    test('two different numbers are two accounts', () {
      final accounts = dueAccounts([
        _s('a', customerId: null, customerPhone: '9876543210', paid: 0),
        _s('b', customerId: null, customerPhone: '9123456780', paid: 0),
      ]);
      expect(accounts, hasLength(2));
    });

    test('bills are newest first, and the age comes off the oldest', () {
      final accounts = dueAccounts([
        _s('old', total: 100, paid: 0, completedAt: DateTime(2026, 1, 1)),
        _s('new', total: 100, paid: 0, completedAt: DateTime(2026, 3, 1)),
      ]);
      expect(accounts.single.sales.map((s) => s.id), ['new', 'old']);
      expect(accounts.single.oldestUnpaid, DateTime(2026, 1, 1));
      expect(
        accounts.single.daysOutstanding(DateTime(2026, 1, 31)),
        30,
      );
    });
  });

  group('collecting is admin only, and never more than is owed', () {
    final sale = _s('a', total: 1000, paid: 400);

    test('staff may not collect', () {
      final check = canCollect(sale, 600, isAdmin: false);
      expect(check.isAllowed, isFalse);
      expect(check.refusal, CollectionRefusal.notAdmin);
    });

    test('an admin may, and a part payment is fine', () {
      final check = canCollect(sale, 200, isAdmin: true);
      expect(check.isAllowed, isTrue);
      expect(check.remaining, 400);
    });

    test('collecting the lot settles it', () {
      expect(canCollect(sale, 600, isAdmin: true).remaining, 0);
    });

    test('more than is owed is refused — the extra belongs in the wallet', () {
      final check = canCollect(sale, 900, isAdmin: true);
      expect(check.isAllowed, isFalse);
      expect(check.refusal, CollectionRefusal.overpayment);
      expect(check.message, contains('wallet'));
    });

    test('zero and nonsense are refused', () {
      expect(canCollect(sale, 0, isAdmin: true).refusal,
          CollectionRefusal.notAnAmount);
      expect(canCollect(sale, '', isAdmin: true).refusal,
          CollectionRefusal.notAnAmount);
      expect(canCollect(sale, -100, isAdmin: true).refusal,
          CollectionRefusal.notAnAmount);
    });

    test('an amount typed with a comma is read', () {
      expect(canCollect(_s('a', total: 5000, paid: 0), '1,500', isAdmin: true)
          .isAllowed, isTrue);
    });

    test('nothing owed, nothing to collect', () {
      final settled = _s('a', total: 1000, paid: 1000);
      expect(canCollect(settled, 100, isAdmin: true).refusal,
          CollectionRefusal.nothingOwed);
    });

    test('a financed bill has nothing to collect from the customer', () {
      final financed = _s('a', method: 'Bajaj Finance', paid: 0);
      expect(canCollect(financed, 100, isAdmin: true).refusal,
          CollectionRefusal.nothingOwed);
    });
  });
}
