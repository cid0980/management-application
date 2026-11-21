import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/sales_repository.dart';
import '../../../domain/sales/due_payments.dart';
import '../../../domain/sales/sale.dart';
import 'sale_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/fading_scroll.dart';
import '../../widgets/empty_state.dart';

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

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.salesCouldNotBeLoaded),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: repo.load,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

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

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('sale-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchSales,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Scrolls sideways, like every other tab strip in the app: four
          // labels with counts do not fit across a phone.
          FadingScroll(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final entry in <(String, SaleStatus?)>[
                  (context.l10n.completedStatus, SaleStatus.completed),
                  (context.l10n.drafts, SaleStatus.draft),
                  (context.l10n.cancelledStatus, SaleStatus.cancelled),
                  (context.l10n.all, null),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _tab == entry.$2,
                      label: Text(
                        '${entry.$1} '
                        '${all.where((s) => entry.$2 == null || s.status == entry.$2).where((s) => s.matches(_query)).length}',
                      ),
                      onSelected: (_) => setState(() => _tab = entry.$2),
                    ),
                  ),
              ],
            ),
          ),
          if (outstanding > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // Customers only. A financed sale is never counted here:
                      // the customer owes nothing.
                      context.l10n.owedByCustomersShort('$outstanding'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/due-payments'),
                    child: Text(context.l10n.navDuePayments),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    icon: _query.isEmpty
                        ? Icons.receipt_long_outlined
                        : Icons.search_off,
                    title: _query.isEmpty
                        ? context.l10n.noBillsHereYet
                        : context.l10n.noMatchFor(_query),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _SaleRow(sale: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sale-new',
        onPressed: () => openSaleSheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newSale),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => context.go('/sales/${sale.id}'),
      title: Text(sale.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (sale.customerName.isNotEmpty) sale.customerName,
              '${sale.totals.lineCount} item(s)',
              sale.paymentMethod,
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            sale.isFinanced
                // Fully paid as far as the customer is concerned.
                ? context.l10n.financedOwesNothing('${sale.total}')
                : sale.balanceDue > 0
                ? context.l10n.totalStillOwed(
                    '${sale.total}',
                    '${sale.balanceDue}',
                  )
                : context.l10n.totalPaid('${sale.total}'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: sale.balanceDue > 0 ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
      trailing: Text(switch (sale.status) {
        SaleStatus.draft => context.l10n.draftStatus,
        SaleStatus.completed => context.l10n.doneStatus,
        SaleStatus.cancelled => context.l10n.cancelledStatus,
      }, style: theme.textTheme.labelSmall),
      isThreeLine: true,
    );
  }
}
