import 'package:flutter/material.dart';

import '../../../domain/common/money.dart';
import '../../../domain/expenses/expense.dart';
import '../../../domain/reports/sales_breakdown.dart';
import '../../../domain/reports/shop_report.dart';
import '../../../domain/sales/payment_methods.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/forest.dart';
import '../../widgets/fact_icons.dart';
import '../../widgets/input_sheet.dart';
import '../expenses/expense_labels.dart';

/// THE REPORTS PAGE, READ AT A GLANCE
///
/// The period's takings first and big (the dark card, as on Home), the
/// other money figures as tiles under it, then the shape of the period as a
/// column chart, how customers paid as one split bar, the activity as icon
/// tiles, what sold best and the money out as ranked bars. Words only where
/// a figure needs naming; what each figure measures is one tap away (the
/// info button), not printed under every number.

/// The colours of the ways of paying, by method — never by rank, so UPI is
/// the same green in every period. Checked with the palette validator on
/// white (light-band, chroma, colour-blind separation; every segment is
/// named beside it, so no colour stands alone).
Color methodColour(String method) => switch (method.toLowerCase()) {
  'upi' => const Color(0xFF1F7A4C),
  'cash' => const Color(0xFFEBA524),
  'card' => const Color(0xFF3A66C4),
  _ => const Color(0xFFB04E9E),
};

/// A white card with an icon and a title, the same for every section.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FactIcon(icon, meaning: title, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// The takings, big, on the dark card; the other money figures as tiles.
class ReportHeadline extends StatelessWidget {
  const ReportHeadline({super.key, required this.report});

  final ShopReport report;

