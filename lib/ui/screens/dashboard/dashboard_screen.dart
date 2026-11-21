import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/customer_repository.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/product_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/dashboard/board.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/service/order_state.dart';
import '../../theme/app_theme.dart';

/// THE DASHBOARD
///
/// Laid out the way the owner chose on 2026-11-11: a greeting instead of a
/// title bar, one big card with today's takings, the one main button, three
/// icon tiles for the other things staff start from, and then a single
/// grouped list of everything that needs a look.
///
/// The order is still deliberate. Money first because it is the number
/// somebody opens the app for; the list starts with what is overdue, because
/// somebody opening this at nine in the morning needs to know what is late
/// before they need to know how many customers are on file.
///
/// **A row that could not be counted says so.** It does not show a zero, and
/// it does not vanish — see `board.dart`, where that rule lives and is tested.
/// This file only draws what it is handed.
///
/// **Every row lands on the list it counts.** A number nobody can act on is
/// decoration, and the shop's old board had six of them.
///
/// The counting is all in the domain layer, which is why this screen can read
/// six repositories without having an opinion about any of them.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
    final user = auth.user;
    final name = user?.name.trim() ?? '';
    final greeting = switch (dayPartFor(now)) {
      DayPart.morning => l10n.goodMorning,
      DayPart.afternoon => l10n.goodAfternoon,
      DayPart.evening => l10n.goodEvening,
    };
    final tiles = board.tiles.keys.toList();

    // No title bar on this page — the greeting is the header — so the clock
    // and battery sit on the page colour and have to be dark to be seen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        // Transparent, so the blush page runs right up behind the clock
        // instead of stopping at a grey strip.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: theme.textTheme.bodySmall),
                      Text(
                        name.isEmpty
                            ? (auth.shopName ?? l10n.navDashboard)
                            : name.split(' ').first,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _TakingsCard(takings: board.takings),
            const SizedBox(height: 14),

            // The one main button. Green, like every main button in the app.
            FilledButton.icon(
              key: const Key('home-new-sale'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: () =>
                  context.go(kQuickActionRoutes[QuickAction.sale]!),
              icon: const Icon(Icons.add),
              label: Text(l10n.newSale),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, action) in const [
                  QuickAction.serviceOrder,
                  QuickAction.purchase,
                  QuickAction.scan,
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: switch (action) {
                        QuickAction.serviceOrder => Icons.build_outlined,
                        QuickAction.purchase => Icons.smartphone_outlined,
                        QuickAction.scan => Icons.qr_code_scanner,
                        QuickAction.sale => Icons.point_of_sale_outlined,
                      },
                      label: switch (action) {
                        QuickAction.serviceOrder => l10n.newServiceOrder,
                        QuickAction.purchase => l10n.newPurchase,
                        QuickAction.sale => l10n.newSale,
                        QuickAction.scan => l10n.tabScan,
                      },
                      // Pink and sage by turns, so a tile is found by its
                      // colour as well as by its word.
                      rose: i.isEven,
                      onTap: () => context.go(kQuickActionRoutes[action]!),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // What is late comes first, and is shown even at zero: "nothing
            // overdue" is worth reading on a board checked every morning.
            _Group(
              children: [
                _CountRow(
                  icon: Icons.schedule,
                  label: l10n.overdueServiceOrders,
                  count: board.overdueOrders,
                  alert: true,
                  onTap: () => context.go('/service'),
                ),
                for (final (i, tile) in tiles.indexed)
                  _CountRow(
                    icon: _tileIcons[tile]!,
                    label: tileLabel(l10n, tile),
                    count: board.tile(tile),
                    money: kMoneyTiles.contains(tile),
                    rose: i.isOdd,
                    // Every row lands on the list it counts.
                    onTap: () => context.go(kBoardTileRoutes[tile]!),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Text(l10n.recentOrders, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (orders.error != null)
              _Unreadable(message: orders.error!)
            else if (board.recentOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.nothingTakenInYet),
              )
            else
              _Group(
                children: [
                  for (final order in board.recentOrders)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: Text(order.device),
                      subtitle: Text(
                        [
                          if (order.orderNumber.isNotEmpty) order.orderNumber,
                          if (order.customerName.isNotEmpty) order.customerName,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        order.status,
                        style: TextStyle(
                          color:
                              isOverdue(
                                ServiceOrderState(
                                  status: order.status,
                                  expectedCompletionAt:
                                      order.expectedCompletionAt,
                                ),
                                now: now,
                              )
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                      onTap: () => context.go('/service/${order.id}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

const Map<BoardTile, IconData> _tileIcons = {
  BoardTile.pendingOrders: Icons.build_outlined,
  BoardTile.overdue: Icons.warning_amber,
  BoardTile.dueToday: Icons.event_available_outlined,
  BoardTile.lowStock: Icons.inventory_2_outlined,
  BoardTile.duePayments: Icons.currency_rupee,
  BoardTile.pendingBills: Icons.receipt_long_outlined,
  BoardTile.openEnquiries: Icons.chat_bubble_outline,
  BoardTile.customers: Icons.people_outline,
  BoardTile.newToday: Icons.person_add_alt,
};

/// A count rendered as itself: a number, a spinner, or the reason there is no
/// number. Never a zero standing in for a failure.
class _CountText extends StatelessWidget {
  const _CountText({
    required this.count,
    this.style,
    this.money = false,
    this.onDark = false,
  });

  final BoardCount count;
  final TextStyle? style;
  final bool money;

  /// Drawn on the rose card, where the spinner and the warning have to be
  /// white to be seen.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (count.loading) {
      return SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: onDark ? Colors.white : null,
        ),
      );
    }
    if (count.unavailable != null) {
      return Icon(
        Icons.error_outline,
        size: 20,
        color: onDark ? Colors.white : Theme.of(context).colorScheme.error,
      );
    }
    return Text(money ? '₹${count.value}' : '${count.value}', style: style);
  }
}

/// Today's takings, as the one big thing on the page.
class _TakingsCard extends StatelessWidget {
  const _TakingsCard({required this.takings});

  final BoardCount takings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rose = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: rose,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: rose.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.today,
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          _CountText(
            count: takings,
            money: true,
            onDark: true,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Said out loud, because the figure is only completed bills: a
          // draft is a bill somebody is still building.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              takings.unavailable ?? context.l10n.completedBillsOnly,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the three things staff start from: a big coloured square with an
/// icon, and the words under it.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.rose,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool rose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: rose ? scheme.primaryContainer : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 32,
              color: rose ? scheme.primary : scheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A white rounded card holding rows with thin lines between them.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: 62),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// One thing that is counted: an icon on a soft square, what it is, how many,
/// and an arrow, because the row opens the list it counts.
class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.money = false,
    this.rose = false,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final BoardCount count;
  final VoidCallback onTap;
  final bool money;
  final bool rose;

  /// The overdue row: it turns red, with a red count, when there is anything
  /// in it.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.shopColors;
    final alerting = alert && count.isAlerting;

    final (Color bg, Color fg) = alerting
        ? (colors.stopSoft, colors.stop)
        : rose
        ? (scheme.primaryContainer, scheme.primary)
        : (scheme.secondaryContainer, scheme.secondary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: alerting ? colors.stop : null,
                    ),
                  ),
                  // The reason, on the board itself rather than behind a tap.
                  if (count.unavailable != null)
                    Text(
                      context.l10n.couldNotBeRead,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
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
                color: alerting ? colors.stop : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
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
  BoardTile.lowStock => l10n.tileLowStock,
  BoardTile.duePayments => l10n.tileDuePayments,
  BoardTile.pendingBills => l10n.tilePendingBills,
  BoardTile.openEnquiries => l10n.tileOpenEnquiries,
  BoardTile.customers => l10n.tileCustomers,
  BoardTile.newToday => l10n.tileNewToday,
};
