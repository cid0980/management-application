import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/empty_state.dart';
import '../../../data/sales_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/common/money.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/sales/due_payments.dart';
import '../../../domain/sales/sale.dart';
import 'sale_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../data/printing/documents.dart';
import '../../printing/print_sheet.dart';
import '../../../l10n/rule_messages.dart';

/// ONE BILL
///
/// Two things happen from here, and both are rules rather than buttons:
///
/// - **collecting a balance is admin only.** A staff member sees what is owed
///   and cannot take it; the button says so rather than being absent, because
///   "there is no way to do this" and "you may not do this" are different
///   answers to give someone standing at a counter with a customer.
/// - **a financed bill shows no balance at all**, because the customer owes
///   nothing. What the financier owes the shop is a different ledger.
class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SalesRepository>();
    final sale = repo.byId(id);

    if (sale == null) {
      if (repo.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return EmptyState(
        icon: Icons.search_off,
        title: context.l10n.noSale(id),
      );
    }

    final isAdmin = context.watch<AuthState>().isAdmin;
    final totals = sale.totals;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(sale.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [
              switch (sale.status) {
                SaleStatus.draft => context.l10n.draftNothingOffShelf,
                SaleStatus.completed => context.l10n.completedStatus,
                SaleStatus.cancelled => context.l10n.cancelledStatus,
              },
              sale.paymentMethod,
            ].join(' · '),
          ),
          _Block(context.l10n.customer, {
            context.l10n.name: sale.customerName.isEmpty
                ? context.l10n.noNameGiven
                : sale.customerName,
            context.l10n.shopPhone: formatPhone(sale.customerPhone),
          }),
          const SizedBox(height: 16),
          Text(
            context.l10n.items,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          for (final item in sale.items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.description),
              subtitle: Text(
                [
                  '₹${item.unitPrice} × ${item.effectiveQuantity}',
                  if (item.discount > 0) '− ₹${item.discount}',
                  // The IMEI is on the invoice because a warranty claim is made
                  // against it.
                  if ((item.imei ?? '').isNotEmpty) 'IMEI ${item.imei}',
                ].join(' · '),
              ),
              trailing: Text(rupees(item.total)),
            ),
          _Block(context.l10n.bill, {
            context.l10n.gross: rupees(totals.gross),
            context.l10n.discount: rupees(totals.discount),
            context.l10n.total: rupees(totals.total),
            context.l10n.paid: rupees(sale.amountPaid),
            if (sale.walletUsed > 0)
              context.l10n.fromTheWallet: rupees(sale.walletUsed),
            // Financed sales show this plainly rather than a balance: the
            // customer owes nothing, and they must never reach Due Payments.
            if (sale.isFinanced)
              context.l10n.customerOwes: context.l10n.nothingFinancedThrough(
                sale.paymentMethod,
              )
            else
              context.l10n.balance: rupees(sale.balanceDue),
          }),
          // Each later payment with its day and method — what was collected
          // after the bill, and how.
          if (sale.collections.isNotEmpty)
            _Block(context.l10n.collectedLaterTitle, {
              for (final c in sale.collections)
                c.at == null
                        ? c.method
                        : '${c.at!.day.toString().padLeft(2, '0')}/'
                              '${c.at!.month.toString().padLeft(2, '0')}/'
                              '${c.at!.year} · ${c.method}':
                    rupees(c.amount),
            }),
          if (sale.notes.isNotEmpty)
            _Block(context.l10n.notes, {'': sale.notes}),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _Actions(sale: sale, isAdmin: isAdmin),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.sale, required this.isAdmin});

  final Sale sale;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (sale.status == SaleStatus.draft)
              FilledButton.icon(
                onPressed: () => openSaleSheet(context, existing: sale),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.finishThisBill),
              ),
            if (sale.completed && sale.balanceDue > 0)
              FilledButton.icon(
                // Shown to staff as well, and refused with a reason. "No way
                // to do this" and "you may not do this" are different answers
                // to give someone standing at a counter.
                onPressed: () => _collect(context),
                icon: const Icon(Icons.currency_rupee),
                label: Text(context.l10n.collectAmount('${sale.balanceDue}')),
              ),
            if (sale.status != SaleStatus.cancelled)
              OutlinedButton.icon(
                onPressed: () => _cancel(context),
                icon: const Icon(Icons.undo),
                label: Text(context.l10n.cancelThisBill),
              ),
            if (sale.completed)
              OutlinedButton.icon(
                onPressed: () => showPrintSheet(
                  context,
                  title: context.l10n.printBillTitle,
                  fileName: 'bill-${sale.invoiceNumber}',
                  build: (shop, _) => buildInvoicePdf(sale: sale, shop: shop),
                ),
                icon: const Icon(Icons.print_outlined),
                label: Text(context.l10n.printInvoice),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _collect(BuildContext context) async {
    final repo = context.read<SalesRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (!isAdmin) {
      // Checked here as well as in `canCollect`, so the message arrives
      // without a dialog that leads nowhere.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ruleText(context, kCollectionMessages[CollectionRefusal.notAdmin]!),
          ),
        ),
      );
      return;
    }

    final picked = await showDialog<(num, String)>(
      context: context,
      builder: (_) => _CollectDialog(owed: sale.balanceDue),
    );
    if (picked == null) return;
    final (amount, method) = picked;

    final check = await repo.collect(
      sale.id,
      amount,
      isAdmin: isAdmin,
      method: method,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          check.isAllowed
              ? check.remaining > 0
                    ? context.l10n.collectedStillOwed(
                        '$amount',
                        '${check.remaining}',
                      )
                    : context.l10n.collectedSettled('$amount')
              : ruleText(context, check.message!),
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final repo = context.read<SalesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelDialog(completed: sale.completed),
    );
    if (reason == null) return;
    await repo.cancelSale(sale.id, reason: reason);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sale.completed
              ? context.l10n.cancelledHandsetsBack
              : context.l10n.draftCancelled,
        ),
      ),
    );
  }
}

