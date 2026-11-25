import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/service_repository.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/service/order_list.dart';
import '../../../domain/service/order_state.dart';
import '../../../domain/service/service_order.dart';
import 'service_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../../domain/common/contact_links.dart';
import '../../../domain/common/money.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/loading.dart';
import '../../widgets/contact_buttons.dart';
import 'service_detail_screen.dart' show serviceCustomerMessage;

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
  const ServiceListScreen({super.key, this.initialTab});

  /// A tab name from `kTabs` to open on, e.g. from a Home tile. Anything
  /// else, or nothing, opens on Open.
  final String? initialTab;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late String _tab = _tabFrom(widget.initialTab);

  static String _tabFrom(String? name) =>
      name != null && (kTabs.contains(name) || name == kMineTab)
      ? name
      : 'Open';

  @override
  void didUpdateWidget(ServiceListScreen old) {
    super.didUpdateWidget(old);
    // Tapping a different Home tile while this list is already open.
    if (widget.initialTab != old.initialTab && widget.initialTab != null) {
      _tab = _tabFrom(widget.initialTab);
    }
  }

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
    final l10n = context.l10n;

    // Read once per build, so every tab, count and row in this frame agrees
    // about what time it is.
    final now = DateTime.now();
    final all = repo.orders;
    final myUid = context.read<AuthState>().user?.uid;
    final counts = orderTabCounts(all, query: _query, now: now, myUid: myUid);
    final rows = orderRows(
      all,
      tab: _tab,
      query: _query,
      now: now,
      myUid: myUid,
    );
    // My jobs right after Open: a technician's own list, soonest first.
    final tabs = [kTabs.first, kMineTab, ...kTabs.skip(1)];
    String tabLabel(String t) =>
        t == kMineTab ? l10n.tabMyJobs : serviceStatusLabel(context, t);

    final Widget body;
    if (repo.error != null) {
      body = ErrorState(
        title: l10n.serviceOrdersCouldNotLoad,
        detail: repo.error!,
        onRetry: repo.load,
      );
    } else if (repo.loading && all.isEmpty) {
      body = LoadingWords(first: context.l10n.loadingRepairs);
    } else {
      body = FadeIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
          children: [
            ChipRow(
              key: const Key('repairs-tabs'),
              children: [
                for (final tab in tabs)
                  CountChip(
                    key: Key('service-tab-$tab'),
                    label: tabLabel(tab),
                    count: counts[tab],
                    color: _tabColour(context, tab),
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              EmptyState(
                icon: _query.isEmpty ? Icons.build_outlined : Icons.search_off,
                title: _query.isEmpty
                    ? l10n.nothingInTab(tabLabel(_tab))
                    : l10n.noMatchFor(_query),
              )
            else
              for (final (i, o) in rows.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                SwipeToContact(
                  id: o.id,
                  phone: o.customerPhone,
                  message: () => serviceCustomerMessage(context, o),
                  child: _OrderRow(order: o, now: now),
                ),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavySearchBlock(
            fieldKey: const Key('service-search'),
            hint: l10n.searchServiceOrders,
            onChanged: (v) => setState(() => _query = v),
            onScan: () => context.go('/scanner'),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('repairs-new'),
        heroTag: 'service-new',
        onPressed: () => openServiceSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.homeNewRepair),
      ),
    );
  }

  Color? _tabColour(BuildContext context, String tab) {
    final c = context.shopColors;
    return switch (tab) {
      'Overdue' => c.stop,
      'Due Today' => c.wait,
      'Ready' => c.good,
      'Open' || 'In Progress' || 'All' => null,
      _ => c.done,
    };
  }
}

/// One job as a card: job number and where it is, the phone, the fault, the
/// customer; on the right what it costs, when it is due, and a call button.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.now});

  final ServiceOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final c = context.shopColors;
    final lifecycle = order.lifecycleAt(now);
    final ready = isReady(order.status);
    // The raw status is shown, coloured by the derived state: the tabs read
    // the derived state, but the person working the bench needs the actual
    // step, and an unrecognised one has to show as itself.
    final (Color fg, Color soft) = switch (lifecycle) {
      OrderLifecycle.overdue => (c.stop, c.stopSoft),
      OrderLifecycle.closed => (c.done, c.doneSoft),
      OrderLifecycle.open when ready => (c.good, c.goodSoft),
      OrderLifecycle.open => (AppTheme.primary, AppTheme.surfaceSubtle),
    };
    final price = order.finalPrice ?? order.estimatedPrice;
    final due = order.expectedCompletionAt;
    final call = callUri(order.customerPhone);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: 14,
    );

    return Card(
      key: Key('order-${order.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/service/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (order.orderNumber.isNotEmpty)
                          Text(
                            order.orderNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        StatusPill(
                          serviceStatusLabel(context, order.status),
                          color: fg,
                          soft: soft,
                        ),
                        if (lifecycle == OrderLifecycle.overdue)
                          StatusPill(
                            orderLifecycleLabel(context, lifecycle),
                            color: c.stop,
                            soft: c.stopSoft,
                            icon: Icons.schedule,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.device.isEmpty ? order.title : order.device,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.complaints.isEmpty
                          ? l10n.noComplaintRecorded
                          : order.complaints.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondary,
                    ),
                    Text(
                      [
                        if (order.customerName.isNotEmpty) order.customerName,
                        if (order.customerPhone.isNotEmpty) order.customerPhone,
                        if (order.technician.isNotEmpty) order.technician,
                      ].join(' · '),
                      style: secondary,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price > 0)
                    Text(
                      rupees(price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (due != null)
                    Text(
                      DateFormat.MMMd().format(due),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: lifecycle == OrderLifecycle.overdue
                            ? c.stop
                            : null,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (call != null)
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.contactCall,
                      onPressed: () => launchUrl(call),
                      icon: const Icon(Icons.call_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
