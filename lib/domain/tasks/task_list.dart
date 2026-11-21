/// THE TASK LIST — tabs, counts and order
///
/// Pure, so both pages (the owner's and a staff member's) show the same rows
/// in the same order, and so the order has a test.
library;

import 'task.dart';

/// `unassigned` is the owner's tab only: tasks written down but given to
/// nobody, which no staff member can see.
enum TaskTab { toDo, done, daily, weekly, monthly, oneTime, unassigned }

/// The tabs a person is shown. Staff never get `unassigned` — there would
/// never be anything in it.
List<TaskTab> taskTabsFor(TaskActor actor) => [
  for (final tab in TaskTab.values)
    if (tab != TaskTab.unassigned || actor.isAdmin) tab,
];

bool _inTab(ShopTask task, TaskTab tab, DateTime now) => switch (tab) {
  TaskTab.toDo => !task.isDoneOn(now),
  TaskTab.done => task.isDoneOn(now),
  TaskTab.daily => task.frequency == TaskFrequency.daily,
  TaskTab.weekly => task.frequency == TaskFrequency.weekly,
  TaskTab.monthly => task.frequency == TaskFrequency.monthly,
  TaskTab.oneTime => task.frequency == TaskFrequency.oneTime,
  TaskTab.unassigned => !task.isAssigned,
};

/// The tasks [actor] may see at all, optionally narrowed to one staff member.
List<ShopTask> visibleTasks(
  Iterable<ShopTask> tasks,
  TaskActor actor, {
  String? assignedTo,
}) => [
  for (final task in tasks)
    if (canSeeTask(task, actor) &&
        (assignedTo == null || task.assignedTo == assignedTo))
      task,
];

Map<TaskTab, int> taskTabCounts(
  Iterable<ShopTask> tasks, {
  required TaskActor actor,
  required DateTime now,
  String? assignedTo,
}) {
  final visible = visibleTasks(tasks, actor, assignedTo: assignedTo);
  return {
    for (final tab in TaskTab.values)
      tab: visible.where((t) => _inTab(t, tab, now)).length,
  };
}

/// The rows for one tab.
///
/// What still has to be done comes first, and within that: overdue, then the
/// higher priority, then the title — so the top of the list is always the
/// thing to do next, and two phones show the same order.
List<ShopTask> taskRows(
  Iterable<ShopTask> tasks, {
  required TaskTab tab,
  required TaskActor actor,
  required DateTime now,
  String? assignedTo,
}) {
  final rows = [
    for (final task in visibleTasks(tasks, actor, assignedTo: assignedTo))
      if (_inTab(task, tab, now)) task,
  ];
  int rank(ShopTask t) {
    if (t.isDoneOn(now)) return 2;
    return t.isOverdueOn(now) ? 0 : 1;
  }

  rows.sort((a, b) {
    final byState = rank(a).compareTo(rank(b));
    if (byState != 0) return byState;
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) return byPriority;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return rows;
}

/// How many tasks [actor] still has to do today. For a badge or a dashboard
/// row.
int openTaskCount(
  Iterable<ShopTask> tasks, {
  required TaskActor actor,
  required DateTime now,
}) => visibleTasks(tasks, actor).where((t) => !t.isDoneOn(now)).length;
