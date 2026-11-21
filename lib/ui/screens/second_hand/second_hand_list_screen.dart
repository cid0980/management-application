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
import '../../widgets/fading_scroll.dart';
import '../../widgets/margins.dart';

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

    // A failed load says so. An empty shelf and a broken query look identical
    // otherwise, and staff read both as "no stock".
    if (repo.error != null) {
      return _Message(
        icon: Icons.cloud_off,
        title: context.l10n.stockCouldNotBeLoaded,
        detail: repo.error!,
        action: FilledButton(
          onPressed: repo.load,
          child: Text(context.l10n.tryAgain),
        ),
      );
    }

    final all = repo.devices;
    final counts = stockTabCounts(all, query: _query);
    final rows = stockRows(all, tab: _tab, query: _query);
    final value = stockValue(all);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(
              hint: context.l10n.searchStock,
              help: context.l10n.helpSearchStock,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SummaryCard(value: value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: _TabTrack(
                    selected: _tab,
                    counts: counts,
                    colourOf: (t) => _tabColour(context, t),
                    onSelected: (t) => setState(() => _tab = t),
                  ),
                ),
                HelpButton(
                  title: context.l10n.helpStockTabsTitle,
                  body: context.l10n.helpStockTabs,
                ),
              ],
            ),
          ),
          Expanded(
            child: repo.loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? _Message(
                    icon: Icons.smartphone_outlined,
                    title: _query.isEmpty
                        ? context.l10n.nothingInTab(
                            stockTabLabel(context, _tab),
                          )
                        : context.l10n.noMatchFor(_query),
                    detail: _query.isEmpty
                        ? context.l10n.takeAHandsetIn
                        : context.l10n.stockSearchCovers,
                  )
                : ListView.separated(
                    // Clear of the Take in button, so the last phone can
                    // still be tapped.
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _StockCard(device: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'second-hand-new',
        shape: const StadiumBorder(),
        onPressed: () => openPurchaseSheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.takeIn),
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

/// A rounded white search pill with the "?" inside it.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.help,
    required this.onChanged,
  });

  final String hint;
  final String help;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hint,
          filled: true,
          fillColor: AppTheme.surface,
          border: pill,
          enabledBorder: pill,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppTheme.action, width: 2),
          ),
          suffixIcon: HelpButton(title: hint, body: help),
        ),
        onChanged: onChanged,
      ),
    );
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
    final rose = theme.colorScheme.primary;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: rose,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: rose.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stockOnHand('${value.count}'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _WhitePill(l10n.stockSellingFor('${value.asking}')),
                    if (canSeeMargins(context))
                      _WhitePill(l10n.stockPaidFor('${value.cost}')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The four tabs as one sliding track. It scrolls sideways when the words are
/// long, as Tamil ones are, rather than squeezing them.
class _TabTrack extends StatelessWidget {
  const _TabTrack({
    required this.selected,
    required this.counts,
    required this.colourOf,
    required this.onSelected,
  });

  final StockTab selected;
  final Map<StockTab, int> counts;
  final Color? Function(StockTab) colourOf;
  final ValueChanged<StockTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE4E3),
        borderRadius: BorderRadius.circular(26),
      ),
      child: FadingScroll(
        child: Row(
          children: [
            for (final tab in StockTab.values)
              _Segment(
                key: Key('stock-tab-${tab.name}'),
                label: '${stockTabLabel(context, tab)} ${counts[tab]}',
                // The colour dot is the state's colour everywhere in the
                // app, so it can be read before the word is.
                dot: colourOf(tab),
                selected: selected == tab,
                onTap: () => onSelected(tab),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
    required this.style,
  });

  final String label;
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Icon(Icons.circle, size: 10, color: dot),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: style?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One phone: its picture, its grade, what state it is in and what it sells
/// for.
class _StockCard extends StatelessWidget {
  const _StockCard({required this.device});

  final SecondHandDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = context.shopColors;
    final costing = device.costing;
    final grade = device.grade;
    final (Color soft, Color strong) = stateColours(context, device.status);
    final photo = device.frontPhoto;
    // The form still records a placeholder for a photo slot; only a real web
    // address is drawn as a picture.
    final hasPicture = photo != null && photo.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.go('/inventory/second-hand/${device.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The picture, in the state's soft colour, with the grade on
                // its corner: the one glance that says what this phone is and
                // whether it can go out today.
                SizedBox(
                  width: 74,
                  height: 90,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: soft,
                            alignment: Alignment.center,
                            child: hasPicture
                                ? Image.network(
                                    photo,
                                    fit: BoxFit.cover,
                                    width: 74,
                                    height: 90,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.smartphone,
                                      size: 34,
                                      color: strong,
                                    ),
                                  )
                                : Icon(
                                    Icons.smartphone,
                                    size: 34,
                                    color: strong,
                                  ),
                          ),
                        ),
                      ),
                      if (grade != null)
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: strong,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.surface,
                                width: 3,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
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
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (device.imei.isNotEmpty || device.labelNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (device.imei.isNotEmpty) 'IMEI ${device.imei}',
                              if (device.labelNumber != null)
                                context.l10n.labelNamed(
                                  '${device.labelNumber}',
                                ),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Under the name rather than beside it: a long state in
                      // Tamil would otherwise squeeze the price off the card.
                      StateChip(status: device.status),
                      const SizedBox(height: 8),
                      if (device.isSold)
                        // Realised, not expected: what it actually went out
                        // at.
                        Text(
                          canSeeMargins(context)
                              ? context.l10n.soldMade(
                                  '${device.soldPrice}',
                                  '${costing.realisedProfit}',
                                )
                              : context.l10n.soldFor('${device.soldPrice}'),
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
                              '₹${costing.askingPrice}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (canSeeMargins(context))
                              ProfitPill(profit: costing.expectedProfit),
                          ],
                        ),
                        if (canSeeMargins(context)) ...[
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.costNamed('${costing.totalCost}'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
