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
