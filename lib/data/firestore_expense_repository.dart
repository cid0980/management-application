/// EXPENSES, OUT OF FIRESTORE
///
/// `shops/{shopId}/expenses`, newest first. The last 400 are kept live —
/// months of a small shop's spending — which is what the list and the
/// reports read.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/expenses/expense.dart';
import 'expense_repository.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';

class FirestoreExpenseStore extends ChangeNotifier
    implements ExpenseRepository {
  FirestoreExpenseStore({required this.scope});

  final ShopScope scope;

  List<Expense> _all = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  List<Expense> get expenses => _all;

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
    _sub = scope.expenses
        .orderBy('spentAt', descending: true)
        .limit(400)
        .snapshots()
        .listen(
          (snap) {
            _all = List.unmodifiable(
              newestFirst([
                for (final d in snap.docs) Expense.fromMap(d.id, d.data()),
              ]),
            );
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object e) {
            _loading = false;
            _error = describeFirestoreError(e, 'expenses');
            notifyListeners();
          },
        );
  }

  @override
  Expense? byId(String id) {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  String newId() => scope.expenses.doc().id;

  @override
  Future<ExpenseBlock?> save(Expense expense, ExpenseActor actor) async {
    final existing = byId(expense.id);
    final block = expenseSaveBlock(expense, actor, isNew: existing == null);
    if (block != null) return block;
    final stored = stampExpense(expense, existing, actor);
    await localWrite(scope.expenses.doc(stored.id).set(stored.toMap()));
    return null;
  }

  @override
  Future<ExpenseBlock?> delete(String id, ExpenseActor actor) async {
    if (!actor.isAdmin) return ExpenseBlock.adminOnly;
    await localWrite(scope.expenses.doc(id).delete());
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
