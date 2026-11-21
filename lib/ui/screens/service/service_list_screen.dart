import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/service_repository.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/service/order_list.dart';
import '../../../domain/service/order_state.dart';
import '../../../domain/service/service_order.dart';
import 'service_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';

/// THE SERVICE LIST
///
/// Nine tabs, and the first three are the ones that matter: what is in the
/// shop, what is promised today, what is already late. The rest are for
/// looking something up.
///
/// The tabs read the DERIVED state, not the raw status, which is the rule the
/// old list got wrong: a job completed last month was showing red because its
/// promised date had passed. Closed beats overdue.
class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  String _tab = 'Open';
  String _query = '';

  /// A scan that lands here with an IMEI on the route opens the intake form
  /// straight away, prefilled.
  ///
  /// Done once, after the first frame: the sheet needs a built context, and
  /// re-opening it on every rebuild would trap someone behind a form they had
  /// just closed. The query parameters stay on the route so the link can be
  /// bookmarked or sent on, which is why this guards on a flag rather than
  /// clearing them.
  bool _openedFromScan = false;

  void _maybeOpenFromScan() {
    if (_openedFromScan) return;
    // maybeOf, not of: the prefill is a convenience and must not be
    // load-bearing. This screen has to render with no router above it at all.
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final prefill = IntakePrefill.fromQuery(
      router.routerDelegate.currentConfiguration.uri.queryParameters,
    );
    if (prefill.isEmpty) return;
    _openedFromScan = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openServiceSheet(context, prefill: prefill);
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeOpenFromScan();
    final repo = context.watch<ServiceRepository>();

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.serviceOrdersCouldNotLoad),
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
    // about what time it is.
    final now = DateTime.now();
    final all = repo.orders;
    final counts = orderTabCounts(all, query: _query, now: now);
    final rows = orderRows(all, tab: _tab, query: _query, now: now);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('service-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchServiceOrders,
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
                for (final tab in kTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _tab == tab,
                      label: Text(
                        '${serviceStatusLabel(context, tab)} ${counts[tab]}',
                      ),
                      onSelected: (_) => setState(() => _tab = tab),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                                serviceStatusLabel(context, _tab),
                              )
                            : context.l10n.noMatchFor(_query),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _OrderRow(order: rows[i], now: now),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'service-new',
        onPressed: () => openServiceSheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.takeIn),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.now});

  final ServiceOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lifecycle = order.lifecycleAt(now);

    return ListTile(
      onTap: () => context.go('/service/${order.id}'),
      title: Text(order.device),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              order.orderNumber,
              if (order.customerName.isNotEmpty) order.customerName,
              if (order.technician.isNotEmpty) order.technician,
            ].where((p) => p.isNotEmpty).join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            order.complaints.isEmpty
                ? context.l10n.noComplaintRecorded
                : order.complaints.join(', '),
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _LifecycleChip(lifecycle: lifecycle),
          const SizedBox(height: 2),
          // The raw status is shown as well as the derived one: the tabs read
          // the derived state, but the person working the bench needs the
          // actual step, and an unrecognised one has to show as itself.
          Text(
            serviceStatusLabel(context, order.status),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _LifecycleChip extends StatelessWidget {
  const _LifecycleChip({required this.lifecycle});

  final OrderLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Red is an alarm, not decoration: it means a customer is already waiting
    // past the time they were given.
    final (Color bg, Color fg) = switch (lifecycle) {
      OrderLifecycle.overdue => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      OrderLifecycle.open => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      OrderLifecycle.closed => (
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
        kStateLabels[lifecycle]!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
