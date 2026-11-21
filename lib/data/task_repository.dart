/// WHERE TASKS COME FROM
///
/// The rules are in `domain/tasks/task.dart`; this applies them to the write.
/// A screen hiding a button is not what stops a staff member ticking somebody
/// else's task — [tick] refusing it is.
///
/// A refusal comes back as a value, not an exception: being told "this task
/// belongs to someone else" is an ordinary thing to be told.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/tasks/task.dart';

abstract class TaskRepository extends ChangeNotifier {
  List<ShopTask> get tasks;
  bool get loading;
  String? get error;

  Future<void> load();

  ShopTask? byId(String id);

  /// A fresh id for a task that has not been saved yet.
  String newId();

  /// Add or edit. Admin only. Never touches the ticks.
  Future<TaskResult> save(ShopTask task, TaskActor actor);

  /// Mark done for the period [day] falls in. Ticking twice is one tick.
  Future<TaskResult> tick(String id, TaskActor actor, {required DateTime day});

  /// Take the tick for [day]'s period back off.
  Future<TaskResult> untick(
    String id,
    TaskActor actor, {
    required DateTime day,
  });

  /// Admin only.
  Future<TaskResult> delete(String id, TaskActor actor);
}

class TaskResult {
  const TaskResult.ok([this.task]) : block = null;
  const TaskResult.refused(TaskBlock this.block) : task = null;

  final ShopTask? task;
  final TaskBlock? block;

  bool get ok => block == null;
  String? get message => block == null ? null : kTaskBlockMessages[block];
}

class NoSuchTask implements Exception {
  const NoSuchTask(this.id);
  final String id;
  @override
  String toString() => 'No task $id';
}

class InMemoryTaskStore extends ChangeNotifier implements TaskRepository {
  InMemoryTaskStore({List<ShopTask>? seed}) {
    _tasks = [...(seed ?? _seedRecords())];
  }

  late List<ShopTask> _tasks;
  int _next = 1;

  @override
  List<ShopTask> get tasks => List.unmodifiable(_tasks);

  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  Future<void> load() async {}

  @override
  ShopTask? byId(String id) => _tasks.where((t) => t.id == id).firstOrNull;

  @override
  String newId() => 'task-new-${_next++}';

  @override
  Future<TaskResult> save(ShopTask task, TaskActor actor) async {
    final block = taskSaveBlockFor(task, actor);
    if (block != null) return TaskResult.refused(block);

    final existing = byId(task.id);
    final now = DateTime.now();
    final stored = task.copyWith(
      title: task.title.trim(),
      // The ticks are not the form's to change.
      completedDays: existing?.completedDays ?? const [],
      lastCompletedBy: existing?.lastCompletedBy ?? '',
      createdBy: existing?.createdBy ?? actor.uid,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final index = _tasks.indexWhere((t) => t.id == stored.id);
    if (index >= 0) {
      _tasks[index] = stored;
    } else {
      _tasks.add(stored);
    }
    notifyListeners();
    return TaskResult.ok(stored);
  }

  @override
  Future<TaskResult> tick(
    String id,
    TaskActor actor, {
    required DateTime day,
  }) async {
    final task = byId(id);
    if (task == null) throw NoSuchTask(id);
    final block = taskTickBlockFor(task, actor);
    if (block != null) return TaskResult.refused(block);
    if (task.isDoneOn(day)) return TaskResult.ok(task);

    final updated = task.copyWith(
      completedDays: [...task.completedDays, taskDayKey(day)],
      lastCompletedBy: actor.uid,
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    return TaskResult.ok(updated);
  }

  @override
  Future<TaskResult> untick(
    String id,
    TaskActor actor, {
    required DateTime day,
  }) async {
    final task = byId(id);
    if (task == null) throw NoSuchTask(id);
    final block = taskTickBlockFor(task, actor);
    if (block != null) return TaskResult.refused(block);
    final key = task.tickCovering(day);
    if (key == null) return TaskResult.ok(task);

    final updated = task.copyWith(
      completedDays: [...task.completedDays]..remove(key),
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    return TaskResult.ok(updated);
  }

  @override
  Future<TaskResult> delete(String id, TaskActor actor) async {
    if (!actor.isAdmin) return const TaskResult.refused(TaskBlock.adminOnly);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    return const TaskResult.ok();
  }

  void _replace(ShopTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index < 0) throw NoSuchTask(task.id);
    _tasks[index] = task;
    notifyListeners();
  }
}

/// Seed tasks, each one a state the list has to get right.
List<ShopTask> _seedRecords() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    // Daily, ticked yesterday: has to read as NOT done today.
    ShopTask(
      id: 'task-1',
      title: 'Wipe the display cabinet',
      assignedTo: 'local-staff',
      assignedToName: 'Mani',
      frequency: TaskFrequency.daily,
      completedDays: [taskDayKey(today.subtract(const Duration(days: 1)))],
      createdAt: today.subtract(const Duration(days: 30)),
    ),
    // One-time and past its date: the only kind that is ever overdue.
    ShopTask(
      id: 'task-2',
      title: 'Ring the parts supplier about the A54 displays',
      assignedTo: 'local-staff',
      assignedToName: 'Mani',
      frequency: TaskFrequency.oneTime,
      priority: TaskPriority.high,
      dueDate: today.subtract(const Duration(days: 2)),
      createdAt: today.subtract(const Duration(days: 5)),
    ),
    // Written down, given to nobody. Only the owner sees it.
    ShopTask(
      id: 'task-3',
      title: 'Count the accessories stock',
      frequency: TaskFrequency.monthly,
      priority: TaskPriority.low,
      createdAt: today.subtract(const Duration(days: 3)),
    ),
    // Somebody else's.
    ShopTask(
      id: 'task-4',
      title: 'Bank the cash',
      assignedTo: 'other-staff',
      assignedToName: 'Suresh',
      frequency: TaskFrequency.weekly,
      createdAt: today.subtract(const Duration(days: 10)),
    ),
    // Written by the POS: a status and a completedAt instead of days.
    ShopTask.fromMap('task-5', {
      'title': 'Fix the shop signboard light',
      'assignedTo': 'local-staff',
      'assignedToName': 'Mani',
      'frequency': 'one-time',
      'priority': 'medium',
      'status': 'completed',
      'completedAt': today.subtract(const Duration(days: 4)).toIso8601String(),
      'dueDate': today.subtract(const Duration(days: 4)).toIso8601String(),
    }),
  ];
}
