import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../../widgets/input_rules.dart';
import '../../../l10n/value_labels.dart';

import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../../data/sales_repository.dart';
import '../../../data/shop_repository.dart';
import '../../../app/auth_state.dart';
import '../../../data/product_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/common/money.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/customers/wallet.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/inventory/second_hand_device.dart';
import '../../../domain/products/product.dart';
import '../../../domain/products/product_list.dart';
import '../../../domain/sales/payment_methods.dart';
import '../../../domain/sales/sale.dart';
import '../../../domain/sales/sale_item.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/rule_messages.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/form_jump.dart';

/// RAISING A BILL
///
/// Four sections, the order the counter works in: customer, items, payment,
/// summary.
///
/// The rule that shapes this screen: **nothing moves until Complete.** Adding
/// a handset to the bill does not mark it sold, and closing the sheet leaves
/// the shelf exactly as it was. "Complete sale" is one step that takes the
/// wallet payment, marks the handsets sold and assigns the invoice number —
/// and refuses the lot if a handset has gone out from under the bill
/// meanwhile.
///
/// Only sellable stock reaches the picker. The rest is still loaded, so a
/// handset that is on the bench or already sold can say so rather than
/// appearing not to exist.
/// Answers the completed bill, or null when it was closed or only drafted.
Future<Sale?> openSaleSheet(
  BuildContext context, {
  Sale? existing,
  List<SaleItem> initialItems = const [],
  String initialPhone = '',
  String initialName = '',
}) async {
  final sales = context.read<SalesRepository>();
  final stock = context.read<SecondHandRepository>();
  final productsRepo = context.read<ProductRepository>();
  final customers = context.read<CustomerRepository>();
  final drafts = context.read<DraftStore>();
  final done = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, not inside the tab, so the bottom bar does not
    // sit under the form's own buttons.
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<SalesRepository>.value(value: sales),
        ChangeNotifierProvider<SecondHandRepository>.value(value: stock),
        ChangeNotifierProvider<ProductRepository>.value(value: productsRepo),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        Provider<DraftStore>.value(value: drafts),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: SaleForm(
          existing: existing,
          initialItems: initialItems,
          initialPhone: initialPhone,
          initialName: initialName,
        ),
      ),
    ),
  );
  return done is Sale ? done : null;
}

class SaleForm extends StatefulWidget {
  const SaleForm({
    super.key,
    this.existing,
    this.initialItems = const [],
    this.initialPhone = '',
    this.initialName = '',
  });

  /// The customer a new bill starts with (from an enquiry).
  final String initialPhone;
  final String initialName;

  final Sale? existing;

  /// Lines a new bill starts with — the handset whose page "Sell" was
  /// pressed on.
  final List<SaleItem> initialItems;

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _paid = TextEditingController();
  final _wallet = TextEditingController();

  /// Split: how much came in by each way.
  final _split = {
    for (final m in const ['Cash', 'UPI', 'Card']) m: TextEditingController(),
  };

  /// Financed: how the down payment was paid.
  String _downMethod = 'Cash';
  final _items = <SaleItem>[];

  Customer? _customer;
  String _method = 'Cash';

  /// A customer in another state: GST prints as IGST. Asked only when the
  /// shop charges GST at all ([_shopChargesGst]).
  bool _interState = false;
  bool _shopChargesGst = false;
  SaleValidation _result = const SaleValidation({}, {});
  bool _submitted = false;

  String get _draftKey => draftKey('sale', id: widget.existing?.id);