class _CollectDialog extends StatefulWidget {
  const _CollectDialog({required this.owed});

  final num owed;

  @override
  State<_CollectDialog> createState() => _CollectDialogState();
}

class _CollectDialogState extends State<_CollectDialog> {
  late final _controller = TextEditingController(text: widget.owed.toString());

  /// How it came in, so Reports can count it against the drawer or the bank.
  String _method = 'Cash';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.collectFromCustomer),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('collect-amount'),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.amount,
            // Never more than is owed: the extra would be a credit nobody
            // recorded, which is what the wallet is for.
            helperText: context.l10n.owedPartPaymentsFine('${widget.owed}'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final m in const ['Cash', 'UPI', 'Card'])
              ChoiceChip(
                key: Key('collect-method-$m'),
                label: Text(m),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.of(context).pop((asAmount(_controller.text), _method)),
        child: Text(context.l10n.collect),
      ),
    ],
  );
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.completed});

  final bool completed;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.cancelThisBill),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.completed
              // The record is kept: a bill that was given to a customer and
              // then deleted is how a till comes up short with nothing to
              // explain it.
              ? context.l10n.handsetsGoBack
              : context.l10n.nothingToPutBack,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('cancel-reason'),
          controller: _controller,
          decoration: InputDecoration(
            labelText: context.l10n.why,
            helperText: context.l10n.goesOnTheRecord,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.keepIt),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.cancelTheBill),
      ),
    ],
  );
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.rows);
  final String title;
  final Map<String, String> rows;

  /// A labelled card, read like a paper job card. An empty value is left
  /// out; a value of a single space marks a row that is its own label.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: FactsCard(
      title: title,
      rows: [
        for (final e in rows.entries)
          e.value.trim().isEmpty
              ? FactRow.widget(e.key, const SizedBox.shrink())
              : FactRow(e.key, e.value),
      ],
    ),
  );
}
