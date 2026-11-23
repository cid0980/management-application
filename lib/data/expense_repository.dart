/// WHERE EXPENSES COME FROM
///
/// The rules are in `domain/expenses/expense.dart`; the stores apply them on
/// the write, so a hidden button is not the only thing stopping a staff
/// member editing yesterday's rent.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/expenses/expense.dart';

abstract class ExpenseRepository extends ChangeNotifier {
  /// Newest first.
  List<Expense> get expenses;
  bool get loading;
  String? get error;

  Future<void> load();

  Expense? byId(String id);

  /// A fresh id for one not saved yet.
  String newId();

  /// Add, or (owner only) change. Null when saved.
  Future<ExpenseBlock?> save(Expense expense, ExpenseActor actor);

  /// Owner only. Null when deleted.
  Future<ExpenseBlock?> delete(String id, ExpenseActor actor);
}

/// Shared by both stores: the record as it should be written.
Expense stampExpense(Expense e, Expense? existing, ExpenseActor actor) {
  final now = DateTime.now();
  return e.copyWith(
    kind: e.kind.trim(),
    note: e.note.trim(),
    paidBy: existing?.paidBy.isNotEmpty == true ? existing!.paidBy : actor.uid,
    paidByName: existing?.paidByName.isNotEmpty == true
        ? existing!.paidByName
        : actor.name,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  );
}

class InMemoryExpenseStore extends ChangeNotifier implements ExpenseRepository {
  InMemoryExpenseStore({List<Expense>? seed}) {
    _all = [...(seed ?? _seed())];
  }

  late List<Expense> _all;
  int _next = 1;

  @override
  List<Expense> get expenses => List.unmodifiable(newestFirst(_all));

  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  Future<void> load() async {}

  @override
  Expense? byId(String id) => _all.firstWhereOrNull((e) => e.id == id);

  @override
  String newId() => 'exp-new-${_next++}';

  @override
  Future<ExpenseBlock?> save(Expense expense, ExpenseActor actor) async {
    final existing = byId(expense.id);
    final block = expenseSaveBlock(expense, actor, isNew: existing == null);
    if (block != null) return block;
    final stored = stampExpense(expense, existing, actor);
    final i = _all.indexWhere((e) => e.id == stored.id);
    if (i >= 0) {
      _all[i] = stored;
    } else {
      _all.add(stored);
    }
    notifyListeners();
    return null;
  }

  @override
  Future<ExpenseBlock?> delete(String id, ExpenseActor actor) async {
    if (!actor.isAdmin) return ExpenseBlock.adminOnly;
    _all.removeWhere((e) => e.id == id);
    notifyListeners();
    return null;
  }
}

/// A few days of a small shop's spending, for trying the app and for tours.
List<Expense> _seed() {
  final now = DateTime.now();
  DateTime at(int daysAgo, int h) =>
      DateTime(now.year, now.month, now.day - daysAgo, h);
  return [
    Expense(
      id: 'exp-1',
      amount: 60,
      kind: 'Tea & food',
      spentAt: at(0, 11),
      paidByName: 'Mani',
    ),
    Expense(
      id: 'exp-2',
      amount: 1800,
      kind: 'Parts',
      note: 'A54 display from Ritchie Street',
      method: 'UPI',
      spentAt: at(0, 13),
    ),
    Expense(
      id: 'exp-3',
      amount: 120,
      kind: 'Transport',
      note: 'Auto to the market',
      spentAt: at(1, 16),
    ),
    Expense(
      id: 'exp-4',
      amount: 15000,
      kind: 'Rent',
      method: 'UPI',
      spentAt: at(3, 10),
    ),
  ];
}
