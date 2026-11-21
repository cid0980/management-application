/// A SHOP TASK
///
/// "Wipe the display cabinet", "count the cash drawer", "ring the parts
/// supplier" — the routine an owner wants done and has no way to check on when
/// they are not standing in the shop.
///
/// **A task stores the days it was done on. Nothing resets it.**
///
/// The POS this was ported from kept a `status` and a `resetDate`, and cleared
/// the status when somebody next opened the task page. In a shop that
/// "somebody" does not reliably exist: the app is closed, the phone is in a
/// drawer, and Monday opens with Saturday's ticks still showing. Staff then
/// either trust the list and skip the checks, or stop trusting the list.
///
/// So "is it done" is a question about a particular day:
///
///   - a **daily** task is done today if today is one of its days;
///   - a **weekly** task is done if any of its days falls in this week
///     (Monday to Sunday);
///   - a **monthly** task is done if any falls in this month;
///   - a **one-time** task is done once it has any day at all.
///
/// Nothing runs at midnight, and nothing can be stale, because there is
/// nothing to be stale. The history is free as well: "was the cabinet wiped on
/// Saturday" is the same question asked about a different day.
///
/// **Only a one-time task can be overdue.** A daily task is due today, every
/// day; calling yesterday's unticked check overdue leaves a red mark nobody can
/// ever clear, which is how staff learn to ignore red.
library;

import '../common/dates.dart';

enum TaskFrequency { daily, weekly, monthly, oneTime }

enum TaskPriority { low, medium, high }

/// The strings the POS wrote, kept so a shop's existing tasks still read.
const Map<TaskFrequency, String> kTaskFrequencyWire = {
  TaskFrequency.daily: 'daily',
  TaskFrequency.weekly: 'weekly',
  TaskFrequency.monthly: 'monthly',
  TaskFrequency.oneTime: 'one-time',
};

/// An unrecognised frequency reads as one-time: the safe direction, because a
/// one-time task asks to be done once and then stays done, where guessing
/// "daily" would put a stranger's task in front of staff every morning.
TaskFrequency taskFrequencyFrom(Object? raw) {
  final text = (raw ?? '').toString().trim().toLowerCase();
  for (final entry in kTaskFrequencyWire.entries) {
    if (entry.value == text) return entry.key;
  }
  if (text == 'onetime' || text == 'one time' || text == 'once') {
    return TaskFrequency.oneTime;
  }
  return TaskFrequency.oneTime;
}

/// An unrecognised priority reads as medium — neither shouting nor hidden.
TaskPriority taskPriorityFrom(Object? raw) {
  final text = (raw ?? '').toString().trim().toLowerCase();
  for (final p in TaskPriority.values) {
    if (p.name == text) return p;
  }
  return TaskPriority.medium;
}

/// `2026-11-11`. The unit a tick is stored in.
///
/// Local time, like every other "day" in this app: a check ticked at nine in
/// the evening in Chennai was done today, not tomorrow.
String taskDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime? _dayFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// The Monday of the week [day] falls in.
DateTime _startOfWeek(DateTime day) =>
    _startOfDay(day).subtract(Duration(days: day.weekday - DateTime.monday));

