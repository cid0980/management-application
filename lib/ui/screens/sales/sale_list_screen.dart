import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/sales_repository.dart';
import '../../../domain/sales/due_payments.dart';
import '../../../domain/sales/sale.dart';
import 'sale_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../../domain/common/money.dart';

import 'package:intl/intl.dart';

import '../../widgets/loading.dart';

/// BILLS RAISED AT THE COUNTER
///
/// Drafts sit at the top of their own tab rather than mixed in, because a
/// draft is not a sale: nothing has moved, and somebody has to either finish
/// it or throw it away.
class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key, this.initialTab});

  /// A [SaleStatus] name to open on, e.g. `draft` from the Pending Bills
  /// tile, or `all`.
  final String? initialTab;

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  late SaleStatus? _tab = _tabFrom(widget.initialTab);

  static SaleStatus? _tabFrom(String? name) => name == 'all'
      ? null
      : SaleStatus.values.firstWhere(
          (t) => t.name == name,
          orElse: () => SaleStatus.completed,
        );

  @override
  void didUpdateWidget(SaleListScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialTab != old.initialTab && widget.initialTab != null) {
      _tab = _tabFrom(widget.initialTab);
    }
  }

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SalesRepository>();
    final l10n = context.l10n;
    final c = context.shopColors;

    final all = repo.sales;
    final rows =
        [
          for (final s in all)
            if ((_tab == null || s.status == _tab) && s.matches(_query)) s,
        ]..sort((a, b) {
          final x = a.completedAt ?? a.updatedAt ?? a.createdAt;
          final y = b.completedAt ?? b.updatedAt ?? b.createdAt;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });

    final outstanding = totalOutstanding(all);
    int countOf(SaleStatus? t) => all
        .where((s) => t == null || s.status == t)
        .where((s) => s.matches(_query))
        .length;

    final Widget body;
    if (repo.error != null) {
      body = ErrorState(
        title: l10n.salesCouldNotBeLoaded,
        detail: repo.error!,
        onRetry: repo.load,
      );
    } else if (repo.loading && all.isEmpty) {
      body = LoadingWords(first: context.l10n.loadingBills);
    } else {
      body = FadeIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
          children: [
            ChipRow(
              key: const Key('sales-tabs'),
              children: [
                for (final (label, tab, colour)
                    in <(String, SaleStatus?, Color?)>[
                      (l10n.completedStatus, SaleStatus.completed, c.good),
                      (l10n.drafts, SaleStatus.draft, c.wait),
                      (l10n.cancelledStatus, SaleStatus.cancelled, c.done),
                      (l10n.all, null, null),
                    ])
                  CountChip(
                    label: label,
                    count: countOf(tab),
                    color: colour,
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
            if (outstanding > 0) ...[
              const SizedBox(height: 12),
              // Customers only. A financed sale is never counted here: the
              // customer owes nothing.
              Card(
                color: c.stopSoft,
                child: ListTile(
                  leading: Icon(Icons.currency_rupee, color: c.stop),
                  title: Text(
                    l10n.owedByCustomersShort(formatIndianNumber(outstanding)),
                    style: TextStyle(
                      color: c.stop,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => context.go('/due-payments'),
                    child: Text(l10n.navDuePayments),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (rows.isEmpty)
              EmptyState(
                icon: _query.isEmpty
                    ? Icons.receipt_long_outlined
                    : Icons.search_off,
                title: _query.isEmpty
                    ? l10n.noBillsHereYet
                    : l10n.noMatchFor(_query),
              )
            else
              for (final (i, sale) in rows.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                _SaleRow(sale: sale),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavySearchBlock(
            fieldKey: const Key('sale-search'),
            hint: l10n.searchSales,
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('sales-new'),
        heroTag: 'sale-new',
        onPressed: () => openSaleSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSale),
      ),
    );
  }
}

/// One bill as a card: its number and state, what was sold, who to, how it
/// was paid; on the right the total and the day.
class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final c = context.shopColors;
    final (String status, Color fg, Color soft) = switch (sale.status) {
      SaleStatus.draft => (l10n.draftStatus, c.wait, c.waitSoft),
      SaleStatus.completed => (l10n.doneStatus, c.good, c.goodSoft),
      SaleStatus.cancelled => (l10n.cancelledStatus, c.done, c.doneSoft),
    };
    final when = sale.completedAt ?? sale.updatedAt ?? sale.createdAt;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: 14,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/sales/${sale.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (sale.invoiceNumber.isNotEmpty)
                          Text(
                            sale.invoiceNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        StatusPill(status, color: fg, soft: soft),
                        if (sale.pendingCompletion)
                          StatusPill(
                            l10n.pendingInternet,
                            color: c.wait,
                            soft: c.waitSoft,
                            icon: Icons.cloud_off,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sale.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (sale.customerName.isNotEmpty) sale.customerName,
                        context.l10n.itemsCount(sale.totals.lineCount),
                        sale.paymentMethod,
                      ].join(' · '),
                      style: secondary,
                    ),
                    Text(
                      sale.isFinanced
                          // Fully paid as far as the customer is concerned.
                          ? l10n.financedOwesNothing(
                              formatIndianNumber(sale.total),
                            )
                          : sale.balanceDue > 0
                          ? l10n.totalStillOwed(
                              formatIndianNumber(sale.total),
                              formatIndianNumber(sale.balanceDue),
                            )
                          : l10n.totalPaid(formatIndianNumber(sale.total)),
                      style: secondary?.copyWith(
                        color: sale.balanceDue > 0 ? c.stop : null,
                        fontWeight: sale.balanceDue > 0
                            ? FontWeight.w700
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupees(sale.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (when != null)
                    Text(
                      DateFormat.MMMd().format(when),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
