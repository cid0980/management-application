import '../dashboard/board.dart';
import '../enquiries/enquiry.dart';
import '../service/service_order.dart';

/// WHAT THE MORNING REMINDER SAYS
///
/// The phone tells the shop, at opening time, what the day holds: repairs
/// promised for today, repairs already late, phones ready and waiting for
/// their customer, and enquiries due a call back. Worked out from the shop's
/// records as the phone last saw them, so the reminder can be set up the
/// evening before without a server.
class MorningSummary {
  const MorningSummary({
    required this.dueToday,
    required this.late,
    required this.ready,
    required this.ringBack,
  });

  final int dueToday;
  final int late;
  final int ready;
  final int ringBack;

  /// Nothing to say: no reminder is shown on a quiet day.
  bool get isEmpty => dueToday + late + ready + ringBack == 0;

  /// Where a tap on the reminder goes: the most pressing list.
  String get route => late > 0
      ? '/service?tab=Overdue'
      : dueToday > 0
      ? '/service?tab=Due%20Today'
      : ready > 0
      ? '/service?tab=Ready'
      : '/enquiries';
}

/// The summary for the morning of [day]: what will be due, late and ready
/// then, as the records stand now.
MorningSummary morningSummary({
  required Iterable<ServiceOrder> orders,
  required Iterable<Enquiry> enquiries,
  required DateTime day,
}) {
  final morning = DateTime(day.year, day.month, day.day, 9);
  final queues = benchQueues(orders, now: morning);
  final end = DateTime(day.year, day.month, day.day + 1);
  final ringBack = enquiries
      .where((e) => !e.closed)
      .where((e) => e.followUpAt != null && e.followUpAt!.isBefore(end))
      .length;
  return MorningSummary(
    dueToday: queues[BenchKind.dueToday]!.length,
    late: queues[BenchKind.late]!.length,
    ready: queues[BenchKind.ready]!.length,
    ringBack: ringBack,
  );
}

/// The next time the reminder should show: today at [hour]:[minute] if that
/// is still ahead, otherwise tomorrow.
DateTime nextReminderAt(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now) ? today : today.add(const Duration(days: 1));
}
