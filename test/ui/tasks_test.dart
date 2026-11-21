import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/task_repository.dart';
import 'package:fm_shop/domain/tasks/task.dart';
import 'package:fm_shop/ui/screens/tasks/task_list_screen.dart';

ShopTask _t(
  String id,
  String title, {
  String assignedTo = 'local-staff',
  TaskFrequency frequency = TaskFrequency.daily,
  DateTime? dueDate,
}) =>
    ShopTask(
      id: id,
      title: title,
      assignedTo: assignedTo,
      assignedToName: assignedTo.isEmpty ? '' : 'Mani',
      frequency: frequency,
      dueDate: dueDate,
    );

Future<InMemoryTaskStore> pumpTasks(
  WidgetTester tester, {
  required Role role,
  required bool manage,
  required List<ShopTask> seed,
}) async {
  tester.view.physicalSize = const Size(540, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthState();
  await auth.signInLocally(email: 'a@b.c', role: role);
  final tasks = InMemoryTaskStore(seed: seed);
  addTearDown(auth.dispose);
  addTearDown(tasks.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<TaskRepository>.value(value: tasks),
      ],
      child: MaterialApp(home: TaskListScreen(manage: manage)),
    ),
  );
  await tester.pumpAndSettle();
  return tasks;
}

void main() {
  final seed = [
    _t('mine', 'Wipe the cabinet'),
    _t('theirs', 'Bank the cash', assignedTo: 'other-staff'),
    _t('nobody', 'Count the accessories', assignedTo: ''),
  ];

  testWidgets('a staff member sees their own tasks and nobody else\'s',
      (tester) async {
    await pumpTasks(tester, role: Role.staff, manage: false, seed: seed);
    expect(find.text('Wipe the cabinet'), findsOneWidget);
    expect(find.text('Bank the cash'), findsNothing);
    expect(find.text('Count the accessories'), findsNothing);
    // No way to add one, and no nobody-yet tab.
    expect(find.text('Add task'), findsNothing);
    expect(find.byKey(const Key('task-tab-unassigned')), findsNothing);
  });

  testWidgets('tapping Done ticks today, and the task leaves To do',
      (tester) async {
    final store =
        await pumpTasks(tester, role: Role.staff, manage: false, seed: seed);
    await tester.tap(find.byKey(const Key('task-done-mine')));
    await tester.pumpAndSettle();
    expect(store.byId('mine')!.isDoneOn(DateTime.now()), isTrue);
    expect(find.text('Wipe the cabinet'), findsNothing);

    await tester.tap(find.byKey(const Key('task-tab-done')));
    await tester.pumpAndSettle();
    expect(find.text('Wipe the cabinet'), findsOneWidget);
    // And it can be taken back.
    await tester.tap(find.byKey(const Key('task-undo-mine')));
    await tester.pumpAndSettle();
    expect(store.byId('mine')!.isDoneOn(DateTime.now()), isFalse);
  });

  testWidgets('the owner sees every task, and is told which nobody can see',
      (tester) async {
    await pumpTasks(tester, role: Role.admin, manage: true, seed: seed);
    expect(find.text('Wipe the cabinet'), findsOneWidget);
    expect(find.text('Bank the cash'), findsOneWidget);
    expect(find.text('Count the accessories'), findsOneWidget);
    expect(find.text('Given to nobody — staff cannot see it yet'),
        findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });

  testWidgets('the owner adds a task from the form', (tester) async {
    final store =
        await pumpTasks(tester, role: Role.admin, manage: true, seed: const []);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // Saving with nothing written says what is missing and stores nothing.
    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pumpAndSettle();
    expect(find.text('Write what has to be done.'), findsOneWidget);
    expect(store.tasks, isEmpty);

    await tester.enterText(
        find.byKey(const Key('task-title')), 'Sweep the front');
    await tester.tap(find.byKey(const Key('task-frequency-weekly')));
    await tester.tap(find.byKey(const Key('task-priority-high')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pumpAndSettle();

    expect(store.tasks, hasLength(1));
    final task = store.tasks.single;
    expect(task.title, 'Sweep the front');
    expect(task.frequency, TaskFrequency.weekly);
    expect(task.priority, TaskPriority.high);
    expect(find.text('Sweep the front'), findsOneWidget);
  });

  testWidgets('a one-time task past its day is marked Late', (tester) async {
    await pumpTasks(tester, role: Role.staff, manage: false, seed: [
      _t('late', 'Ring the supplier',
          frequency: TaskFrequency.oneTime,
          dueDate: DateTime.now().subtract(const Duration(days: 3))),
    ]);
    expect(find.text('Late'), findsOneWidget);
  });

  testWidgets('the owner deletes a task after being asked', (tester) async {
    final store =
        await pumpTasks(tester, role: Role.admin, manage: true, seed: seed);
    await tester.tap(find.byKey(const Key('task-mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-delete-confirm')));
    await tester.pumpAndSettle();
    expect(store.byId('mine'), isNull);
  });
}
