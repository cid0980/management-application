/// THE PHONE'S HOME-SCREEN WIDGET: WHAT IT SHOWS
///
/// The same figures as Home, worked out by the same functions, so the widget
/// on the phone's home screen and the app never disagree: today's sales and
/// how many bills, how the money came in (UPI, cash, the rest), the repairs
/// that are late, due today and ready, and what customers owe (owners only,
/// as on Home).
library;

import '../common/dates.dart';
import '../reports/sales_breakdown.dart';
import '../sales/due_payments.dart';
import '../sales/sale.dart';
import '../service/service_order.dart';
import 'board.dart';

class WidgetSummary {
  const WidgetSummary({
    required this.takings,
    required this.bills,
    required this.upi,
    required this.cash,
    required this.other,
    this.otherMethods = 0,
    required this.late,
    required this.dueToday,
    required this.ready,
    this.owed,
  });

  final num takings;
  final int bills;
  final num upi;
  final num cash;

  /// Card, finance and every other way, together.
  final num other;

  /// How many ways make up [other].
  final int otherMethods;
  final int late;
  final int dueToday;
  final int ready;

  /// Null when the person may not see money owed.
  final num? owed;
}

WidgetSummary summarizeForWidget({
  required Iterable<Sale> sales,
  required Iterable<ServiceOrder> orders,
  required DateTime now,
  required bool includeOwed,
}) {
  final split = paymentSplit(sales, DateRange.day(now), orders: orders);
  num upi = 0, cash = 0, other = 0;
  var others = 0;
  for (final m in split.methods) {
    switch (m.method.toLowerCase()) {
      case 'upi':
        upi += m.collected;
      case 'cash':
        cash += m.collected;
      default:
        other += m.collected;
        others++;
    }
  }
  final queues = benchQueues(orders, now: now);
  return WidgetSummary(
    takings: takingsOn(sales, now),
    bills: billsOn(sales, now),
    upi: upi,
    cash: cash,
    other: other,
    otherMethods: others,
    late: queues[BenchKind.late]!.length,
    dueToday: queues[BenchKind.dueToday]!.length,
    ready: queues[BenchKind.ready]!.length,
    owed: includeOwed ? totalOutstanding(sales) : null,
  );
}
