import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/product_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../domain/common/form_draft.dart';
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
Future<void> openSaleSheet(
  BuildContext context, {
  Sale? existing,
  List<SaleItem> initialItems = const [],
}) async {
  final sales = context.read<SalesRepository>();
  final stock = context.read<SecondHandRepository>();
  final productsRepo = context.read<ProductRepository>();
  final customers = context.read<CustomerRepository>();
  final drafts = context.read<DraftStore>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
        child: SaleForm(existing: existing, initialItems: initialItems),
      ),
    ),
  );
}

class SaleForm extends StatefulWidget {
  const SaleForm({super.key, this.existing, this.initialItems = const []});

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
  final _items = <SaleItem>[];

  Customer? _customer;
  String _method = 'Cash';
  SaleValidation _result = const SaleValidation({}, {});
  bool _submitted = false;

  String get _draftKey => draftKey('sale', id: widget.existing?.id);

  @override
  void initState() {
    super.initState();
    for (final c in [_phone, _name, _paid, _wallet]) {
      c.addListener(_recompute);
    }
    final e = widget.existing;
    if (e != null) {
      _phone.text = e.customerPhone;
      _name.text = e.customerName;
      // A completed bill shows exactly what was paid, 0 included; only a
      // draft's untouched box stays empty (= paid in full).
      _paid.text = e.amountPaid == 0 && e.status == SaleStatus.draft
          ? ''
          : e.amountPaid.toString();
      _wallet.text = e.walletUsed == 0 ? '' : e.walletUsed.toString();
      _method = e.paymentMethod;
      _items.addAll(e.items);
    } else {
      _items.addAll(widget.initialItems);
    }
    _recompute();
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _paid.dispose();
    _wallet.dispose();
    super.dispose();
  }

  Sale _asSale() => Sale(
    id: widget.existing?.id ?? 'new',
    invoiceNumber: widget.existing?.invoiceNumber ?? '',
    customerId: _customer?.id ?? widget.existing?.customerId,
    customerName:
        _customer?.name ??
        (_name.text.trim().isNotEmpty
            ? _name.text.trim()
            : widget.existing?.customerName ?? ''),
    customerPhone: _phone.text.trim(),
    items: List.of(_items),
    paymentMethod: _method,
    amountPaid: amountPaidFrom(
      _paid.text,
      total: billTotals(_items).total,
      walletUsed: asAmount(_wallet.text),
    ),
    walletUsed: asAmount(_wallet.text),
    status: widget.existing?.status ?? SaleStatus.draft,
    completedAt: widget.existing?.completedAt,
    createdAt: widget.existing?.createdAt,
  );

