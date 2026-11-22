import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/enquiry_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/common/money.dart';
import '../../../domain/enquiries/enquiry.dart';
import '../../../domain/enquiries/enquiry_state.dart';
import 'enquiry_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/contact_buttons.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/rule_messages.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../service/service_form_sheet.dart';

/// ONE ENQUIRY
///
/// What was asked, who asked, and what came of it.
///
/// The status chips are free to go anywhere, because an enquiry has no
/// workflow to protect — somebody who quoted a price and then heard the
/// customer went elsewhere moves it straight to Lost, and reopening a Lost
/// enquiry because they came back is an ordinary Tuesday.
///
/// The one exception is **Won**, which asks what it became. An enquiry marked
/// won with nothing to point at is how a conversion rate gets inflated.
class EnquiryDetailScreen extends StatelessWidget {
  const EnquiryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EnquiryRepository>();
    final enquiry = repo.byId(id);

    if (enquiry == null) {
      if (repo.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return EmptyState(
        icon: Icons.search_off,
        title: context.l10n.noEnquiry(id),
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final validation = validateEnquiry(enquiry);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RecordTitleCard(
            title: enquiry.headline,
            pills: [
              _LifecyclePill(lifecycle: enquiry.lifecycleAt(now)),
              // The raw status as well: an unrecognised one shows as itself.
              StatusPill(
                enquiry.status,
                color: AppTheme.primary,
                soft: AppTheme.surfaceSubtle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatusPicker(enquiry: enquiry),
          _Block(context.l10n.whoAsked, {
            context.l10n.name: enquiry.customerName.isEmpty
                ? context.l10n.noNameGiven
                : enquiry.customerName,
            context.l10n.shopPhone: formatPhone(enquiry.customerPhone),
            if (enquiry.handledBy.isNotEmpty)
              context.l10n.takenBy: enquiry.handledBy,
          }),
          const SizedBox(height: 4),
          ContactButtons(
            phone: enquiry.customerPhone,
            message: context.l10n.waEnquiry(
              enquiry.customerName,
              shopNameOf(context),
              enquiry.headline,
            ),
          ),
          const SizedBox(height: 12),
          _Block(context.l10n.whatTheyAsked, {
            if (enquiry.about.isNotEmpty) context.l10n.about: enquiry.about,
            if (enquiry.question.isNotEmpty)
              context.l10n.inTheirWords: enquiry.question,
            if (enquiry.device.isNotEmpty) context.l10n.device: enquiry.device,
          }),
          _Block(context.l10n.money, {
            // Zero means they did not say, which is not a zero budget.
            context.l10n.theirBudget: enquiry.hasBudget
                ? rupees(enquiry.budget)
                : context.l10n.theyDidNotSay,
            context.l10n.quoted: enquiry.quotedPrice > 0
                ? rupees(enquiry.quotedPrice)
                : context.l10n.notQuoted,
          }),
          if (enquiry.quotedOverBudget)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                // Usually the reason the answer was no.
                context.l10n.quotedAgainstBudget(
                  '${enquiry.quotedPrice}',
                  '${enquiry.budget}',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          _Block(context.l10n.followUp, {
            context.l10n.askedOn: _formatDate(enquiry.askedAt),
            context.l10n.ringBack: enquiry.followUpAt == null
                ? context.l10n.notSet
                : _formatDate(enquiry.followUpAt),
            if (enquiry.closedAt != null)
              context.l10n.dealtWith: _formatDate(enquiry.closedAt),
            if (enquiry.outcomeRef.isNotEmpty)
              context.l10n.whatItBecame: enquiry.outcomeRef,
          }),
          if (enquiry.notes.isNotEmpty)
            _Block(context.l10n.notes, {'': enquiry.notes}),
          if (validation.hasWarnings)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.worthALook,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      for (final w in validation.warnings.values) Text('• $w'),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: ActionBar(
        children: [
          OutlinedButton.icon(
            onPressed: () => openEnquirySheet(context, existing: enquiry),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.l10n.edit),
          ),
          // The enquiry became a job: open the repair form with what the
          // enquiry already knows, and mark it Won with the job number.
          if (!enquiry.closed)
            FilledButton.icon(
              key: const Key('enquiry-start-repair'),
              onPressed: () => _startRepair(context, enquiry),
              icon: const Icon(Icons.build_outlined),
              label: Text(context.l10n.startARepair),
            ),
          OutlinedButton.icon(
            key: const Key('enquiry-followup-set'),
            onPressed: () => _pickFollowUp(context, enquiry),
            icon: const Icon(Icons.event),
            label: Text(
              enquiry.followUpAt == null
                  ? context.l10n.setAFollowUp
                  : context.l10n.changeTheFollowUp,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRepair(BuildContext context, Enquiry enquiry) async {
    final repo = context.read<EnquiryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final order = await openServiceSheet(
      context,
      prefill: IntakePrefill(
        brand: enquiry.brand,
        model: enquiry.model,
        customerPhone: enquiry.customerPhone,
        customerName: enquiry.customerName,
        notes: enquiry.question,
      ),
    );
    if (order == null) {
      return;
    }
    final ref = order.orderNumber.isEmpty ? order.id : order.orderNumber;
    if (!context.mounted) return;
    final result = await guardSave(
      context,
      () => repo.setStatus(enquiry.id, 'Won', outcomeRef: ref),
    );
    if (result == null) {
      return;
    }
    if (result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.enquiryWonAs(ref))));
    }
  }

  Future<void> _pickFollowUp(BuildContext context, Enquiry enquiry) async {
    final repo = context.read<EnquiryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: enquiry.followUpAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !context.mounted) return;
    final said = context.l10n.ringBackOn(_formatDate(picked));
    if (!context.mounted) return;
    if (!await guardRun(
      context,
      () => repo.setFollowUp(
        enquiry.id,
        DateTime(picked.year, picked.month, picked.day, 11),
      ),
    )) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(said)));
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return 'not set';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final options = enquiryStatusOptions(enquiry.status);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.whatCameOfIt,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final status in options)
                  ChoiceChip(
                    key: Key('enquiry-status-$status'),
                    label: Text(status),
                    selected: enquiry.status == status,
                    onSelected: enquiry.status == status
                        ? null
                        : (_) => _set(context, status),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              // Said plainly, so nobody avoids Won because they do not know
              // what it will ask for.
              context.l10n.wonAsksWhich,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _set(BuildContext context, String status) async {
    final repo = context.read<EnquiryRepository>();
    final messenger = ScaffoldMessenger.of(context);

    String? ref;
    if (isEnquiryWon(status) && enquiry.outcomeRef.trim().isEmpty) {
      ref = await showDialog<String>(
        context: context,
        builder: (_) => const _OutcomeDialog(),
      );
      // Cancelled: the status does not move, because Won without an outcome is
      // exactly what this is for.
      if (ref == null) {
        return;
      }
    }

    if (!context.mounted) return;
    final result = await guardSave(
      context,
      () => repo.setStatus(enquiry.id, status, outcomeRef: ref),
    );
    if (result == null) {
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? context.l10n.statusNamed(status)
              : ruleText(context, result.message!),
        ),
      ),
    );
  }
}

/// Owns its controller, because the dialog's widgets keep rebuilding while the
/// route animates out.
class _OutcomeDialog extends StatefulWidget {
  const _OutcomeDialog();

  @override
  State<_OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<_OutcomeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.whatDidThisBecome),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wonOutcomeHelp),
        const SizedBox(height: 12),
        TextField(
          key: const Key('outcome-ref'),
          controller: _controller,
          decoration: InputDecoration(
            labelText: context.l10n.saleRepairOrNote,
            hintText: 'INV-20260304-007',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.markWon),
      ),
    ],
  );
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.rows);
  final String title;
  final Map<String, String> rows;

  /// A labelled card, read like a paper job card. An empty value is left
  /// out; a value of a single space marks a row that is its own label.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: FactsCard(
      title: title,
      rows: [
        for (final e in rows.entries)
          e.value.trim().isEmpty
              ? FactRow.widget(e.key, const SizedBox.shrink())
              : FactRow(e.key, e.value),
      ],
    ),
  );
}

class _LifecyclePill extends StatelessWidget {
  const _LifecyclePill({required this.lifecycle});

  final EnquiryLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final c = context.shopColors;
    final (Color fg, Color soft) = switch (lifecycle) {
      EnquiryLifecycle.overdue => (c.stop, c.stopSoft),
      EnquiryLifecycle.open => (AppTheme.primary, AppTheme.surfaceSubtle),
      EnquiryLifecycle.closed => (c.done, c.doneSoft),
    };
    return StatusPill(
      enquiryLifecycleLabel(context, lifecycle),
      color: fg,
      soft: soft,
      icon: lifecycle == EnquiryLifecycle.overdue ? Icons.schedule : null,
    );
  }
}
