/// IS THERE ENOUGH OF THIS ON THE SHELF
///
/// Three answers, and the middle one is the useful one: **out of stock**,
/// **low**, **in stock**.
///
/// Two rules carry this.
///
/// **Low is a threshold per product, never one number for the shop.** The shop
/// sells fifty screen guards a week and one car charger a month. A single
/// "warn below five" either screams about the charger forever or never warns
/// about the guards until a Saturday with none left. So every product carries
/// its own reorder level, set by whoever does the ordering.
///
/// **A product with no reorder level set is not secretly assumed to be five.**
/// It has no low-stock alert, and the list says as much. Guessing a threshold
/// means an alert nobody chose, which is an alert nobody trusts — and the
/// whole value of this list is that the rows on it are worth acting on.
///
/// Out of stock is kept apart from low on purpose. Zero is not "nearly gone",
/// it is a sale the shop cannot make today, and folding it into low hid that.
library;

enum StockLevel {
  /// None on the shelf. A sale that cannot be made today.
  outOfStock,

  /// At or below this product's own reorder level. Time to order.
  low,

  /// Enough.
  inStock,
}

const Map<StockLevel, String> kStockLevelLabels = {
  StockLevel.outOfStock: 'Out of stock',
  StockLevel.low: 'Low',
  StockLevel.inStock: 'In stock',
};

/// Where [count] sits against this product's own [reorderLevel].
///
/// A [reorderLevel] of zero or less means no alert is configured, so the
/// product can only be in stock or out — never low. See the library note.
StockLevel stockLevelFor(int count, int reorderLevel) {
  if (count <= 0) return StockLevel.outOfStock;
  if (reorderLevel <= 0) return StockLevel.inStock;
  return count <= reorderLevel ? StockLevel.low : StockLevel.inStock;
}

/// Whether this product belongs on the dashboard's Low Stock tile.
///
/// Out of stock counts: it is the most urgent version of the same problem, and
/// a tile that excluded it would show zero on the morning the shop ran out.
bool needsReordering(int count, int reorderLevel) {
  final level = stockLevelFor(count, reorderLevel);
  return level == StockLevel.low || level == StockLevel.outOfStock;
}

/// How many to order to get back above the reorder level.
///
/// Null when no reorder level is set — there is no target to get back to, and
/// inventing one would put a number in front of whoever does the ordering that
/// nobody chose.
int? suggestedReorderQuantity(int count, int reorderLevel) {
  if (reorderLevel <= 0) return null;
  // One above the threshold, so receiving the suggestion actually clears the
  // alert rather than landing back on it.
  final target = reorderLevel + 1;
  final shortfall = target - count;
  return shortfall > 0 ? shortfall : 0;
}
