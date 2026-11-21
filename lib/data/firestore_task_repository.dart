/// TASKS, OUT OF FIRESTORE
///
/// The same `TaskRepository` the screens talk to, backed by
/// `shops/{shopId}/tasks` — one shop's tasks and no other's.
///
/// **A tick is an append.** `arrayUnion` of a day key, so two phones ticking
/// the same task in the same minute agree, and editing a task's title on one
/// phone cannot overwrite a tick made on another: `save` merges and never
/// writes `completedDays`.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/tasks/task.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'task_repository.dart';

class FirestoreTaskStore extends ChangeNotifier implements TaskRepository {
  FirestoreTaskStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

  List<ShopTask> _tasks = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  List<ShopTask> get tasks => List.unmodifiable(_tasks);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    _subscription = scope.tasks.snapshots().listen(
      (snapshot) {
        _tasks = [
          for (final doc in snapshot.docs) ShopTask.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'tasks');
        notifyListeners();
      },
    );
  }

  @override
  ShopTask? byId(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  String newId() => scope.tasks.doc().id;

  @override
  Future<TaskResult> save(ShopTask task, TaskActor actor) async {
    final block = taskSaveBlockFor(task, actor);
    if (block != null) return TaskResult.refused(block);

    final existing = byId(task.id);
    final now = DateTime.now();
    final stored = task.copyWith(
      title: task.title.trim(),
      createdBy: existing?.createdBy.isNotEmpty == true
          ? existing!.createdBy
          : actor.uid,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final map = stored.toMap();
    // A repeating task whose date was cleared has no date. Deleted rather than
    // written as null, so the old one does not sit under a merge.
    if (stored.dueDate == null) map['dueDate'] = FieldValue.delete();
    // Merge, so the ticks — which this map never carries — are left alone.
    await scope.tasks.doc(stored.id).set(map, SetOptions(merge: true));
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

    final key = taskDayKey(day);
    await scope.tasks.doc(id).update({
      'completedDays': FieldValue.arrayUnion([key]),
      'lastCompletedBy': actor.uid,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return TaskResult.ok(
      task.copyWith(
        completedDays: [...task.completedDays, key],
        lastCompletedBy: actor.uid,
      ),
    );
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

    await scope.tasks.doc(id).update({
      'completedDays': FieldValue.arrayRemove([key]),
      // A task the POS finished carries a status as well as, now, a day. Both
      // have to go or `fromMap` reads it straight back as done.
      'status': 'pending',
      'completedAt': FieldValue.delete(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return TaskResult.ok(
      task.copyWith(completedDays: [...task.completedDays]..remove(key)),
    );
  }

  @override
  Future<TaskResult> delete(String id, TaskActor actor) async {
    if (!actor.isAdmin) return const TaskResult.refused(TaskBlock.adminOnly);
    await scope.tasks.doc(id).delete();
    return const TaskResult.ok();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
