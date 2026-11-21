/// WHAT STATE A SERVICE ORDER IS IN
///
/// An order carries a status, but the status alone is not what staff need to
/// know. "Parts Awaiting" tells you nothing about whether it was promised to
/// the customer yesterday. The list has to answer one question at a glance —
/// what do I have to do about this phone — and that has three answers:
///
///   overdue  it was promised and the time has passed
///   open     it is in the shop, and there is still time
///   closed   it has been handed back, and is history
///
/// Closed beats overdue on purpose. A job completed last month is not an
/// alarm, and leaving those red filled the list with warnings about work
/// already done.
///
/// `now` is passed in rather than read here, so the behaviour can be stated
/// exactly in a test instead of depending on the day it runs.
library;

import '../common/dates.dart';

const List<String> kStatuses = [
  'Received',
  'In Progress',
  'Parts Awaiting',
  'Awaiting Customer Approval',
  'Ready',
  'Completed',
  'Returned',
];

/// READY FOR PICKUP
///
/// The work is done and the phone is waiting for its owner. Before this
/// status existed a finished phone stayed "In Progress" until the customer
/// turned up, went red as overdue the day after it was promised — although
/// the shop had kept its word — and the "it's ready, please collect" message
/// was only offered after the phone had already been handed back.
///
/// It is still open (the phone is in the shop and the bill is not settled),
/// but it is never overdue or due: from here the clock is the customer's.
const String kReadyStatus = 'Ready';

bool isReady(String? status) => status == kReadyStatus;

/// Handed back, one way or the other. Nothing more is owed on it.
bool isClosed(String? status) => status == 'Completed' || status == 'Returned';

/// The slice of an order this logic needs. Keeps the rules testable without a
/// database and without a widget.
class ServiceOrderState {
  const ServiceOrderState({this.status, this.expectedCompletionAt});

  final String? status;
  final Object? expectedCompletionAt;

  DateTime? get expected => normalizeDate(expectedCompletionAt);
}

bool isOverdue(ServiceOrderState order, {DateTime? now}) {
  if (isClosed(order.status) || isReady(order.status)) return false;
  final expected = order.expected;
  return expected != null && expected.isBefore(now ?? DateTime.now());
}

bool isDueToday(ServiceOrderState order, {DateTime? now}) {
  if (isClosed(order.status) || isReady(order.status)) return false;
  final expected = order.expected;
  if (expected == null) return false;
  final n = now ?? DateTime.now();
  final start = DateTime(n.year, n.month, n.day);
  final end = DateTime(n.year, n.month, n.day + 1);
  return !expected.isBefore(start) && expected.isBefore(end);
}

enum OrderLifecycle { overdue, open, closed }

OrderLifecycle stateOf(ServiceOrderState order, {DateTime? now}) {
  if (isClosed(order.status)) return OrderLifecycle.closed;
  return isOverdue(order, now: now)
      ? OrderLifecycle.overdue
      : OrderLifecycle.open;
}

/// The words for each state. Red is an alarm, not decoration: it means a
/// customer is already waiting past the time they were given. Colours are the
/// app theme's business — only the labels live here.
const Map<OrderLifecycle, String> kStateLabels = {
  OrderLifecycle.overdue: 'Overdue',
  OrderLifecycle.open: 'In the shop',
  OrderLifecycle.closed: 'Finished',
};

/// Open leads, because the work still in the shop is the reason anyone opens
/// this page. The rest are there for looking something up.
const List<String> kTabs = [
  'Open',
  'Due Today',
  'Overdue',
  'Ready',
  'In Progress',
  'Parts Awaiting',
  'Awaiting Customer Approval',
  'Completed',
  'Returned',
  'All',
];

bool matchesTab(ServiceOrderState order, String tab, {DateTime? now}) {
  switch (tab) {
    case 'All':
      return true;
    case 'Open':
      return !isClosed(order.status);
    case 'Overdue':
      return isOverdue(order, now: now);
    case 'Due Today':
      return isDueToday(order, now: now);
    default:
      return order.status == tab;
  }
}

/// The two dates an order cannot be saved without.
///
/// This check lives in one place so "Save" and "Save & Print" cannot disagree
/// about what a valid order is: in the original one refused an unparseable
/// date and the other wrote it as an Invalid Date, where it then read as
/// neither overdue nor due nor anything else.
///
/// It throws rather than returning a flag, so a caller cannot forget to look.
const String kDateError =
    'Please provide valid datetime values for received and expected completion';

({DateTime received, DateTime expected}) requireOrderDates(
  Object? receivedAt,
  Object? expectedCompletionAt,
) {
  final received = normalizeDate(receivedAt);
  final expected = normalizeDate(expectedCompletionAt);
  if (received == null || expected == null) throw ArgumentError(kDateError);
  return (received: received, expected: expected);
}

/// WHICH STATUSES SOMEONE MAY MOVE AN ORDER TO
///
/// 'Completed' is never one of them, from any role: finishing an order goes
/// through the pre-delivery checklist, never a dropdown.
///
/// The rule is written down rather than derived from position in [kStatuses],
/// because position is the order they are listed in, not a workflow — and
/// deriving it meant adding a status silently changed what staff could do.
/// 'Received' is the one you cannot go back to: an order past it has been
/// looked at, and saying otherwise would hide work that has already happened.
List<String> statusOptionsFor(String? current, {bool isAdmin = false}) {
  final open = kStatuses.where((s) => s != 'Completed');
  final allowed = isAdmin
      ? open.toList()
      : open.where((s) => s == current || s != 'Received').toList();

  // An order carrying a status this build does not know — an older spelling,
  // or one since renamed — still has to show what it actually says.
  if (current != null &&
      current.isNotEmpty &&
      current != 'Completed' &&
      !allowed.contains(current)) {
    return [current, ...allowed];
  }
  return allowed;
}
