import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/tasks/task.dart';
import 'package:fm_shop/domain/tasks/task_list.dart';

const _admin = TaskActor(uid: 'owner', isAdmin: true);
const _mani = TaskActor(uid: 'mani', isAdmin: false);

// A Wednesday.
final _today = DateTime(2026, 11, 11, 10, 30);

ShopTask _t(
  String id, {
  TaskFrequency frequency = TaskFrequency.daily,
  TaskPriority priority = TaskPriority.medium,
  String assignedTo = 'mani',
  List<DateTime> doneOn = const [],
  DateTime? dueDate,
  String title = 'Wipe the cabinet',
}) => ShopTask(
  id: id,
  title: title,
  assignedTo: assignedTo,
  frequency: frequency,
  priority: priority,
  dueDate: dueDate,
  completedDays: [for (final d in doneOn) taskDayKey(d)],
);

void main() {
  group('a task stores the days it was done on, and nothing resets it', () {
    test('a daily task ticked yesterday is not done today', () {
      final task = _t('a', doneOn: [DateTime(2026, 11, 10)]);
      expect(task.isDoneOn(_today), isFalse);
      expect(task.isDoneOn(DateTime(2026, 11, 10, 23)), isTrue);
    });

    test(
      'a weekly task ticked on Monday is done until Sunday, and not after',
      () {
        final task = _t(
          'a',
          frequency: TaskFrequency.weekly,
          doneOn: [DateTime(2026, 11, 9)],
        );
        expect(task.isDoneOn(_today), isTrue);
        expect(task.isDoneOn(DateTime(2026, 11, 15)), isTrue);
        expect(task.isDoneOn(DateTime(2026, 11, 16)), isFalse);
      },
    );

    test('a monthly task ticked this month is done until the month turns', () {
      final task = _t(
        'a',
        frequency: TaskFrequency.monthly,
        doneOn: [DateTime(2026, 11, 2)],
      );
      expect(task.isDoneOn(DateTime(2026, 11, 30)), isTrue);
      expect(task.isDoneOn(DateTime(2026, 12, 1)), isFalse);
    });

    test('a one-time task stays done for good', () {
      final task = _t(
        'a',
        frequency: TaskFrequency.oneTime,
        doneOn: [DateTime(2026, 1, 5)],
      );
      expect(task.isDoneOn(_today), isTrue);
    });

    test(
      'the history is free: was it done on Saturday is the same question',
      () {
        final task = _t(
          'a',
          doneOn: [DateTime(2026, 11, 7), DateTime(2026, 11, 9)],
        );
        expect(task.isDoneOn(DateTime(2026, 11, 7)), isTrue);
        expect(task.isDoneOn(DateTime(2026, 11, 8)), isFalse);
      },
    );

    test('undoing a weekly task on Thursday finds the Tuesday tick', () {
      final task = _t(
        'a',
        frequency: TaskFrequency.weekly,
        doneOn: [DateTime(2026, 11, 10)],
      );
      expect(task.tickCovering(DateTime(2026, 11, 12)), '2026-11-10');
    });
  });

  group('only a one-time task can be overdue', () {
    test('a daily task left unticked for a week is not overdue', () {
      final task = _t('a', dueDate: DateTime(2026, 11, 1));
      expect(task.isOverdueOn(_today), isFalse);
    });

    test('a one-time task past its day is overdue until it is done', () {
      final late = _t(
        'a',
        frequency: TaskFrequency.oneTime,
        dueDate: DateTime(2026, 11, 9),
      );
      expect(late.isOverdueOn(_today), isTrue);
      final done = late.copyWith(completedDays: [taskDayKey(_today)]);
      expect(done.isOverdueOn(_today), isFalse);
    });

    test('a one-time task due today is not overdue yet', () {
      final task = _t(
        'a',
        frequency: TaskFrequency.oneTime,
        dueDate: DateTime(2026, 11, 11),
      );
      expect(task.isOverdueOn(_today), isFalse);
    });
  });

  group('staff see and tick only their own', () {
    test('not somebody else\'s', () {
      expect(canSeeTask(_t('a', assignedTo: 'suresh'), _mani), isFalse);
      expect(
        taskTickBlockFor(_t('a', assignedTo: 'suresh'), _mani),
        TaskBlock.notYours,
      );
    });

    test('and not the unassigned ones — nobody has been asked yet', () {
      expect(canSeeTask(_t('a', assignedTo: ''), _mani), isFalse);
    });

    test('the owner sees every task, assigned or not', () {
      expect(canSeeTask(_t('a', assignedTo: 'suresh'), _admin), isTrue);
      expect(canSeeTask(_t('a', assignedTo: ''), _admin), isTrue);
    });

    test('staff are never shown the nobody-yet tab', () {
      expect(taskTabsFor(_mani), isNot(contains(TaskTab.unassigned)));
      expect(taskTabsFor(_admin), contains(TaskTab.unassigned));
    });
  });

  group('saving a task', () {
    test('only the owner can', () {
      expect(taskSaveBlockFor(_t('a'), _mani), TaskBlock.adminOnly);
    });

    test('it needs to say what has to be done', () {
      expect(taskSaveBlockFor(_t('a', title: '  '), _admin), TaskBlock.noTitle);
    });

    test('a one-time task needs a day; a daily one does not', () {
      expect(
        taskSaveBlockFor(_t('a', frequency: TaskFrequency.oneTime), _admin),
        TaskBlock.noDueDate,
      );
      expect(taskSaveBlockFor(_t('a'), _admin), isNull);
    });

    test('a new task cannot be due on a day already gone; an old one can', () {
      final now = DateTime(2026, 11, 25, 10);
      final yesterday = _t(
        'a',
        frequency: TaskFrequency.oneTime,
        dueDate: DateTime(2026, 11, 24),
      );
      expect(
        taskSaveBlockFor(yesterday, _admin, isNew: true, now: now),
        TaskBlock.pastDue,
      );
      expect(taskSaveBlockFor(yesterday, _admin, now: now), isNull);
      expect(
        taskSaveBlockFor(
          _t(
            'a',
            frequency: TaskFrequency.oneTime,
            dueDate: DateTime(2026, 11, 25),
          ),
          _admin,
          isNew: true,
          now: now,
        ),
        isNull,
      );
    });

    test('nobody has to be assigned — the list can be written first', () {
      expect(taskSaveBlockFor(_t('a', assignedTo: ''), _admin), isNull);
    });
  });

  group('reading what the POS wrote', () {
    test('a completed status with a date is one tick on that day', () {
      final task = ShopTask.fromMap('a', {
        'title': 'Fix the signboard',
        'frequency': 'one-time',
        'status': 'completed',
        'completedAt': '2026-11-07T18:00:00',
      });
      expect(task.completedDays, ['2026-11-07']);
      expect(task.isDoneOn(_today), isTrue);
    });

    test('an unknown frequency is one-time, an unknown priority is medium', () {
      final task = ShopTask.fromMap('a', {
        'title': 'x',
        'frequency': 'fortnightly',
        'priority': 'urgent',
      });
      expect(task.frequency, TaskFrequency.oneTime);
      expect(task.priority, TaskPriority.medium);
    });

    test('saving never writes the ticks, so an edit cannot undo one', () {
      final map = _t('a', doneOn: [_today]).toMap();
      expect(map.containsKey('completedDays'), isFalse);
    });
  });

  group('the list', () {
    final tasks = [
      _t('done', title: 'A done', doneOn: [_today]),
      _t('low', title: 'B low', priority: TaskPriority.low),
      _t('high', title: 'C high', priority: TaskPriority.high),
      _t(
        'late',
        title: 'D late',
        frequency: TaskFrequency.oneTime,
        priority: TaskPriority.low,
        dueDate: DateTime(2026, 11, 1),
      ),
      _t('other', title: 'E other', assignedTo: 'suresh'),
      _t('nobody', title: 'F nobody', assignedTo: ''),
    ];

    test(
      'overdue first, then the more important, and done is not in To do',
      () {
        final rows = taskRows(
          tasks,
          tab: TaskTab.toDo,
          actor: _mani,
          now: _today,
        );
        expect(rows.map((t) => t.id), ['late', 'high', 'low']);
      },
    );

    test('counts are of what that person can see', () {
      final mine = taskTabCounts(tasks, actor: _mani, now: _today);
      expect(mine[TaskTab.toDo], 3);
      expect(mine[TaskTab.done], 1);
      final owner = taskTabCounts(tasks, actor: _admin, now: _today);
      expect(owner[TaskTab.toDo], 5);
      expect(owner[TaskTab.unassigned], 1);
    });

    test('the owner can narrow the list to one staff member', () {
      final rows = taskRows(
        tasks,
        tab: TaskTab.toDo,
        actor: _admin,
        now: _today,
        assignedTo: 'suresh',
      );
      expect(rows.map((t) => t.id), ['other']);
    });

    test('open task count is what is left for today', () {
      expect(openTaskCount(tasks, actor: _mani, now: _today), 3);
    });
  });
}
