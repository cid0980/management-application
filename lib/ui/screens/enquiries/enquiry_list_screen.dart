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
import '../../widgets/empty_state.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading.dart';
import '../../widgets/contact_buttons.dart';

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
      return ErrorState(
        title: context.l10n.enquiriesCouldNotLoad,
        detail: repo.error!,
        onRetry: repo.load,
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
          NavySearchBlock(
            fieldKey: const Key('enquiry-search'),
            hint: context.l10n.searchEnquiries,
            onChanged: (v) => setState(() => _query = v),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final tab in EnquiryTab.values)
                  CountChip(
                    label: enquiryTabLabel(context, tab),
                    count: counts[tab],
                    color: switch (tab.name) {
                      'overdue' => context.shopColors.stop,
                      'won' => context.shopColors.good,
                      'lost' => context.shopColors.done,
                      _ => null,
                    },
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
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
          const SizedBox(height: 8),
          Expanded(
            child: repo.loading && all.isEmpty
                ? LoadingWords(first: context.l10n.loadingEnquiries)
                : rows.isEmpty
                ? EmptyState(
                    icon: _query.isEmpty
                        ? Icons.chat_bubble_outline
                        : Icons.search_off,
                    title: _query.isEmpty
                        ? context.l10n.nothingInTab(
                            enquiryTabLabel(context, _tab),
                          )
                        : context.l10n.noMatchFor(_query),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => SwipeToContact(
                      id: rows[i].id,
                      phone: rows[i].customerPhone,
                      message: () => context.l10n.waEnquiry(
                        rows[i].customerName,
                        shopNameOf(context),
                        rows[i].headline,
                      ),
                      child: _EnquiryRow(enquiry: rows[i], now: now),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('enquiries-new'),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 2, 10, 2),
        visualDensity: VisualDensity.compact,
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
            // The raw status too, but only when it says something the pill
            // does not ("Open / Open" said it twice — FM #55).
            if (enquiry.status.toLowerCase() !=
                enquiryLifecycleLabel(context, lifecycle).toLowerCase())
              Text(enquiry.status, style: theme.textTheme.labelSmall),
          ],
        ),
        isThreeLine: true,
      ),
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
    final c = context.shopColors;
    final (Color bg, Color fg) = switch (lifecycle) {
      EnquiryLifecycle.overdue => (c.stopSoft, c.stop),
      EnquiryLifecycle.open => (AppTheme.surfaceSubtle, AppTheme.primary),
      EnquiryLifecycle.closed => (c.doneSoft, c.done),
    };
    return StatusPill(
      enquiryLifecycleLabel(context, lifecycle),
      color: fg,
      soft: bg,
    );
  }
}
