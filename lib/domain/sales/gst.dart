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
/// Intra-state only: the tax is split half CGST, half SGST. A sale to another
/// state (IGST) is not handled here.
library;

import 'sale.dart';
import 'sale_item.dart';

class GstSplit {
  const GstSplit({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.rate,
  });

  /// The value before tax.
  final num taxable;
  final num cgst;
  final num sgst;

  /// The full rate, e.g. 18.
  final num rate;

  num get tax => cgst + sgst;
}

num _paise(num v) => (v * 100).round() / 100;

/// The tax inside a GST-inclusive [amount] at [ratePercent]. Null for no rate.
GstSplit? gstInclusive(num amount, num ratePercent) {
  if (ratePercent <= 0 || amount <= 0) return null;
  final taxable = _paise(amount * 100 / (100 + ratePercent));
  final tax = _paise(amount - taxable);
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
