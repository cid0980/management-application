import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/customer_repository.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/product_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/common/dates.dart';
import '../../../domain/common/money.dart';
import '../../../domain/dashboard/board.dart';
import '../../../domain/reports/sales_breakdown.dart';
import '../../../domain/service/service_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/expense_repository.dart';
import '../../../domain/expenses/expense.dart';
import '../../../l10n/l10n.dart';
import '../../theme/forest.dart';
import '../../widgets/shop_ui.dart' show groupsByCount;
import '../../../domain/sales/due_payments.dart';
import '../../../domain/service/order_state.dart' show kReadyStatus;
import '../../../l10n/display_labels.dart';
import '../../../l10n/value_labels.dart';
import '../enquiries/enquiry_form_sheet.dart';
import '../sales/sale_form_sheet.dart';
import '../second_hand/second_hand_form_sheet.dart';
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

  /// The eye on the till card: amounts shown as dots, for a counter a
  /// customer can see.
  bool _hideMoney = false;

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

    // The board's other cards. Money (dues) only for those who may see it;
    // stock and drafts only when there is something in them.
    final dues = board.tiles.containsKey(BoardTile.duePayments)
        ? dueAccounts(sales.sales)
        : null;
    // Each model once, the most asked-for first (two people after an A54
    // is one chip, not two).
    final asked = groupsByCount([
      for (final e in enquiries.enquiries)
        if (!e.closed) '${e.brand} ${e.model}'.trim(),
    ]);
    final extra = [
      for (final tile in const [BoardTile.lowStock, BoardTile.pendingBills])
        if (board.tiles.containsKey(tile) &&
            (board.tile(tile).unavailable != null ||
                (board.tile(tile).value ?? 0) > 0))
          tile,
    ];

    // A light page: the clock and battery are drawn dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: Forest.canvas,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _TopBar(
              shopName: auth.shopName ?? l10n.appTitle,
              initials: auth.user?.initials ?? '?',
              now: now,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: const Key('home-today'),
                    child: _TillCard(
                      takings: board.takings,
                      bills: board.bills,
                      repairs: repairTakingsOn(orders.orders, now),
                      split: split,
                      spent: _spentToday(context, now),
                      hidden: _hideMoney,
                      onToggleHidden: () =>
                          setState(() => _hideMoney = !_hideMoney),
                      // The owner's way into today's full figures.
                      onOpen: auth.isAdmin
                          ? () => openPage(context, '/reports?period=today')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const KeyedSubtree(
                    key: Key('home-actions'),
                    child: _BentoDeck(),
                  ),
                  const SizedBox(height: 22),
                  _SectionBar(
                    title: l10n.homeNeedsAction,
                    action: _AllPill(
                      key: const Key('home-all-repairs'),
                      label: l10n.homeAllCount(
                        (board.tile(BoardTile.pendingOrders).value ?? 0)
                            .toInt(),
                      ),
                      onTap: () => context.go('/service'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (orders.error != null)
                    _Unreadable(message: orders.error!)
                  else ...[
                    _FilterRail(
                      key: const Key('home-queue'),
                      counts: {
                        for (final k in BenchKind.values) k: queues[k]!.length,
                      },
                      selected: kind,
                      onPick: (k) => setState(() => _picked = k),
                    ),
                    const SizedBox(height: 12),
                    if (jobs.isEmpty)
                      const _EmptyStub()
                    else
                      for (final (i, job) in jobs.take(_cards).indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _JobStub(order: job, kind: kind, now: now),
                      ],
                    if (jobs.length > _cards)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton(
                          onPressed: () => context.go(_queueRoute(kind)),
                          child: Text(l10n.homeAllCount(jobs.length)),
                        ),
                      ),
                  ],
                  const SizedBox(height: 22),
                  _SectionBar(title: l10n.homeAlsoToday),
                  const SizedBox(height: 10),
                  _BoardGrid(
                    children: [
                      if (dues != null)
                        _DuesCard(
                          count: board.tile(BoardTile.duePayments),
                          accounts: dues,
                          hidden: _hideMoney,
                        ),
                      if (board.tiles.containsKey(BoardTile.openEnquiries))
                        _WantedCard(
                          count: board.tile(BoardTile.openEnquiries),
                          asked: asked,
                        ),
                      for (final tile in extra)
                        _TileCard(tile: tile, count: board.tile(tile)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

/// The shop's mark and name, today's date, the tour and the account.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.shopName,
    required this.initials,
    required this.now,
  });

  final String shopName;
  final String initials;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mark = shopName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Forest.forest900,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    mark.isEmpty ? '·' : mark,
                    style: const TextStyle(
                      color: Forest.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEE d MMM',
                          locale,
                        ).format(now).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: Forest.ink600,
                        ),
                      ),
                      Text(
                        shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: Forest.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoundButton(
                  key: const Key('page-tour'),
                  tooltip: l10n.tourThisPage,
                  onTap: () => runTourHere(context, '/dashboard'),
                  child: const Icon(Icons.help_outline, size: 20),
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  tooltip: l10n.tabMore,
                  onTap: () => context.go('/more'),
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Forest.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Forest.hairline),
                    ),
                    child: InkWell(
                      key: const Key('home-search'),
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () => openPage(context, '/search'),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 13),
                            const Icon(
                              Icons.search,
                              size: 20,
                              color: Forest.ink400,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                l10n.searchEverythingHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Forest.ink400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.tabScan,
                  child: Material(
                    color: Forest.forest900,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: const Key('home-scan'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => openPage(
                        context,
                        kQuickActionRoutes[QuickAction.scan]!,
                      ),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Forest.onForest,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Forest.surface,
      shape: const CircleBorder(side: BorderSide(color: Forest.hairline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: IconTheme(
            data: const IconThemeData(color: Forest.ink900),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Forest.ink900, fontSize: 13),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Today's sales on the forest card: the amount, the bills, how it came in
/// (a bar, UPI against cash and the rest), what came from repairs and what
/// went out. The eye hides every amount.
class _TillCard extends StatelessWidget {
  const _TillCard({
    required this.takings,
    required this.bills,
    required this.repairs,
    required this.split,
    required this.spent,
    required this.hidden,
    required this.onToggleHidden,
    this.onOpen,
  });

  final BoardCount takings;
  final BoardCount bills;

  /// Repair advances and pickups today — not in [takings], which is bills.
  final num repairs;

  /// How today's money came in, by method; null when sales cannot be read.
  final PaymentSplit? split;
  final num spent;
  final bool hidden;
  final VoidCallback onToggleHidden;

  /// Opens today's report; null for staff, who have no Reports.
  final VoidCallback? onOpen;

  String _money(num v) => hidden ? '₹ •••••' : rupees(v);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final methods = split?.methods ?? const <MethodTotal>[];
    // UPI and cash by name, then everything else in one.
    MethodTotal? named(String m) {
      for (final t in methods) {
        if (t.method.toLowerCase() == m) return t;
      }
      return null;
    }

    final upi = named('upi');
    final cash = named('cash');
    final rest = methods
        .where((t) => t != upi && t != cash)
        .fold<num>(0, (sum, t) => sum + t.collected);
    final total = (upi?.collected ?? 0) + (cash?.collected ?? 0) + rest;
    final billCount = bills.value?.toInt();
    const muted = TextStyle(fontSize: 12.5, color: Forest.onForestMuted);

    return Material(
      color: Forest.forest900,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('home-today-open'),
        onTap: onOpen,
        child: CustomPaint(
          painter: const _Rings(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.homeTodaysSales,
                      style: muted.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('home-hide-money'),
                      tooltip: hidden
                          ? l10n.homeShowAmounts
                          : l10n.homeHideAmounts,
                      visualDensity: VisualDensity.compact,
                      color: Forest.onForest,
                      iconSize: 18,
                      onPressed: onToggleHidden,
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                    const Spacer(),
                    if (billCount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: billCount > 0
                              ? Forest.lime
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          l10n.homeBillsCount(billCount).toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: billCount > 0
                                ? Forest.forest900
                                : Forest.onForest,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: takings.unavailable != null
                          ? Text(
                              takings.unavailable!,
                              style: const TextStyle(
                                color: Forest.onForest,
                                fontSize: 14,
                              ),
                            )
                          : takings.loading
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Forest.lime,
                                ),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _money(takings.value ?? 0),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  height: 1.05,
                                  color: Forest.onForest,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                    ),
                    if (onOpen != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${l10n.homeDaybook} ↗',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Forest.onForest,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // The bar: each way the money came in, in proportion.
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    child: total <= 0
                        ? const ColoredBox(color: Color(0x1FFFFFFF))
                        : Row(
                            children: [
                              for (final (part, color) in [
                                (upi?.collected ?? 0, Forest.lime),
                                (cash?.collected ?? 0, Forest.amber),
                                (rest, Forest.otherMethod),
                              ])
                                if (part > 0)
                                  Expanded(
                                    flex: (part / total * 1000).round().clamp(
                                      1,
                                      1000,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _Legend(
                      color: Forest.lime,
                      label: 'UPI',
                      value: _money(upi?.collected ?? 0),
                    ),
                    _Legend(
                      color: Forest.amber,
                      label: l10n.expenseCash,
                      value: _money(cash?.collected ?? 0),
                    ),
                    if (rest > 0)
                      _Legend(
                        color: Forest.otherMethod,
                        label: l10n.otherMethods(
                          methods.length -
                              (upi == null ? 0 : 1) -
                              (cash == null ? 0 : 1),
                        ),
                        value: _money(rest),
                      ),
                  ],
                ),
                if (repairs > 0 || spent > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (repairs > 0)
                        Text(
                          l10n.plusFromRepairs(_money(repairs)),
                          key: const Key('today-repairs'),
                          style: muted,
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
                                  l10n.homeSpentToday(_money(spent)),
                                  style: muted,
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Forest.onForestMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '$label ',
        style: const TextStyle(fontSize: 12.5, color: Forest.onForestMuted),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Forest.onForest,
        ),
      ),
    ],
  );
}

/// Thin rings in the card's corner — lines, not a glow.
class _Rings extends CustomPainter {
  const _Rings();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.09);
    final c = Offset(size.width - 35, 20);
    for (final r in const [45.0, 70.0, 95.0, 120.0]) {
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(_Rings oldDelegate) => false;
}

/// New sale tall on the left; New repair, Buy phone and Enquiry beside it.
class _BentoDeck extends StatelessWidget {
  const _BentoDeck();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 158,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 108,
            child: Material(
              color: Forest.forest800,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('home-new-sale'),
                onTap: () => startQuickAction(context, QuickAction.sale),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Forest.lime,
                            size: 22,
                          ),
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.north_east,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const _Barcode(),
                      const SizedBox(height: 6),
                      Text(
                        l10n.newSale,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        l10n.homeSaleSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xC7FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DeckTile(
                    key: const Key('home-new-repair'),
                    icon: Icons.build_outlined,
                    label: l10n.homeNewRepair,
                    big: true,
                    onTap: () =>
                        startQuickAction(context, QuickAction.serviceOrder),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _DeckTile(
                          key: const Key('home-buy-phone'),
                          icon: Icons.add_to_home_screen_outlined,
                          label: l10n.homeBuyPhone,
                          onTap: () =>
                              startQuickAction(context, QuickAction.purchase),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DeckTile(
                          key: const Key('home-enquiry'),
                          icon: Icons.chat_bubble_outline,
                          label: l10n.homeEnquiry,
                          onTap: () => openEnquirySheet(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.big = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) => Material(
    color: Forest.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Forest.hairline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: big ? 13 : 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: big ? 20 : 18, color: Forest.ink900),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: big ? 15 : 13,
                fontWeight: big ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.15,
                color: Forest.ink900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The receipt-barcode mark on New sale.
class _Barcode extends StatelessWidget {
  const _Barcode();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    height: 22,
    child: CustomPaint(painter: _BarcodePainter()),
  );
}

class _BarcodePainter extends CustomPainter {
  static const _bars = [
    (0.0, 3.0),
    (6.0, 1.5),
    (11.0, 4.0),
    (18.0, 2.0),
    (24.0, 1.5),
    (29.0, 5.0),
    (37.0, 2.0),
    (43.0, 3.0),
    (49.0, 1.5),
    (54.0, 4.0),
    (61.0, 2.0),
    (67.0, 5.0),
    (75.0, 1.5),
    (80.0, 3.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (final (x, w) in _bars) {
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => false;
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Forest.ink900,
          ),
        ),
      ),
      ?action,
    ],
  );
}

class _AllPill extends StatelessWidget {
  const _AllPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Forest.surfaceMuted,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$label →',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Forest.ink900,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Late / Due today / Ready as one segmented rail; the picked one is white.
class _FilterRail extends StatelessWidget {
  const _FilterRail({
    super.key,
    required this.counts,
    required this.selected,
    required this.onPick,
  });

  final Map<BenchKind, int> counts;
  final BenchKind selected;
  final ValueChanged<BenchKind> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Forest.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final k in BenchKind.values)
            Expanded(
              child: Material(
                color: k == selected ? Forest.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                elevation: k == selected ? 1 : 0,
                shadowColor: Colors.black26,
                child: InkWell(
                  key: Key('home-queue-${k.name}'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onPick(k),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            switch (k) {
                              BenchKind.late => l10n.homeLate,
                              BenchKind.dueToday => l10n.homeDueToday,
                              BenchKind.ready => l10n.homeReady,
                            },
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: k == selected
                                  ? Forest.ink900
                                  : Forest.ink600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: k == BenchKind.late && counts[k]! > 0
                                ? Forest.lateBg
                                : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${counts[k]}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: k == BenchKind.late && counts[k]! > 0
                                  ? Forest.lateInk
                                  : Forest.ink900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A repair as a die-cut ticket: the job's number, the phone, the fault and
/// customer, the price; a perforation with a notch each side; then how far
/// along it is and when it is due. The whole ticket opens the job.
class _JobStub extends StatelessWidget {
  const _JobStub({required this.order, required this.kind, required this.now});

  final ServiceOrder order;
  final BenchKind kind;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = order.expectedCompletionAt;
    final (badge, badgeBg, badgeInk) = switch (kind) {
      BenchKind.late => (
        l10n.homeDaysLate(daysLate(order, now)),
        Forest.lateBg,
        Forest.lateInk,
      ),
      BenchKind.dueToday => (
        due == null || (due.hour == 0 && due.minute == 0)
            ? l10n.homeDueToday
            : l10n.homeDueAt(DateFormat.jm().format(due)),
        Forest.dueBg,
        Forest.dueInk,
      ),
      BenchKind.ready => (l10n.homeReady, Forest.readyBg, Forest.readyInk),
    };
    // Three steps: taken in, being worked on, ready.
    final reached = switch (order.status) {
      'Received' => 1,
      kReadyStatus => 3,
      _ => 2,
    };
    final stepColor = switch (kind) {
      BenchKind.late => Forest.stepAlert,
      BenchKind.ready => Forest.stepOk,
      BenchKind.dueToday => Forest.forest900,
    };
    final problem = order.complaints.isNotEmpty
        ? order.complaints.map((c) => shopValue(context, c)).join(', ')
        : order.complaintNotes.trim();
    final who = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()
        : order.customerPhone.trim();
    final sub = [
      if (problem.isNotEmpty) problem,
      if (who.isNotEmpty) who,
    ].join(' • ');
    // What is still to collect. A job the advance already covers says Paid,
    // rather than showing its price as if it were owed.
    final charge = order.finalPrice ?? order.estimatedPrice;
    final paidUp = charge > 0 && order.toCollect <= 0 && order.advancePaid > 0;
    final price = order.toCollect;
    final number = order.orderNumber.trim();
    final token = number.isEmpty ? '' : '#${number.split('-').last}';

    return Material(
      key: Key('home-job-${order.id}'),
      color: Forest.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Forest.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPage(context, '/service/${order.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (token.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Forest.forest900,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  token,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Forest.lime,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                            Expanded(
                              child: Text(
                                order.device.isEmpty
                                    ? order.title
                                    : order.device,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: Forest.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (sub.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Forest.ink600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (paidUp) ...[
                    const SizedBox(width: 10),
                    Text(
                      l10n.paid,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Forest.readyInk,
                      ),
                    ),
                  ] else if (price > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      rupees(price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Forest.ink900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const _Perforation(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 6, 15, 11),
              child: Row(
                children: [
                  for (var i = 1; i <= 3; i++) ...[
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= reached ? stepColor : Forest.surfaceMuted,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      serviceStatusLabel(context, order.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Forest.ink600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ticket's tear line: dashes, and a half-circle bitten out each side.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 14, child: CustomPaint(painter: _PerforationPainter()));
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final dash = Paint()
      ..color = Forest.surfaceMuted
      ..strokeWidth = 1.5;
    for (var x = 11.0; x < size.width - 11; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
    }
    final notch = Paint()..color = Forest.canvas;
    final edge = Paint()
      ..color = Forest.hairline
      ..style = PaintingStyle.stroke;
    for (final cx in [-1.0, size.width + 1]) {
      canvas.drawCircle(Offset(cx, y), 7, notch);
      canvas.drawCircle(Offset(cx, y), 7, edge);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => false;
}

/// Nothing in this queue: a blank ticket with a way to take a phone in.
class _EmptyStub extends StatelessWidget {
  const _EmptyStub();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Forest.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Forest.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Forest.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Forest.forest900,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeNothingNeedsAction,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Forest.ink900,
                        ),
                      ),
                      Text(
                        l10n.homeBenchClear,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Forest.ink600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Forest.forest900,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    key: const Key('home-empty-new-repair'),
                    borderRadius: BorderRadius.circular(11),
                    onTap: () =>
                        startQuickAction(context, QuickAction.serviceOrder),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        '+ ${l10n.homeNewRepair}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Forest.lime,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _Perforation(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// The "also on the board" cards, two to a row.
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.title,
    required this.onTap,
    required this.child,
    this.trailing,
  });

  final String title;
  final VoidCallback onTap;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: Forest.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Forest.hairline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Forest.ink600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    ),
  );
}

/// What customers owe, and who: their initials, the first two and "+n".
class _DuesCard extends StatelessWidget {
  const _DuesCard({
    required this.count,
    required this.accounts,
    required this.hidden,
  });

  final BoardCount count;
  final List<DueAccount> accounts;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String initialOf(DueAccount a) {
      final n = a.customerName.trim();
      return n.isEmpty ? '#' : n.characters.first.toUpperCase();
    }

    final avatars = [
      for (final a in accounts.take(2)) initialOf(a),
      if (accounts.length > 2) '+${accounts.length - 2}',
    ];
    return _BoardCard(
      title: tileLabel(l10n, BoardTile.duePayments),
      onTap: () => openPage(context, kBoardTileRoutes[BoardTile.duePayments]!),
      trailing: avatars.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, a) in avatars.indexed)
                  Transform.translate(
                    offset: Offset(-6.0 * i, 0),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Forest.forest900,
                        shape: BoxShape.circle,
                        border: Border.all(color: Forest.surface, width: 2),
                      ),
                      child: Text(
                        a,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Forest.lime,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count.unavailable != null || count.loading)
            _CountText(count: count, money: true)
          else
            Text(
              hidden ? '₹ •••' : rupees(count.value ?? 0),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Forest.ink900,
              ),
            ),
          Text(
            count.unavailable != null
                ? l10n.couldNotBeRead
                : accounts.isEmpty
                ? l10n.homeNoCredit
                : l10n.homeDueCustomers(accounts.length),
            style: const TextStyle(fontSize: 12, color: Forest.ink600),
          ),
        ],
      ),
    );
  }
}

/// What customers asked for and the shop does not have: models as chips.
class _WantedCard extends StatelessWidget {
  const _WantedCard({required this.count, required this.asked});

  final BoardCount count;
  final List<String> asked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = count.value?.toInt() ?? 0;
    return _BoardCard(
      title: tileLabel(l10n, BoardTile.openEnquiries),
      onTap: n == 0 && count.unavailable == null
          ? () => openEnquirySheet(context)
          : () => openPage(context, kBoardTileRoutes[BoardTile.openEnquiries]!),
      trailing: Text(
        n == 0 ? '+ ${l10n.add}' : '$n →',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Forest.ink600,
        ),
      ),
      child: count.unavailable != null || count.loading
          ? Row(
              children: [
                _CountText(count: count),
                const SizedBox(width: 6),
                if (count.unavailable != null)
                  Flexible(
                    child: Text(
                      l10n.couldNotBeRead,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Forest.lateInk,
                      ),
                    ),
                  ),
              ],
            )
          : asked.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$n',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Forest.ink900,
                  ),
                ),
                Text(
                  l10n.homeLogLeads,
                  style: const TextStyle(fontSize: 12, color: Forest.ink600),
                ),
              ],
            )
          : Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final m in asked.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Forest.surfaceMuted,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      m,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Forest.ink900,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Low stock or bills left as drafts, when there are any.
class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile, required this.count});

  final BoardTile tile;
  final BoardCount count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _BoardCard(
      title: tileLabel(l10n, tile),
      onTap: () => openPage(context, kBoardTileRoutes[tile]!),
      trailing: Icon(_tileIcons[tile], size: 18, color: Forest.ink600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountText(
            count: count,
            money: kMoneyTiles.contains(tile),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Forest.ink900,
            ),
          ),
          if (count.unavailable != null)
            Text(
              l10n.couldNotBeRead,
              style: const TextStyle(fontSize: 12, color: Forest.lateInk),
            ),
        ],
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
