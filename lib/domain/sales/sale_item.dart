/// ONE LINE ON A BILL
///
/// A line is either a handset out of second-hand stock, a product off the
/// shelf, or something typed in by hand. The source matters, because it
/// decides what happens to stock when the sale completes:
///
/// - a **second-hand** line marks that one handset sold; there is only ever
///   one of it, so the quantity is fixed at 1;
/// - a **product** line brings the stock count down by the quantity;
/// - a **manual** line touches nothing. A fitting charge, a screen guard out
///   of the drawer nobody counts, a round-off.
///
/// The price is copied onto the line rather than read from the stock record at
/// bill time. A price corrected next week must not change a bill already
/// given to a customer.
library;

import '../inventory/purchase_costing.dart' show asAmount;

enum LineSource {
  /// A used handset. One of it, by definition.
  secondHand,

  /// New goods with a stock count.
  product,

  /// Typed in. Touches no stock.
  manual,
}

class SaleItem {
  const SaleItem({
    required this.description,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
    this.source = LineSource.manual,
    this.recordId,
    this.imei,
    this.labelNumber,
  });

  final String description;

  /// Copied at bill time, on purpose. See the library note.
  final num unitPrice;

  final int quantity;

  /// Taken off this line's total, in rupees rather than a percentage: the
  /// counter haggles in rupees.
  final num discount;

  final LineSource source;

  /// The stock record this line came from, for the write that happens when the
  /// sale completes. Null on a manual line.
  final String? recordId;

  /// Printed on the invoice for a handset, because the IMEI is what a warranty
  /// claim is made against.
  final String? imei;

  final int? labelNumber;

  /// A used handset is one of one. Anything claiming otherwise is a mistake
  /// the line itself can correct.
  int get effectiveQuantity =>
      source == LineSource.secondHand ? 1 : (quantity < 1 ? 1 : quantity);

  num get gross => unitPrice * effectiveQuantity;

  /// Never below zero: a discount bigger than the line is a typo, and a
  /// negative line total would quietly pay the customer.
  num get total {
    final net = gross - discount;
    return net < 0 ? 0 : net;
  }

  /// The discount is larger than the line. Flagged rather than silently
  /// clamped, so the counter sees it.
  bool get discountExceedsLine => discount > gross;

  /// Whether completing the sale has to write to stock for this line.
  bool get movesStock => source != LineSource.manual;

  SaleItem copyWith({
    String? description,
    num? unitPrice,
    int? quantity,
    num? discount,
  }) => SaleItem(
    description: description ?? this.description,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    discount: discount ?? this.discount,
    source: source,
    recordId: recordId,
    imei: imei,
    labelNumber: labelNumber,
  );

  Map<String, Object?> toMap() => {
    'description': description,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'discount': discount,
    'source': source.name,
    'recordId': recordId,
    'imei': imei,
    'labelNumber': labelNumber,
  };

  static SaleItem fromMap(Map<String, Object?> map) => SaleItem(
    description: (map['description'] ?? '').toString().trim(),
    unitPrice: asAmount(map['unitPrice'] ?? map['price']),
    quantity: _int(map['quantity']) ?? 1,
    discount: asAmount(map['discount']),
    source: switch ((map['source'] ?? '').toString()) {
      'secondHand' || 'second_hand' => LineSource.secondHand,
      'product' => LineSource.product,
      _ => LineSource.manual,
    },
    recordId: map['recordId'] as String?,
    imei: map['imei'] as String?,
    labelNumber: _int(map['labelNumber']),
  );

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// What the lines add up to before payment.
class BillTotals {
  const BillTotals({
    required this.gross,
    required this.discount,
    required this.total,
    required this.lineCount,
  });

  final num gross;
  final num discount;
  final num total;
  final int lineCount;
}

BillTotals billTotals(Iterable<SaleItem> items) {
  num gross = 0;
  num discount = 0;
  num total = 0;
  var count = 0;
  for (final item in items) {
    gross += item.gross;
    // The discount as it actually applied, not as it was typed: a discount
    // bigger than the line cannot take money off the rest of the bill.
    discount += item.gross - item.total;
    total += item.total;
    count++;
  }
  return BillTotals(
    gross: gross,
    discount: discount,
    total: total,
    lineCount: count,
  );
}
