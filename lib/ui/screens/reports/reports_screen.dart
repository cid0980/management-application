import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/common/dates.dart';
import '../../../domain/common/money.dart';
import '../../../domain/reports/shop_report.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/reports/sales_breakdown.dart';
import '../../../domain/sales/payment_methods.dart';
import '../../../l10n/display_labels.dart';
import '../../../data/printing/documents.dart';
import '../../printing/print_sheet.dart';

/// REPORTS
///
/// Four figures and the activity behind them, over a period the owner picks.
///
/// **There is no total on this page, and there will not be one.** Takings and
/// second-hand margin overlap — a handset sold for ₹24,000 is both — so a
/// total would count that sale twice. Each figure carries the sentence saying
/// what it is counted from, right under it, because a number whose basis is
/// not on the page is a number that gets argued about.
///
/// **Nothing here is computed in this file.** `buildReport` decides what falls
/// in a period and what counts; this draws the answer. That is what lets the
/// rules be tested without a widget.
///
/// A period that cannot be read is not a report of zeroes: if an area failed
/// to load, the page says so above the figures rather than quietly reporting a
/// month in which the shop apparently did nothing.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateRange? _custom;

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesRepository>();
    final orders = context.watch<ServiceRepository>();
    final stock = context.watch<SecondHandRepository>();
    final customers = context.watch<CustomerRepository>();

    final theme = Theme.of(context);
    final now = DateTime.now();
    final range = rangeFor(_period, now, custom: _custom);

    final report = buildReport(
      range: range,
      sales: sales.sales,
      orders: orders.orders,
      stock: stock.devices,
      customers: customers.customers,
    );

    // Named so the warning says which figures are short, rather than a vague
    // "some data could not be loaded".
    final unreadable = <String>[
      if (sales.error != null) context.l10n.areaSales,
      if (orders.error != null) context.l10n.areaServiceOrders,
      if (stock.error != null) context.l10n.areaSecondHandStock,
      if (customers.error != null) context.l10n.areaCustomers,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final period in ReportPeriod.values)
              ChoiceChip(
                label: Text(reportPeriodLabel(context, period)),
                selected: _period == period,
                onSelected: (_) => period == ReportPeriod.custom
                    ? _pickCustom(context, now)
                    : setState(() => _period = period),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(_rangeLabel(range), style: theme.textTheme.bodySmall),
            ),
            // The closing summary, as a PDF to print or send on WhatsApp.
            TextButton.icon(
              key: const Key('share-report'),
              icon: const Icon(Icons.ios_share),
              label: Text(context.l10n.shareReport),
              onPressed: () => showPrintSheet(
                context,
                title: context.l10n.shareReport,
                fileName: 'report-${_rangeLabel(range)}'.replaceAll(
                  RegExp(r'[^A-Za-z0-9-]+'),
                  '-',
                ),
                build: (shop, _) => buildShopReportPdf(
                  shop: shop,
                  rangeLabel: _rangeLabel(range),
                  report: report,
                  split: paymentSplit(
                    sales.sales,
                    range,
                    orders: orders.orders,
                  ),
                  topSellers: topSellers(sales.sales, range),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (unreadable.isNotEmpty) ...[
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.figuresAreShort(unreadable.join(', ')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        for (final figure in report.figures) _FigureCard(figure: figure),

        const SizedBox(height: 16),
        Text(context.l10n.activity, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _ActivityRow(
                label: context.l10n.billsCompleted,
                value: report.billsCompleted,
              ),
              _ActivityRow(
                label: context.l10n.billsCancelled,
                value: report.billsCancelled,
              ),
              _ActivityRow(
                label: context.l10n.jobsTakenIn,
                value: report.jobsTakenIn,
              ),
              _ActivityRow(
                label: context.l10n.jobsCompleted,
                value: report.jobsCompleted,
              ),
              _ActivityRow(
                label: context.l10n.handsetsBought,
                value: report.handsetsBought,
              ),
              _ActivityRow(
                label: context.l10n.handsetsSold,
                value: report.handsetsSold,
              ),
              _ActivityRow(
                label: context.l10n.customersAdded,
                value: report.customersAdded,
                last: true,
              ),
            ],
          ),
        ),

        if (report.handsetsSold > 0) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.howMarginMadeUp,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // Both halves, so the margin can be checked rather than
                  // taken on faith.
                  Text(context.l10n.soldForAmount('${report.handsetRevenue}')),
                  Text(
                    context.l10n.costPurchaseRepairs('${report.handsetCost}'),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        _DayByDay(days: dailyTakings(sales.sales, range)),
        const SizedBox(height: 16),
        _WhatSold(rows: topSellers(sales.sales, range)),
        const SizedBox(height: 16),
        _HowPaid(
          split: paymentSplit(sales.sales, range, orders: orders.orders),
        ),

        if (report.isEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              context.l10n.nothingHappened,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickCustom(BuildContext context, DateTime now) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _custom == null
          ? null
          : DateTimeRange(start: _custom!.start, end: _custom!.end),
    );
    if (picked == null) return;
    setState(() {
      _custom = DateRange(picked.start, picked.end);
      _period = ReportPeriod.custom;
    });
  }

  String _rangeLabel(DateRange range) {
    String day(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    return range.isOneDay
        ? day(range.start)
        : '${day(range.start)} – ${day(range.end)} · ${range.days} days';
  }
}

/// Ported from the French Mobiles Flutter port: one bar per day, so the shape
/// of the period is visible at a glance.
class _DayByDay extends StatelessWidget {
  const _DayByDay({required this.days});

  final List<DayTakings> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final biggest = days.fold<num>(0, (m, d) => d.amount > m ? d.amount : m);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.reportDayByDay, style: theme.textTheme.titleMedium),
              ],
            ),
            Text(l10n.reportDayByDayHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (biggest == 0)
              Text(l10n.reportNoSales)
            else
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${d.day.day}/${d.day.month}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: d.amount / biggest,
                            minHeight: 14,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 84,
                        child: Text(
                          d.amount == 0 ? '-' : rupees(d.amount),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _WhatSold extends StatelessWidget {
  const _WhatSold({required this.rows});

  final List<ItemSales> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.reportWhatSold, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(l10n.reportNoSales)
            else
              for (final (i, r) in rows.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text('${i + 1}', style: theme.textTheme.labelLarge),
                  ),
                  title: Text(r.description),
                  subtitle: Text(l10n.reportSoldCount('${r.quantity}')),
                  trailing: Text(
                    rupees(r.amount),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.figure});

  final ReportFigure figure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final negative = figure.amount < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reportFigureText(context, figure.label, figure.note).$1,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  rupees(figure.amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    // A loss is shown as a loss. Hiding the sign is how a bad
                    // month reads like a flat one.
                    color: negative ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reportFigureText(context, figure.label, figure.note).$2,
              style: theme.textTheme.bodySmall,
            ),
            if (figure.count > 0) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.fromRecords('${figure.count}'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final int value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(label),
          trailing: Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}

class _HowPaid extends StatelessWidget {
  const _HowPaid({required this.split});

  final PaymentSplit split;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final anyFinance = split.methods.any((m) => isFinanceMethod(m.method));
    return Card(
      key: const Key('report-how-paid'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.reportHowPaid, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (split.isEmpty)
              Text(l10n.reportNoSales)
            else ...[
              for (final m in split.methods)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(m.method),
                  subtitle: Text(l10n.reportBillsCount(m.bills)),
                  trailing: Text(
                    rupees(m.collected),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              if (split.wallet > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.reportWalletUsed),
                  trailing: Text(rupees(split.wallet)),
                ),
              if (split.owed > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.reportStillOwed),
                  trailing: Text(
                    rupees(split.owed),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              if (anyFinance)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.reportFinanceNote,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
