/// TAKINGS DAY BY DAY, AND WHAT SOLD
///
/// Ported from the French Mobiles Flutter port's Reports screen, where these
/// were worked out inside the widget; here they are rules with tests.
///
/// Counted the same way as the takings on the report: completed bills only,
/// dated on the day they were settled. A draft is a bill somebody is still
/// building, and a cancelled one never happened as far as the till goes.
library;

import '../common/dates.dart';
import '../sales/payment_methods.dart';
import '../sales/sale.dart';

/// One day's takings.
class DayTakings {
  const DayTakings(this.day, this.amount, this.bills);

  final DateTime day;
  final num amount;
  final int bills;
}

/// Every day in [range], oldest first — including the days with nothing, so a
/// quiet Tuesday shows up as a gap instead of disappearing from the chart.
///
/// A range longer than [maxDays] gives its last [maxDays] days: a bar per day
/// for a year is a smudge, not a chart.
List<DayTakings> dailyTakings(
  Iterable<Sale> sales,
  DateRange range, {
  int maxDays = 31,
}) {
  final totals = <DateTime, (num, int)>{};
  for (final sale in sales) {
    final at = sale.completedAt;
    if (!sale.completed || !range.contains(at)) continue;
    final day = DateTime(at!.year, at.month, at.day);
    final (amount, bills) = totals[day] ?? (0, 0);
    totals[day] = (amount + sale.total, bills + 1);
  }
  final days = <DayTakings>[];
  var day = DateTime(range.end.year, range.end.month, range.end.day);
  final first = DateTime(range.start.year, range.start.month, range.start.day);
  while (!day.isBefore(first) && days.length < maxDays) {
    final (amount, bills) = totals[day] ?? (0, 0);
    days.add(DayTakings(day, amount, bills));
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return days.reversed.toList();
}

/// What sold, by line description, biggest earner first.
class ItemSales {
  const ItemSales(this.description, this.amount, this.quantity);

  final String description;
  final num amount;
  final int quantity;
}

/// The [limit] best sellers in [range]. Lines are matched by what they are
/// called, ignoring case and spacing, so "Tempered glass" typed twice two
/// ways is one row.
List<ItemSales> topSellers(
  Iterable<Sale> sales,
  DateRange range, {
  int limit = 10,
}) {
  final rows = <String, (String, num, int)>{};
  for (final sale in sales) {
    if (!sale.completed || !range.contains(sale.completedAt)) continue;
    for (final item in sale.items) {
      final name = item.description.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final (shown, amount, qty) = rows[key] ?? (name, 0, 0);
      rows[key] = (shown, amount + item.total, qty + item.effectiveQuantity);
    }
  }
  final list = [
    for (final (shown, amount, qty) in rows.values)
      ItemSales(shown, amount, qty),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return list.take(limit).toList();
}

/// HOW IT WAS PAID
///
/// What closing up needs: the drawer is counted against Cash, the bank app
/// against UPI and Card. The report only ever had the total, so a drawer ₹500
/// short could not be told apart from a bill paid by UPI.
///
/// Completed bills in [range], by the method on the bill:
///
/// - **collected** is what came in by that method — what was paid at the
///   counter. A **financed** bill counts its total (less wallet) under the
///   finance company: the customer owes nothing, the financier pays the shop,
///   and none of it is in the drawer, which the screen says.
/// - **wallet** is store credit used on bills, which is no new money at all.
/// - **owed** is what customers still owe on these bills.
class MethodTotal {
  const MethodTotal(this.method, this.collected, this.bills);

  final String method;
  final num collected;
  final int bills;
}

class PaymentSplit {
  const PaymentSplit({
    required this.methods,
    required this.wallet,
    required this.owed,
  });

  /// Most money first.
  final List<MethodTotal> methods;
  final num wallet;
  final num owed;

  bool get isEmpty => methods.isEmpty && wallet == 0 && owed == 0;
}

PaymentSplit paymentSplit(Iterable<Sale> sales, DateRange range) {
  final totals = <String, (num, int)>{};
  num wallet = 0;
  num owed = 0;
  for (final sale in sales) {
    if (!sale.completed || !range.contains(sale.completedAt)) continue;
    final method = sale.paymentMethod.trim().isEmpty
        ? 'Cash'
        : sale.paymentMethod.trim();
    final collected = isFinanceMethod(method)
        ? sale.total - sale.walletUsed
        : sale.amountPaid;
    final (amount, bills) = totals[method] ?? (0, 0);
    totals[method] = (amount + (collected < 0 ? 0 : collected), bills + 1);
    wallet += sale.walletUsed;
    owed += sale.balanceDue;
  }
  final methods = [
    for (final e in totals.entries) MethodTotal(e.key, e.value.$1, e.value.$2),
  ]..sort((a, b) => b.collected.compareTo(a.collected));
  return PaymentSplit(methods: methods, wallet: wallet, owed: owed);
}
