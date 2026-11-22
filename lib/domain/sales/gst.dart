/// GST ON THE BILL
///
/// Indian retail prices are GST-inclusive — the price on the tag is what the
/// customer pays — so a registered shop's invoice has to show how much of the
/// total is tax. This works that out from the shop's own rate.
///
/// What this does NOT decide is the law. The rate is the shop's setting (18%
/// for phones, accessories and repair work as of 2026, but the owner and their
/// accountant set it), and **used handsets are left out**: a dealer in second-
/// hand phones usually pays GST on the margin, not the price, and that is not
/// printed as a tax line on the customer's bill.
///
/// Within the state the tax is split half CGST, half SGST. A sale to a
/// customer in another state is IGST: the whole tax, on one line.
library;

import 'sale.dart';
import 'sale_item.dart';

class GstSplit {
  const GstSplit({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.rate,
    this.igst = 0,
  });

  /// The value before tax.
  final num taxable;
  final num cgst;
  final num sgst;

  /// The whole tax, for a customer in another state; 0 within the state.
  final num igst;

  bool get interState => igst > 0;

  /// The full rate, e.g. 18.
  final num rate;

  num get tax => cgst + sgst + igst;
}

num _paise(num v) => (v * 100).round() / 100;

/// The tax inside a GST-inclusive [amount] at [ratePercent]. Null for no rate.
/// [interState] puts the whole tax on one IGST line.
GstSplit? gstInclusive(num amount, num ratePercent, {bool interState = false}) {
  if (ratePercent <= 0 || amount <= 0) return null;
  final taxable = _paise(amount * 100 / (100 + ratePercent));
  final tax = _paise(amount - taxable);
  if (interState) {
    return GstSplit(
      taxable: taxable,
      cgst: 0,
      sgst: 0,
      igst: tax,
      rate: ratePercent,
    );
  }
  final cgst = _paise(tax / 2);
  return GstSplit(
    taxable: taxable,
    cgst: cgst,
    sgst: _paise(tax - cgst),
    rate: ratePercent,
  );
}

/// The part of a bill GST is shown on: everything except used handsets.
num taxableAmountOf(Sale sale) => sale.items
    .where((i) => i.source != LineSource.secondHand)
    .fold<num>(0, (s, i) => s + i.total);

/// Whether the bill has used handsets, which the invoice then notes.
bool hasMarginSchemeLines(Sale sale) =>
    sale.items.any((i) => i.source == LineSource.secondHand);
