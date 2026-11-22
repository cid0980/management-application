import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/shop_repository.dart';
import '../../../data/task_repository.dart';
import '../../../domain/shops/membership.dart';
import '../../../domain/tasks/task.dart';
import '../../../domain/tasks/task_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import 'task_form_sheet.dart';
import '../../widgets/fading_scroll.dart';
import '../../widgets/loading.dart';

/// THE TASK LIST — one screen behind two doors
///
/// `/admin/tasks` ([manage] true) is the owner's: every task in the shop, a
/// filter by staff member, and the button that adds one. `/tasks` is a staff
/// member's: their own tasks and a big Done button on each.
///
/// One widget rather than two, so a row cannot look or sort differently
/// depending on who opened it. What differs is decided by `canSeeTask`, which
/// the repository applies again on the write.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.manage});

  /// The owner's page: add, edit, delete, and filter by staff member.
  final bool manage;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskTab _tab = TaskTab.toDo;

  /// Null means everyone. Only the owner's page can set it.
  String? _staffUid;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();
    final auth = context.watch<AuthState>();
    final l10n = context.l10n;
    final user = auth.user;

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.tasksCouldNotLoad),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: repo.load, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      );
    }

    // The staff page never acts as an admin, even for an admin who opens it:
    // "My Tasks" means mine.
    final actor = TaskActor(
      uid: user?.uid ?? '',
      isAdmin: widget.manage && auth.isAdmin,
    );

    // Read once per build, so every count and row agrees what day it is.
    final now = DateTime.now();
    final tabs = taskTabsFor(actor);
    final tab = tabs.contains(_tab) ? _tab : TaskTab.toDo;
    final counts = taskTabCounts(
      repo.tasks,
      actor: actor,
      now: now,
      assignedTo: _staffUid,
    );
    final rows = taskRows(
      repo.tasks,
      tab: tab,
      actor: actor,
      now: now,
      assignedTo: _staffUid,
    );

    final shops = context.watch<ShopRepository?>();
    final shopId = auth.shopId;

    Widget body(List<ShopMember> members) => Column(
      children: [
        if (widget.manage && members.isNotEmpty)
          _StaffFilter(
            members: members,
            selected: _staffUid,
            onChanged: (uid) => setState(() => _staffUid = uid),
          ),
        FadingScroll(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              for (final t in tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('task-tab-${t.name}'),
                    selected: tab == t,
                    label: Text('${taskTabLabel(l10n, t)} ${counts[t]}'),
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: repo.loading
              ? LoadingWords(first: context.l10n.loadingTasks)
              : rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 48,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.taskNoTasks),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _TaskCard(
                    task: rows[i],
                    now: now,
                    actor: actor,
                    manage: widget.manage,
                  ),
                ),
        ),
      ],
    );

    return Scaffold(
      body: !widget.manage || shops == null || shopId == null
          ? body(const [])
          : StreamBuilder<List<ShopMember>>(
              stream: shops.watchMembers(shopId),
              builder: (_, snapshot) => body(snapshot.data ?? const []),
            ),
      floatingActionButton: widget.manage && auth.isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'task-new',
              onPressed: () => openTaskSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.taskAdd),
            )
          : null,
    );
  }
}

String taskTabLabel(AppLocalizations l10n, TaskTab tab) => switch (tab) {
  TaskTab.toDo => l10n.taskTabToDo,
  TaskTab.done => l10n.taskTabDone,
  TaskTab.daily => l10n.taskFreqDaily,
  TaskTab.weekly => l10n.taskFreqWeekly,
  TaskTab.monthly => l10n.taskFreqMonthly,
  TaskTab.oneTime => l10n.taskFreqOnce,
  TaskTab.unassigned => l10n.taskTabUnassigned,
};

String taskFrequencyLabel(AppLocalizations l10n, TaskFrequency f) =>
    switch (f) {
      TaskFrequency.daily => l10n.taskFreqDaily,
      TaskFrequency.weekly => l10n.taskFreqWeekly,
      TaskFrequency.monthly => l10n.taskFreqMonthly,
      TaskFrequency.oneTime => l10n.taskFreqOnce,
    };

