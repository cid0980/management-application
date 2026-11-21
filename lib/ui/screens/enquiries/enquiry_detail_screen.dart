import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/enquiry_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/enquiries/enquiry.dart';
import '../../../domain/enquiries/enquiry_state.dart';
import 'enquiry_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/contact_buttons.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l10n.noEnquiry(id), textAlign: TextAlign.center),
        ),
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final validation = validateEnquiry(enquiry);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(enquiry.headline, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            [
              kEnquiryStateLabels[enquiry.lifecycleAt(now)]!,
              enquiry.status,
            ].join(' · '),
          ),
          const SizedBox(height: 16),
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
                ? '₹${enquiry.budget}'
                : context.l10n.theyDidNotSay,
            context.l10n.quoted: enquiry.quotedPrice > 0
                ? '₹${enquiry.quotedPrice}'
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => openEnquirySheet(context, existing: enquiry),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.edit),
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
        ),
      ),
    );
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
    await repo.setFollowUp(
      enquiry.id,
      DateTime(picked.year, picked.month, picked.day, 11),
    );
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
              'Marking this Won asks which sale or repair it became.',
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
      if (ref == null) return;
    }

    final result = await repo.setStatus(enquiry.id, status, outcomeRef: ref);
    messenger.showSnackBar(
      SnackBar(content: Text(result.ok ? 'Now $status' : result.message!)),
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
        const Text(
          'An invoice number, a service order number, or a note. A won '
          'enquiry with nothing to point at cannot be counted.',
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.titleSmall),
        const Divider(),
        for (final entry in rows.entries)
          if (entry.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.key.isNotEmpty)
                    SizedBox(
                      width: 140,
                      child: Text(entry.key, style: theme.textTheme.bodySmall),
                    ),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            ),
      ],
    );
  }
}
