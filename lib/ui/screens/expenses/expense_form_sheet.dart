import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/expense_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/settings/shop_settings.dart' show OptionKind;
import '../../../domain/common/money.dart';
import '../../../domain/expenses/expense.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../l10n/l10n.dart';
import '../../widgets/busy.dart';
import '../../widgets/date_sheet.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import 'expense_labels.dart';

/// Open the add / edit expense form over the whole screen.
Future<void> openExpenseSheet(BuildContext context, {Expense? editing}) async {
  final repo = context.read<ExpenseRepository>();
  final auth = context.read<AuthState>();
  SettingsRepository? settings;
  try {
    settings = context.read<SettingsRepository>();
  } on ProviderNotFoundException {
    settings = null;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseRepository>.value(value: repo),
        ChangeNotifierProvider<AuthState>.value(value: auth),
        if (settings != null)
          ChangeNotifierProvider<SettingsRepository>.value(value: settings),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: ExpenseFormSheet(editing: editing),
      ),
    ),
  );
}

/// MONEY OUT, WRITTEN DOWN
///
/// How much first (the keyboard is already up), then what for — one tap in
/// a row — then how it was paid and which day; both have the usual answer
/// picked already (Cash, today), so tea is three taps and the amount.
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, this.editing});

  final Expense? editing;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final _amount = TextEditingController(
    text: widget.editing == null ? '' : '${widget.editing!.amount}',
  );
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late String? _kind = widget.editing?.kind;
  late String _method = widget.editing?.method ?? 'Cash';
  late DateTime _day = widget.editing?.spentAt ?? DateTime.now();
  ExpenseBlock? _block;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The shop's list (Settings > Expense types), plus the one being edited
  /// if it has since been taken off it.
  List<String> _kinds(BuildContext context) {
    List<String> listed;
    try {
      listed = context
          .watch<SettingsRepository>()
          .settings
          .list(OptionKind.expenseKinds)
          .values;
    } on ProviderNotFoundException {
      listed = kExpenseKinds;
    }
    final current = widget.editing?.kind;
    return [
      ...listed,
      if (current != null && !listed.contains(current)) current,
    ];
  }

  /// One of the usual ones, copied in; the day stays today.
  void _fill(Expense e) => setState(() {
    _amount.text = '${e.amount}';
    _kind = e.kind;
    _method = e.method;
    _note.text = e.note;
    _block = null;
  });

  ExpenseActor _actor() {
    final auth = context.read<AuthState>();
    return ExpenseActor(
      uid: auth.user?.uid ?? '',
      isAdmin: auth.isAdmin,
      name: auth.user?.name ?? '',
    );
  }

  Future<void> _save() async {
    final repo = context.read<ExpenseRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.l10n.expenseSaved;
    final now = DateTime.now();
    final expense = Expense(
      id: widget.editing?.id ?? repo.newId(),
      amount: asAmount(_amount.text),
      kind: _kind ?? '',
      method: _method,
      note: _note.text,
      // The day picked, at the time it was written down (or the original
      // time when only the day is being corrected).
      spentAt: DateTime(
        _day.year,
        _day.month,
        _day.day,
        widget.editing?.spentAt.hour ?? now.hour,
        widget.editing?.spentAt.minute ?? now.minute,
      ),
      paidBy: widget.editing?.paidBy ?? '',
      paidByName: widget.editing?.paidByName ?? '',
      createdAt: widget.editing?.createdAt,
    );
    setState(() => _saving = true);
    // Wrapped, so "saved with no complaint" (a null block) is told apart
    // from "failed, and the sheet already said why" (no answer at all).
    final answer = await guardSave(
      context,
      () async => (await repo.save(expense, _actor()),),
    );
    if (!mounted) return;
    final block = answer?.$1;
    final ok = answer != null && block == null;
    setState(() {
      _saving = false;
      _block = block;
    });
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } else if (block == ExpenseBlock.noAmount) {
      await jumpToFirstError(context, const [Key('expense-amount')]);
    } else if (block == ExpenseBlock.noKind) {
      await jumpToFirstError(context, const [Key('expense-kind')]);
    }
  }

  Future<void> _delete() async {
    final repo = context.read<ExpenseRepository>();
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final sure = await confirmSheet(
      context,
      title: l10n.expenseDeleteConfirm,
      body: widget.editing!.headline,
      yes: l10n.taskDelete,
      no: l10n.cancel,
      yesKey: const Key('expense-delete-confirm'),
    );
    if (!sure || !mounted) return;
    final block = await whileBusy(
      context,
      repo.delete(widget.editing!.id, _actor()),
    );
    if (!mounted) return;
    if (block == null) {
      navigator.pop();
    } else {
      setState(() => _block = block);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final editing = widget.editing;
    final isAdmin = context.watch<AuthState>().isAdmin;
    final locked = editing != null && !isAdmin;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('form-close'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(editing == null ? l10n.expenseNew : l10n.expenseEdit),
        actions: [
          if (editing != null && isAdmin)
            IconButton(
              key: const Key('expense-delete'),
              tooltip: l10n.taskDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.expenseOwnerOnly,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (editing == null) _Usual(onPicked: _fill),
          TextField(
            key: const Key('expense-amount'),
            controller: _amount,
            enabled: !locked,
            autofocus: editing == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              label: FieldLabel(l10n.amount, required: true),
              prefixText: '₹ ',
              border: const OutlineInputBorder(),
              errorText: _block == ExpenseBlock.noAmount
                  ? l10n.expenseNeedAmount
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          FieldLabel(l10n.expenseWhatFor, required: true),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: locked,
            child: ChoiceRow<String>(
              key: const Key('expense-kind'),
              values: _kinds(context),
              selected: _kind,
              labelOf: (k) => expenseKindLabel(l10n, k),
              keyOf: (k) => Key('expense-kind-$k'),
              onPicked: (k) => setState(() {
                _kind = k;
                if (_block == ExpenseBlock.noKind) _block = null;
              }),
            ),
          ),
          if (_block == ExpenseBlock.noKind)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.expenseNeedKind,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          Text(l10n.expensePaidHow, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: locked,
            child: ChoiceRow<String>(
              values: kExpenseMethods,
              selected: _method,
              labelOf: (m) => expenseMethodLabel(l10n, m),
              keyOf: (m) => Key('expense-method-$m'),
              onPicked: (m) => setState(() => _method = m),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            key: const Key('expense-day'),
            enabled: !locked,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(l10n.expenseDay),
            subtitle: Text(
              MaterialLocalizations.of(context).formatMediumDate(_day),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await pickDateSheet(
                context,
                initial: _day,
                first: DateTime(today.year - 2),
                last: today,
              );
              if (picked != null) setState(() => _day = picked);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('expense-note'),
            controller: _note,
            enabled: !locked,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.expenseNote,
              hintText: l10n.expenseNoteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_block == ExpenseBlock.adminOnly)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                l10n.expenseOwnerOnly,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      bottomNavigationBar: locked
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const Key('expense-save'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.save),
                  ),
                ),
              ),
            ),
    );
  }
}

/// "Again?": the last few different expenses as one row of buttons.
class _Usual extends StatelessWidget {
  const _Usual({required this.onPicked});

  final ValueChanged<Expense> onPicked;

  @override
  Widget build(BuildContext context) {
    final usual = usualExpenses(context.read<ExpenseRepository>().expenses);
    if (usual.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.expenseAgain, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, e) in usual.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ActionChip(
                    key: Key('expense-again-$i'),
                    avatar: Icon(expenseKindIcon(e.kind), size: 18),
                    label: Text(
                      '${e.note.trim().isEmpty ? expenseKindLabel(l10n, e.kind) : e.note.trim()} · ${rupees(e.amount)}',
                    ),
                    onPressed: () => onPicked(e),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
