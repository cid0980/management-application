import 'package:flutter/material.dart';

import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';

import '../../widgets/record_refs.dart';

import '../../../app/nav.dart';
import '../../../domain/sales/sale.dart';
import '../../../domain/service/service_order.dart';
import '../../../data/live_window.dart' show mergedById;

import '../../../data/customer_repository.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/empty_state.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/customers/customer_history.dart';
import '../../../domain/common/money.dart';
import '../../../l10n/display_labels.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/customers/wallet.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../l10n/rule_messages.dart';
import 'customer_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/contact_buttons.dart';
import '../../widgets/margins.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/loading.dart';

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
      if (repo.loading) {
        return LoadingWords(first: context.l10n.loadingRecord, record: true);
      }
      return EmptyState(
        icon: Icons.search_off,
        title: context.l10n.noCustomer(id),
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
          ListSection(
            title: context.l10n.soldToTheShop,
            empty: context.l10n.nothingYet,
            children: [
              for (final d in soldToShop)
                ListTile(
                  title: Text(d.title),
                  subtitle: Text(
                    canSeeMargins(context)
                        ? '${rupees(d.purchasePrice)} · ${d.stockState}'
                        : d.stockState,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      openPage(context, '/inventory/second-hand/${d.id}'),
                ),
            ],
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
            // The balance on its own line, the buttons under it: a long
            // amount never runs into them (FM #33).
            Text(
              context.l10n.wallet(formatIndianNumber(customer.walletBalance)),
              key: const Key('wallet-balance'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('wallet-add'),
                    onPressed: () => _move(context, WalletMoveKind.credit),
                    child: Text(context.l10n.addCredit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('wallet-spend'),
                    onPressed: () => _move(context, WalletMoveKind.debit),
                    child: Text(context.l10n.spend),
                  ),
                ),
              ],
            ),
            if (disagrees)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.historyDisagrees(
                    formatIndianNumber(ledger),
                    formatIndianNumber(customer.walletBalance),
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
                  // The bill's invoice number, not its internal id (FM #32).
                  subtitle: m.reference == null
                      ? null
                      : Text(recordNumber(context, m.reference!)),
                  trailing: Text(
                    '${m.kind == WalletMoveKind.credit ? '+' : '−'}${rupees(m.amount)}',
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

    final move = await showInputSheet<WalletMove>(
      context: context,
      builder: (_) =>
          _WalletMoveDialog(kind: kind, balance: customer.walletBalance),
    );
    if (move == null || !context.mounted) return;

    final result = await whileBusy(context, repo.moveWallet(customer.id, move));
    if (!context.mounted) return;
    // A refusal is an ordinary thing the counter handles, not an error: the
    // balance is untouched and the message says what to do instead.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.allowed
              ? context.l10n.walletIsNow(formatIndianNumber(result.newBalance))
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
  const _WalletMoveDialog({required this.kind, this.balance = 0});

  final WalletMoveKind kind;

  /// What the wallet holds now, so a refusal is said in the sheet.
  final num balance;

  @override
  State<_WalletMoveDialog> createState() => _WalletMoveDialogState();
}

class _WalletMoveDialogState extends State<_WalletMoveDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  /// The wallet rules' answer, said in the sheet with what was typed kept
  /// (FM #52), and against the field it is about.
  String? _amountError;
  String? _reasonError;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputSheet(
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
            inputFormatters: moneyInput(),
            controller: _amount,
            keyboardType: moneyKeyboard,
            decoration: InputDecoration(
              labelText: context.l10n.amount,
              errorText: _amountError,
            ),
            onChanged: (_) => setState(() => _amountError = null),
          ),
          TextField(
            key: const Key('wallet-reason'),
            controller: _reason,
            decoration: InputDecoration(
              labelText: context.l10n.whatItIsFor,
              // An unexplained line in a wallet history is how an argument at
              // the counter becomes unwinnable.
              helperText: context.l10n.required,
              errorText: _reasonError,
            ),
            onChanged: (_) => setState(() => _reasonError = null),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const Key('wallet-apply'),
          onPressed: () {
            final move = WalletMove(
              kind: widget.kind,
              amount: asAmount(_amount.text),
              reason: _reason.text.trim(),
            );
            // The same rules the store applies, asked before closing.
            final check = applyMove(widget.balance, move);
            if (!check.allowed) {
              final said = ruleText(context, check.refusalMessage!);
              setState(() {
                if (check.refusal == WalletRefusal.noReason) {
                  _reasonError = said;
                } else {
                  _amountError = said;
                }
              });
              return;
            }
            Navigator.of(context).pop(move);
          },
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

/// Repairs, bills and enquiries for this customer. An area whose store is not
/// above this page (a test pumping the page bare) is simply left out.
class _History extends StatefulWidget {
  const _History({required this.customer});

  final Customer customer;

  @override
  State<_History> createState() => _HistoryState();
}

/// The live lists keep only recent and open repairs and bills; a customer's
/// page shows all of theirs, so the older ones are asked for once.
class _HistoryState extends State<_History> {
  Customer get customer => widget.customer;

  List<ServiceOrder> _olderOrders = const [];
  List<Sale> _olderBills = const [];
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fetched) return;
    _fetched = true;
    final service = _maybe<ServiceRepository>(context, listen: false);
    final sales = _maybe<SalesRepository>(context, listen: false);
    if (service?.liveSince != null) {
      service!
          .fetchOlder(customerId: customer.id, phone: customer.phone)
          .then((o) {
            if (mounted) setState(() => _olderOrders = o);
          })
          .catchError((Object _) {});
    }
    if (sales?.liveSince != null) {
      sales!
          .fetchOlder(customerId: customer.id, phone: customer.phone)
          .then((b) {
            if (mounted) setState(() => _olderBills = b);
          })
          .catchError((Object _) {});
    }
  }

  static T? _maybe<T>(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<T>(context, listen: listen);
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
      orders: mergedById([
        service?.orders ?? const <ServiceOrder>[],
        _olderOrders,
      ], (o) => o.id),
      sales: mergedById([
        sales?.sales ?? const <Sale>[],
        _olderBills,
      ], (b) => b.id),
      enquiries: enquiries?.enquiries ?? const [],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (service != null)
          ListSection(
            title: l10n.navService,
            empty: l10n.nothingYet,
            children: [
              for (final o in h.repairs)
                ListTile(
                  key: Key('history-order-${o.id}'),
                  title: Text(o.title),
                  subtitle: Text(serviceStatusLabel(context, o.status)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openPage(context, '/service/${o.id}'),
                ),
            ],
          ),
        if (sales != null)
          ListSection(
            title: l10n.navSales,
            empty: l10n.nothingYet,
            children: [
              for (final s in h.bills)
                ListTile(
                  key: Key('history-sale-${s.id}'),
                  title: Text(s.title),
                  trailing: Text(
                    rupees(s.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => openPage(context, '/sales/${s.id}'),
                ),
            ],
          ),
        if (enquiries != null)
          ListSection(
            title: l10n.navEnquiries,
            empty: l10n.nothingYet,
            children: [
              for (final e in h.enquiries)
                ListTile(
                  key: Key('history-enquiry-${e.id}'),
                  title: Text(e.headline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openPage(context, '/enquiries/${e.id}'),
                ),
            ],
          ),
      ],
    );
  }
}
