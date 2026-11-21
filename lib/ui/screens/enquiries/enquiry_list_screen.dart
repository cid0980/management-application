import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/enquiry_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/enquiries/enquiry.dart';
import '../../../domain/enquiries/enquiry_list.dart';
import '../../../domain/enquiries/enquiry_state.dart';
import 'enquiry_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';

/// THE ENQUIRIES LIST
///
/// A call list. The first two tabs are the reason anybody opens it: what
/// should have been rung back already, and what needs ringing today.
///
/// Follow-up soonest first, with the unscheduled ones last — an enquiry with
/// no follow-up date is not urgent, it is just not scheduled, and letting it
/// sit at the top would imply otherwise.
class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  EnquiryTab _tab = EnquiryTab.open;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EnquiryRepository>();
    final theme = Theme.of(context);

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.enquiriesCouldNotLoad),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: repo.load,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    // Read once per build, so every tab, count and row in this frame agrees
    // about what day it is.
    final now = DateTime.now();
    final all = repo.enquiries;
    final counts = enquiryTabCounts(all, query: _query, now: now);
    final rows = enquiryRows(all, tab: _tab, query: _query, now: now);
    final conversion = enquiryConversion(all);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('enquiry-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchEnquiries,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final tab in EnquiryTab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _tab == tab,
                      label: Text(
                        '${enquiryTabLabel(context, tab)} ${counts[tab]}',
                      ),
                      onSelected: (_) => setState(() => _tab = tab),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    conversion.rate == null
                        // Null, not zero: nothing closed yet does not mean the
                        // shop wins nothing.
                        ? context.l10n.openNothingClosed('${conversion.open}')
                        : context.l10n.openWonOfClosed(
                            '${conversion.open}',
                            '${conversion.won}',
                            '${conversion.closed}',
                            (conversion.rate! * 100).toStringAsFixed(0),
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: repo.loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _query.isEmpty
                            ? context.l10n.nothingInTab(
                                enquiryTabLabel(context, _tab),
                              )
                            : context.l10n.noMatchFor(_query),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _EnquiryRow(enquiry: rows[i], now: now),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'enquiry-new',
        onPressed: () => openEnquirySheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.record),
      ),
    );
  }
}

class _EnquiryRow extends StatelessWidget {
  const _EnquiryRow({required this.enquiry, required this.now});

  final Enquiry enquiry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lifecycle = enquiry.lifecycleAt(now);

    return ListTile(
      onTap: () => context.go('/enquiries/${enquiry.id}'),
      // The question leads, because it is what somebody scanning the list is
      // looking for.
      title: Text(
        enquiry.headline,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (enquiry.customerName.isNotEmpty) enquiry.customerName,
              formatPhone(enquiry.customerPhone),
              if (enquiry.handledBy.isNotEmpty) enquiry.handledBy,
            ].where((p) => p.isNotEmpty).join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            enquiry.followUpAt == null
                ? context.l10n.noFollowUpSet
                : context.l10n.ringBackNamed(_formatDay(enquiry.followUpAt!)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: lifecycle == EnquiryLifecycle.overdue
                  ? theme.colorScheme.error
                  : null,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _LifecycleChip(lifecycle: lifecycle),
          const SizedBox(height: 2),
          // The raw status as well as the derived one: an unrecognised status
          // has to show as itself.
          Text(enquiry.status, style: theme.textTheme.labelSmall),
        ],
      ),
      isThreeLine: true,
    );
  }

  static String _formatDay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LifecycleChip extends StatelessWidget {
  const _LifecycleChip({required this.lifecycle});

  final EnquiryLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (lifecycle) {
      EnquiryLifecycle.overdue => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      EnquiryLifecycle.open => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      EnquiryLifecycle.closed => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        kEnquiryStateLabels[lifecycle]!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
