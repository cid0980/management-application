/// THE PRODUCTS LIST'S OWN RULES
///
/// Four tabs: everything, the ones to order, the ones that have run out, and
/// everything grouped by category. The middle two are the reason anyone opens
/// this page.
///
/// **Low stock leads.** The list is ordered so the rows worth acting on are at
/// the top of the default tab, rather than alphabetically with the two empty
/// products somewhere in the middle of four hundred.
library;

import 'product.dart';
import 'stock_level.dart';

enum ProductTab { all, toOrder, outOfStock }

const Map<ProductTab, String> kProductTabLabels = {
  ProductTab.all: 'All',
  ProductTab.toOrder: 'To order',
  ProductTab.outOfStock: 'Out of stock',
};

bool inProductTab(Product product, ProductTab tab) => switch (tab) {
  ProductTab.all => true,
  // Out of stock is included: it is the most urgent version of the same
  // problem, and a tab that excluded it would be empty on the morning the
  // shop ran out.
  ProductTab.toOrder => product.needsOrdering,
  ProductTab.outOfStock => product.level == StockLevel.outOfStock,
};

/// The rows for a tab and a search box.
///
/// Out of stock first, then low, then the rest — and alphabetically within
/// each. Whoever opens this page is either selling something or ordering
/// something, and both are served by the problems being at the top.
List<Product> productRows(
  Iterable<Product> all, {
  ProductTab tab = ProductTab.all,
  String? query,
}) {
  final rows = [
    for (final p in all)
      if (inProductTab(p, tab) && p.matches(query)) p,
  ];
  rows.sort((a, b) {
    final byLevel = _levelRank(a.level).compareTo(_levelRank(b.level));
    if (byLevel != 0) return byLevel;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return rows;
}

int _levelRank(StockLevel level) => switch (level) {
  StockLevel.outOfStock => 0,
  StockLevel.low => 1,
  StockLevel.inStock => 2,
};

/// How many rows each tab holds for the current search.
///
/// Against the same query the list is showing. A badge of forty over an empty
/// tab is how staff conclude the app is broken.
Map<ProductTab, int> productTabCounts(Iterable<Product> all, {String? query}) {
  final counts = {for (final t in ProductTab.values) t: 0};
  for (final p in all) {
    if (!p.matches(query)) continue;
    for (final t in ProductTab.values) {
      if (inProductTab(p, t)) counts[t] = counts[t]! + 1;
    }
  }
  return counts;
}

/// What the sale picker is allowed to offer.
///
/// Only products with something on the shelf. The rest are still LOADED, not
/// dropped — the same rule as second-hand: a product that simply does not
/// appear is one somebody adds a second record for.
List<Product> sellableProducts(Iterable<Product> all) => [
  for (final p in all)
    if (p.isSellable) p,
];

/// Money tied up in new goods, and what it would bring in.
class ProductStockValue {
  const ProductStockValue({
    required this.lines,
    required this.units,
    required this.cost,
    required this.retail,
  });

  /// Distinct products, which is a different number from [units] and the one
  /// people mean by "how many products do we stock".
  final int lines;

  final int units;
  final num cost;
  final num retail;

  num get expectedProfit => retail - cost;
}

ProductStockValue productStockValue(Iterable<Product> all) {
  var lines = 0;
  var units = 0;
  num cost = 0;
  num retail = 0;
  for (final p in all) {
    lines++;
    units += p.stockCount;
    cost += p.stockCost;
    retail += p.stockValue;
  }
  return ProductStockValue(
    lines: lines,
    units: units,
    cost: cost,
    retail: retail,
  );
}

/// The products the dashboard's Low Stock tile counts, worst first.
List<Product> lowStockAlerts(Iterable<Product> all) =>
    productRows(all, tab: ProductTab.toOrder);

/// Products grouped by the shop's own categories, for a list of four hundred.
///
/// Categories in the order they first appear rather than alphabetically, so a
/// shop that has ordered its settings list sensibly sees that order here.
Map<String, List<Product>> byCategory(Iterable<Product> all) {
  final groups = <String, List<Product>>{};
  for (final p in productRows(all)) {
    final key = p.category.trim().isEmpty ? 'Uncategorised' : p.category.trim();
    (groups[key] ??= []).add(p);
  }
  return groups;
}