  static IconData _iconFor(String label) => switch (label) {
    'Takings' => Icons.receipt_long_outlined,
    'Service revenue' => Icons.build_outlined,
    'Second-hand margin' => Icons.smartphone,
    'Outstanding' => Icons.hourglass_bottom,
    _ => Icons.currency_rupee,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final figures = report.figures;
    final lead = figures.first;
    final rest = figures.skip(1).toList();
    final (leadTitle, _) = reportFigureText(context, lead.label, lead.note);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('report-headline'),
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 18),
          decoration: BoxDecoration(
            color: Forest.forest900,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(lead.label), color: Forest.lime, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leadTitle,
                      style: const TextStyle(
                        color: Forest.onForestMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('report-explain'),
                    tooltip: l10n.reportWhatTheyMean,
                    icon: const Icon(
                      Icons.info_outline,
                      color: Forest.onForestMuted,
                    ),
                    onPressed: () => _explain(context, figures),
                  ),
                ],
              ),
              Text(
                rupees(lead.amount),
                style: const TextStyle(
                  color: Forest.onForest,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (lead.count > 0) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.fromRecords(lead.count),
                  style: const TextStyle(color: Forest.onForestMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, f) in rest.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _FigureTile(figure: f, icon: _iconFor(f.label)),
              ),
            ],
          ],
        ),
        if (report.handsetsSold > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.smartphone,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.reportPhonesSoldFor(
                      rupees(report.handsetRevenue),
                      rupees(report.handsetCost),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static void _explain(BuildContext context, List<ReportFigure> figures) {
    showInputSheet<void>(
      context: context,
      builder: (sheet) => InputSheet(
        title: Text(sheet.l10n.reportWhatTheyMean),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in figures)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FactIcon(_iconFor(f.label), meaning: f.label, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportFigureText(sheet, f.label, f.note).$1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(reportFigureText(sheet, f.label, f.note).$2),
                        ],
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

class _FigureTile extends StatelessWidget {
  const _FigureTile({required this.figure, required this.icon});

  final ReportFigure figure;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, _) = reportFigureText(context, figure.label, figure.note);
    final bad =
        figure.amount < 0 ||
        (figure.label == 'Outstanding' && figure.amount > 0);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FactIcon(icon, meaning: title, size: 30),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rupees(figure.amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: bad ? theme.colorScheme.error : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Takings by day as columns; a long period by week. One tap on a column
/// names its day and amount above the chart; the best day is picked to
/// start with.
class TakingsChart extends StatefulWidget {
  const TakingsChart({super.key, required this.days});

  final List<DayTakings> days;

  @override
  State<TakingsChart> createState() => _TakingsChartState();
}

class _TakingsChartState extends State<TakingsChart> {
  int? _picked;

  /// Days, or weeks once there are too many days for a column each.
  List<DayTakings> get _bars {
    final days = widget.days;
    if (days.length <= 45) return days;
    final weeks = <DayTakings>[];
    for (var i = 0; i < days.length; i += 7) {
      final chunk = days.skip(i).take(7);
      weeks.add(
        DayTakings(
          chunk.first.day,
          chunk.fold<num>(0, (t, d) => t + d.amount),
          chunk.fold<int>(0, (t, d) => t + d.bills),
        ),
      );
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bars = _bars;
    final weekly = bars.length != widget.days.length;
    final top = bars.fold<num>(0, (m, d) => d.amount > m ? d.amount : m);
    if (top == 0) {
      return ReportCard(
        icon: Icons.bar_chart,
        title: l10n.reportDayByDay,
        child: Text(l10n.reportNoSales),
      );
    }
    final best = bars.indexWhere((d) => d.amount == top);
    final picked = _picked ?? best;
    String label(DateTime d) => '${d.day}/${d.month}';
    String name(DayTakings d) =>
        weekly ? l10n.reportWeekOf(label(d.day)) : label(d.day);
    final p = bars[picked];
    return ReportCard(
      icon: Icons.bar_chart,
      title: l10n.reportDayByDay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The column picked, said in words.
          Text(
            l10n.reportDayLine(
              name(p),
              rupees(p.amount),
              l10n.reportBillsCount(p.bills),
            ),
            key: const Key('report-day-picked'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            picked == best
                ? l10n.reportBestDay(name(p), rupees(top))
                : l10n.reportTapDay,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, box) {
                final slot = box.maxWidth / bars.length;
                return GestureDetector(
                  key: const Key('report-day-bars'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => setState(
                    () => _picked = (d.localPosition.dx / slot).floor().clamp(
                      0,
                      bars.length - 1,
                    ),
                  ),
                  child: CustomPaint(
                    size: Size(box.maxWidth, 150),
                    painter: _ColumnsPainter(
                      values: [for (final d in bars) d.amount.toDouble()],
                      top: top.toDouble(),
                      picked: picked,
                      ink: Forest.forest900,
                      quiet: AppTheme.border,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // First, middle and last dates under the columns.
          Row(
            children: [
              Text(label(bars.first.day), style: theme.textTheme.bodySmall),
              const Spacer(),
              if (bars.length > 2)
                Text(
                  label(bars[bars.length ~/ 2].day),
                  style: theme.textTheme.bodySmall,
                ),
              const Spacer(),
              Text(label(bars.last.day), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnsPainter extends CustomPainter {
  _ColumnsPainter({
    required this.values,
    required this.top,
    required this.picked,
    required this.ink,
    required this.quiet,
  });

  final List<double> values;
  final double top;
  final int picked;
  final Color ink;
  final Color quiet;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final slot = size.width / n;
    // Thin columns with a gap between, never wider than 22.
    final w = (slot - (slot > 8 ? 3 : 1.5)).clamp(1.5, 22.0);
    final base = size.height - 1;
    final line = Paint()
      ..color = quiet
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, base + 0.5),
      Offset(size.width, base + 0.5),
      line,
    );
    for (var i = 0; i < n; i++) {
      final x = i * slot + (slot - w) / 2;
      final v = values[i];
      if (v <= 0) {
        // A quiet day: a dot on the baseline, not a missing column.
        canvas.drawCircle(
          Offset(x + w / 2, base - 2),
          1.6,
          Paint()..color = quiet,
        );
        continue;
      }
      final h = (v / top * (size.height - 6)).clamp(3.0, size.height - 6);
      final paint = Paint()
        ..color = i == picked ? ink : ink.withValues(alpha: 0.32);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, base - h, w, h),
          topLeft: Radius.circular(w.clamp(1, 4)),
          topRight: Radius.circular(w.clamp(1, 4)),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ColumnsPainter old) =>
      old.values != values || old.picked != picked || old.top != top;
}

/// How customers paid: one bar split by method, each named with its
/// amount underneath; what is still owed and wallet credit after.
class HowPaidCard extends StatelessWidget {
  const HowPaidCard({super.key, required this.split});

  final PaymentSplit split;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = split.methods.fold<num>(0, (t, m) => t + m.collected);
    final anyFinance = split.methods.any((m) => isFinanceMethod(m.method));
    return ReportCard(
      key: const Key('report-how-paid'),
      icon: Icons.payments_outlined,
      title: l10n.reportHowPaid,
      child: split.isEmpty
          ? Text(l10n.reportNoSales)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          for (final (i, m) in split.methods.indexed)
                            if (m.collected > 0) ...[
                              if (i > 0) const SizedBox(width: 2),
                              Expanded(
                                flex: (m.collected / total * 1000)
                                    .round()
                                    .clamp(1, 1000),
                                child: ColoredBox(
                                  color: methodColour(m.method),
                                  // A box with no child takes no height.
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                for (final m in split.methods)
                  _LegendRow(
                    swatch: methodColour(m.method),
                    name: m.method,
                    detail: l10n.reportBillsCount(m.bills),
                    amount: rupees(m.collected),
                  ),
                if (split.wallet > 0)
                  _LegendRow(
                    icon: Icons.account_balance_wallet_outlined,
                    name: l10n.reportWalletUsed,
                    amount: rupees(split.wallet),
                  ),
                if (split.owed > 0)
                  _LegendRow(
                    icon: Icons.hourglass_bottom,
                    name: l10n.reportStillOwed,
                    amount: rupees(split.owed),
                    bad: true,
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
            ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    this.swatch,
    this.icon,
    required this.name,
    this.detail,
    required this.amount,
    this.bad = false,
  });

  final Color? swatch;
  final IconData? icon;
  final String name;
  final String? detail;
  final String amount;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: swatch != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )
                : Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  if (detail != null)
                    TextSpan(
                      text: '  $detail',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: bad ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The period's counts as icon tiles, three to a row.
class ActivityGrid extends StatelessWidget {
  const ActivityGrid({super.key, required this.report});

  final ShopReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(IconData, String, int)>[
      (Icons.receipt_long_outlined, l10n.billsCompleted, report.billsCompleted),
      (Icons.receipt_outlined, l10n.billsCancelled, report.billsCancelled),
      (Icons.move_to_inbox_outlined, l10n.jobsTakenIn, report.jobsTakenIn),
      (Icons.outbox_outlined, l10n.jobsCompleted, report.jobsCompleted),
      (Icons.add_shopping_cart, l10n.handsetsBought, report.handsetsBought),
      (Icons.sell_outlined, l10n.handsetsSold, report.handsetsSold),
      (Icons.person_add_alt, l10n.customersAdded, report.customersAdded),
    ];
    return ReportCard(
      icon: Icons.insights_outlined,
      title: l10n.activity,
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 8.0;
          final w = (box.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (icon, label, n) in items)
                SizedBox(
                  width: w,
                  child: _ActivityTile(icon: icon, label: label, value: n),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = value == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Forest.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: quiet ? AppTheme.border : theme.colorScheme.primary,
              ),
              const Spacer(),
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: quiet ? AppTheme.textSecondary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// A name and amount on one line, a thin bar under it showing its share of
/// the largest: what sold best, what the money went on.
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.rows});

  final List<RankedRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = rows.fold<num>(0, (m, r) => r.amount > m ? r.amount : m);
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                if (r.icon != null) ...[
                  Icon(r.icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                ] else if (r.rank != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r.rank == 1 ? Forest.lime : Forest.canvas,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${r.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Forest.ink900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  if (r.detail != null)
                                    TextSpan(
                                      text: '  ${r.detail}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rupees(r.amount),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: top <= 0 ? 0 : r.amount / top,
                          minHeight: 5,
                          backgroundColor: Forest.canvas,
                          color: Forest.forest900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RankedRow {
  const RankedRow({
    required this.name,
    required this.amount,
    this.detail,
    this.icon,
    this.rank,
  });

  final String name;
  final num amount;
  final String? detail;
  final IconData? icon;
  final int? rank;
}

/// Money out by kind, then what is left: two tiles, the cash that should
/// be in the drawer the one to check at closing.
class MoneyOutCard extends StatelessWidget {
  const MoneyOutCard({
    super.key,
    required this.spent,
    required this.cashIn,
    required this.allIn,
  });

  final ExpenseSummary spent;
  final num cashIn;
  final num allIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final left = cashIn - spent.cash;
    return ReportCard(
      key: const Key('report-money-out'),
      icon: Icons.outbox_outlined,
      title: l10n.reportMoneyOut,
      trailing: Text(
        rupees(spent.total),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (spent.isEmpty)
            Text(l10n.reportMoneyOutNone)
          else
            RankedBars(
              rows: [
                for (final (kind, amount) in spent.byKind)
                  RankedRow(
                    name: expenseKindLabel(l10n, kind),
                    amount: amount,
                    icon: expenseKindIcon(kind),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeftTile(
                  key: const Key('report-after-expenses'),
                  icon: Icons.account_balance_outlined,
                  label: l10n.reportAfterExpenses,
                  amount: allIn - spent.total,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LeftTile(
                  key: const Key('report-cash-left'),
                  icon: Icons.point_of_sale_outlined,
                  label: l10n.reportCashLeft,
                  hint: l10n.reportCashLeftHint,
                  amount: left,
                  strong: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeftTile extends StatelessWidget {
  const _LeftTile({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    this.hint,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final num amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final negative = amount < 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: strong ? Forest.forest900 : Forest.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: strong ? Forest.lime : theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupees(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: negative
                    ? (strong
                          ? const Color(0xFFFCA5A5)
                          : theme.colorScheme.error)
                    : (strong ? Forest.onForest : Forest.ink900),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: strong ? Forest.onForestMuted : AppTheme.textSecondary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: strong ? Forest.onForestMuted : AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
