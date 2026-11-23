import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/auth_state.dart';
import '../../../data/customer_repository.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/product_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/common/contact_links.dart';
import '../../../domain/common/dates.dart';
import '../../../domain/common/money.dart';
import '../../../domain/dashboard/board.dart';
import '../../../domain/reports/sales_breakdown.dart';
import '../../../domain/service/service_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/expense_repository.dart';
import '../../../domain/expenses/expense.dart';
import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../enquiries/enquiry_form_sheet.dart';
import '../sales/sale_form_sheet.dart';
import '../second_hand/second_hand_form_sheet.dart';
import '../service/service_detail_screen.dart' show serviceCustomerMessage;
import '../service/service_form_sheet.dart';
import '../../../app/nav.dart';
import '../../tour/app_tour.dart';

/// HOME
///
/// Laid out the way the owner chose on 2026-11-22, from a Flutter mockup: an
/// ordinary Android screen, one column, big text. A navy top block with the
/// shop's name and the search box (scan at its end); today's sales; the four
/// things staff start from; and the repairs that need somebody now — late,
/// due today, ready — as job cards with Call, WhatsApp and Open on each.
/// Below them, the other counts that need a look, only when there is one.
///
/// **A count that could not be read says so.** It does not show a zero, and
/// it does not vanish — see `board.dart`, where that rule lives and is tested.
/// This file only draws what it is handed.
///
/// **Every count lands on the list it counts.**
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The queue the person picked; null until they pick, meaning "the most
  /// urgent one with anything in it".
  BenchKind? _picked;

  /// How many job cards Home shows before "see all" takes over.
  static const _cards = 5;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final orders = context.watch<ServiceRepository>();
    final sales = context.watch<SalesRepository>();
    final products = context.watch<ProductRepository>();
    final customers = context.watch<CustomerRepository>();
    final enquiries = context.watch<EnquiryRepository>();

    final now = DateTime.now();
    final board = buildBoard(
      orders: AreaState(
        items: orders.orders,
        loading: orders.loading,
        error: orders.error,
        what: 'service orders',
      ),
      sales: AreaState(
        items: sales.sales,
        loading: sales.loading,
        error: sales.error,
        what: 'sales',
      ),
      products: AreaState(
        items: products.products,
        loading: products.loading,
        error: products.error,
        what: 'products',
      ),
      customers: AreaState(
        items: customers.customers,
        loading: customers.loading,
        error: customers.error,
        what: 'customers',
      ),
      enquiries: AreaState(
        items: enquiries.enquiries,
        loading: enquiries.loading,
        error: enquiries.error,
        what: 'enquiries',
      ),
      isAdmin: auth.isAdmin,
      now: now,
    );

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final queues = benchQueues(orders.orders, now: now);
    final kind =
        _picked ??
        BenchKind.values.firstWhere(
          (k) => queues[k]!.isNotEmpty,
          orElse: () => BenchKind.late,
        );
    final jobs = queues[kind]!;
    final split = sales.error == null
        ? paymentSplit(sales.sales, DateRange.day(now), orders: orders.orders)
        : null;

    // Counts that need a look but are not repairs: shown only when there is
    // something in them, or when they could not be read.
    final others = [
      for (final tile in const [
        BoardTile.duePayments,
        BoardTile.pendingBills,
        BoardTile.lowStock,
        BoardTile.openEnquiries,
      ])
        if (board.tiles.containsKey(tile) &&
            (board.tile(tile).unavailable != null ||
                (board.tile(tile).value ?? 0) > 0))
          tile,
    ];

    // The top block is navy, so the clock and battery are drawn white.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TopBlock(
            shopName: auth.shopName ?? l10n.appTitle,
            initials: auth.user?.initials ?? '?',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const Key('home-today'),
                  child: _SalesCard(
                    takings: board.takings,
                    bills: board.bills,
                    repairs: repairTakingsOn(orders.orders, now),
                    split: split,
                    spent: _spentToday(context, now),
                    // The owner's way into today's full figures.
                    onOpen: auth.isAdmin
                        ? () => openPage(context, '/reports?period=today')
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                KeyedSubtree(key: const Key('home-actions'), child: _Actions()),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.homeNeedsAction,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('home-all-repairs'),
                      onPressed: () => context.go('/service'),
                      child: Text(
                        l10n.homeAllCount(
                          (board.tile(BoardTile.pendingOrders).value ?? 0)
                              .toInt(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (orders.error != null)
                  _Unreadable(message: orders.error!)
                else ...[
                  SingleChildScrollView(
                    key: const Key('home-queue'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final k in BenchKind.values) ...[
                          if (k != BenchKind.late) const SizedBox(width: 8),
                          _QueueChip(
                            kind: k,
                            count: queues[k]!.length,
                            selected: k == kind,
                            onTap: () => setState(() => _picked = k),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (jobs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          l10n.homeNothingNeedsAction,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final (i, job) in jobs.take(_cards).indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _JobCard(order: job, kind: kind, now: now),
                    ],
                  if (jobs.length > _cards)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton(
                        onPressed: () => context.go(_queueRoute(kind)),
                        child: Text(l10n.homeAllCount(jobs.length)),
                      ),
                    ),
                ],
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.homeAlsoToday,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, tile) in others.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _CountRow(
                            icon: _tileIcons[tile]!,
                            label: tileLabel(l10n, tile),
                            count: board.tile(tile),
                            money: kMoneyTiles.contains(tile),
                            onTap: () =>
                                openPage(context, kBoardTileRoutes[tile]!),
                          ),
                        ],
                      ],
                    ),
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

/// The list tab a queue's "see all" opens.
String _queueRoute(BenchKind kind) => switch (kind) {
  BenchKind.late => kBoardTileRoutes[BoardTile.overdue]!,
  BenchKind.dueToday => kBoardTileRoutes[BoardTile.dueToday]!,
  BenchKind.ready => kBoardTileRoutes[BoardTile.readyForPickup]!,
};

const Map<BoardTile, IconData> _tileIcons = {
  BoardTile.pendingOrders: Icons.build_outlined,
  BoardTile.overdue: Icons.warning_amber,
  BoardTile.dueToday: Icons.event_available_outlined,
  BoardTile.readyForPickup: Icons.check_circle_outline,
  BoardTile.lowStock: Icons.inventory_2_outlined,
  BoardTile.duePayments: Icons.currency_rupee,
  BoardTile.pendingBills: Icons.receipt_long_outlined,
  BoardTile.openEnquiries: Icons.chat_bubble_outline,
  BoardTile.customers: Icons.people_outline,
  BoardTile.newToday: Icons.person_add_alt,
};

/// Navy, straight-edged, holding the shop's name and the search box — the
/// box every list in the shop's phones already has at the top.
class _TopBlock extends StatelessWidget {
  const _TopBlock({required this.shopName, required this.initials});

  final String shopName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppTheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 21,
                      ),
                    ),
                  ),
                  // The tour for Home, as every page has.
                  IconButton(
                    key: const Key('page-tour'),
                    tooltip: context.l10n.tourThisPage,
                    color: Colors.white,
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => runTourHere(context, '/dashboard'),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.go('/more'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryPressed,
                      foregroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // One box for everything: a name, a number, an IMEI, a job or
              // bill number. Opens the search page, which answers from every
              // area at once. Scan sits at its end.
              Material(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const Key('home-search'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => openPage(context, '/search'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.searchEverythingHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('home-scan'),
                          tooltip: context.l10n.tabScan,
                          onPressed: () => openPage(
                            context,
                            kQuickActionRoutes[QuickAction.scan]!,
                          ),
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's sales: the big amount, how many bills, what came in from repairs,
/// and how it was paid.
/// Today's expenses, or nothing when this screen has no expenses to read.
num _spentToday(BuildContext context, DateTime now) {
  try {
    final all = context.watch<ExpenseRepository>().expenses;
    return summarizeExpenses(all, DateRange.day(now)).total;
  } on ProviderNotFoundException {
    return 0;
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.takings,
    required this.bills,
    required this.repairs,
    required this.split,
    this.spent = 0,
    this.onOpen,
  });

  /// Opens today's report; null for staff, who have no Reports.
  final VoidCallback? onOpen;

  /// Expenses written down today.
  final num spent;

  /// Completed bills only — see `takingsOn`.
  final BoardCount takings;
  final BoardCount bills;

  /// Repair advances and pickups today — not in [takings], which is bills.
  final num repairs;

  /// How today's money came in, by method; null when sales cannot be read.
  final PaymentSplit? split;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.shopColors;
    final l10n = context.l10n;
    final methods = split?.methods.take(3).toList() ?? const <MethodTotal>[];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('home-today-open'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.page,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.homeTodaysSales,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (bills.value != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.goodSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.homeBillsCount(bills.value!.toInt()),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.good,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _CountText(
                count: takings,
                money: true,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text,
                ),
              ),
              if (takings.unavailable != null)
                Text(
                  takings.unavailable!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (repairs > 0)
                Text(
                  l10n.plusFromRepairs(rupees(repairs)),
                  key: const Key('today-repairs'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              if (spent > 0)
                InkWell(
                  key: const Key('today-spent'),
                  onTap: () => openPage(context, '/expenses'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeSpentToday(rupees(spent)),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              if (methods.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final (i, m) in methods.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.page,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.method,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  rupees(m.collected),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The four things staff start from. New sale is the one filled button.
class _Actions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const tall = Size.fromHeight(48);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    Widget outlined(Key key, IconData icon, String label, VoidCallback onTap) =>
        OutlinedButton.icon(
          key: key,
          style: OutlinedButton.styleFrom(
            minimumSize: tall,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('home-new-sale'),
                style: FilledButton.styleFrom(
                  minimumSize: tall,
                  shape: shape,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => startQuickAction(context, QuickAction.sale),
                icon: const Icon(Icons.receipt_long),
                label: Text(
                  l10n.newSale,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: outlined(
                const Key('home-new-repair'),
                Icons.build_outlined,
                l10n.homeNewRepair,
                () => startQuickAction(context, QuickAction.serviceOrder),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: outlined(
                const Key('home-buy-phone'),
                Icons.add_a_photo_outlined,
                l10n.homeBuyPhone,
                () => startQuickAction(context, QuickAction.purchase),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: outlined(
                const Key('home-enquiry'),
                Icons.chat_outlined,
                l10n.homeEnquiry,
                () => openEnquirySheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Late / Due today / Ready, with how many are in each. The picked one is
/// filled with its colour.
class _QueueChip extends StatelessWidget {
  const _QueueChip({
    required this.kind,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final BenchKind kind;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _queueColor(context, kind);
    final label = switch (kind) {
      BenchKind.late => l10n.homeLate,
      BenchKind.dueToday => l10n.homeDueToday,
      BenchKind.ready => l10n.homeReady,
    };
    final ink = selected ? Colors.white : AppTheme.text;
    return Material(
      color: selected ? color : AppTheme.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? color : AppTheme.borderSubtle),
      ),
      child: InkWell(
        key: Key('home-queue-${kind.name}'),
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _queueColor(BuildContext context, BenchKind kind) {
  final c = context.shopColors;
  return switch (kind) {
    BenchKind.late => c.stop,
    BenchKind.dueToday => c.wait,
    BenchKind.ready => c.good,
  };
}

/// One repair as a card: job number and how it stands, the phone, the fault
/// and what is left to pay, the customer, and Call / WhatsApp / Open.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.order, required this.kind, required this.now});

  final ServiceOrder order;
  final BenchKind kind;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colors = context.shopColors;
    final color = _queueColor(context, kind);
    final soft = switch (kind) {
      BenchKind.late => colors.stopSoft,
      BenchKind.dueToday => colors.waitSoft,
      BenchKind.ready => colors.goodSoft,
    };
    final due = order.expectedCompletionAt;
    final status = switch (kind) {
      BenchKind.late => l10n.homeDaysLate(daysLate(order, now)),
      BenchKind.dueToday => l10n.homeDueAt(
        due == null ? l10n.homeDueToday : DateFormat.jm().format(due),
      ),
      BenchKind.ready => l10n.homeReady,
    };
    final problem = order.complaints.isNotEmpty
        ? order.complaints.join(', ')
        : order.complaintNotes;
    final line1 = [
      if (problem.trim().isNotEmpty) problem.trim(),
      if (order.toCollect > 0) l10n.homeAmountDue(rupees(order.toCollect)),
    ].join('  ·  ');
    final line2 = [
      if (order.customerName.trim().isNotEmpty) order.customerName.trim(),
      if (order.customerPhone.trim().isNotEmpty) order.customerPhone.trim(),
    ].join('  ·  ');
    final call = callUri(order.customerPhone);
    final wa = whatsAppUri(
      order.customerPhone,
      serviceCustomerMessage(context, order),
    );
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: 14,
    );
    const small = EdgeInsets.symmetric(horizontal: 8);

    return Card(
      key: Key('home-job-${order.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: order.orderNumber.isEmpty
                      ? const SizedBox.shrink()
                      : Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${l10n.homeJob} ',
                                style: secondary,
                              ),
                              TextSpan(
                                text: order.orderNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kind == BenchKind.ready
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        maxLines: 1,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.device.isEmpty ? order.title : order.device,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (line1.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(line1, style: secondary),
            ],
            if (line2.isNotEmpty) Text(line2, style: secondary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: small,
                    ),
                    onPressed: call == null ? null : () => launchUrl(call),
                    icon: const Icon(Icons.call_outlined, size: 20),
                    label: Text(l10n.contactCall),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: small,
                      foregroundColor: colors.good,
                    ),
                    onPressed: wa == null
                        ? null
                        : () => launchUrl(
                            wa,
                            mode: LaunchMode.externalApplication,
                          ),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: Text(
                      l10n.contactWhatsApp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: small,
                    ),
                    onPressed: () => context.go('/service/${order.id}'),
                    child: Text(l10n.homeOpenJob),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One other count: an icon, what it is, how many, and an arrow, because the
/// row opens the list it counts.
class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.money = false,
  });

  final IconData icon;
  final String label;
  final BoardCount count;
  final VoidCallback onTap;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.page,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // The reason, on the board itself rather than behind a tap.
                  if (count.unavailable != null)
                    Text(
                      context.l10n.couldNotBeRead,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CountText(
              count: count,
              money: money,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A count rendered as itself: a number, a spinner, or the reason there is no
/// number. Never a zero standing in for a failure.
class _CountText extends StatelessWidget {
  const _CountText({required this.count, this.style, this.money = false});

  final BoardCount count;
  final TextStyle? style;
  final bool money;

  @override
  Widget build(BuildContext context) {
    if (count.loading) {
      return SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (count.unavailable != null) {
      return Icon(
        Icons.error_outline,
        size: 20,
        color: Theme.of(context).colorScheme.error,
      );
    }
    return Text(money ? rupees(count.value) : '${count.value}', style: style);
  }
}

class _Unreadable extends StatelessWidget {
  const _Unreadable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

/// What a tile is called in the shop's language.
///
/// By tile rather than by its English label, so a translation cannot drift
/// away from the tile it belongs to.
String tileLabel(AppLocalizations l10n, BoardTile tile) => switch (tile) {
  BoardTile.pendingOrders => l10n.tilePendingOrders,
  BoardTile.overdue => l10n.tileOverdue,
  BoardTile.dueToday => l10n.tileDueToday,
  BoardTile.readyForPickup => l10n.tileReadyForPickup,
  BoardTile.lowStock => l10n.tileLowStock,
  BoardTile.duePayments => l10n.tileDuePayments,
  BoardTile.pendingBills => l10n.tilePendingBills,
  BoardTile.openEnquiries => l10n.tileOpenEnquiries,
  BoardTile.customers => l10n.tileCustomers,
  BoardTile.newToday => l10n.tileNewToday,
};

/// A "New …" button on Home opens the form itself, over Home.
///
/// It used to go to the area's list, so "New sale" landed on the list of past
/// sales and staff had to find the + button a second time. The person who
/// pressed "New sale" is standing at the counter with a customer: the form is
/// what they asked for. Scan has no form, so it still goes to the scanner.
Future<void> startQuickAction(BuildContext context, QuickAction action) =>
    switch (action) {
      QuickAction.sale => openSaleSheet(context),
      QuickAction.serviceOrder => openServiceSheet(context),
      QuickAction.purchase => openPurchaseSheet(context),
      QuickAction.scan => Future.sync(
        () => openPage(context, kQuickActionRoutes[QuickAction.scan]!),
      ),
    };
