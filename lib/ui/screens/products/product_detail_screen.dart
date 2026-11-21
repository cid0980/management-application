import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/label_repository.dart';
import '../../../data/print_server.dart';
import '../../../data/product_repository.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/labels/label_target.dart';
import '../../../domain/products/product.dart';
import '../../../domain/products/stock_level.dart';
import '../../../domain/products/stock_movement.dart';
import 'product_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';

/// ONE PRODUCT
///
/// Where stock actually changes, and the only place it can. Four buttons, and
/// each is a movement with a reason: received, sold off the shelf without a
/// bill, damaged, or a stock-take correction.
///
/// The history under them is the point. "The system says three and I have
/// counted five" is the question this page exists to answer, and a count with
/// no history has nothing to say to it.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProductRepository>();
    final product = repo.byId(id);

    if (product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${context.l10n.noProduct(id)}\n\n'
            '${context.l10n.deletedShelfLabelNote}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final history = repo.history(id);
    final ledger = countFromMovements(history);
    final suggested = product.suggestedOrder;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(product.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [
              stockLevelLabel(context, product.level),
              '${product.stockCount} on the shelf',
              if (product.labelNumber != null)
                context.l10n.labelNamed('${product.labelNumber}'),
            ].join(' · '),
          ),
          if (product.needsOrdering)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    product.level == StockLevel.outOfStock
                        // Zero is a sale the shop cannot make today, not
                        // "nearly gone".
                        ? context.l10n.outOfStockCannotSell
                        : '${context.l10n.atOrBelowReorder('${product.reorderLevel}')}'
                              '${suggested != null && suggested > 0 ? ' · $suggested' : ''}',
                  ),
                ),
              ),
            ),
          if (ledger != product.stockCount && history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                // The stored count is what the till reads; the history is what
                // it should add up to. Saying they disagree is more use than
                // picking one to believe.
                context.l10n.historyDisagreesStock(
                  '$ledger',
                  '${product.stockCount}',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          _Block(context.l10n.whatItIs, {
            context.l10n.name: product.name,
            context.l10n.brand: product.brand,
            context.l10n.category: product.category.isEmpty
                ? context.l10n.notCategorised
                : product.category,
            context.l10n.variant: product.variant,
            context.l10n.colour: product.colour,
            'SKU': product.sku,
            context.l10n.supplier: product.supplier,
          }),
          _Block(context.l10n.money, {
            context.l10n.costPrice: '₹${product.costPrice}',
            context.l10n.sellingPrice: '₹${product.sellingPrice}',
            if (product.mrp > 0) context.l10n.printedMaximum: '₹${product.mrp}',
            context.l10n.profitPerUnit: '₹${product.unitProfit}',
            context.l10n.stockAtCost: '₹${product.stockCost}',
            context.l10n.stockAtRetail: '₹${product.stockValue}',
          }),
          _Block(context.l10n.reordering, {
            context.l10n.reorderLevel: product.reorderLevel > 0
                ? '${product.reorderLevel}'
                // Nothing invents one, so the page says plainly what that
                // means.
                : context.l10n.noReorderLevelSet,
            if (suggested != null) context.l10n.suggestedOrder: '$suggested',
          }),
          if (product.notes.isNotEmpty)
            _Block(context.l10n.notes, {'': product.notes}),
          const SizedBox(height: 16),
          Text(context.l10n.stockHistory, style: theme.textTheme.titleSmall),
          const Divider(),
          if (history.isEmpty)
            Text(context.l10n.noStockHistory, style: theme.textTheme.bodySmall)
          else
            for (final move in history)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  move.signed > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                ),
                title: Text(kStockMoveLabels[move.kind]!),
                subtitle: Text(move.reason),
                trailing: Text(
                  '${move.signed > 0 ? '+' : '−'}${move.quantity}',
                ),
              ),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: _Actions(product: product),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('product-receive'),
              onPressed: () => _move(context, StockMoveKind.received),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.receive),
            ),
            OutlinedButton.icon(
              key: const Key('product-stocktake'),
              onPressed: () => _stockTake(context),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(context.l10n.stockTake),
            ),
            OutlinedButton.icon(
              key: const Key('product-damaged'),
              onPressed: () => _move(context, StockMoveKind.damaged),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.damaged),
            ),
            OutlinedButton.icon(
              onPressed: () => openProductSheet(context, existing: product),
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.l10n.edit),
            ),
            OutlinedButton.icon(
              key: const Key('product-label'),
              onPressed: () => _label(context),
              icon: const Icon(Icons.qr_code_2),
              label: Text(
                product.labelNumber == null
                    ? context.l10n.assignAndPrintLabel
                    : context.l10n.reprintLabel('${product.labelNumber}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(BuildContext context, StockMoveKind kind) async {
    final repo = context.read<ProductRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final movement = await showDialog<StockMovement>(
      context: context,
      builder: (_) => _MovementDialog(kind: kind, onShelf: product.stockCount),
    );
    if (movement == null) return;

    final result = await repo.move(product.id, movement);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.allowed
              ? context.l10n.nowOnTheShelf('${result.newCount}')
              // A refusal is an ordinary thing at a counter: the count is
              // untouched and the message says what to do instead.
              : result.message!,
        ),
      ),
    );
  }

  Future<void> _stockTake(BuildContext context) async {
    final repo = context.read<ProductRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final counted = await showDialog<int>(
      context: context,
      builder: (_) => _StockTakeDialog(recorded: product.stockCount),
    );
    if (counted == null) return;

    final result = await repo.stockTake(
      product.id,
      counted: counted,
      reason: 'Counted $counted on the shelf',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.allowed
              ? counted == product.stockCount
                    // Nothing moved, so nothing was written — and saying so is
                    // better than a line in the history that looks like a change.
                    ? l10n.stockCountMatched
                    : l10n.stockCorrectedTo(counted)
              : result.message!,
        ),
      ),
    );
  }

  /// Through the registry, which is the only thing that mints a number.
  Future<void> _label(BuildContext context) async {
    final labels = context.read<LabelRepository>();
    final printer = context.read<PrintServer>();
    final messenger = ScaffoldMessenger.of(context);

    final assignment = await labels.assign(LabelTargetKind.product, product.id);
    if (!assignment.ok) {
      messenger.showSnackBar(SnackBar(content: Text(assignment.error!)));
      return;
    }
    final entry = assignment.entry!;
    if (assignment.alreadyLabelled) {
      await labels.markReprinted(entry.number);
    }

    final view = labels.resolve(entry.number);
    final result = await printer.printLabel(
      LabelPrintJob(
        number: entry.number,
        title: view?.title ?? product.title,
        subtitle: view?.subtitle ?? '',
        price: view?.price ?? product.sellingPrice,
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.sent
              ? assignment.alreadyLabelled
                    ? 'Label ${entry.number} sent to the printer again'
                    : 'Label ${entry.number} assigned and sent to the printer'
              // The number is assigned either way: reassigning after a failed
              // print would burn a second one.
              : '${result.error!} — the label is still ${entry.number}',
        ),
      ),
    );
  }
}