  @override
  void initState() {
    super.initState();
    for (final c in [_phone, _name, _paid, _wallet, ..._split.values]) {
      c.addListener(_recompute);
    }
    final e = widget.existing;
    if (e != null) {
      _phone.text = e.customerPhone;
      _name.text = e.customerName;
      // A completed bill shows exactly what was paid, 0 included; only a
      // draft's untouched box stays empty (= paid in full).
      final counter = e.paidBy?.values.fold<num>(0, (a, b) => a + b);
      _paid.text = e.status == SaleStatus.draft && e.paidBy == null
          // A draft saved with the box empty: still "paid in full", not the
          // total typed in (which made it part-paid when a line was added).
          ? ''
          : '${counter ?? (e.amountPaid - e.walletUsed)}';
      if (e.paymentMethod == 'Split') {
        for (final m in e.paidBy?.entries ?? const <MapEntry<String, num>>[]) {
          _split[m.key]?.text = '${m.value}';
        }
        _paid.text = '';
      }
      if (isFinanceMethod(e.paymentMethod) && (e.paidBy?.isNotEmpty ?? false)) {
        _downMethod = e.paidBy!.keys.first;
      }
      _wallet.text = e.walletUsed == 0 ? '' : e.walletUsed.toString();
      _method = e.paymentMethod;
      _interState = e.interState;
      _items.addAll(e.items);
    } else {
      _items.addAll(widget.initialItems);
      _phone.text = widget.initialPhone;
      _name.text = widget.initialName;
    }
    _recompute();
    _loadShopGst();
  }

  /// Whether this shop prints GST: a GSTIN and a rate. Read once; without a
  /// shop record (offline, tests) the IGST question is simply not asked.
  Future<void> _loadShopGst() async {
    try {
      final shops = context.read<ShopRepository?>();
      final id = context.read<AuthState>().shopId;
      if (shops == null || id == null || id.isEmpty) return;
      final shop = await shops.load(id);
      if (!mounted || shop == null) return;
      setState(
        () =>
            _shopChargesGst = shop.gstin.trim().isNotEmpty && shop.gstRate > 0,
      );
    } catch (_) {
      // No shop record to read: no GST question.
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _paid.dispose();
    _wallet.dispose();
    for (final c in _split.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The customer for the number typed: the one picked, or the one the book
  /// already has on that number (FM #18).
  Customer? get _bookMatch {
    if (_customer != null) return _customer;
    try {
      return findByPhone(
        context.read<CustomerRepository>().customers,
        _phone.text,
      );
    } on ProviderNotFoundException {
      return null;
    }
  }

  Sale _asSale() => Sale(
    id: widget.existing?.id ?? 'new',
    invoiceNumber: widget.existing?.invoiceNumber ?? '',
    customerId: _bookMatch?.id ?? widget.existing?.customerId,
    customerName:
        _customer?.name ??
        (_name.text.trim().isNotEmpty
            ? _name.text.trim()
            : _bookMatch?.name ?? widget.existing?.customerName ?? ''),
    customerPhone: _phone.text.trim(),
    items: List.of(_items),
    paymentMethod: _method,
    amountPaid: _payment.amountPaid,
    paidBy: _payment.paidBy,
    walletUsed: asAmount(_wallet.text),
    interState: _interState,
    status: widget.existing?.status ?? SaleStatus.draft,
    completedAt: widget.existing?.completedAt,
    createdAt: widget.existing?.createdAt,
  );

  /// What the typed boxes come to: paid, by method, and any change.
  BillPayment get _payment => settleBill(
    total: billTotals(_items).total,
    method: _method,
    typed: _paid.text,
    wallet: asAmount(_wallet.text),
    splitTyped: {for (final e in _split.entries) e.key: e.value.text},
    downPaymentMethod: _downMethod,
  );

  void _recompute() {
    final checked = validateSale(_asSale());
    final errors = {...checked.errors};
    // The wallet box against what this customer's wallet holds.
    final holds = _bookMatch?.walletBalance ?? 0;
    if (asAmount(_wallet.text) > holds) {
      // Worded in build: this also runs from initState.
      errors['walletUsed'] = '#walletHolds:$holds';
    }
    // Split says how much by each way, or it is not a payment at all.
    if (_method == 'Split' &&
        _split.values.every((c) => asAmount(c.text) == 0)) {
      errors['amountPaid'] = '#split';
    }
    setState(() => _result = SaleValidation(errors, checked.warnings));
  }

  /// The form's own messages, worded in the phone's language.
  String _worded(String code) {
    final l10n = context.l10n;
    if (code == '#split') return l10n.splitSayHowMuch;
    if (code.startsWith('#walletHolds:')) {
      return l10n.walletHoldsOnly(
        formatIndianNumber(asAmount(code.split(':').last)),
      );
    }
    return code;
  }

  /// A draft with the paid box untouched keeps it untouched: nothing paid
  /// yet, and "paid in full" again when it is reopened.
  Sale _draftSale() {
    final sale = _asSale();
    if (_method != 'Split' && _paid.text.trim().isEmpty) {
      final map = sale.toMap()
        ..remove('paidBy')
        ..['amountPaid'] = 0;
      return Sale.fromMap(sale.id, map);
    }
    return sale;
  }

  Sale _withId(Sale sale) => sale.id != 'new'
      ? sale
      : Sale.fromMap('s-${DateTime.now().millisecondsSinceEpoch}', {
          ...sale.toMap(),
          'createdAt': DateTime.now().toIso8601String(),
        });

  /// Saved as a draft. Deliberately moves nothing: the shelf is left exactly
  /// as it was, so an abandoned bill costs the shop nothing.
  Future<void> _saveDraft() async {
    final repo = context.read<SalesRepository>();
    final drafts = context.read<DraftStore>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final stored = await guardSave(
      context,
      () => repo.saveDraft(_withId(_draftSale())),
    );
    if (stored == null) {
      return;
    }
    await drafts.clear(_draftKey);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.keptAsDraftItems(stored.totals.lineCount)),
      ),
    );
  }

