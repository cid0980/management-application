import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/shop_widget.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/domain/dashboard/board.dart';
import 'package:fm_shop/domain/dashboard/widget_summary.dart';
import 'package:fm_shop/domain/expenses/expense.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);
  Sale bill(String id, num price, String method, {num? paid}) => Sale(
    id: id,
    status: SaleStatus.completed,
    items: [SaleItem(description: 'Case', unitPrice: price, quantity: 1)],
    paymentMethod: method,
    amountPaid: paid ?? price,
    completedAt: now,
    createdAt: now,
  );

  test('the widget shows what Home shows', () {
    final sales = [
      bill('a', 1000, 'UPI'),
      bill('b', 500, 'Cash'),
      bill('c', 300, 'Card'),
      bill('d', 700, 'Cash', paid: 200),
    ];
    final orders = [
      ServiceOrder(
        id: 'late',
        status: 'In Progress',
        expectedCompletionAt: now.subtract(const Duration(days: 2)),
      ),
      ServiceOrder(id: 'ready', status: 'Ready'),
    ];
    final w = summarizeForWidget(
      sales: sales,
      orders: orders,
      now: now,
      includeOwed: true,
    );
    expect(w.takings, takingsOn(sales, now));
    expect(w.bills, 4);
    expect(w.upi, 1000);
    expect(w.cash, 700);
    expect(w.other, 300);
    expect(w.late, 1);
    expect(w.ready, 1);
    expect(w.owed, 500);
    expect(w.otherMethods, 1);
    final t = widgetTexts(
      w,
      lookupAppLocalizations(const Locale('en')),
      locale: 'en',
      at: now,
    );
    // One other way of paying is "1 other", not "1 others".
    expect(t['w_split'], contains('1 other ₹300'));
  });

  test('staff: no money owed on the widget', () {
    final w = summarizeForWidget(
      sales: const [],
      orders: const [],
      now: now,
      includeOwed: false,
    );
    expect(w.owed, isNull);
    expect(w.takings, 0);
  });

  test('the widget says it in words: amounts, counts, owed only when owed', () {
    const s = WidgetSummary(
      takings: 28450,
      bills: 6,
      upi: 17250,
      cash: 11200,
      other: 0,
      late: 2,
      dueToday: 1,
      ready: 1,
      owed: 4900,
    );
    final t = widgetTexts(
      s,
      lookupAppLocalizations(const Locale('en')),
      locale: 'en',
      at: DateTime(2026, 11, 25, 15, 10),
    );
    expect(t['w_amount'], '₹28,450');
    expect(t['w_split'], 'UPI ₹17,250  ·  Cash ₹11,200  ·  6 bills');
    expect(t['w_late'], 'Late 2');
    expect(t['w_owed'], 'Customers owe ₹4,900');
    expect(t['w_updated']!.replaceAll('\u202f', ' '), '3:10 PM');
    final staff = widgetTexts(
      const WidgetSummary(
        takings: 0,
        bills: 0,
        upi: 0,
        cash: 0,
        other: 0,
        late: 0,
        dueToday: 0,
        ready: 0,
      ),
      lookupAppLocalizations(const Locale('ta')),
      locale: 'ta',
      at: DateTime(2026, 11, 25, 15, 10),
    );
    expect(staff['w_owed'], '');
    expect(staff['w_title'], isNot("Today's sales"));
  });

  test(
    'more lines: repairs, spent and net, the latest job, stock and calls',
    () {
      final orders = [
        ServiceOrder(
          id: 'late',
          orderNumber: 'SO-1',
          brand: 'Samsung',
          model: 'Galaxy M14',
          customerName: 'Ramesh K',
          status: 'In Progress',
          receivedAt: now,
          expectedCompletionAt: now.subtract(const Duration(days: 2)),
        ),
      ];
      final w = summarizeForWidget(
        sales: [bill('a', 1000, 'UPI')],
        orders: orders,
        now: now,
        includeOwed: false,
        expenses: [
          Expense(id: 'e', amount: 200, kind: 'Tea & food', spentAt: now),
        ],
        devices: const [],
        products: const [],
        enquiries: const [],
      );
      expect(w.takenIn, 1);
      expect(w.spent, 200);
      expect(w.net, 800);
      expect(w.lateJob, ('Samsung Galaxy M14', 'Ramesh K', 2));
      final t = widgetTexts(
        w,
        lookupAppLocalizations(const Locale('en')),
        locale: 'en',
        at: now,
      );
      expect(t['w_net'], 'Spent ₹200 · Net ₹800');
      expect(
        t['w_late_job'],
        'Most late: Samsung Galaxy M14 · Ramesh K · 2 days late',
      );
      expect(
        t['w_stock'],
        '0 phones in stock · 0 products low · 0 calls today',
      );
      expect(t['w_repairs'], contains('1 taken in'));
    },
  );

  test('the refresh button does not overwrite what it did not read', () {
    final w = summarizeForWidget(
      sales: const [],
      orders: const [],
      now: now,
      includeOwed: false,
    );
    final t = widgetTexts(
      w,
      lookupAppLocalizations(const Locale('en')),
      locale: 'en',
      at: now,
    );
    expect(t.containsKey('w_stock'), isFalse);
    expect(t.containsKey('w_net'), isFalse);
  });
}
