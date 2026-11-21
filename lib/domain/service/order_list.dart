/// THE SERVICE LIST'S OWN RULES
///
/// Which tab an order belongs in comes from `order_state.dart`, which already
/// knows that closed beats overdue. This adds the ordering and the counts.
///
/// `now` is passed in, never read here, so "overdue" means the same thing in a
/// test as it does at the counter.
library;

import 'order_state.dart';
import 'service_order.dart';

/// The rows for a tab and a search box.
///
/// Promised soonest first, because that is the order the work has to be done
/// in. An order with no promised date sorts last: it is incomplete, not
/// urgent — and `validateOrder` will not let a new one be saved without one.
///
/// Closed tabs are the exception: those are history, and history reads newest
/// first.
List<ServiceOrder> orderRows(
  Iterable<ServiceOrder> all, {
  String tab = 'Open',
  String? query,
  required DateTime now,
}) {
  final rows = all
      .where((o) => matchesTab(o.asState, tab, now: now) && o.matches(query))
      .toList();

  final history = tab == 'Completed' || tab == 'Returned';
  rows.sort((a, b) {
    if (history) {
      final x = a.completedAt ?? a.updatedAt ?? a.receivedAt;
      final y = b.completedAt ?? b.updatedAt ?? b.receivedAt;
      return _compareDates(y, x, a.title, b.title);
    }
    return _compareDates(
      a.expectedCompletionAt,
      b.expectedCompletionAt,
      a.title,
      b.title,
    );
  });
  return rows;
}

/// Nulls last whichever way round the comparison is, so an undated row never
/// jumps to the top of a list people work down.
int _compareDates(DateTime? x, DateTime? y, String xTitle, String yTitle) {
  if (x == null && y == null) return xTitle.compareTo(yTitle);
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// How many orders each tab holds for the current search.
///
/// Against the same query the list is showing. A badge of 40 over an empty tab
/// is how staff conclude the app is broken.
Map<String, int> orderTabCounts(
  Iterable<ServiceOrder> all, {
  String? query,
  required DateTime now,
}) {
  final counts = {for (final t in kTabs) t: 0};
  for (final o in all) {
    if (!o.matches(query)) continue;
    for (final t in kTabs) {
      if (matchesTab(o.asState, t, now: now)) counts[t] = counts[t]! + 1;
    }
  }
  return counts;
}

/// The alert rows the dashboard opens with: what is already late, and what is
/// promised today. Overdue first — a customer is already waiting.
class ServiceAlerts {
  const ServiceAlerts({required this.overdue, required this.dueToday});

  final List<ServiceOrder> overdue;
  final List<ServiceOrder> dueToday;

  bool get any => overdue.isNotEmpty || dueToday.isNotEmpty;
}

ServiceAlerts serviceAlerts(
  Iterable<ServiceOrder> all, {
  required DateTime now,
}) => ServiceAlerts(
  overdue: orderRows(all, tab: 'Overdue', now: now),
  dueToday: orderRows(all, tab: 'Due Today', now: now),
);

/// What finished service work has brought in.
///
/// Only closed orders that were actually charged. An open order contributes
/// nothing: its estimate is a quote, and counting quotes as revenue is how a
/// month looked profitable before any of the work was done.
///
/// This is revenue, NOT what is outstanding. Service orders carry no payment
/// record in this build, so nothing here can say what has been collected —
/// Due Payments reads sales, where the payment is.
num serviceRevenue(Iterable<ServiceOrder> all) => all
    .where((o) => o.closed && o.finalPrice != null)
    .fold<num>(0, (sum, o) => sum + o.finalPrice!);
