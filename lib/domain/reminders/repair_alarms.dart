/// THE TECHNICIAN'S ALARMS
///
/// Worked out on each phone from the repairs it has synced, for the person
/// holding it (no server; see phone_reminders.dart):
///
/// - **An hour before** a job is promised, and **at** the promised time if
///   it is still not ready: an alarm on the phone of the technician the job
///   is linked to. A job linked to nobody rings on the admins' phones, so a
///   promise is never left with nobody reminded.
/// - **A job given to you**: shown once, when this phone first sees it.
///
/// Ready, handed back and returned jobs ring for nobody: the work is done.
library;

import '../service/order_state.dart';
import '../service/service_order.dart';

enum RepairAlarmKind { hourBefore, dueNow }

class RepairAlarm {
  const RepairAlarm({
    required this.order,
    required this.kind,
    required this.at,
  });

  final ServiceOrder order;
  final RepairAlarmKind kind;
  final DateTime at;

  /// Stable per job and kind, so planning again replaces rather than adds.
  int get id =>
      500000 +
      (order.id.hashCode.abs() % 200000) * 2 +
      (kind == RepairAlarmKind.dueNow ? 1 : 0);
}

/// Jobs still being worked on.
bool _open(ServiceOrder o) => !isClosed(o.status) && !isReady(o.status);

/// Whose alarms these are: this person's jobs, and — for an admin — the
/// jobs linked to nobody.
bool isMyJob(ServiceOrder o, {required String myUid, required bool isAdmin}) =>
    o.technicianUid.isNotEmpty ? o.technicianUid == myUid : isAdmin;

/// The alarms still ahead, soonest first, at most [max] (Android limits how
/// many one app may set).
List<RepairAlarm> repairAlarms(
  Iterable<ServiceOrder> orders, {
  required String myUid,
  required bool isAdmin,
  required DateTime now,
  int max = 40,
}) {
  final out = <RepairAlarm>[];
  for (final o in orders) {
    final due = o.expectedCompletionAt;
    if (due == null || !_open(o)) continue;
    if (!isMyJob(o, myUid: myUid, isAdmin: isAdmin)) continue;
    final before = due.subtract(const Duration(hours: 1));
    if (before.isAfter(now)) {
      out.add(
        RepairAlarm(order: o, kind: RepairAlarmKind.hourBefore, at: before),
      );
    }
    if (due.isAfter(now)) {
      out.add(RepairAlarm(order: o, kind: RepairAlarmKind.dueNow, at: due));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(max).toList();
}

/// What marks one handing-over of a job to somebody: the same job given to
/// the same person again later is a new assignment.
String assignmentKey(ServiceOrder o) =>
    '${o.id}@${o.technicianUid}@${o.assignedAt?.millisecondsSinceEpoch ?? 0}';

/// Jobs given to [myUid] by somebody else that this phone has not told them
/// about yet ([seen] holds [assignmentKey]s already shown).
List<ServiceOrder> newAssignments(
  Iterable<ServiceOrder> orders, {
  required String myUid,
  required Set<String> seen,
}) => [
  for (final o in orders)
    if (myUid.isNotEmpty &&
        o.technicianUid == myUid &&
        o.assignedBy != myUid &&
        _open(o) &&
        !seen.contains(assignmentKey(o)))
      o,
];

/// The event that last made [o] Ready, if somebody else did it — the owner
/// is told once per such event.
RepairReady? readyBySomebodyElse(ServiceOrder o, {required String myUid}) {
  if (!isReady(o.status)) return null;
  for (final e in o.history.reversed) {
    if (e.kind == 'status' && e.detail == kReadyStatus) {
      if (e.byUid.isEmpty || e.byUid == myUid) return null;
      return RepairReady(
        order: o,
        by: e.byName,
        key: '${o.id}@ready@${e.at.millisecondsSinceEpoch}',
      );
    }
  }
  return null;
}

class RepairReady {
  const RepairReady({required this.order, required this.by, required this.key});

  final ServiceOrder order;
  final String by;
  final String key;
}

/// Jobs made Ready by somebody else that an admin's phone has not told
/// them about yet.
List<RepairReady> newReadies(
  Iterable<ServiceOrder> orders, {
  required String myUid,
  required Set<String> seen,
}) => [
  for (final o in orders)
    if (readyBySomebodyElse(o, myUid: myUid) case final r?)
      if (!seen.contains(r.key)) r,
];

/// This person's jobs that are past their promised time and still not
/// ready, the latest first.
List<ServiceOrder> lateJobsFor(
  Iterable<ServiceOrder> orders, {
  required String myUid,
  required bool isAdmin,
  required DateTime now,
}) {
  final late = [
    for (final o in orders)
      if (_open(o) &&
          o.expectedCompletionAt != null &&
          o.expectedCompletionAt!.isBefore(now) &&
          isMyJob(o, myUid: myUid, isAdmin: isAdmin))
        o,
  ]..sort((a, b) => a.expectedCompletionAt!.compareTo(b.expectedCompletionAt!));
  return late;
}

/// When a late job rings again: the next reminder time and the next 3 PM,
/// whichever are still ahead (one of each).
List<DateTime> lateRingTimes(DateTime now, int hour, int minute) {
  DateTime next(int h, int m) {
    final today = DateTime(now.year, now.month, now.day, h, m);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  final a = next(hour, minute);
  final b = next(15, 0);
  return a == b ? [a] : [a, b];
}
