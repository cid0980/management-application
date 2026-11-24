import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/product_repository.dart';
import '../../../domain/products/product.dart';
import '../../../domain/products/product_list.dart';
import '../../../domain/products/stock_level.dart';
import 'product_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../../domain/common/money.dart';
import '../../widgets/margins.dart';
import '../../widgets/contact_buttons.dart';
import '../../widgets/loading.dart';

/// NEW GOODS
///
/// The page answers one question per row: **how many are left**. That is the
/// whole difference from the second-hand list, which answers "can I sell
/// this".
///
/// Out of stock sorts above low, and low above everything else, so the rows
/// worth acting on are at the top of whichever tab is open. A list of four
/// hundred accessories sorted alphabetically buries the two that have run out.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialTab});

  /// A [ProductTab] name to open on, e.g. `toOrder` from the Low Stock tile.
  final String? initialTab;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductTab _tab = _tabFrom(widget.initialTab);

  static ProductTab _tabFrom(String? name) => ProductTab.values.firstWhere(
    (t) => t.name == name,
    orElse: () => ProductTab.all,
  );

  @override
  void didUpdateWidget(ProductListScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialTab != old.initialTab && widget.initialTab != null) {
      _tab = _tabFrom(widget.initialTab);
    }
  }

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProductRepository>();
    final theme = Theme.of(context);

    // A failed load says so. An empty shelf and a broken query look identical
    // otherwise, and staff read both as "we stock nothing".
    if (repo.error != null) {
      return ErrorState(
        title: context.l10n.productsCouldNotBeLoaded,
        detail: repo.error!,
        onRetry: repo.load,
      );
    }

    final all = repo.products;
    final counts = productTabCounts(all, query: _query);
    final rows = productRows(all, tab: _tab, query: _query);
    final value = productStockValue(all);

    return Scaffold(
      body: Column(
        children: [
          NavySearchBlock(
            fieldKey: const Key('product-search'),
            hint: context.l10n.searchProducts,
            onChanged: (v) => setState(() => _query = v),
            onScan: () => context.go('/scanner'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ChipRow(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final tab in ProductTab.values)
                  CountChip(
                    key: Key('products-tab-${tab.name}'),
                    label: productTabLabel(context, tab),
                    count: counts[tab],
                    color: switch (tab) {
                      ProductTab.toOrder => context.shopColors.wait,
                      _ => null,
                    },
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
          ),
          // The message to the supplier, written from the list.
          if (_tab == ProductTab.toOrder && rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('send-order-list'),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(context.l10n.sendOrderList),
                  onPressed: () => openContactLink(
                    context,
                    Uri.https('wa.me', '/', {
                      'text': orderListMessage(
                        all,
                        shopName: shopNameOf(context),
                      ),
                    }),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // Lines and units are different numbers, and people mean
                    // the first by "how many products do we stock".
                    canSeeMargins(context)
                        ? context.l10n.productSummary(
                            value.lines,
                            value.units,
                            formatIndianNumber(value.cost),
                            formatIndianNumber(value.retail),
                          )
                        : context.l10n.productSummaryRetail(
                            value.lines,
                            value.units,
                            formatIndianNumber(value.retail),
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
                ? LoadingWords(first: context.l10n.loadingProducts)
                : rows.isEmpty
                ? EmptyState(
                    icon: _query.isEmpty
                        ? Icons.inventory_2_outlined
                        : Icons.search_off,
                    title: _query.isEmpty
                        ? _tab == ProductTab.all
                              ? context.l10n.nothingOnTheListYet
                              : context.l10n.nothingInTab(
                                  productTabLabel(context, _tab),
                                )
                        : context.l10n.noMatchFor(_query),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ProductRow(product: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('products-new'),
        heroTag: 'product-new',
        onPressed: () => openProductSheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.add),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggested = product.suggestedOrder;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 2, 10, 2),
        visualDensity: VisualDensity.compact,
        onTap: () => context.go('/products/${product.id}'),
        leading: CircleAvatar(
          backgroundColor: AppTheme.page,
          foregroundColor: AppTheme.text,
          child: Text(
            '${product.stockCount}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(product.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (product.category.isNotEmpty) product.category,
                rupees(product.sellingPrice),
                if (product.labelNumber != null)
                  context.l10n.labelNamed('${product.labelNumber}'),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              product.reorderLevel > 0
                  ? '${context.l10n.reorderAt('${product.reorderLevel}')}'
                        '${suggested != null && suggested > 0 ? ' · $suggested' : ''}'
                  // Said rather than left blank: this product will never show as
                  // low, and that is worth knowing on the row.
                  : context.l10n.noReorderLevel,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _LevelChip(level: product.level),
        isThreeLine: true,
      ),
    );
  }
}

/// How many are left, as one word. Out of stock is its own answer, not a
/// shade of low.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final StockLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.shopColors;
    final (Color bg, Color fg) = switch (level) {
      StockLevel.outOfStock => (c.stopSoft, c.stop),
      StockLevel.low => (c.waitSoft, c.wait),
      StockLevel.inStock => (c.goodSoft, c.good),
    };
    return StatusPill(stockLevelLabel(context, level), color: fg, soft: bg);
  }
}
