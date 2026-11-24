/// WHAT THE SHOP DID, OVER A PERIOD
///
/// Four figures the owner actually acts on — what came in over the counter,
/// what the repair bench earned, what the second-hand cabinet made, and what
/// is still owed — plus the activity behind them.
///
/// **Nothing here is added up for you, and that is deliberate.** Takings and
/// handset margin overlap: a phone sold for ₹24,000 on a bill is ₹24,000 of
/// takings AND, separately, ₹5,000 of margin on that handset. Adding the two
/// into a "total" would count the same sale twice, which is exactly what the
/// shop's old spreadsheet did — and it made every month look better than it
/// was. So each figure is reported as itself, with what it measures written
/// next to it.
///
/// **A period is dated on when the money moved, not when the record was
/// made.** A bill started on the 30th and settled on the 1st belongs to the
/// new month: that is the day the cash was taken. Same for a repair — the day
/// it went back to the customer, not the day it came in.
///
/// **Only finished things count.** A draft bill is not takings, a quote is not
/// service revenue, and a handset still in the cabinet has made nothing. The
/// shop's old report counted estimates, so a month looked profitable before
/// any of the work had been done.
///
/// **Outstanding is a position, not a flow.** It is what is owed right now,
/// across every unpaid bill, whenever those bills were written — so it does
/// not change when you change the period, and it is reported apart from the
/// figures that do.
library;

import '../common/dates.dart';
import '../customers/customer.dart';
import '../inventory/second_hand_device.dart';
import '../sales/due_payments.dart';
import '../sales/sale.dart';
import '../service/service_order.dart';

/// One figure, with what it measures.
class ReportFigure {
  const ReportFigure({
    required this.label,
    required this.amount,
    required this.note,
    this.count = 0,
  });

  final String label;

  /// Rupees.
  final num amount;

  /// What it is counted from, said plainly. This is shown, not stored as a
  /// comment: a figure whose basis is not on the page gets argued about.
  final String note;

  /// How many records are behind it — bills, jobs, handsets.
  final int count;
}

/// The period's whole picture.
class ShopReport {
  const ShopReport({
    required this.range,
    required this.takings,
    required this.serviceRevenue,
    required this.handsetMargin,
    required this.outstanding,
    required this.billsCompleted,
    required this.billsCancelled,
    required this.jobsTakenIn,
    required this.jobsCompleted,
    required this.handsetsBought,
    required this.handsetsSold,
    required this.customersAdded,
    required this.handsetCost,
    required this.handsetRevenue,
  });

  final DateRange range;

  /// Completed bills in the period. The counter's own figure.
  final num takings;

  /// Repairs that went back to the customer in the period, at the price
  /// charged.
  final num serviceRevenue;

  /// What the second-hand cabinet made on what it sold: sale price less
  /// everything each handset cost, repairs included.
  final num handsetMargin;

  /// Owed right now, across every unpaid bill. See the library note.
  final num outstanding;

  final int billsCompleted;
  final int billsCancelled;
  final int jobsTakenIn;
  final int jobsCompleted;
  final int handsetsBought;
  final int handsetsSold;
  final int customersAdded;

  /// The two halves of [handsetMargin], so the margin can be checked rather
  /// than taken on faith.
  final num handsetCost;
  final num handsetRevenue;

  /// Whether anything at all happened in the period.
  bool get isEmpty =>
      billsCompleted == 0 &&
      jobsTakenIn == 0 &&
      jobsCompleted == 0 &&
      handsetsBought == 0 &&
      handsetsSold == 0 &&
      customersAdded == 0;

  /// The money figures, in the order they are read. Never summed — see the
  /// library note.
  List<ReportFigure> get figures => [
    ReportFigure(
      label: 'Takings',
      amount: takings,
      note: 'Completed bills, on the day they were completed — paid or still owed',
      count: billsCompleted,
    ),
    ReportFigure(
      label: 'Service revenue',
      amount: serviceRevenue,
      note: 'Jobs that went back to the customer, at the price charged',
      count: jobsCompleted,
    ),
    ReportFigure(
      label: 'Second-hand margin',
      amount: handsetMargin,
      note:
          'Sale price less purchase, repairs and other costs. '
          'Part of takings, not on top of it',
      count: handsetsSold,
    ),
    ReportFigure(
      label: 'Outstanding',
      amount: outstanding,
      note:
          'Owed right now, across all unpaid bills — not just this '
          'period. Financed sales are not counted',
    ),
  ];
}

