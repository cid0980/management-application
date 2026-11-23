import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/expense_repository.dart';
import '../../../domain/common/dates.dart';
import '../../../domain/common/money.dart';
import '../../../domain/expenses/expense.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading.dart';
import 'expense_form_sheet.dart';
import 'expense_labels.dart';

/// MONEY OUT — `/expenses`
///
/// Today's and this month's spending at the top, then every payment, a day
/// at a time with the day's total. A row opens it; the button adds one.
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.watch<ExpenseRepository>();
    final theme = Theme.of(context);

    if (repo.error != null) {
      return ErrorState(
        title: l10n.expensesCouldNotLoad,
        detail: repo.error!,
        onRetry: repo.load,
      );
    }
    final now = DateTime.now();
    final all = repo.expenses;
    final today = summarizeExpenses(all, DateRange.day(now));
    final month = summarizeExpenses(all, DateRange.month(now));

    // A day at a time, newest first.
    final days = <DateTime, List<Expense>>{};
    for (final e in all) {
      final d = DateTime(e.spentAt.year, e.spentAt.month, e.spentAt.day);
      (days[d] ??= []).add(e);
    }
    final loc = MaterialLocalizations.of(context);

    return Scaffold(
      body: repo.loading && all.isEmpty
          ? LoadingWords(first: l10n.loadingExpenses)
          : all.isEmpty
          ? EmptyState(
              icon: Icons.payments_outlined,
              title: l10n.expensesEmpty,
              detail: l10n.expensesEmptyDetail,
            )
          : FadeIn(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  Card(
                    key: const Key('expenses-totals'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Total(
                              label: l10n.today,
                              amount: today.total,
                              note: today.cash > 0
                                  ? l10n.expenseCashPart(rupees(today.cash))
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: _Total(
                              label: l10n.expenseThisMonth,
                              amount: month.total,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final entry in days.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSameDay(entry.key, now)
                                  ? l10n.today
                                  : loc.formatMediumDate(entry.key),
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            rupees(
                              entry.value.fold<num>(0, (s, e) => s + e.amount),
                            ),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    for (final e in entry.value)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          key: Key('expense-${e.id}'),
                          leading: Icon(expenseKindIcon(e.kind)),
                          title: Text(
                            e.note.trim().isEmpty
                                ? expenseKindLabel(l10n, e.kind)
                                : e.note.trim(),
                          ),
                          subtitle: Text(
                            [
                              if (e.note.trim().isNotEmpty)
                                expenseKindLabel(l10n, e.kind),
                              expenseMethodLabel(l10n, e.method),
                              if (e.paidByName.isNotEmpty) e.paidByName,
                            ].join(' · '),
                          ),
                          trailing: Text(
                            rupees(e.amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => openExpenseSheet(context, editing: e),
                        ),
                      ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('expenses-new'),
        heroTag: 'expense-new',
        onPressed: () => openExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseNew),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount, this.note});

  final String label;
  final num amount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          rupees(amount),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (note != null) Text(note!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
