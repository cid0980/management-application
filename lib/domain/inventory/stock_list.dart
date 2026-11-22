/// THE STOCK LIST'S OWN RULES
///
/// Which tab a device belongs in, what the tab counts say, and what order the
/// rows come in. Pulled out of the widget because these are the rules people
/// argue about, and a rule in a widget cannot be tested.
///
/// The tabs are the three states plus All, and they are not a filter on a
/// dropdown value: `stockStateOf` decides, so a device carrying a status this
/// build has never seen still lands somewhere a human can find it.
library;

import 'second_hand_device.dart';
import 'stock_state.dart';

enum StockTab { available, repairing, sold, all }

const Map<StockTab, String> kStockTabLabels = {
  StockTab.available: 'In stock',
  StockTab.repairing: 'Repairing',
  StockTab.sold: 'Sold',
  StockTab.all: 'All',
};

bool inTab(SecondHandDevice d, StockTab tab) => switch (tab) {
  StockTab.available => d.stockState == kAvailable,
  StockTab.repairing => d.stockState == kRepairing,
  StockTab.sold => d.stockState == kSold,
  StockTab.all => true,
};

/// The rows for a tab and a search box.
///
/// Newest purchase first, because the row someone is looking for is almost
/// always the one just taken in. A record with no purchase date sorts last
/// rather than first: an undated row is incomplete, not urgent.
List<SecondHandDevice> stockRows(
  Iterable<SecondHandDevice> all, {
  StockTab tab = StockTab.available,
  String? query,
}) {
  final rows = all.where((d) => inTab(d, tab) && d.matches(query)).toList();
  rows.sort((a, b) {
    final x = a.purchasedAt ?? a.createdAt;
    final y = b.purchasedAt ?? b.createdAt;
    if (x == null && y == null) return a.title.compareTo(b.title);
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  });
  return rows;
}

/// How many rows each tab holds for the current search.
///
/// Counted against the SAME query the list is showing. A badge of 40 over an
/// empty tab is how staff conclude the app is broken.
Map<StockTab, int> stockTabCounts(
  Iterable<SecondHandDevice> all, {
  String? query,
}) {
  final counts = {for (final t in StockTab.values) t: 0};
  for (final d in all) {
    if (!d.matches(query)) continue;
    for (final t in StockTab.values) {
      if (inTab(d, t)) counts[t] = counts[t]! + 1;
    }
  }
  return counts;
}

/// What the sale picker is allowed to offer.
///
/// Only sellable stock. The rest is still LOADED, not dropped — a scan of a
/// repairing or sold handset has to be able to explain itself instead of
/// saying "no such device", which is how staff end up re-entering a phone the
/// shop already owns.
List<SecondHandDevice> sellableStock(Iterable<SecondHandDevice> all) => [
  for (final d in all)
    if (d.isSellable) d,
];

/// Money tied up in stock on the shelf and on the bench, and what the shop
/// stands to make on it. Sold devices are not stock and are not counted.
class StockValue {
  const StockValue({
    required this.count,
    required this.cost,
    required this.asking,
  });

  final int count;
  final num cost;
  final num asking;

  num get expectedProfit => asking - cost;
}

StockValue stockValue(Iterable<SecondHandDevice> all) {
  var count = 0;
  num cost = 0;
  num asking = 0;
  for (final d in all) {
    if (d.isSold) continue;
    count++;
    cost += d.costing.totalCost;
    asking += d.costing.askingPrice;
  }
  return StockValue(count: count, cost: cost, asking: asking);
}

/// WHAT THIS MODEL WENT FOR BEFORE
///
/// Buying a used phone is a price said out loud at the counter, usually from
/// memory. This is the shop's own memory instead: what it paid for the same
/// brand and model before (lowest to highest) and, of those sold, what they
/// sold for on average. Case and spacing are ignored, as everywhere a brand
/// or model is compared. Null when the shop has never bought one.
class ModelPriceHistory {
  const ModelPriceHistory({
    required this.bought,
    required this.paidLow,
    required this.paidHigh,
    required this.sold,
    this.soldAverage,
  });

  final int bought;
  final num paidLow;
  final num paidHigh;
  final int sold;
  final num? soldAverage;
}

ModelPriceHistory? priceHistoryFor(
  Iterable<SecondHandDevice> all, {
  required String brand,
  required String model,
  String? excludeId,
}) {
  String k(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (k(brand).isEmpty || k(model).isEmpty) return null;
  final same = all
      .where(
        (d) =>
            d.id != excludeId &&
            k(d.brand) == k(brand) &&
            k(d.model) == k(model) &&
            d.purchasePrice > 0,
      )
      .toList();
  if (same.isEmpty) return null;
  final paid = same.map((d) => d.purchasePrice).toList()..sort();
  final soldPrices = [
    for (final d in same)
      if (d.isSold && (d.soldPrice ?? 0) > 0) d.soldPrice!,
  ];
  return ModelPriceHistory(
    bought: same.length,
    paidLow: paid.first,
    paidHigh: paid.last,
    sold: soldPrices.length,
    soldAverage: soldPrices.isEmpty
        ? null
        : (soldPrices.fold<num>(0, (a, b) => a + b) / soldPrices.length)
              .round(),
  );
}