/// Build the report for [range].
///
/// Everything is filtered here rather than by the caller, so the page cannot
/// quietly use a different idea of "in the period" from the figures.
ShopReport buildReport({
  required DateRange range,
  required Iterable<Sale> sales,
  required Iterable<ServiceOrder> orders,
  required Iterable<SecondHandDevice> stock,
  required Iterable<Customer> customers,
}) {
  // Completed, not cancelled, dated on when it was settled.
  final settled = [
    for (final sale in sales)
      if (sale.completed && range.contains(sale.completedAt)) sale,
  ];

  final cancelled = [
    for (final sale in sales)
      if (sale.cancelled && range.contains(sale.updatedAt)) sale,
  ];

  // A job earns on the day it goes back, and only if it was charged. An open
  // order's estimate is a quote.
  final finished = [
    for (final order in orders)
      if (order.closed &&
          order.finalPrice != null &&
          range.contains(order.completedAt))
        order,
  ];

  final takenIn = [
    for (final order in orders)
      if (range.contains(order.receivedAt ?? order.createdAt)) order,
  ];

  final bought = [
    for (final device in stock)
      if (range.contains(device.purchasedAt ?? device.createdAt)) device,
  ];

  // Sold in the period, whenever it was bought. A handset bought in March and
  // sold in April made its money in April.
  final sold = [
    for (final device in stock)
      if (device.isSold && range.contains(device.soldAt)) device,
  ];

  var handsetRevenue = 0 as num;
  var handsetCost = 0 as num;
  for (final device in sold) {
    final costing = device.costing;
    handsetRevenue += costing.soldPrice ?? 0;
    handsetCost += costing.totalCost;
  }

  return ShopReport(
    range: range,
    takings: settled.fold<num>(0, (sum, s) => sum + s.total),
    serviceRevenue: finished.fold<num>(0, (sum, o) => sum + o.finalPrice!),
    handsetMargin: handsetRevenue - handsetCost,
    handsetRevenue: handsetRevenue,
    handsetCost: handsetCost,
    // Deliberately unfiltered: a position, not a flow.
    outstanding: totalOutstanding(sales),
    billsCompleted: settled.length,
    billsCancelled: cancelled.length,
    jobsTakenIn: takenIn.length,
    jobsCompleted: finished.length,
    handsetsBought: bought.length,
    handsetsSold: sold.length,
    customersAdded: [
      for (final customer in customers)
        if (range.contains(customer.createdAt)) customer,
    ].length,
  );
}

/// The periods the page offers, so "this month" means the same thing every
/// time somebody opens it.
enum ReportPeriod { today, sevenDays, thirtyDays, thisMonth, custom }

const Map<ReportPeriod, String> kReportPeriodLabels = {
  ReportPeriod.today: 'Today',
  ReportPeriod.sevenDays: 'Last 7 days',
  ReportPeriod.thirtyDays: 'Last 30 days',
  ReportPeriod.thisMonth: 'This month',
  ReportPeriod.custom: 'Custom',
};

/// The range a period means on [day]. [custom] is what a hand-picked range
/// falls back to, and is ignored by every other period.
DateRange rangeFor(ReportPeriod period, DateTime day, {DateRange? custom}) =>
    switch (period) {
      ReportPeriod.today => DateRange.day(day),
      ReportPeriod.sevenDays => DateRange.lastDays(7, ending: day),
      ReportPeriod.thirtyDays => DateRange.lastDays(30, ending: day),
      ReportPeriod.thisMonth => DateRange.month(day),
      ReportPeriod.custom => custom ?? DateRange.day(day),
    };