String taskPriorityLabel(AppLocalizations l10n, TaskPriority p) => switch (p) {
  TaskPriority.low => l10n.taskPriorityLow,
  TaskPriority.medium => l10n.taskPriorityMedium,
  TaskPriority.high => l10n.taskPriorityHigh,
};

String taskBlockLabel(AppLocalizations l10n, TaskBlock block) =>
    switch (block) {
      TaskBlock.noTitle => l10n.taskBlockNoTitle,
      TaskBlock.noDueDate => l10n.taskBlockNoDueDate,
      TaskBlock.adminOnly => l10n.taskBlockAdminOnly,
      TaskBlock.notYours => l10n.taskBlockNotYours,
    };

String formatTaskDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class _StaffFilter extends StatelessWidget {
  const _StaffFilter({
    required this.members,
    required this.selected,
    required this.onChanged,
  });

  final List<ShopMember> members;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DropdownButtonFormField<String?>(
        key: const Key('task-staff-filter'),
        initialValue: members.any((m) => m.uid == selected) ? selected : null,
        isExpanded: true,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.person_outline),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(context.l10n.taskAllStaff),
          ),
          for (final m in members)
            DropdownMenuItem<String?>(value: m.uid, child: Text(m.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.now,
    required this.actor,
    required this.manage,
  });

  final ShopTask task;
  final DateTime now;
  final TaskActor actor;
  final bool manage;

  Future<void> _toggle(BuildContext context, bool done) async {
    final repo = context.read<TaskRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = done
        ? await repo.untick(task.id, actor, day: now)
        : await repo.tick(task.id, actor, day: now);
    if (!result.ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(taskBlockLabel(l10n, result.block!))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.shopColors;
    final l10n = context.l10n;
    final done = task.isDoneOn(now);
    final overdue = task.isOverdueOn(now);

    // Every state is a word and an icon as well as a colour.
    final (Color fg, Color bg, IconData icon) = switch (task.priority) {
      TaskPriority.high => (colors.stop, colors.stopSoft, Icons.priority_high),
      TaskPriority.medium => (colors.wait, colors.waitSoft, Icons.remove),
      TaskPriority.low => (colors.info, colors.infoSoft, Icons.arrow_downward),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: Key('task-${task.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: manage && actor.isAdmin
            ? () => openTaskSheet(context, editing: task)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? colors.good : theme.disabledColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? theme.disabledColor : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(task.description, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Badge(
                    icon: icon,
                    text: taskPriorityLabel(l10n, task.priority),
                    fg: fg,
                    bg: bg,
                  ),
                  _Badge(
                    icon: Icons.repeat,
                    text: taskFrequencyLabel(l10n, task.frequency),
                    fg: colors.done,
                    bg: colors.doneSoft,
                  ),
                  if (overdue)
                    _Badge(
                      icon: Icons.warning_amber,
                      text: l10n.taskOverdue,
                      fg: colors.stop,
                      bg: colors.stopSoft,
                    ),
                ],
              ),
              if (task.frequency == TaskFrequency.oneTime &&
                  task.dueDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.taskDueOn(formatTaskDay(task.dueDate!)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overdue ? colors.stop : null,
                  ),
                ),
              ],
              if (manage) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      task.isAssigned
                          ? Icons.person_outline
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: task.isAssigned ? null : colors.wait,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.isAssigned
                            ? (task.assignedToName.isEmpty
                                  ? task.assignedTo
                                  : task.assignedToName)
                            // Said on the row, because a task nobody can see
                            // looks exactly like one that is being ignored.
                            : l10n.taskNobodySees,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isAssigned ? null : colors.wait,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: done
                    ? OutlinedButton.icon(
                        key: Key('task-undo-${task.id}'),
                        onPressed: () => _toggle(context, true),
                        icon: const Icon(Icons.undo),
                        label: Text(l10n.taskUndo),
                      )
                    : FilledButton.icon(
                        key: Key('task-done-${task.id}'),
                        onPressed: () => _toggle(context, false),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.taskMarkDone),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
