/// WHAT CUSTOMERS STILL OWE
///
/// One rule carries this whole page: **a financed sale is never here.**
///
/// A finance (EMI) sale is recorded as fully paid. The customer paid their
/// down payment and the financier pays the shop the rest, so the customer owes
/// the shop nothing. Due Payments is the list staff ring people from. A
/// financed sale appearing on it meant customers were chased for money they
/// did not owe, over a settlement the financier had not sent yet.
///
/// The exclusion is not a filter applied here — it comes out of
/// `balanceDueFor`, which returns zero for a finance method. One rule, one
/// place, so the sale page, this list and Reports cannot disagree.
library;

import '../inventory/purchase_costing.dart' show asAmount;
import 'sale.dart';

/// One customer's outstanding total, and the bills it came from.
class DueAccount {
  const DueAccount({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.sales,
  });

  final String? customerId;
  final String customerName;
  final String customerPhone;

  /// Newest first. Each one carries its own balance.
  final List<Sale> sales;

  num get outstanding => sales.fold<num>(0, (sum, s) => sum + s.balanceDue);

  DateTime? get oldestUnpaid {
    DateTime? oldest;
    for (final s in sales) {
      final at = s.completedAt ?? s.createdAt;
      if (at == null) continue;
      if (oldest == null || at.isBefore(oldest)) oldest = at;
    }
    return oldest;
  }

  /// How long the oldest unpaid bill has been outstanding.
  int? daysOutstanding(DateTime now) {
    final oldest = oldestUnpaid;
    return oldest == null ? null : now.difference(oldest).inDays;
  }
}

/// The bills with money still on them.
///
/// Completed sales only. A draft is not a debt — nothing was handed over and
/// nobody was asked for anything. A cancelled sale is not a debt either.
List<Sale> unpaidSales(Iterable<Sale> all) => [
  for (final s in all)
    if (s.completed && s.balanceDue > 0) s,
];

/// Due Payments, grouped by customer, most owed first.
///
/// Grouped because the person at the counter is one customer with three bills,
/// not three rows, and ringing them three times is how the shop annoyed the
/// people who actually pay.
List<DueAccount> dueAccounts(Iterable<Sale> all) {
  final groups = <String, List<Sale>>{};
  for (final sale in unpaidSales(all)) {
    // Keyed by customer id where there is one, by number otherwise: a walk-in
    // recorded by number alone still has their bills added up together.
    final key = sale.customerId ?? 'phone:${sale.customerPhone}';
    (groups[key] ??= []).add(sale);
  }

  final accounts = <DueAccount>[];
  groups.forEach((_, sales) {
    sales.sort((a, b) {
      final x = a.completedAt ?? a.createdAt;
      final y = b.completedAt ?? b.createdAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    final first = sales.first;
    accounts.add(
      DueAccount(
        customerId: first.customerId,
        customerName: first.customerName,
        customerPhone: first.customerPhone,
        sales: sales,
      ),
    );
  });

  accounts.sort((a, b) => b.outstanding.compareTo(a.outstanding));
  return accounts;
}

/// Everything the shop is owed by customers.
num totalOutstanding(Iterable<Sale> all) =>
    unpaidSales(all).fold<num>(0, (sum, s) => sum + s.balanceDue);

/// Whether this collection may go through.
///
/// Only an admin collects a balance — the rule the sale page enforces too. And
/// never more than is owed: taking 600 against a 500 balance leaves a credit
/// nobody recorded, which is what the wallet is for.
enum CollectionRefusal { notAnAmount, overpayment, notAdmin, nothingOwed }

const Map<CollectionRefusal, String> kCollectionMessages = {
  CollectionRefusal.notAnAmount: 'Enter an amount above zero',
  CollectionRefusal.overpayment:
      'That is more than is owed on this bill — put the extra in the wallet '
      'instead',
  CollectionRefusal.notAdmin: 'Only an admin may collect a balance',
  CollectionRefusal.nothingOwed: 'Nothing is owed on this bill',
};

class CollectionCheck {
  const CollectionCheck.allowed(this.remaining) : refusal = null;

  CollectionCheck.refused(CollectionRefusal this.refusal, this.remaining);

  final CollectionRefusal? refusal;

  /// What would still be owed after this collection.
  final num remaining;

  bool get isAllowed => refusal == null;
  String? get message => refusal == null ? null : kCollectionMessages[refusal];
}

CollectionCheck canCollect(Sale sale, Object? amount, {required bool isAdmin}) {
  final owed = sale.balanceDue;
  if (!isAdmin) {
    return CollectionCheck.refused(CollectionRefusal.notAdmin, owed);
  }
  if (owed <= 0) {
    return CollectionCheck.refused(CollectionRefusal.nothingOwed, 0);
  }
  final value = asAmount(amount);
  if (value <= 0) {
    return CollectionCheck.refused(CollectionRefusal.notAnAmount, owed);
  }
  if (value > owed) {
    return CollectionCheck.refused(CollectionRefusal.overpayment, owed);
  }
  return CollectionCheck.allowed(owed - value);
}