  /// The one step that moves stock.
  Future<void> _complete() async {
    final sale = _withId(_asSale());
    _recompute();
    final result = _result;
    setState(() => _submitted = true);
    if (!result.isValid) {
      // To the first thing that needs something; its error is under it.
      final firstError = _worded(ruleText(context, result.errors.values.first));
      final said = ScaffoldMessenger.of(context);
      final jumped = await jumpToFirstError(
        context,
        result.errors.keys.map(
          (rule) => Key(switch (rule) {
            'customer' => 'sale-phone',
            'amountPaid' => 'sale-paid',
            'walletUsed' => 'sale-wallet',
            _ => 'sale-$rule',
          }),
        ),
      );
      if (!jumped) said.showSnackBar(SnackBar(content: Text(firstError)));
      return;
    }

    final repo = context.read<SalesRepository>();
    final drafts = context.read<DraftStore>();
    final customers = context.read<CustomerRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // No internet: the invoice number and the stock move need the server.
    // Keep the bill on the phone and let it complete itself when the
    // connection is back (pending_bills.dart), instead of turning the
    // customer away.
    var queued = false;
    final outcome = await guardSave<SaleCompletion?>(context, () async {
      try {
        return await repo
            .completeSale(sale)
            .timeout(const Duration(seconds: 15));
      } on FirebaseException catch (e) {
        if (e.code != 'unavailable' && e.code != 'deadline-exceeded') rethrow;
      } on TimeoutException {
        // Still trying; treated as offline.
      }
      queued = true;
      return null;
    });
    if (queued) {
      if (!mounted) return;
      final kept = await guardSave(
        context,
        () => repo.saveDraft(sale.copyWith(pendingCompletion: true)),
      );
      if (kept == null) return;
      await drafts.clear(_draftKey);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(context.l10n.billQueuedOffline),
        ),
      );
      return;
    }
    if (outcome == null) {
      return;
    }
    if (!outcome.completed) {
      // Nothing was written. The message names the handset that went out from
      // under the bill, so the counter can take it off and try again.
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(ruleText(context, outcome.message!))),
      );
      return;
    }
    await drafts.clear(_draftKey);
    // A buyer who is not in the book joins it, after the bill, unawaited.
    unawaited(
      fileCustomer(
        customers,
        name: sale.customerName,
        phone: sale.customerPhone,
      ),
    );
    if (!mounted) return;
    navigator.pop(outcome.sale);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${outcome.sale!.invoiceNumber} — '
          '${rupees(outcome.sale!.total)}'
          '${outcome.sale!.balanceDue > 0 ? context.l10n.billStillOwed(formatIndianNumber(outcome.sale!.balanceDue)) : ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = _asSale();
    final totals = sale.totals;
    final errors = _submitted
        ? {
            for (final e in ruleTexts(context, _result.errors).entries)
              e.key: _worded(e.value),
          }
        : <String, String>{};
    // The wallet box is checked as it is typed, not only on Complete.
    final walletProblem = _result.errors['walletUsed'];
    if (walletProblem != null && walletProblem.startsWith('#')) {
      errors['walletUsed'] = _worded(walletProblem);
    }
    final walletBalance = _bookMatch?.walletBalance ?? 0;
    final payment = _payment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.l10n.newSaleTitle
              : context.l10n.editBill,
        ),
        leading: IconButton(
          key: const Key('form-close'),
          icon: const Icon(Icons.close),
          tooltip: context.l10n.closeWithoutSaving,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Section(context.l10n.customer, [
            TextField(
              key: const Key('sale-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: phoneInput(),
              maxLength: kPhoneDigits,
              decoration: InputDecoration(
                label: FieldLabel(context.l10n.phoneNumber, required: true),
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: errors['customer'],
                helperText: context.l10n.findsWhoeverBeenHere,
              ),
            ),
            const SizedBox(height: 8),
            _CustomerMatch(
              phone: _phone.text,
              picked: _customer,
              onPicked: (c) {
                setState(() {
                  _customer = c;
                  _phone.text = c.phone;
                });
                _recompute();
              },
            ),
            // Somebody not in the book: their name goes on the bill and into
            // the book with it. A number on its own is still enough.
            if (_customer == null && _phone.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              TextField(
                key: const Key('sale-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.l10n.name,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: context.l10n.nameOptionalHelp,
                ),
              ),
            ],
          ]),
          _Section(context.l10n.items, required: true, [
            for (var i = 0; i < _items.length; i++)
              _LineTile(
                item: _items[i],
                onRemove: () {
                  setState(() => _items.removeAt(i));
                  _recompute();
                },
              ),
            if (errors.containsKey('items'))
              KeyedSubtree(
                key: const Key('sale-items'),
                child: _ErrorText(errors['items']!),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('sale-add-stock'),
                  onPressed: _addFromStock,
                  icon: const Icon(Icons.smartphone_outlined),
                  label: Text(context.l10n.addFromStock),
                ),
                TextButton.icon(
                  key: const Key('sale-add-product'),
                  onPressed: _addProduct,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(context.l10n.addAProductLine),
                ),
                TextButton.icon(
                  onPressed: _addManual,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addALine),
                ),
              ],
            ),
          ]),
          _Section(context.l10n.payment, [
            // Cash, UPI, Card… in one row: a tap, not a pop-up list.
            Text(
              context.l10n.method,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            ChoiceRow<String>(
              key: const Key('sale-method'),
              values: kPaymentMethods,
              selected: _method,
              labelOf: (m) => m,
              keyOf: (m) => Key('sale-method-$m'),
              onPicked: (m) {
                setState(() => _method = m);
                _recompute();
              },
            ),
            const SizedBox(height: 10),
            if (_method == 'Split')
              // How much came in by each way: each goes to its own row in
              // Reports, cash into the drawer figure.
              Row(
                key: const Key('sale-split'),
                children: [
                  for (final (i, m) in const [
                    'Cash',
                    'UPI',
                    'Card',
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: Key('sale-split-$m'),
                        controller: _split[m],
                        inputFormatters: moneyInput(),
                        keyboardType: moneyKeyboard,
                        decoration: InputDecoration(
                          labelText: m,
                          prefixText: '₹ ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          errorText: i == 0 ? errors['amountPaid'] : null,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else ...[
              TextField(
                key: const Key('sale-paid'),
                inputFormatters: moneyInput(),
                controller: _paid,
                keyboardType: moneyKeyboard,
                decoration: InputDecoration(
                  labelText: isFinanceMethod(_method)
                      ? context.l10n.downPaymentAtCounter
                      : context.l10n.paidAtTheCounter,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: errors['amountPaid'],
                  hintText: isFinanceMethod(_method)
                      ? rupees(0)
                      : rupees(
                          billTotals(_items).total - asAmount(_wallet.text),
                        ),
                  helperText: isFinanceMethod(_method)
                      ? context.l10n.downPaymentEmptyMeansNone
                      : context.l10n.paidEmptyMeansFull,
                ),
              ),
              // A down payment is money in the drawer or the bank: say which.
              if (isFinanceMethod(_method) && asAmount(_paid.text) > 0) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.downPaymentPaidBy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                ChoiceRow<String>(
                  key: const Key('sale-down-method'),
                  values: const ['Cash', 'UPI', 'Card'],
                  selected: _downMethod,
                  labelOf: (m) => m,
                  keyOf: (m) => Key('sale-down-$m'),
                  onPicked: (m) {
                    setState(() => _downMethod = m);
                    _recompute();
                  },
                ),
              ],
            ],
            const SizedBox(height: 10),
            if (walletBalance > 0) ...[
              TextField(
                key: const Key('sale-wallet'),
                inputFormatters: moneyInput(),
                controller: _wallet,
                keyboardType: moneyKeyboard,
                decoration: InputDecoration(
                  labelText: context.l10n.ofWhichFromWallet,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: errors['walletUsed'],
                  // A wallet with 300 against a 500 bill covers 300, and the
                  // rest is taken another way. All-or-nothing is how staff
                  // stopped using the wallet at all.
                  helperText: context.l10n.walletCovers(
                    formatIndianNumber(walletBalance),
                    formatIndianNumber(
                      walletCoverage(walletBalance, totals.total),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_shopChargesGst)
              SwitchListTile(
                key: const Key('sale-inter-state'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.igstTitle),
                subtitle: Text(context.l10n.igstHint),
                value: _interState,
                onChanged: (v) {
                  setState(() => _interState = v);
                  _recompute();
                },
              ),
          ]),
          _Section(context.l10n.billSummary, [
            _SummaryRow(context.l10n.items, '${totals.lineCount}'),
            _SummaryRow(context.l10n.gross, rupees(totals.gross)),
            _SummaryRow(context.l10n.discount, rupees(totals.discount)),
            _SummaryRow(context.l10n.total, rupees(totals.total), bold: true),
            _SummaryRow(context.l10n.paid, rupees(sale.amountPaid)),
            if (sale.walletUsed > 0)
              _SummaryRow(context.l10n.fromTheWallet, rupees(sale.walletUsed)),
            // More handed over than the bill: the difference goes back and
            // is not counted as takings.
            if (payment.change > 0)
              _SummaryRow(
                context.l10n.changeToGiveBack,
                rupees(payment.change),
                bold: true,
              ),
            _SummaryRow(
              sale.isFinanced
                  ? context.l10n.customerOwes
                  : context.l10n.balance,
              rupees(sale.balanceDue),
              bold: sale.balanceDue > 0,
            ),
          ]),
          if (_result.hasWarnings) _Warnings(warnings: _result.warnings),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saveDraft,
                  child: Text(context.l10n.keepAsDraft),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('sale-complete'),
                  onPressed: _complete,
                  child: Text(context.l10n.completeSale),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addFromStock() async {
    final picked = await showModalBottomSheet<SecondHandDevice>(
      context: context,
      isScrollControlled: true,
      // Below the status bar, with a handle, sized to what it lists.
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<SecondHandRepository>.value(
        value: context.read<SecondHandRepository>(),
        // What is already on this bill is not offered again.
        child: _StockPicker(
          onBill: {
            for (final i in _items)
              if (i.source == LineSource.secondHand) ?i.recordId,
          },
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(handsetLine(picked)));
    _recompute();
  }

  Future<void> _addProduct() async {
    final picked = await showModalBottomSheet<SaleItem>(
      context: context,
      isScrollControlled: true,
      // Below the status bar, with a handle, sized to what it lists.
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<ProductRepository>.value(
        value: context.read<ProductRepository>(),
        child: _ProductPicker(
          onBill: productQuantities(Sale(id: 'x', items: _items)),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(picked));
    _recompute();
  }

  Future<void> _addManual() async {
    final item = await showInputSheet<SaleItem>(
      context: context,
      builder: (_) => const _ManualLineDialog(),
    );
    if (item == null) return;
    setState(() => _items.add(item));
    _recompute();
  }
}

/// Whoever has been here before, found by the number being typed.
class _CustomerMatch extends StatelessWidget {
  const _CustomerMatch({
    required this.phone,
    required this.picked,
    required this.onPicked,
  });

  final String phone;
  final Customer? picked;
  final ValueChanged<Customer> onPicked;

  @override
  Widget build(BuildContext context) {
    if (picked != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: const Icon(Icons.person, size: 16),
          label: Text(picked!.display),
        ),
      );
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return const SizedBox.shrink();

    final matches = suggestCustomers(
      context.watch<CustomerRepository>().customers,
      digits,
      limit: 4,
    );
    if (matches.isEmpty) {
      return Text(
        context.l10n.nobodyOnThatNumberBill,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    // One sideways row, like every other pick in the app.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in matches) ...[
            ActionChip(
              avatar: const Icon(Icons.person_outline, size: 16),
              label: Text(c.display),
              onPressed: () => onPicked(c),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// THE STOCK PICKER
///
/// Only sellable handsets can be picked. The rest are still SHOWN, greyed and
/// labelled — a handset on the bench or already sold has to be able to explain
/// itself, because a device that simply does not appear is one staff re-enter
/// as a new purchase.
class _StockPicker extends StatefulWidget {
  const _StockPicker({this.onBill = const {}});

  /// Handsets already on this bill.
  final Set<String> onBill;

  @override
  State<_StockPicker> createState() => _StockPickerState();
}

class _StockPickerState extends State<_StockPicker> {
  String _query = '';

  /// '' is every brand.
  String _brand = '';

  Set<String> get onBill => widget.onBill;

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<SecondHandRepository>().devices;
    final brands = groupsByCount([
      for (final d in devices)
        if (d.isSellable) d.brand,
    ]);
    final all = [
      for (final d in devices)
        if (d.matches(_query) &&
            (_brand.isEmpty ||
                d.brand.trim().toLowerCase() == _brand.toLowerCase()))
          d,
    ];
    final sellable = [
      for (final d in all)
        if (d.isSellable && !onBill.contains(d.id)) d,
    ];
    final rest = [
      for (final d in all)
        if (!d.isSellable || onBill.contains(d.id)) d,
    ];

    return _PickerFrame(
      title: context.l10n.inStock,
      searchKey: const Key('pick-stock-search'),
      searchHint: context.l10n.searchStock,
      onSearch: (q) => setState(() => _query = q),
      filters: brands.length < 2
          ? null
          : ChoiceRow<String>(
              values: ['', ...brands],
              selected: _brand,
              labelOf: (b) => b.isEmpty ? context.l10n.all : b,
              keyOf: (b) => Key('pick-brand-${b.isEmpty ? 'all' : b}'),
              onPicked: (b) => setState(() => _brand = b),
            ),
      children: [
        if (sellable.isEmpty)
          Text(context.l10n.nothingSellable)
        else
          for (final d in sellable)
            PickTile(
              key: Key('pick-${d.id}'),
              icon: Icons.smartphone,
              title: d.title,
              price: rupees(d.askingPrice),
              subtitle: [
                if (d.grade != null) context.l10n.gradeNamed('${d.grade}'),
                if (d.imei.isNotEmpty) 'IMEI ${d.imei}',
              ].join(' · '),
              onTap: () => Navigator.of(context).pop(d),
            ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.notSellable,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          for (final d in rest)
            PickTile(
              icon: Icons.smartphone,
              title: d.title,
              // Says why, rather than being absent.
              subtitle: onBill.contains(d.id)
                  ? context.l10n.alreadyOnBill
                  : d.isSold
                  ? context.l10n.alreadySold
                  : context.l10n.onBenchNotReady,
            ),
        ],
      ],
    );
  }
}

/// A picker sheet: its title, a search box, then the list — as tall as the
/// list needs and no taller, scrolling when it is long.
class _PickerFrame extends StatelessWidget {
  const _PickerFrame({
    required this.title,
    required this.searchKey,
    required this.searchHint,
    required this.onSearch,
    required this.children,
    this.filters,
  });

  final String title;
  final Key searchKey;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final List<Widget> children;

  /// Brands or categories, in one sideways row under the search box.
  final Widget? filters;

  @override
  Widget build(BuildContext context) => Padding(
    // Clear of the keyboard while searching.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            key: searchKey,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (filters != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: filters,
          ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: children,
          ),
        ),
      ],
    ),
  );
}

/// THE PRODUCT PICKER
///
/// Only products with something on the shelf can be picked. The rest are
/// still SHOWN and labelled out of stock — the same rule as the handset
/// picker: a product that simply does not appear is one somebody adds a
/// second record for.
///
/// The quantity is asked for here rather than edited on the line, and capped
/// at what is on the shelf. The sale would refuse an over-count at completion
/// anyway, but finding that out after the customer has been told a total is
/// the wrong moment.
class _ProductPicker extends StatefulWidget {
  const _ProductPicker({this.onBill = const {}});

  /// How many of each product the bill already takes.
  final Map<String, int> onBill;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _query = '';

  /// '' is every category.
  String _category = '';

  Map<String, int> get onBill => widget.onBill;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductRepository>().products;
    final categories = groupsByCount([
      for (final p in products)
        if (p.isSellable && p.stockCount > 0) p.category,
    ]);
    final all = [
      for (final p in products)
        if (p.matches(_query) &&
            (_category.isEmpty || p.category.trim() == _category))
          p,
    ];
    // "Left" is what is on the shelf less what this bill already takes.
    int left(Product p) => p.stockCount - (onBill[p.id] ?? 0);
    final available = [
      for (final p in sellableProducts(all))
        if (left(p) > 0) p,
    ];
    final rest = [
      for (final p in all)
        if (!p.isSellable || left(p) <= 0) p,
    ];

    return _PickerFrame(
      title: context.l10n.onTheShelf,
      searchKey: const Key('pick-product-search'),
      searchHint: context.l10n.searchProducts,
      onSearch: (q) => setState(() => _query = q),
      filters: categories.length < 2
          ? null
          : ChoiceRow<String>(
              values: ['', ...categories],
              selected: _category,
              labelOf: (c) =>
                  c.isEmpty ? context.l10n.all : shopValue(context, c),
              keyOf: (c) => Key('pick-category-${c.isEmpty ? 'all' : c}'),
              onPicked: (c) => setState(() => _category = c),
            ),
      children: [
        if (available.isEmpty)
          Text(context.l10n.nothingInNewGoods)
        else
          for (final p in available)
            PickTile(
              key: Key('pick-product-${p.id}'),
              icon: Icons.inventory_2_outlined,
              title: p.title,
              price: rupees(p.sellingPrice),
              subtitle: [
                context.l10n.leftCount(left(p)),
                if (p.category.isNotEmpty) shopValue(context, p.category),
              ].join(' · '),
              onTap: () async {
                final quantity = await showInputSheet<int>(
                  context: context,
                  builder: (_) =>
                      _QuantityDialog(product: p, available: left(p)),
                );
                if (quantity == null || !context.mounted) return;
                Navigator.of(context).pop(
                  SaleItem(
                    description: p.title,
                    // Copied at bill time: a price corrected next week must
                    // not change a bill already given to a customer.
                    unitPrice: p.sellingPrice,
                    quantity: quantity,
                    source: LineSource.product,
                    recordId: p.id,
                    labelNumber: p.labelNumber,
                  ),
                );
              },
            ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.tabOutOfStock,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          for (final p in rest)
            PickTile(
              icon: Icons.inventory_2_outlined,
              title: p.title,
              // Says why, rather than being absent.
              subtitle: p.isSellable
                  ? context.l10n.allOnThisBill
                  : context.l10n.noneOnTheShelf,
            ),
        ],
      ],
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.product, required this.available});

  final Product product;

  /// On the shelf, less what this bill already takes.
  final int available;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');

  /// Said under the box instead of quietly changing the number.
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(widget.product.title),
    content: TextField(
      key: const Key('sale-product-quantity'),
      inputFormatters: wholeNumberInput(maxDigits: 4),
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.l10n.howMany,
        helperText: context.l10n.onShelfCount(widget.available),
        errorText: _error,
      ),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          final asked = int.tryParse(_controller.text.trim()) ?? 0;
          // Said, not quietly changed: 9 asked with 5 on the shelf is a
          // question for the person at the counter.
          if (asked < 1) {
            setState(() => _error = context.l10n.quantityAtLeastOne);
            return;
          }
          if (asked > widget.available) {
            setState(
              () => _error = context.l10n.onlyLeftCount(widget.available),
            );
            return;
          }
          Navigator.of(context).pop(asked);
        },
        key: const Key('sale-quantity-add'),
        child: Text(context.l10n.add),
      ),
    ],
  );
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.item, required this.onRemove});

  final SaleItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(item.description),
      subtitle: Text(
        [
          '${rupees(item.unitPrice)} × ${item.effectiveQuantity}',
          // Capped at the line, as the total is.
          if (item.discount > 0)
            '− ${rupees(item.discountExceedsLine ? item.gross : item.discount)}',
          if (item.imei != null && item.imei!.isNotEmpty) 'IMEI ${item.imei}',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rupees(item.total)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ManualLineDialog extends StatefulWidget {
  const _ManualLineDialog();

  @override
  State<_ManualLineDialog> createState() => _ManualLineDialogState();
}

class _ManualLineDialogState extends State<_ManualLineDialog> {
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  /// A quantity of 0 is said, not quietly turned into 1.
  String? _qtyError;
  final _discount = TextEditingController();

  @override
  void dispose() {
    for (final c in [_description, _price, _quantity, _discount]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(context.l10n.addALine),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('line-description'),
            controller: _description,
            decoration: InputDecoration(labelText: context.l10n.whatItIsLine),
          ),
          TextField(
            key: const Key('line-price'),
            inputFormatters: moneyInput(),
            controller: _price,
            keyboardType: moneyKeyboard,
            decoration: InputDecoration(labelText: context.l10n.priceLabel),
          ),
          TextField(
            key: const Key('line-quantity'),
            inputFormatters: wholeNumberInput(maxDigits: 4),
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.quantity,
              errorText: _qtyError,
            ),
          ),
          TextField(
            key: const Key('line-discount'),
            inputFormatters: moneyInput(),
            controller: _discount,
            keyboardType: moneyKeyboard,
            decoration: InputDecoration(labelText: context.l10n.discountRupees),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          final quantity = int.tryParse(_quantity.text.trim()) ?? 0;
          if (quantity < 1) {
            setState(() => _qtyError = context.l10n.quantityAtLeastOne);
            return;
          }
          Navigator.of(context).pop(
            SaleItem(
              description: _description.text.trim(),
              unitPrice: asAmount(_price.text),
              quantity: quantity,
              discount: asAmount(_discount.text),
            ),
          );
        },
        child: Text(context.l10n.add),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children, {this.required = false});

  final String title;
  final List<Widget> children;
  final bool required;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FormSection(title, required: required),
      ...children,
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.warnings});

  final Map<String, String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.worthALook, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            // Warnings never block a sale. A balance left on a bill and a
            // financed sale are both ordinary; the counter is told, not
            // stopped.
            for (final w in warnings.values) Text('• ${ruleText(context, w)}'),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// The bill line for a second-hand handset, at its asking price. One place,
/// so a line added from the stock picker and one started from the handset's
/// own page are the same line.
SaleItem handsetLine(SecondHandDevice d) => SaleItem(
  description: d.title,
  unitPrice: d.askingPrice,
  source: LineSource.secondHand,
  recordId: d.id,
  imei: d.imei,
  labelNumber: d.labelNumber,
);