class ShopTask {
  const ShopTask({
    required this.id,
    required this.title,
    this.description = '',
    this.assignedTo = '',
    this.assignedToName = '',
    this.frequency = TaskFrequency.daily,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.completedDays = const [],
    this.lastCompletedBy = '',
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;

  /// The uid of whoever is to do it. Empty when nobody has been picked yet —
  /// an owner writing the list first and deciding who does what afterwards is
  /// a real way to work.
  final String assignedTo;

  /// A copy of their name, so the list reads without loading the staff page.
  final String assignedToName;

  final TaskFrequency frequency;
  final TaskPriority priority;

  /// Asked for on a one-time task, where it is the deadline. On a repeating
  /// task it is only the day the task starts.
  final DateTime? dueDate;

  /// Every day this was ticked, as [taskDayKey]s. See the library note.
  final List<String> completedDays;

  /// Who ticked it most recently.
  final String lastCompletedBy;

  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAssigned => assignedTo.trim().isNotEmpty;

  /// The day-key that was ticked for the period [day] falls in, or null.
  ///
  /// Returned rather than just a bool, because un-ticking has to remove the
  /// key that is actually stored — a weekly task ticked on Tuesday is undone
  /// on Thursday by removing Tuesday.
  String? tickCovering(DateTime day) {
    final today = _startOfDay(day);
    for (final key in completedDays) {
      final done = _dayFromKey(key);
      if (done == null) continue;
      final covers = switch (frequency) {
        TaskFrequency.daily => done == today,
        TaskFrequency.weekly => _startOfWeek(done) == _startOfWeek(today),
        TaskFrequency.monthly =>
          done.year == today.year && done.month == today.month,
        TaskFrequency.oneTime => true,
      };
      if (covers) return key;
    }
    return null;
  }

  /// Whether this is done for the period [day] falls in.
  bool isDoneOn(DateTime day) => tickCovering(day) != null;

  /// Only a one-time task past its date. See the library note.
  bool isOverdueOn(DateTime day) {
    if (frequency != TaskFrequency.oneTime) return false;
    final due = dueDate;
    if (due == null || isDoneOn(day)) return false;
    return _startOfDay(due).isBefore(_startOfDay(day));
  }

  ShopTask copyWith({
    String? title,
    String? description,
    String? assignedTo,
    String? assignedToName,
    TaskFrequency? frequency,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? completedDays,
    String? lastCompletedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShopTask(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    assignedTo: assignedTo ?? this.assignedTo,
    assignedToName: assignedToName ?? this.assignedToName,
    frequency: frequency ?? this.frequency,
    priority: priority ?? this.priority,
    dueDate: dueDate ?? this.dueDate,
    completedDays: completedDays ?? this.completedDays,
    lastCompletedBy: lastCompletedBy ?? this.lastCompletedBy,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Reads a task written by this app or by the POS.
  ///
  /// The POS kept `status: 'completed'` and a `completedAt`. That is read as
  /// one tick on that day, so a task finished in the old system does not come
  /// back as undone here.
  static ShopTask fromMap(String id, Map<String, Object?> map) {
    final days = <String>{
      for (final d in (map['completedDays'] as List?) ?? const [])
        if (d != null && d.toString().trim().isNotEmpty) d.toString().trim(),
    };
    if ((map['status'] ?? '').toString().toLowerCase() == 'completed') {
      final at = normalizeDate(map['completedAt']);
      if (at != null) days.add(taskDayKey(at));
    }
    return ShopTask(
      id: id,
      title: (map['title'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      assignedTo: (map['assignedTo'] ?? '').toString().trim(),
      assignedToName: (map['assignedToName'] ?? '').toString().trim(),
      frequency: taskFrequencyFrom(map['frequency']),
      priority: taskPriorityFrom(map['priority']),
      dueDate: normalizeDate(map['dueDate']),
      completedDays: days.toList()..sort(),
      lastCompletedBy: (map['lastCompletedBy'] ?? map['completedBy'] ?? '')
          .toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: normalizeDate(map['createdAt']),
      updatedAt: normalizeDate(map['updatedAt']),
    );
  }

  /// Everything except the ticks.
  ///
  /// [completedDays] is deliberately left out: a tick is an append made on its
  /// own, so that editing a task's title on one phone cannot overwrite a tick
  /// made on another in the same minute.
  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'assignedTo': assignedTo,
    'assignedToName': assignedToName,
    'frequency': kTaskFrequencyWire[frequency],
    'priority': priority.name,
    'dueDate': dueDate?.toIso8601String(),
    'createdBy': createdBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

/// Who is asking. Passed to every rule below, and to the repository, so the
/// same answer comes back whichever screen asks.
class TaskActor {
  const TaskActor({required this.uid, required this.isAdmin});

  final String uid;
  final bool isAdmin;
}

/// STAFF SEE AND TICK ONLY THEIR OWN.
///
/// Not the unassigned ones: a list the owner wrote before deciding who does
/// what has not asked anybody to do anything, and showing those to everyone
/// means five people each assuming somebody else had it.
///
/// One function, used by both pages and by the repository on the write as
/// well — a rule enforced only by which buttons a screen draws is a rule a
/// deep link walks straight past.
bool canSeeTask(ShopTask task, TaskActor actor) =>
    actor.isAdmin || (task.isAssigned && task.assignedTo == actor.uid);

/// Why a task was not saved, ticked or removed.
enum TaskBlock { noTitle, noDueDate, adminOnly, notYours }

const Map<TaskBlock, String> kTaskBlockMessages = {
  TaskBlock.noTitle: 'Write what has to be done.',
  TaskBlock.noDueDate: 'Pick the day this has to be done by.',
  TaskBlock.adminOnly: 'Only the shop owner can change tasks.',
  TaskBlock.notYours: 'This task belongs to someone else.',
};

/// What stops a task being saved, or null.
///
/// A due date is asked for only on a one-time task, where it is the deadline.
/// Nobody is required to be assigned — see [ShopTask.assignedTo].
TaskBlock? taskSaveBlockFor(ShopTask task, TaskActor actor) {
  if (!actor.isAdmin) return TaskBlock.adminOnly;
  if (task.title.trim().isEmpty) return TaskBlock.noTitle;
  if (task.frequency == TaskFrequency.oneTime && task.dueDate == null) {
    return TaskBlock.noDueDate;
  }
  return null;
}

/// What stops a task being ticked or un-ticked, or null.
TaskBlock? taskTickBlockFor(ShopTask task, TaskActor actor) =>
    canSeeTask(task, actor) ? null : TaskBlock.notYours;