/// Owns its controllers, because the dialog's widgets keep rebuilding while
/// the route animates out.
class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.kind, required this.onShelf});

  final StockMoveKind kind;
  final int onShelf;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(kStockMoveLabels[widget.kind]!),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('move-quantity'),
          controller: _quantity,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.howMany,
            helperText: '${widget.onShelf} on the shelf now',
          ),
        ),
        TextField(
          key: const Key('move-reason'),
          controller: _reason,
          decoration: InputDecoration(
            labelText: context.l10n.why,
            // "Why is the count three" has no answer if the lines in the
            // history do not say.
            helperText: context.l10n.requiredGoesInHistory,
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
          StockMovement(
            kind: widget.kind,
            // Left to the movement rules to refuse: a blank quantity is
            // zero, and zero comes back with a message rather than being
            // swallowed here.
            quantity: asAmount(_quantity.text).toInt(),
            reason: _reason.text.trim(),
          ),
        ),
        child: Text(context.l10n.record),
      ),
    ],
  );
}

class _StockTakeDialog extends StatefulWidget {
  const _StockTakeDialog({required this.recorded});

  final int recorded;

  @override
  State<_StockTakeDialog> createState() => _StockTakeDialogState();
}

class _StockTakeDialogState extends State<_StockTakeDialog> {
  late final _controller = TextEditingController(
    text: widget.recorded.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.stockTake),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recordedCount('${widget.recorded}')),
        const SizedBox(height: 8),
        TextField(
          key: const Key('stocktake-counted'),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.countedOnShelf,
            // The difference is recorded rather than the count being
            // overwritten, so the fact that it was ever wrong survives.
            helperText: context.l10n.differenceGoesInHistory,
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
        onPressed: () =>
            Navigator.of(context)
                .pop(int.tryParse(_controller.text.trim()) ?? -1),
        child: Text(context.l10n.correctIt),
      ),
    ],
  );
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
          if (entry.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.key.isNotEmpty)
                    SizedBox(
                      width: 150,
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
