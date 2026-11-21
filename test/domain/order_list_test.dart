import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/order_list.dart';
import 'package:fm_shop/domain/service/service_order.dart';

final _now = DateTime(2026, 3, 4, 12);

ServiceOrder _o(
  String id, {
  String status = 'In Progress',
  DateTime? expected,
  DateTime? completedAt,
  String customerName = '',
  num? finalPrice,
}) =>
    ServiceOrder(
      id: id,
      orderNumber: 'SO-$id',
      customerName: customerName,
      brand: 'Samsung',
      model: 'Galaxy M14',
      status: status,
      finalPrice: finalPrice,
      receivedAt: DateTime(2026, 3, 1),
      expectedCompletionAt: expected,
      completedAt: completedAt,
    );

void main() {
  group('ordering', () {
    test('promised soonest first — that is the order the work is done in', () {
      final rows = orderRows([
        _o('late', expected: DateTime(2026, 3, 10)),
        _o('soon', expected: DateTime(2026, 3, 5)),
      ], tab: 'Open', now: _now);
      expect(rows.map((r) => r.id), ['soon', 'late']);
    });

    test('an undated order sorts last: incomplete, not urgent', () {
      final rows = orderRows([
        _o('undated'),
        _o('dated', expected: DateTime(2026, 3, 10)),
      ], tab: 'Open', now: _now);
      expect(rows.map((r) => r.id), ['dated', 'undated']);
    });

    test('history reads newest first', () {
      final rows = orderRows([
        _o('old',
            status: 'Completed',
            expected: DateTime(2026, 1, 1),
            completedAt: DateTime(2026, 1, 2)),
        _o('recent',
            status: 'Completed',
            expected: DateTime(2026, 2, 1),
            completedAt: DateTime(2026, 2, 2)),
      ], tab: 'Completed', now: _now);
      expect(rows.map((r) => r.id), ['recent', 'old']);
    });
  });

  group('tabs read the derived state', () {
    final all = [
      _o('overdue', expected: DateTime(2026, 3, 2)),
      _o('today', expected: DateTime(2026, 3, 4, 18)),
      _o('later', expected: DateTime(2026, 3, 10)),
      _o('done',
          status: 'Completed',
          expected: DateTime(2026, 1, 1),
          completedAt: DateTime(2026, 1, 2),
          finalPrice: 1800),
      _o('returned', status: 'Returned', expected: DateTime(2026, 1, 1)),
      _o('unknown', status: 'Waiting For Spare', expected: DateTime(2026, 3, 9)),
    ];

    test('Open is everything still in the shop, unknown statuses included', () {
      expect(
        orderRows(all, tab: 'Open', now: _now).map((r) => r.id),
        ['overdue', 'today', 'unknown', 'later'],
      );
    });

    test('a job finished in January is not in Overdue', () {
      expect(
        orderRows(all, tab: 'Overdue', now: _now).map((r) => r.id),
        ['overdue'],
      );
    });

    test('Due Today is the promised day', () {
      expect(
        orderRows(all, tab: 'Due Today', now: _now).map((r) => r.id),
        ['today'],
      );
    });

    test('a status tab is an exact status, including an unrecognised one', () {
      expect(
        orderRows(all, tab: 'In Progress', now: _now).map((r) => r.id),
        ['overdue', 'today', 'later'],
      );
      // The unknown status has no tab of its own, so All is where it is found.
      expect(orderRows(all, tab: 'All', now: _now), hasLength(6));
    });

    test('counts are against the same query the list is showing', () {
      final counts = orderTabCounts(all, query: 'SO-overdue', now: _now);
      expect(counts['All'], 1);
      expect(counts['Overdue'], 1);
      expect(counts['Open'], 1);
      expect(counts['Completed'], 0);
    });

    test('with no query, the counts cover everything', () {
      final counts = orderTabCounts(all, now: _now);
      expect(counts['All'], 6);
      expect(counts['Open'], 4);
      expect(counts['Completed'], 1);
      expect(counts['Returned'], 1);
    });
  });

  group('the dashboard alerts', () {
    test('overdue and due today, and nothing finished', () {
      final alerts = serviceAlerts([
        _o('overdue', expected: DateTime(2026, 3, 2)),
        _o('today', expected: DateTime(2026, 3, 4, 18)),
        _o('later', expected: DateTime(2026, 3, 10)),
        _o('done', status: 'Completed', expected: DateTime(2026, 1, 1)),
      ], now: _now);
      expect(alerts.overdue.map((o) => o.id), ['overdue']);
      expect(alerts.dueToday.map((o) => o.id), ['today']);
      expect(alerts.any, isTrue);
    });

    test('a quiet shop has no alerts', () {
      final alerts = serviceAlerts([
        _o('later', expected: DateTime(2026, 3, 10)),
      ], now: _now);
      expect(alerts.any, isFalse);
    });
  });

  group('revenue, not what is outstanding', () {
    test('only closed orders that were actually charged', () {
      expect(
        serviceRevenue([
          _o('done', status: 'Completed', finalPrice: 1800),
          _o('also', status: 'Returned', finalPrice: 200),
          // A quote is not revenue: counting quotes is how a month looked
          // profitable before any of the work was done.
          _o('open', expected: DateTime(2026, 3, 10)),
          _o('closed_unpaid', status: 'Completed'),
        ]),
        2000,
      );
    });

    test('a shop that has finished nothing has no revenue', () {
      expect(serviceRevenue([_o('open')]), 0);
      expect(serviceRevenue(const []), 0);
    });
  });
}
