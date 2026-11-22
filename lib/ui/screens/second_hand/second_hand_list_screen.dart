import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/second_hand_repository.dart';
import '../../../domain/inventory/second_hand_device.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/inventory/stock_list.dart';
import '../../theme/app_theme.dart';
import '../../widgets/field_help.dart';
import 'second_hand_form_sheet.dart';
import 'stock_badges.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/margins.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shop_ui.dart';
import '../../../domain/common/money.dart';

/// THE STOCK LIST
///
/// Three tabs, because the shop has three answers to "can I sell this", and a
/// search box over everything printed on the row — including the IMEI and the
/// label number, which is what someone holding the phone actually has to go
/// on.
///
/// Which rows appear, in what order, and what the tab counts say are all in
/// `stock_list.dart`. This widget draws them.
class SecondHandListScreen extends StatefulWidget {
  const SecondHandListScreen({super.key});

  @override
  State<SecondHandListScreen> createState() => _SecondHandListScreenState();
}

class _SecondHandListScreenState extends State<SecondHandListScreen> {
  StockTab _tab = StockTab.available;
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
      if (mounted) openPurchaseSheet(context, prefill: prefill);
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeOpenFromScan();
    final repo = context.watch<SecondHandRepository>();
    final l10n = context.l10n;

    final all = repo.devices;
    final counts = stockTabCounts(all, query: _query);
    final rows = stockRows(all, tab: _tab, query: _query);
    final value = stockValue(all);
    final now = DateTime.now();

    final Widget body;
    if (repo.error != null) {
      // A failed load says so. An empty shelf and a broken query look
      // identical otherwise, and staff read both as "no stock".
      body = ErrorState(
        title: l10n.stockCouldNotBeLoaded,
        detail: repo.error!,
        onRetry: repo.load,
      );
    } else if (repo.loading && all.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        // Clear of the Buy phone button, so the last phone can be tapped.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _SummaryCard(value: value),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChipRow(
                  children: [
                    for (final t in StockTab.values)
                      CountChip(
                        key: Key('stock-tab-${t.name}'),
                        label: stockTabLabel(context, t),
                        count: counts[t],
                        color: _tabColour(context, t),
                        selected: t == _tab,
                        onTap: () => setState(() => _tab = t),
                      ),
                  ],
                ),
              ),
              HelpButton(
                title: l10n.helpStockTabsTitle,
                body: l10n.helpStockTabs,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            EmptyState(
              icon: _query.isEmpty
                  ? Icons.smartphone_outlined
                  : Icons.search_off,
              title: _query.isEmpty
                  ? l10n.nothingInTab(stockTabLabel(context, _tab))
                  : l10n.noMatchFor(_query),
              detail: _query.isEmpty
                  ? l10n.takeAHandsetIn
                  : l10n.stockSearchCovers,
            )
          else
            for (final (i, d) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _StockCard(device: d, now: now),
            ],
        ],
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavySearchBlock(
            hint: l10n.searchStock,
            onChanged: (v) => setState(() => _query = v),
            onScan: () => context.go('/scanner'),
            trailing: HelpButton(
              title: l10n.searchStock,
              body: l10n.helpSearchStock,
            ),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'second-hand-new',
        onPressed: () => openPurchaseSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.homeBuyPhone),
      ),
    );
  }

  Color? _tabColour(BuildContext context, StockTab tab) {
    final c = context.shopColors;
    return switch (tab) {
      StockTab.available => c.good,
      StockTab.repairing => c.wait,
      StockTab.sold => c.done,
      StockTab.all => null,
    };
  }
}

/// What the shop's money is in: everything on the shelf and on the bench.
///
/// That is a different number from the "In stock" tab, and the card says
/// "on hand" so the two are not read as the same thing.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value});

  final StockValue value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final margins = canSeeMargins(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.page,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stockOnHand('${value.count}'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.stockSellingFor(formatIndianNumber(value.asking)),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (margins)
                    Text(
                      l10n.stockPaidFor(formatIndianNumber(value.cost)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (margins && value.count > 0)
              ProfitPill(profit: value.expectedProfit),
          ],
        ),
      ),
    );
  }
}

/// One phone: its picture with the grade on it, the name and memory, the
/// IMEI and label, the price — and, for the owner, cost and profit — and how
/// long it has been in the shop.
class _StockCard extends StatelessWidget {
  const _StockCard({required this.device, required this.now});

  final SecondHandDevice device;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = context.shopColors;
    final l10n = context.l10n;
    final costing = device.costing;
    final grade = device.grade;
    final photo = device.frontPhoto;
    // The form still records a placeholder for a photo slot; only a real web
    // address is drawn as a picture.
    final hasPicture = photo != null && photo.startsWith('http');
    final margins = canSeeMargins(context);
    final days = daysInStock(device, now);
    final stale = isStale(device, now);
    final gradeColour = switch (grade) {
      'A' || 'A+' => colours.good,
      'B' => colours.wait,
      null => colours.done,
      _ => colours.stop,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/inventory/second-hand/${device.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                height: 104,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: AppTheme.page,
                          child: hasPicture
                              ? Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.smartphone,
                                    size: 36,
                                    color: AppTheme.border,
                                  ),
                                )
                              : const Icon(
                                  Icons.smartphone,
                                  size: 36,
                                  color: AppTheme.border,
                                ),
                        ),
                      ),
                    ),
                    if (grade != null)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: gradeColour,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            grade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (device.colour.isNotEmpty)
                      Text(
                        device.colour,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    if (device.imei.isNotEmpty || device.labelNumber != null)
                      Text(
                        [
                          if (device.imei.isNotEmpty) 'IMEI ${device.imei}',
                          if (device.labelNumber != null)
                            l10n.labelNamed('${device.labelNumber}'),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // On the shelf it goes without saying; any other
                        // state is said in words.
                        if (!device.isSellable)
                          StateChip(status: device.status),
                        if (days != null && !device.isSold)
                          StatusPill(
                            l10n.stockDays(days),
                            color: stale ? colours.wait : colours.done,
                            soft: stale ? colours.waitSoft : colours.doneSoft,
                            icon: Icons.schedule,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (device.isSold)
                      // Realised, not expected: what it actually went out at.
                      Text(
                        margins
                            ? l10n.soldMade(
                                '${device.soldPrice}',
                                '${costing.realisedProfit}',
                              )
                            : l10n.soldFor('${device.soldPrice}'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colours.done,
                        ),
                      )
                    else ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            rupees(costing.askingPrice),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (margins)
                            ProfitPill(profit: costing.expectedProfit),
                        ],
                      ),
                      if (margins)
                        Text(
                          l10n.costNamed(formatIndianNumber(costing.totalCost)),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
