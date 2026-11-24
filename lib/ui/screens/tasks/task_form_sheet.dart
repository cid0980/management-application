import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../widgets/save_guard.dart';
import '../../../data/shop_repository.dart';
import '../../../data/task_repository.dart';
import '../../../domain/shops/membership.dart';
import '../../../domain/tasks/task.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/field_help.dart';
import 'task_list_screen.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/busy.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/date_sheet.dart';

/// Open the add / edit task form over the whole screen, bottom bar included.
Future<void> openTaskSheet(BuildContext context, {ShopTask? editing}) async {
  final repo = context.read<TaskRepository>();
  final auth = context.read<AuthState>();
  final shops = context.read<ShopRepository?>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskRepository>.value(value: repo),
        ChangeNotifierProvider<AuthState>.value(value: auth),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: TaskFormSheet(editing: editing, shops: shops),
      ),
    ),
  );
}

/// THE TASK FORM
///
/// Five questions, in the order the POS asks them: what, who, how often, how
/// important, and — only for a one-time job — by when. Each has a "?".
///
/// The form never touches the ticks. Editing a task's wording must not undo
/// the fact that somebody already did it this morning.
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.editing, this.shops});

  final ShopTask? editing;

  /// Null offline or in a test: the form still works, with nobody to pick.
  final ShopRepository? shops;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.editing?.description ?? '',
  );
  late String _assignedTo = widget.editing?.assignedTo ?? '';
  late String _assignedToName = widget.editing?.assignedToName ?? '';
  late TaskFrequency _frequency =
      widget.editing?.frequency ?? TaskFrequency.daily;
  late TaskPriority _priority = widget.editing?.priority ?? TaskPriority.medium;
  late DateTime? _dueDate = widget.editing?.dueDate;

  TaskBlock? _block;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  TaskActor _actor(BuildContext context) {
    final auth = context.read<AuthState>();
    return TaskActor(uid: auth.user?.uid ?? '', isAdmin: auth.isAdmin);
  }

  Future<void> _save() async {
    final repo = context.read<TaskRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.l10n.taskSaved;
    final editing = widget.editing;

    final task = ShopTask(
      id: editing?.id ?? repo.newId(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      assignedTo: _assignedTo,
      assignedToName: _assignedToName,
      frequency: _frequency,
      priority: _priority,
      // A date left over from when this was a one-time job means nothing on a
      // repeating one, so it is not carried across.
      dueDate: _frequency == TaskFrequency.oneTime ? _dueDate : null,
      createdBy: editing?.createdBy ?? '',
      createdAt: editing?.createdAt,
    );

    setState(() => _saving = true);
    final result = await guardSave(
      context,
      () => repo.save(task, _actor(context)),
    );
    if (result == null) {
      // Not saved: the button comes back so it can be tried again.
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _block = result.block;
    });
    if (result.ok) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } else if (result.block == TaskBlock.noTitle) {
      // The cursor into the title, where the error now is.
      await jumpToFirstError(context, const [Key('task-title')]);
    }
  }

  Future<void> _delete() async {
    final repo = context.read<TaskRepository>();
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final actor = _actor(context);
    final sure = await confirmSheet(
      context,
      title: l10n.taskDeleteConfirm,
      body: widget.editing!.title,
      yes: l10n.taskDelete,
      no: l10n.cancel,
      yesKey: const Key('task-delete-confirm'),
    );
    if (!sure || !mounted) return;
    final result = await whileBusy(
      context,
      repo.delete(widget.editing!.id, actor),
    );
    if (!mounted) return;
    if (result.ok) {
      navigator.pop();
    } else {
      setState(() => _block = result.block);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickDateSheet(
      context,
      initial: _dueDate ?? now,
      first: DateTime(now.year - 1),
      last: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = context.watch<AuthState>();
    final shops = widget.shops;
    final shopId = auth.shopId;
    final editing = widget.editing;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('form-close'),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(editing == null ? l10n.taskNew : l10n.taskEdit),
        actions: [
          if (editing != null)
            IconButton(
              key: const Key('task-delete'),
              tooltip: l10n.taskDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            key: const Key('task-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              label: FieldLabel(l10n.taskTitleLabel, required: true),
              border: const OutlineInputBorder(),
              errorText: _block == TaskBlock.noTitle
                  ? l10n.taskBlockNoTitle
                  : null,
              suffixIcon: HelpButton(
                title: l10n.taskTitleLabel,
                body: l10n.helpTaskTitle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('task-description'),
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.taskDescriptionLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          HelpTitle(
            text: l10n.taskAssignLabel,
            help: l10n.helpTaskAssign,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),
          if (shops == null || shopId == null)
            _assignPicker(const [])
          else
            StreamBuilder<List<ShopMember>>(
              stream: shops.watchMembers(shopId),
              builder: (_, snapshot) =>
                  _assignPicker(snapshot.data ?? const []),
            ),
          const SizedBox(height: 20),
          HelpTitle(
            text: l10n.taskFrequencyLabel,
            help: l10n.helpTaskFrequency,
            icon: Icons.repeat,
          ),
          const SizedBox(height: 8),
          ChoiceRow<TaskFrequency>(
            values: TaskFrequency.values,
            selected: _frequency,
            labelOf: (f) => taskFrequencyLabel(l10n, f),
            keyOf: (f) => Key('task-frequency-${f.name}'),
            onPicked: (f) => setState(() => _frequency = f),
          ),
          const SizedBox(height: 20),
          HelpTitle(
            text: l10n.taskPriorityLabel,
            help: l10n.helpTaskPriority,
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 8),
          ChoiceRow<TaskPriority>(
            values: TaskPriority.values,
            selected: _priority,
            labelOf: (p) => taskPriorityLabel(l10n, p),
            keyOf: (p) => Key('task-priority-${p.name}'),
            onPicked: (p) => setState(() => _priority = p),
          ),
          // Asked only where it means something: a daily job has no deadline,
          // it is due today, every day.
          if (_frequency == TaskFrequency.oneTime) ...[
            const SizedBox(height: 20),
            HelpTitle(
              text: l10n.taskDueLabel,
              help: l10n.helpTaskDue,
              icon: Icons.event,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                key: const Key('task-due'),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dueDate == null
                      ? l10n.taskPickDate
                      : formatTaskDay(_dueDate!),
                ),
              ),
            ),
            if (_block == TaskBlock.noDueDate)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.taskBlockNoDueDate,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
          if (_block == TaskBlock.adminOnly)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                l10n.taskBlockAdminOnly,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const Key('task-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assignPicker(List<ShopMember> members) {
    final l10n = context.l10n;
    // Somebody who has since left the shop still holds the task until the
    // owner moves it, so they stay in the list rather than the box going
    // blank and the next save quietly un-assigning it.
    final known = members.any((m) => m.uid == _assignedTo);
    final uids = [
      '',
      if (_assignedTo.isNotEmpty && !known) _assignedTo,
      for (final m in members) m.uid,
    ];
    String nameOf(String uid) {
      if (uid.isEmpty) return l10n.taskTabUnassigned;
      for (final m in members) {
        if (m.uid == uid) return m.label;
      }
      return _assignedToName.isEmpty ? uid : _assignedToName;
    }

    // Everyone in one sideways row: a tap, not a pop-up list.
    return ChoiceRow<String>(
      key: const Key('task-assign'),
      values: uids,
      selected: _assignedTo,
      labelOf: nameOf,
      keyOf: (uid) => Key('task-assign-$uid'),
      onPicked: (uid) => setState(() {
        _assignedTo = uid;
        _assignedToName = uid.isEmpty ? '' : nameOf(uid);
      }),
    );
  }
}
