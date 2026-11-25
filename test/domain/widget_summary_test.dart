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
    expect(t['w_l_other'], '1 other');
    expect(t['w_v_other'], '₹300');
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
    expect(t['w_title'], "Today's sales · 6 bills");
    expect(t['w_v_upi'], '₹17,250');
    expect(t['w_l_cash'], 'Cash');
    expect(t['w_v_cash'], '₹11,200');
    // No other way of paying today: that column is left out.
    expect(t['w_v_other'], '');
    expect(t['w_late'], '2 late');
    expect(t['w_due'], '1 today');
    expect(t['w_owed'], 'Owed ₹4,900');
    expect(t['w_job_n'], '0');
    expect(t['w_jobs_empty'], 'No repairs waiting');
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
      expect(t['w_net'], 'Net ₹800');
      expect(t['w_spent'], 'Spent ₹200');
      expect(t['w_job0'], 'Samsung Galaxy M14 · Ramesh K');
      expect(t['w_job0_label'], '2d late');
      expect(t['w_stock'], '0 in stock · 0 low · 0 calls');
      expect(t['w_jobs_title'], 'Repairs · 1 in · 0 back');
      expect(t['w_v_rep'], '₹0');
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

  group('the repairs on the widget', () {
    ServiceOrder job(
      String id,
      String status, {
      Duration? promisedIn,
      String model = 'Redmi 12',
      DateTime? completedAt,
    }) => ServiceOrder(
      id: id,
      brand: 'Xiaomi',
      model: model,
      customerName: 'Cust $id',
      status: status,
      receivedAt: now.subtract(const Duration(days: 1)),
      expectedCompletionAt: promisedIn == null ? null : now.add(promisedIn),
      completedAt: completedAt,
    );

    test('next to give back first: late, then soonest; ready after; '
        'handed back never', () {
      final jobs = widgetJobs([
        job('later', 'In Progress', promisedIn: const Duration(days: 3)),
        job('soon', 'Pending', promisedIn: const Duration(hours: 3)),
        job('late', 'In Progress', promisedIn: const Duration(days: -2)),
        job('done', 'Completed', promisedIn: const Duration(hours: 1)),
        job('ready', 'Ready', promisedIn: const Duration(hours: 1)),
      ], now: now);
      expect(jobs.map((j) => j.id), ['late', 'soon', 'later']);
      final withReady = widgetJobs([
        job('soon', 'Pending', promisedIn: const Duration(hours: 3)),
        job('ready', 'Ready', promisedIn: const Duration(hours: 1)),
      ], now: now);
      expect(withReady.map((j) => j.id), ['soon', 'ready']);
      expect(withReady.last.ready, isTrue);
      expect(withReady.last.promised, isNull);
      expect(jobs.first.name, 'Xiaomi Redmi 12 · Cust late');
    });

    test('time left or late, in minutes, hours or days', () {
      String say(Duration d) => jobLabel(
        WidgetJob(id: 'x', name: 'x', promised: now.add(d)),
        lookupAppLocalizations(const Locale('en')),
        now,
      );
      expect(say(const Duration(minutes: 45)), '45m left');
      expect(say(const Duration(seconds: 20)), '1m left');
      expect(say(const Duration(hours: 3, minutes: 50)), '3h left');
      expect(say(const Duration(days: 2, hours: 5)), '2d left');
      expect(say(const Duration(hours: -5)), '5h late');
      expect(say(const Duration(days: -3)), '3d late');
      expect(
        jobLabel(
          const WidgetJob(id: 'r', name: 'r', ready: true),
          lookupAppLocalizations(const Locale('en')),
          now,
        ),
        'Ready',
      );
    });

    test('the chip colour: late, due today, a later day', () {
      // now is 3 pm.
      expect(
        countdown(now.add(const Duration(hours: 8)), now).$3,
        CountdownKind.today,
      );
      expect(
        countdown(now.add(const Duration(hours: 9)), now).$3,
        CountdownKind.later,
      );
      expect(
        countdown(now.subtract(const Duration(minutes: 1)), now).$3,
        CountdownKind.late,
      );
    });

    test('the words the phone uses to redo the sum, in every language', () {
      for (final lang in ['en', 'ta', 'hi']) {
        final t = widgetTexts(
          summarizeForWidget(
            sales: const [],
            orders: [
              job('a', 'In Progress', promisedIn: const Duration(hours: 2)),
            ],
            now: now,
            includeOwed: false,
          ),
          lookupAppLocalizations(Locale(lang)),
          locale: lang,
          at: now,
        );
        for (final k in ['w_u_m', 'w_u_h', 'w_u_d']) {
          expect(t[k], contains('{n}'), reason: '$lang $k');
          expect(t[k], isNot(contains('0')), reason: '$lang $k');
        }
        expect(t['w_t_left'], contains('{t}'), reason: lang);
        expect(t['w_t_late'], contains('{t}'), reason: lang);
        expect(t['w_job_n'], '1');
        expect(
          int.parse(t['w_job0_at']!),
          now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
        );
        expect(t['w_job0_id'], 'a');
        // Every key written is one the phone knows (and clears on sign-out).
        for (final k in t.keys) {
          expect(widgetKeys, contains(k), reason: k);
        }
      }
    });
  });
}
