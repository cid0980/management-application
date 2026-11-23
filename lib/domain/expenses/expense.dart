/// MONEY OUT
///
/// What the shop paid for: parts from the supplier, tea, the rent, the
/// electricity bill, a salary, an auto to the market. Without it the reports
/// only know what came in, so "how much should be in the drawer tonight" and
/// "did we make money this month" cannot be answered.
///
/// One payment is one record: how much, what for, how it was paid, which
/// day, and a line of note. Anyone in the shop can write one down (the
/// person who paid for tea is the one who knows); only the owner can change
/// or delete one afterwards.
library;

import '../common/dates.dart';
import '../inventory/purchase_costing.dart' show asAmount;

/// What it was for. Stored in English, shown in the phone's language.
const List<String> kExpenseKinds = [
  'Parts',
  'Tea & food',
  'Rent',
  'Electricity',
  'Salary',
  'Transport',
  'Shop supplies',
  'Other',
];

/// How it was paid. Cash comes out of the drawer; the rest does not.
const List<String> kExpenseMethods = ['Cash', 'UPI', 'Card'];

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.kind,
    required this.spentAt,
    this.method = 'Cash',
    this.note = '',
    this.paidBy = '',
    this.paidByName = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final num amount;
  final String kind;
  final DateTime spentAt;
  final String method;
  final String note;

  /// Who wrote it down.
  final String paidBy;
  final String paidByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCash => method.trim().isEmpty || method == 'Cash';

  /// "Tea & food · Cash" or the note when there is one.
  String get headline => note.trim().isEmpty ? kind : note.trim();

  Expense copyWith({
    num? amount,
    String? kind,
    DateTime? spentAt,
    String? method,
    String? note,
    String? paidBy,
    String? paidByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Expense(
    id: id,
    amount: amount ?? this.amount,
    kind: kind ?? this.kind,
    spentAt: spentAt ?? this.spentAt,
    method: method ?? this.method,
    note: note ?? this.note,
    paidBy: paidBy ?? this.paidBy,
    paidByName: paidByName ?? this.paidByName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Expense fromMap(String id, Map<String, Object?> map) => Expense(
    id: id,
    amount: asAmount(map['amount']),
    kind: (map['kind'] as String?)?.trim().isNotEmpty == true
        ? (map['kind'] as String).trim()
        : 'Other',
    spentAt:
        normalizeDate(map['spentAt']) ??
        normalizeDate(map['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    method: (map['method'] as String?) ?? 'Cash',
    note: (map['note'] as String?) ?? '',
    paidBy: (map['paidBy'] as String?) ?? '',
    paidByName: (map['paidByName'] as String?) ?? '',
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'amount': amount,
    'kind': kind,
    'spentAt': spentAt.toIso8601String(),
    'method': method,
    'note': note,
    'paidBy': paidBy,
    'paidByName': paidByName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      kind,
      note,
      method,
      paidByName,
      '$amount',
    ].any((s) => s.toLowerCase().contains(q));
  }
}

/// Why an expense cannot be saved, or changed by this person.
enum ExpenseBlock { noAmount, noKind, adminOnly }

/// Who is writing.
class ExpenseActor {
  const ExpenseActor({
    required this.uid,
    required this.isAdmin,
    this.name = '',
  });

  final String uid;
  final bool isAdmin;
  final String name;
}

/// Null when [e] may be saved by [actor]. A new one by anyone; an existing
/// one ([isNew] false) only by the owner, so what was paid out yesterday
/// cannot quietly shrink.
ExpenseBlock? expenseSaveBlock(
  Expense e,
  ExpenseActor actor, {
  required bool isNew,
}) {
  if (!isNew && !actor.isAdmin) return ExpenseBlock.adminOnly;
  if (e.amount <= 0) return ExpenseBlock.noAmount;
  if (e.kind.trim().isEmpty) return ExpenseBlock.noKind;
  return null;
}

/// MONEY OUT OVER A SPAN
///
/// [total] is all of it; [cash] is what left the drawer; [byKind] is most
/// money first, for "where did it go".
class ExpenseSummary {
  const ExpenseSummary({
    required this.total,
    required this.cash,
    required this.byKind,
    required this.count,
  });

  final num total;
  final num cash;
  final List<(String, num)> byKind;
  final int count;

  bool get isEmpty => count == 0;
}

ExpenseSummary summarizeExpenses(Iterable<Expense> all, DateRange range) {
  num total = 0;
  num cash = 0;
  var count = 0;
  final kinds = <String, num>{};
  for (final e in all) {
    if (!range.contains(e.spentAt)) continue;
    count++;
    total += e.amount;
    if (e.isCash) cash += e.amount;
    kinds[e.kind] = (kinds[e.kind] ?? 0) + e.amount;
  }
  final byKind = [for (final k in kinds.entries) (k.key, k.value)]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return ExpenseSummary(total: total, cash: cash, byKind: byKind, count: count);
}

/// Newest first, then by when it was written down.
List<Expense> newestFirst(Iterable<Expense> all) => [...all]
  ..sort((a, b) {
    final c = b.spentAt.compareTo(a.spentAt);
    if (c != 0) return c;
    return (b.createdAt ?? b.spentAt).compareTo(a.createdAt ?? a.spentAt);
  });

/// THE USUAL ONES
///
/// The last few different expenses (what for, how much, how paid, the
/// note), newest first, so a daily tea or the weekly auto is one tap on the
/// form instead of typing it again.
List<Expense> usualExpenses(Iterable<Expense> all, {int limit = 4}) {
  final seen = <String>{};
  final out = <Expense>[];
  for (final e in newestFirst(all)) {
    final key = '${e.kind}|${e.amount}|${e.method}|${e.note.trim()}';
    if (!seen.add(key)) continue;
    out.add(e);
    if (out.length == limit) break;
  }
  return out;
}
