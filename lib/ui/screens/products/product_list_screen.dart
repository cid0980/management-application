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
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductTab _tab = ProductTab.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProductRepository>();
    final theme = Theme.of(context);

    // A failed load says so. An empty shelf and a broken query look identical
    // otherwise, and staff read both as "we stock nothing".
    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.productsCouldNotBeLoaded),
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

    final all = repo.products;
    final counts = productTabCounts(all, query: _query);
    final rows = productRows(all, tab: _tab, query: _query);
    final value = productStockValue(all);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('product-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchProducts,
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
                for (final tab in ProductTab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _tab == tab,
                      label: Text(
                        '${productTabLabel(context, tab)} ${counts[tab]}',
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
                    // Lines and units are different numbers, and people mean
                    // the first by "how many products do we stock".
                    context.l10n.productSummary(
                      '${value.lines}',
                      '${value.units}',
                      '${value.cost}',
                      '${value.retail}',
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
                            ? _tab == ProductTab.all
                                  ? context.l10n.nothingOnTheListYet
                                  : context.l10n.nothingInTab(
                                      productTabLabel(context, _tab),
                                    )
                            : context.l10n.noMatchFor(_query),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ProductRow(product: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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

    return ListTile(
      onTap: () => context.go('/products/${product.id}'),
      leading: CircleAvatar(child: Text('${product.stockCount}')),
      title: Text(product.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (product.category.isNotEmpty) product.category,
              '₹${product.sellingPrice}',
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
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (level) {
      StockLevel.outOfStock => (scheme.errorContainer, scheme.onErrorContainer),
      StockLevel.low => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      StockLevel.inStock => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        stockLevelLabel(context, level),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
