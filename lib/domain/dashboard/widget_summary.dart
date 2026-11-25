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
import '../service/order_state.dart';
import '../service/service_order.dart';
import 'board.dart';
import '../enquiries/enquiry.dart';
import '../enquiries/enquiry_list.dart';
import '../expenses/expense.dart';
import '../inventory/second_hand_device.dart';
import '../products/product.dart';
import '../products/product_list.dart';

/// One repair on the widget: what it is, whose, and when it was promised
/// (null once it is ready — then it only waits for the customer).
class WidgetJob {
  const WidgetJob({
    required this.id,
    required this.name,
    this.promised,
    this.ready = false,
  });

  final String id;
  final String name;
  final DateTime? promised;
  final bool ready;
}

/// The repairs the widget lists: those still being worked on, the one
/// promised soonest first (so the latest-overdue comes first), then the
/// ones ready and waiting, the longest-waiting first. At most [max].
List<WidgetJob> widgetJobs(
  Iterable<ServiceOrder> orders, {
  required DateTime now,
  int max = 3,
}) {
  String name(ServiceOrder o) {
    final what = o.device.isEmpty ? o.orderNumber : o.device;
    final who = o.customerName.trim().isNotEmpty
        ? o.customerName.trim()
        : o.customerPhone;
    return [what, who].where((p) => p.isNotEmpty).join(' · ');
  }

  final open =
      orders
          .where(
            (o) =>
                !isClosed(o.status) &&
                !isReady(o.status) &&
                o.expectedCompletionAt != null,
          )
          .toList()
        ..sort(
          (a, b) => a.expectedCompletionAt!.compareTo(b.expectedCompletionAt!),
        );
  final ready = benchQueues(orders, now: now)[BenchKind.ready]!;
  return [
    for (final o in open)
      WidgetJob(id: o.id, name: name(o), promised: o.expectedCompletionAt),
    for (final o in ready) WidgetJob(id: o.id, name: name(o), ready: true),
  ].take(max).toList();
}

/// How long until a promised time, or how long past it, in the widget's
/// short words: 45m, 3h, 2d. The phone redraws the widget every half hour
/// and works this out again then (ShopWidgetProvider.kt does the same
/// sum), so the words never stay stuck at the time the app last wrote them.
enum CountdownKind { late, today, later }

(int amount, String unit, CountdownKind kind) countdown(
  DateTime promised,
  DateTime now,
) {
  final diff = promised.difference(now);
  final mins = diff.inMinutes.abs();
  final (int n, String unit) = mins < 60
      ? (mins < 1 ? 1 : mins, 'm')
      : mins < 24 * 60
      ? (mins ~/ 60, 'h')
      : (mins ~/ (24 * 60), 'd');
  final endOfToday = DateTime(now.year, now.month, now.day + 1);
  final kind = diff.isNegative
      ? CountdownKind.late
      : promised.isBefore(endOfToday)
      ? CountdownKind.today
      : CountdownKind.later;
  return (n, unit, kind);
}

class WidgetSummary {
  const WidgetSummary({
    this.jobs = const [],
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
    this.repairsCollected = 0,
    this.handedBack = 0,
    this.takenIn = 0,
    this.spent,
    this.lateJob,
    this.phonesInStock,
    this.lowStock,
    this.callsToday,
  });

  /// The repairs to give back, next first.
  final List<WidgetJob> jobs;

  /// Repair money taken today (advances and pickups) — not in [takings].
  final num repairsCollected;

  /// Phones handed back today; phones taken in today.
  final int handedBack;
  final int takenIn;

  /// Expenses written today; null when they could not be read here.
  final num? spent;

  /// The latest-promised job still in the shop: phone, customer, days late.
  final (String device, String customer, int days)? lateJob;

  /// Null when this run could not count them (the refresh button only
  /// reads bills, repairs and expenses — the rest keep what the app wrote).
  final int? phonesInStock;
  final int? lowStock;
  final int? callsToday;

  /// Bills and repair money, less what was spent; null without [spent].
  num? get net => spent == null ? null : takings + repairsCollected - spent!;

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
  Iterable<Expense>? expenses,
  Iterable<SecondHandDevice>? devices,
  Iterable<Product>? products,
  Iterable<Enquiry>? enquiries,
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
  final late = queues[BenchKind.late]!;
  final worst = late.isEmpty
      ? null
      : (late.toList()
              ..sort((a, b) => daysLate(b, now).compareTo(daysLate(a, now))))
            .first;
  return WidgetSummary(
    jobs: widgetJobs(orders, now: now),
    repairsCollected: repairTakingsOn(orders, now),
    handedBack: orders
        .where((o) => o.status == 'Completed' && isSameDay(o.completedAt, now))
        .length,
    takenIn: orders.where((o) => isSameDay(o.receivedAt, now)).length,
    spent: expenses == null
        ? null
        : summarizeExpenses(expenses, DateRange.day(now)).total,
    lateJob: worst == null
        ? null
        : (
            worst.device.isEmpty ? worst.title : worst.device,
            worst.customerName.trim().isNotEmpty
                ? worst.customerName.trim()
                : worst.customerPhone,
            daysLate(worst, now),
          ),
    phonesInStock: devices?.where((d) => d.isSellable).length,
    lowStock: products == null ? null : lowStockAlerts(products).length,
    callsToday: enquiries == null
        ? null
        : enquiryCallList(enquiries, now: now).length,
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
