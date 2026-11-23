import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/expense_repository.dart';
import 'package:fm_shop/domain/expenses/expense.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/screens/expenses/expense_list_screen.dart';

Future<InMemoryExpenseStore> pumpExpenses(
  WidgetTester tester, {
  required Role role,
  List<Expense> seed = const [],
  Locale? locale,
  Size size = const Size(540, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final auth = AuthState();
  await auth.signInLocally(email: 'a@b.c', role: role);
  final store = InMemoryExpenseStore(seed: seed);
  addTearDown(auth.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<ExpenseRepository>.value(value: store),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExpenseListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('tea: the amount, one tap for what for, save', (tester) async {
    final store = await pumpExpenses(tester, role: Role.staff);
    expect(find.text('No expenses yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('expenses-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount')), '60');
    await tester.tap(find.byKey(const Key('expense-kind-Tea & food')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    final saved = store.expenses.single;
    expect(saved.amount, 60);
    expect(saved.kind, 'Tea & food');
    expect(saved.method, 'Cash');
    // On the list, under today, with today's total.
    expect(find.byKey(Key('expense-${saved.id}')), findsOneWidget);
    expect(find.text('₹60'), findsWidgets);
  });

  testWidgets('forgetting what it was for says so instead of saving', (
    tester,
  ) async {
    final store = await pumpExpenses(tester, role: Role.admin);
    await tester.tap(find.byKey(const Key('expenses-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount')), '120');
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();
    expect(store.expenses, isEmpty);
    expect(find.text('Pick what it was for'), findsOneWidget);

    // And with no amount, the amount.
    await tester.enterText(find.byKey(const Key('expense-amount')), '');
    await tester.tap(find.byKey(const Key('expense-kind-Transport')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();
    expect(find.text('Type how much was paid'), findsOneWidget);
    expect(store.expenses, isEmpty);
  });

  testWidgets('staff cannot change one already saved; the owner can delete', (
    tester,
  ) async {
    final rent = Expense(
      id: 'r',
      amount: 15000,
      kind: 'Rent',
      method: 'UPI',
      spentAt: DateTime.now(),
    );
    await pumpExpenses(tester, role: Role.staff, seed: [rent]);
    await tester.tap(find.byKey(const Key('expense-r')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-save')), findsNothing);
    expect(find.byKey(const Key('expense-delete')), findsNothing);
    expect(
      find.text(
        'Only the owner can change or delete an expense once it is saved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the owner deletes, after a yes from the bottom', (tester) async {
    final rent = Expense(
      id: 'r',
      amount: 15000,
      kind: 'Rent',
      spentAt: DateTime.now(),
    );
    final store = await pumpExpenses(tester, role: Role.admin, seed: [rent]);
    await tester.tap(find.byKey(const Key('expense-r')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-delete')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.byKey(const Key('expense-delete-confirm')));
    await tester.pumpAndSettle();
    expect(store.expenses, isEmpty);
  });

  testWidgets('the usual tea is one tap and Save', (tester) async {
    final tea = Expense(
      id: 't',
      amount: 60,
      kind: 'Tea & food',
      spentAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final store = await pumpExpenses(tester, role: Role.staff, seed: [tea]);
    await tester.tap(find.byKey(const Key('expenses-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-again-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();
    expect(store.expenses, hasLength(2));
    final today = store.expenses.first;
    expect(today.amount, 60);
    expect(today.kind, 'Tea & food');
    expect(today.spentAt.day, DateTime.now().day);
  });

  for (final lang in ['ta', 'hi']) {
    testWidgets('fits a small phone in $lang: list, form, a missing field', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpExpenses(
        tester,
        role: Role.admin,
        locale: Locale(lang),
        size: const Size(360, 640),
        seed: [
          Expense(
            id: 'a',
            amount: 1800,
            kind: 'Shop supplies',
            note: 'A54 display from the supplier on Ritchie Street',
            method: 'UPI',
            spentAt: now,
            paidByName: 'Mani',
          ),
          Expense(id: 'b', amount: 15000, kind: 'Electricity', spentAt: now),
        ],
      );
      await tester.tap(find.byKey(const Key('expenses-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expense-save')));
      await tester.pumpAndSettle();
      // An overflow anywhere fails the test by itself.
      expect(tester.takeException(), isNull);
    });
  }
}