  void _recompute() {
    setState(() => _result = validateSale(_asSale()));
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

    final stored = await repo.saveDraft(_withId(_asSale()));
    await drafts.clear(_draftKey);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.keptAsDraftItems('${stored.totals.lineCount}'),
        ),
      ),
    );
  }

  /// The one step that moves stock.
  Future<void> _complete() async {
    final sale = _withId(_asSale());
    final result = validateSale(sale);
    setState(() {
      _submitted = true;
      _result = result;
    });
    if (!result.isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.errors.values.first)));
      return;
    }

    final repo = context.read<SalesRepository>();
    final drafts = context.read<DraftStore>();
    final customers = context.read<CustomerRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final outcome = await repo.completeSale(sale);
    if (!outcome.completed) {
      // Nothing was written. The message names the handset that went out from
      // under the bill, so the counter can take it off and try again.
      messenger.showSnackBar(SnackBar(content: Text(outcome.message!)));
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
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${outcome.sale!.invoiceNumber} — '
          '₹${outcome.sale!.total}'
          '${outcome.sale!.balanceDue > 0 ? context.l10n.billStillOwed('${outcome.sale!.balanceDue}') : ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = _asSale();
    final totals = sale.totals;
    final errors = _submitted ? _result.errors : <String, String>{};
    final walletBalance = _customer?.walletBalance ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.l10n.newSaleTitle
              : context.l10n.editBill,
        ),
        leading: IconButton(
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
              decoration: InputDecoration(
                labelText: context.l10n.phoneNumber,
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
          _Section(context.l10n.items, [
            for (var i = 0; i < _items.length; i++)
              _LineTile(
                item: _items[i],
                onRemove: () {
                  setState(() => _items.removeAt(i));
                  _recompute();
                },
              ),
            if (errors.containsKey('items')) _ErrorText(errors['items']!),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
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
            DropdownButtonFormField<String>(
              key: const Key('sale-method'),
              initialValue: _method,
              decoration: InputDecoration(
                labelText: context.l10n.method,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final m in kPaymentMethods)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) {
                setState(() => _method = v ?? 'Cash');
                _recompute();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('sale-paid'),
              controller: _paid,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.paidAtTheCounter,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: errors['amountPaid'],
                hintText: '₹${billTotals(_items).total}',
                helperText: context.l10n.paidEmptyMeansFull,
              ),
            ),
            const SizedBox(height: 10),
            if (walletBalance > 0) ...[
              TextField(
                key: const Key('sale-wallet'),
                controller: _wallet,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.ofWhichFromWallet,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: errors['walletUsed'],
                  // A wallet with 300 against a 500 bill covers 300, and the
                  // rest is taken another way. All-or-nothing is how staff
                  // stopped using the wallet at all.
                  helperText: context.l10n.walletCovers(
                    '$walletBalance',
                    '${walletCoverage(walletBalance, totals.total)}',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ]),
          _Section(context.l10n.billSummary, [
            _SummaryRow(context.l10n.items, '${totals.lineCount}'),
            _SummaryRow(context.l10n.gross, '₹${totals.gross}'),
            _SummaryRow(context.l10n.discount, '₹${totals.discount}'),
            _SummaryRow(context.l10n.total, '₹${totals.total}', bold: true),
            _SummaryRow(context.l10n.paid, '₹${sale.amountPaid}'),
            _SummaryRow(
              sale.isFinanced
                  ? context.l10n.customerOwes
                  : context.l10n.balance,
              '₹${sale.balanceDue}',
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
      builder: (_) => ChangeNotifierProvider<SecondHandRepository>.value(
        value: context.read<SecondHandRepository>(),
        child: const _StockPicker(),
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
      builder: (_) => ChangeNotifierProvider<ProductRepository>.value(
        value: context.read<ProductRepository>(),
        child: const _ProductPicker(),
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(picked));
    _recompute();
  }

  Future<void> _addManual() async {
    final item = await showDialog<SaleItem>(
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
    return Wrap(
      spacing: 6,
      children: [
        for (final c in matches)
          ActionChip(
            avatar: const Icon(Icons.person_outline, size: 16),
            label: Text(c.display),
            onPressed: () => onPicked(c),
          ),
      ],
    );
  }
}

/// THE STOCK PICKER
///
/// Only sellable handsets can be picked. The rest are still SHOWN, greyed and
/// labelled — a handset on the bench or already sold has to be able to explain
/// itself, because a device that simply does not appear is one staff re-enter
/// as a new purchase.
class _StockPicker extends StatelessWidget {
  const _StockPicker();

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SecondHandRepository>().devices;
    final sellable = [
      for (final d in all)
        if (d.isSellable) d,
    ];
    final rest = [
      for (final d in all)
        if (!d.isSellable) d,
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.inStock,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          if (sellable.isEmpty)
            Text(context.l10n.nothingSellable)
          else
            for (final d in sellable)
              ListTile(
                key: Key('pick-${d.id}'),
                title: Text(d.title),
                subtitle: Text(
                  [
                    '₹${d.askingPrice}',
                    if (d.grade != null) context.l10n.gradeNamed('${d.grade}'),
                    if (d.imei.isNotEmpty) 'IMEI ${d.imei}',
                  ].join(' · '),
                ),
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
              ListTile(
                enabled: false,
                title: Text(d.title),
                // Says why, rather than being absent.
                subtitle: Text(
                  d.isSold
                      ? context.l10n.alreadySold
                      : context.l10n.onBenchNotReady,
                ),
              ),
          ],
        ],
      ),
    );
  }
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
class _ProductPicker extends StatelessWidget {
  const _ProductPicker();

  @override
  Widget build(BuildContext context) {
    final all = context.watch<ProductRepository>().products;
    final available = sellableProducts(all);
    final rest = [
      for (final p in all)
        if (!p.isSellable) p,
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.onTheShelf,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          if (available.isEmpty)
            Text(context.l10n.nothingInNewGoods)
          else
            for (final p in available)
              ListTile(
                key: Key('pick-product-${p.id}'),
                title: Text(p.title),
                subtitle: Text(
                  [
                    '₹${p.sellingPrice}',
                    '${p.stockCount} left',
                    if (p.category.isNotEmpty) p.category,
                  ].join(' · '),
                ),
                onTap: () async {
                  final quantity = await showDialog<int>(
                    context: context,
                    builder: (_) => _QuantityDialog(product: p),
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
              ListTile(
                enabled: false,
                title: Text(p.title),
                // Says why, rather than being absent.
                subtitle: Text(context.l10n.noneOnTheShelf),
              ),
          ],
        ],
      ),
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.product});

  final Product product;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product.title),
    content: TextField(
      key: const Key('sale-product-quantity'),
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.l10n.howMany,
        helperText: '${widget.product.stockCount} on the shelf',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          final asked = int.tryParse(_controller.text.trim()) ?? 1;
          // Capped here as well as refused at completion: finding out
          // after the customer has been told a total is the wrong moment.
          final quantity = asked < 1
              ? 1
              : asked > widget.product.stockCount
              ? widget.product.stockCount
              : asked;
          Navigator.of(context).pop(quantity);
        },
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
          '₹${item.unitPrice} × ${item.effectiveQuantity}',
          if (item.discount > 0) '− ₹${item.discount}',
          if (item.imei != null && item.imei!.isNotEmpty) 'IMEI ${item.imei}',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${item.total}'),
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
  final _discount = TextEditingController();

  @override
  void dispose() {
    for (final c in [_description, _price, _quantity, _discount]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
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
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.priceLabel),
          ),
          TextField(
            key: const Key('line-quantity'),
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.quantity),
          ),
          TextField(
            key: const Key('line-discount'),
            controller: _discount,
            keyboardType: TextInputType.number,
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
        onPressed: () => Navigator.of(context).pop(
          SaleItem(
            description: _description.text.trim(),
            unitPrice: asAmount(_price.text),
            quantity: int.tryParse(_quantity.text.trim()) ?? 1,
            discount: asAmount(_discount.text),
          ),
        ),
        child: Text(context.l10n.add),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const Divider(),
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
            for (final w in warnings.values) Text('• $w'),
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
