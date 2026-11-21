import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/customers/customer_history.dart';
import '../../../l10n/display_labels.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/customers/wallet.dart';
import 'customer_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/contact_buttons.dart';
import '../../widgets/margins.dart';

/// ONE CUSTOMER, AND EVERYTHING THE SHOP HAS DONE WITH THEM
///
/// The history is the point of the page. It is assembled from the other areas
/// by this person's number rather than by a stored list of ids, because the
/// number is the identity and a stored list goes stale the moment a record is
/// edited.
///
/// The wallet sits here too, and its moves go through the repository, which
/// does the read-check-write as one step. The page cannot write a balance.
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CustomerRepository>();
    final customer = repo.byId(id);

    if (customer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l10n.noCustomer(id), textAlign: TextAlign.center),
        ),
      );
    }

    final history = repo.walletHistory(id);
    final ledger = balanceFromHistory(history);

    // Assembled by number: the handsets this person has sold the shop.
    final soldToShop = context
        .watch<SecondHandRepository>()
        .devices
        .where((d) => samePhone(d.sellerPhone, customer.phone))
        .toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, child: Text(customer.initials)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isEmpty
                          ? context.l10n.noNameGiven
                          : customer.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(formatPhone(customer.phone)),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => openCustomerSheet(context, existing: customer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ContactButtons(
            phone: customer.phone,
            message: context.l10n.waHello(customer.name, shopNameOf(context)),
          ),
          const SizedBox(height: 16),
          _Wallet(customer: customer, history: history, ledger: ledger),
          if (customer.altPhone.isNotEmpty ||
              customer.email.isNotEmpty ||
              customer.address.isNotEmpty ||
              customer.notes.isNotEmpty)
            _Block(context.l10n.details, {
              if (customer.altPhone.isNotEmpty)
                context.l10n.secondNumber: formatPhone(customer.altPhone),
              if (customer.email.isNotEmpty) context.l10n.email: customer.email,
              if (customer.address.isNotEmpty)
                context.l10n.address: customer.address,
              if (customer.notes.isNotEmpty) context.l10n.notes: customer.notes,
            }),
          const SizedBox(height: 16),
          Text(
            context.l10n.soldToTheShop,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          if (soldToShop.isEmpty)
            Text(context.l10n.nothingYet)
          else
            for (final d in soldToShop)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(d.title),
                subtitle: Text(
                  canSeeMargins(context)
                      ? '₹${d.purchasePrice} · ${d.stockState}'
                      : d.stockState,
                ),
                onTap: () => context.go('/inventory/second-hand/${d.id}'),
              ),
          // Repairs, bills and enquiries, matched by id or by number — see
          // customer_history.dart.
          _History(customer: customer),
        ],
      ),
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({
    required this.customer,
    required this.history,
    required this.ledger,
  });

  final Customer customer;
  final List<WalletMove> history;
  final num ledger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The stored balance is what the till reads; the history is what it should
    // add up to. When they disagree the record is broken, and saying so is
    // more use than picking one of them to believe.
    final disagrees = history.isNotEmpty && ledger != customer.walletBalance;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.wallet('${customer.walletBalance}'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _move(context, WalletMoveKind.credit),
                  child: Text(context.l10n.addCredit),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _move(context, WalletMoveKind.debit),
                  child: Text(context.l10n.spend),
                ),
              ],
            ),
            if (disagrees)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.historyDisagrees(
                    '$ledger',
                    '${customer.walletBalance}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.noWalletMoves,
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (final m in history)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    m.kind == WalletMoveKind.credit
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  title: Text(m.reason),
                  subtitle: m.reference == null ? null : Text(m.reference!),
                  trailing: Text(
                    '${m.kind == WalletMoveKind.credit ? '+' : '−'}₹${m.amount}',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(BuildContext context, WalletMoveKind kind) async {
    final repo = context.read<CustomerRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final move = await showDialog<WalletMove>(
      context: context,
      builder: (_) => _WalletMoveDialog(kind: kind),
    );
    if (move == null) return;

    final result = await repo.moveWallet(customer.id, move);
    if (!context.mounted) return;
    // A refusal is an ordinary thing the counter handles, not an error: the
    // balance is untouched and the message says what to do instead.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.allowed
              ? context.l10n.walletIsNow('${result.newBalance}')
              : result.refusalMessage!,
        ),
      ),
    );
  }
}

/// The dialog owns its own controllers.
///
/// It has to: the dialog's widgets keep rebuilding while the route animates
/// out, so controllers disposed by the caller the moment it pops are used
/// after being disposed.
class _WalletMoveDialog extends StatefulWidget {
  const _WalletMoveDialog({required this.kind});

  final WalletMoveKind kind;

  @override
  State<_WalletMoveDialog> createState() => _WalletMoveDialogState();
}

class _WalletMoveDialogState extends State<_WalletMoveDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.kind == WalletMoveKind.credit
            ? context.l10n.addCreditToWallet
            : context.l10n.spendFromWallet,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('wallet-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.amount),
          ),
          TextField(
            key: const Key('wallet-reason'),
            controller: _reason,
            decoration: InputDecoration(
              labelText: context.l10n.whatItIsFor,
              // An unexplained line in a wallet history is how an argument at
              // the counter becomes unwinnable.
              helperText: context.l10n.required,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            WalletMove(
              kind: widget.kind,
              // Left to the wallet rules to refuse: a blank amount is zero, and
              // zero is refused with a message rather than swallowed here.
              amount: num.tryParse(_amount.text.trim()) ?? 0,
              reason: _reason.text.trim(),
            ),
          ),
          child: Text(context.l10n.apply),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.title, this.rows);

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.titleSmall),
        const Divider(),
        for (final entry in rows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(entry.key, style: theme.textTheme.bodySmall),
                ),
                Expanded(child: Text(entry.value)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Repairs, bills and enquiries for this customer. An area whose store is not
/// above this page (a test pumping the page bare) is simply left out.
class _History extends StatelessWidget {
  const _History({required this.customer});

  final Customer customer;

  static T? _maybe<T>(BuildContext context) {
    try {
      return Provider.of<T>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = _maybe<ServiceRepository>(context);
    final sales = _maybe<SalesRepository>(context);
    final enquiries = _maybe<EnquiryRepository>(context);
    final h = historyOf(
      customer,
      orders: service?.orders ?? const [],
      sales: sales?.sales ?? const [],
      enquiries: enquiries?.enquiries ?? const [],
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (service != null) ...[
          heading(l10n.navService),
          const Divider(),
          if (h.repairs.isEmpty) Text(l10n.nothingYet),
          for (final o in h.repairs)
            ListTile(
              key: Key('history-order-${o.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(o.title),
              subtitle: Text(serviceStatusLabel(context, o.status)),
              onTap: () => context.go('/service/${o.id}'),
            ),
        ],
        if (sales != null) ...[
          heading(l10n.navSales),
          const Divider(),
          if (h.bills.isEmpty) Text(l10n.nothingYet),
          for (final s in h.bills)
            ListTile(
              key: Key('history-sale-${s.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(s.title),
              trailing: Text('₹${s.total}'),
              onTap: () => context.go('/sales/${s.id}'),
            ),
        ],
        if (enquiries != null) ...[
          heading(l10n.navEnquiries),
          const Divider(),
          if (h.enquiries.isEmpty) Text(l10n.nothingYet),
          for (final e in h.enquiries)
            ListTile(
              key: Key('history-enquiry-${e.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(e.headline),
              onTap: () => context.go('/enquiries/${e.id}'),
            ),
        ],
      ],
    );
  }
}
