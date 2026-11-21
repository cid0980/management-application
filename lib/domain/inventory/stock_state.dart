/// WHAT STATE A SECOND-HAND DEVICE IS IN
///
/// The stock list answers one question about every row: can I sell this. It
/// had two answers, and the shop's actual work needs three.
///
/// A device bought damaged and repaired before resale is a normal week here —
/// the purchase form has costed repairs since it was written, and the profit
/// is right. What was missing was the fortnight in between. With only
/// available and sold, a phone in pieces on the bench showed a green bar
/// meaning "yes, sell this" and offered itself in the new-sale picker. The
/// honest answer in that fortnight is "not yet", and that is what [repairing]
/// is for.
///
/// This is also why staff reached for a service order instead: it has a status
/// to work through. A service order is the wrong instrument — it assumes a
/// customer owns the device and owes money, so it lands in Due Payments as a
/// debt and in Reports as revenue nobody paid. The device never leaves stock;
/// only its state changes.
///
/// Sold always wins. A device that has gone out of the shop cannot be put back
/// into repair by someone editing the record.
library;

const String kAvailable = 'available';
const String kRepairing = 'repairing';
const String kSold = 'sold';

/// Three states, one question: go, wait, gone. Colour is the theme's business.
const Map<String, String> kStockLabels = {
  kAvailable: 'In stock',
  kRepairing: 'Being repaired',
  kSold: 'Sold',
};

/// The state of a device, treating anything unrecognised as plain stock.
String stockStateOf(String? status) {
  if (status == kSold) return kSold;
  if (status == kRepairing) return kRepairing;
  return kAvailable;
}

/// Whether it can go on a bill today.
bool isSellable(String? status) => stockStateOf(status) == kAvailable;

/// Whether the shop is still working on it.
bool isBeingRepaired(String? status) => stockStateOf(status) == kRepairing;

/// The status to store when a purchase is saved.
///
/// [stillBeingRepaired] is the form's own answer to "is this ready to sell". A
/// sold device ignores it: editing the record of something already out of the
/// shop must not put it back on the shelf, or into repair.
String statusForSave({String? current, bool stillBeingRepaired = false}) {
  if (current == kSold) return kSold;
  return stillBeingRepaired ? kRepairing : kAvailable;
}
