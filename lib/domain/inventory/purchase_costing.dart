/// WHAT THE SHOP ACTUALLY MAKES ON A USED HANDSET
///
/// The margin was wrong for as long as repairs lived somewhere else. A phone
/// bought at 6,000 and listed at 9,000 showed a 3,000 profit, and the 1,400
/// spent on a display was recorded as a service job against nobody. The
/// repairs are costed ON THE PURCHASE, so the only number anyone looks at is
/// the true one.
///
/// Two profits, and they are not the same:
///
/// - **expected**, from the asking price, which is what the shop hopes for and
///   what the listing is priced against;
/// - **realised**, from what the handset actually went out at, which is the
///   only one that belongs in Reports.
///
/// A device still in stock has no realised profit. Not zero — none. Reporting
/// a zero would average a shelf full of unsold stock into the month's margin
/// and drag it to nothing.
library;

/// One repair done to a device before resale.
class RepairCost {
  const RepairCost({required this.description, required this.amount});

  final String description;
  final num amount;

  Map<String, Object?> toMap() => {
    'description': description,
    'amount': amount,
  };

  static RepairCost fromMap(Map<String, Object?> map) => RepairCost(
    description: (map['description'] as String?) ?? '',
    amount: asAmount(map['amount']),
  );
}

/// A money field off a form or a document, as a number.
///
/// Amounts arrive as an int, a double, or the string the text field held —
/// `'1,400'`, `'₹1400'`, `''`. An unparseable or missing amount is zero: a
/// blank cost field means nothing was spent, and must not take the whole
/// margin out with a null.
num asAmount(Object? value) {
  if (value is num) return value;
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return num.tryParse(cleaned) ?? 0;
  }
  return 0;
}

/// The money side of one purchase record.
class Costing {
  const Costing({
    required this.purchasePrice,
    required this.repairTotal,
    required this.otherCost,
    required this.askingPrice,
    required this.soldPrice,
  });

  final num purchasePrice;
  final num repairTotal;

  /// Transport, cleaning, a case thrown in — anything spent that is not a
  /// listed repair.
  final num otherCost;

  final num askingPrice;

  /// What it went out at, once it did. Null while it is still in stock.
  final num? soldPrice;

  /// Everything the handset has cost the shop.
  num get totalCost => purchasePrice + repairTotal + otherCost;

  /// What the shop hopes to make, at the asking price.
  num get expectedProfit => askingPrice - totalCost;

  /// What it actually made. Null until it is sold — see the library note.
  num? get realisedProfit => soldPrice == null ? null : soldPrice! - totalCost;

  /// Expected margin as a fraction of the asking price, or null when there is
  /// no asking price to divide by.
  double? get expectedMargin =>
      askingPrice > 0 ? expectedProfit / askingPrice : null;

  /// Priced at or below what it cost. The form warns on this rather than
  /// refusing it — a clearance sale at a loss is a decision, not a mistake.
  bool get atALoss => askingPrice > 0 && expectedProfit <= 0;
}

/// The costing for a purchase record.
Costing costingOf({
  Object? purchasePrice,
  Iterable<RepairCost> repairs = const [],
  Object? otherCost,
  Object? askingPrice,
  Object? soldPrice,
}) {
  return Costing(
    purchasePrice: asAmount(purchasePrice),
    repairTotal: repairTotalOf(repairs),
    otherCost: asAmount(otherCost),
    askingPrice: asAmount(askingPrice),
    // Distinguish "not sold" from "sold for nothing": only an actually present
    // value becomes a realised figure.
    soldPrice: soldPrice == null ? null : asAmount(soldPrice),
  );
}

num repairTotalOf(Iterable<RepairCost> repairs) =>
    repairs.fold<num>(0, (sum, r) => sum + r.amount);
