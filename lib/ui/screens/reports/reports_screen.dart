import '../../../data/firestore_errors.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/live_window.dart' show mergedById;
import '../../../domain/reports/seller_payments.dart';
import '../../../domain/sales/sale.dart';
import '../../../domain/service/service_order.dart';

import '../../../data/customer_repository.dart';
import '../../../data/expense_repository.dart';
import '../../../domain/expenses/expense.dart';
import '../../../data/sales_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../domain/inventory/second_hand_device.dart';
import '../../../data/service_repository.dart';
import '../../../domain/common/dates.dart';
import '../../../domain/reports/shop_report.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/shop_ui.dart';
import '../../../domain/reports/sales_breakdown.dart';
import '../../../l10n/display_labels.dart';
import '../../../data/printing/documents.dart';
import '../../printing/print_sheet.dart';
import '../../widgets/loading.dart';
import 'report_parts.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../../../domain/reports/export_csv.dart';
import '../../widgets/input_sheet.dart';

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
  const ReportsScreen({super.key, this.initialPeriod});

  /// The period to open on; this month unless said.
  final ReportPeriod? initialPeriod;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ReportPeriod _period = widget.initialPeriod == ReportPeriod.custom
      ? ReportPeriod.thisMonth
      : widget.initialPeriod ?? ReportPeriod.thisMonth;
  DateRange? _custom;

  /// Bills and jobs older than the live lists keep, fetched for a range
  /// that reaches back past them. Keyed by the range they were fetched for.
  List<Sale> _olderSales = const [];
  List<ServiceOrder> _olderOrders = const [];
  List<SecondHandDevice> _olderStock = const [];
  String? _olderFor;
  bool _fetchingOlder = false;

  void _fetchOlderFor(
    DateRange range,
    SalesRepository sales,
    ServiceRepository orders,
    SecondHandRepository stock,
  ) {
    final key = '${range.start}-${range.end}';
    if (_olderFor == key) return;
    _olderFor = key;
    _fetchingOlder = true;
    Future.wait([
          sales.fetchCompletedBetween(range.start, range.end),
          orders.fetchClosedBetween(range.start, range.end),
          stock.fetchActiveBetween(range.start, range.end),
        ])
        .then((r) {
          if (!mounted || _olderFor != key) return;
          setState(() {
            _olderSales = r[0] as List<Sale>;
            _olderOrders = r[1] as List<ServiceOrder>;
            _olderStock = r[2] as List<SecondHandDevice>;
            _fetchingOlder = false;
          });
        })
        .catchError((Object _) {
          if (mounted) setState(() => _fetchingOlder = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesRepository>();
    final orders = context.watch<ServiceRepository>();
    final stock = context.watch<SecondHandRepository>();
    final customers = context.watch<CustomerRepository>();

    final theme = Theme.of(context);
    final now = DateTime.now();
    final range = rangeFor(_period, now, custom: _custom);

    // A range reaching back past the live lists asks the server for the
    // rest, once; until it answers the figures are the recent ones.
    final since = [
      sales.liveSince,
      orders.liveSince,
      stock.liveSince,
    ].whereType<DateTime>();
    final reachesBack = since.any((s) => range.start.isBefore(s));
    if (reachesBack) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchOlderFor(range, sales, orders, stock);
      });
    }
    final allSales = reachesBack
        ? mergedById([sales.sales, _olderSales], (b) => b.id)
        : sales.sales;
    final allOrders = reachesBack
        ? mergedById([orders.orders, _olderOrders], (o) => o.id)
        : orders.orders;
    final allStock = reachesBack
        ? mergedById([stock.devices, _olderStock], (d) => d.id)
        : stock.devices;

    // Money out. Absent only in a test that never gave the screen one.
    final expenses = _expensesOf(context);
    final split = paymentSplit(allSales, range, orders: allOrders);

    final report = buildReport(
      range: range,
      sales: allSales,
      orders: allOrders,
      stock: allStock,
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
        // Older bills and jobs on their way from the server.
        if (_fetchingOlder) ...[
          const LinearProgressIndicator(),
          LoadingWords(first: context.l10n.loadingOlder, compact: true),
        ],
        ChoiceRow(
          key: const Key('report-periods'),
          values: ReportPeriod.values,
          selected: _period,
          labelOf: (period) => reportPeriodLabel(context, period),
          onPicked: (period) => period == ReportPeriod.custom
              ? _pickCustom(context, now)
              : setState(() => _period = period),
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
                  split: split,
                  topSellers: topSellers(allSales, range),
                  spent: summarizeExpenses(expenses, range),
                ),
              ),
            ),
            // The period's bills or repairs as a spreadsheet file.
            TextButton.icon(
              key: const Key('export-csv'),
              icon: const Icon(Icons.table_view_outlined),
              label: Text(context.l10n.exportCsv),
              onPressed: () => _export(
                context,
                range: range,
                sales: allSales,
                orders: allOrders,
                expenses: expenses,
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

        ReportHeadline(report: report),
        const SizedBox(height: 14),
        TakingsChart(days: dailyTakings(allSales, range)),
        HowPaidCard(split: split),
        ActivityGrid(report: report),
        ReportCard(
          icon: Icons.sell_outlined,
          title: context.l10n.reportWhatSold,
          child: Builder(
            builder: (context) {
              final rows = topSellers(allSales, range);
              if (rows.isEmpty) return Text(context.l10n.reportNoSales);
              return RankedBars(
                rows: [
                  for (final (i, r) in rows.indexed)
                    RankedRow(
                      rank: i + 1,
                      name: r.description,
                      detail: context.l10n.reportSoldCount('${r.quantity}'),
                      amount: r.amount,
                    ),
                ],
              );
            },
          ),
        ),
        MoneyOutCard(
          phones: sellerPaymentsIn(allStock, range),
          owedToSellers: allStock.fold<num>(0, (t, d) => t + d.owedToSeller),
          spent: summarizeExpenses(expenses, range),
          cashIn: split.methods
              .where((m) => m.method == 'Cash')
              .fold<num>(0, (t, m) => t + m.collected),
          allIn: split.methods.fold<num>(0, (t, m) => t + m.collected),
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
        : '${day(range.start)} – ${day(range.end)} · '
              '${context.l10n.daysCount(range.days)}';
  }
}

List<Expense> _expensesOf(BuildContext context) {
  try {
    return context.watch<ExpenseRepository>().expenses;
  } on ProviderNotFoundException {
    return const [];
  }
}

/// Export: pick bills or repairs; the phone's share sheet gets a CSV file.
Future<void> _export(
  BuildContext context, {
  required DateRange range,
  required Iterable<Sale> sales,
  required Iterable<ServiceOrder> orders,
  Iterable<Expense> expenses = const [],
}) async {
  final l10n = context.l10n;
  final which = await showInputSheet<String>(
    context: context,
    builder: (sheet) => PickSheet(
      title: Text(l10n.exportCsv),
      children: [
        ListTile(
          key: const Key('export-bills'),
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(l10n.exportBills),
          onTap: () => Navigator.of(sheet).pop('bills'),
        ),
        ListTile(
          key: const Key('export-repairs'),
          leading: const Icon(Icons.build_outlined),
          title: Text(l10n.exportRepairs),
          onTap: () => Navigator.of(sheet).pop('repairs'),
        ),
        ListTile(
          key: const Key('export-expenses'),
          leading: const Icon(Icons.payments_outlined),
          title: Text(l10n.exportExpenses),
          onTap: () => Navigator.of(sheet).pop('expenses'),
        ),
        ListTile(
          key: const Key('export-stock'),
          leading: const Icon(Icons.smartphone_outlined),
          title: Text(l10n.exportStock),
          onTap: () => Navigator.of(sheet).pop('stock'),
        ),
      ],
    ),
  );
  if (which == null || !context.mounted) return;
  final devices = context.read<SecondHandRepository>().devices;
  final to = range.end.add(const Duration(milliseconds: 1));
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  final csv = switch (which) {
    'bills' => billsCsv(sales, range.start, to),
    'repairs' => repairsCsv(orders, range.start, to),
    'expenses' => expensesCsv(expenses, range.start, to),
    _ => stockCsv(devices),
  };
  // Stock is as it is today; bills and repairs are for the period shown.
  final name = which == 'stock'
      ? 'phones-in-stock-${day(DateTime.now())}.csv'
      : '$which-${day(range.start)}-to-${day(range.end)}.csv';
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          // A BOM first, so Excel reads ₹ and Tamil names right.
          XFile.fromData(
            Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: [name],
        subject: name,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.exportFailed(plainError(e)))));
  }
}
