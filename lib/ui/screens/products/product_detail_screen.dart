import 'package:flutter/material.dart';

import '../../widgets/photo_strip.dart';
import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';

import '../../widgets/record_refs.dart';

import '../../../data/label_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/print_errors.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../../data/print_server.dart';
import '../../../data/product_repository.dart';
import '../../../domain/labels/label_target.dart';
import '../../../domain/common/money.dart';
import '../../../domain/products/product.dart';
import '../../../domain/products/stock_level.dart';
import '../../../domain/products/stock_movement.dart';
import '../../../l10n/rule_messages.dart';
import 'product_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/margins.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/loading.dart';

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
      if (repo.loading) {
        return LoadingWords(first: context.l10n.loadingRecord, record: true);
      }
      return EmptyState(
        icon: Icons.search_off,
        title: context.l10n.noProduct(id),
        detail: context.l10n.deletedShelfLabelNote,
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
          PhotoStrip(
            keyPrefix: 'product-photo',
            photos: product.photos,
            slots: 2,
            onAdd: (url) =>
                repo.save(product.copyWith(photos: [...product.photos, url])),
          ),
          const SizedBox(height: 12),
          RecordTitleCard(
            title: product.title,
            pills: [
              _LevelPill(level: product.level),
              StatusPill(
                context.l10n.onShelfCount(product.stockCount.toInt()),
                color: AppTheme.primary,
                soft: AppTheme.surfaceSubtle,
                icon: Icons.inventory_2_outlined,
              ),
              if (product.labelNumber != null)
                StatusPill(
                  context.l10n.labelNamed('${product.labelNumber}'),
                  color: AppTheme.textSecondary,
                  soft: AppTheme.page,
                  icon: Icons.qr_code_2,
                ),
            ],
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
                              '${suggested != null && suggested > 0 ? ' · ${context.l10n.suggestedOrder} $suggested' : ''}',
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
            if (canSeeMargins(context))
              context.l10n.costPrice: rupees(product.costPrice),
            context.l10n.sellingPrice: rupees(product.sellingPrice),
            if (product.mrp > 0)
              context.l10n.printedMaximum: rupees(product.mrp),
            if (canSeeMargins(context))
              context.l10n.profitPerUnit: rupees(product.unitProfit),
            if (canSeeMargins(context))
              context.l10n.stockAtCost: rupees(product.stockCost),
            context.l10n.stockAtRetail: rupees(product.stockValue),
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
                title: Text(stockMoveLabel(context, move.kind)),
                subtitle: Text(
                  // "Sold on INV-…", not the bill's internal id (FM #32).
                  withRecordNumber(context, move.reason, move.reference),
                ),
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
    return ActionBar(
      key: const Key('product-actions'),
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
    );
  }

  Future<void> _move(BuildContext context, StockMoveKind kind) async {
    final repo = context.read<ProductRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final movement = await showInputSheet<StockMovement>(
      context: context,
      builder: (_) => _MovementDialog(kind: kind, onShelf: product.stockCount),
    );
    if (movement == null) {
      return;
    }

    if (!context.mounted) return;
    final result = await guardSave(
      context,
      () => repo.move(product.id, movement),
    );
    if (result == null) {
      return;
    }
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

    final counted = await showInputSheet<int>(
      context: context,
      builder: (_) => _StockTakeDialog(recorded: product.stockCount),
    );
    if (counted == null) {
      return;
    }

    if (!context.mounted) return;
    final result = await guardSave(
      context,
      () => repo.stockTake(
        product.id,
        counted: counted,
        reason: 'Counted $counted on the shelf',
      ),
    );
    if (result == null) {
      return;
    }
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
  /// "Printing…" over the screen while the label goes out.
  Future<void> _label(BuildContext context) =>
      whileBusy(context, _sendLabel(context), label: context.l10n.printingNow);

  Future<void> _sendLabel(BuildContext context) async {
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
    if (!context.mounted) return;
    final printL10n = context.l10n;
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
              : '${printErrorText(printL10n, result.error!)} — the label is still ${entry.number}',
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

  /// The stock rules' answer, said in the sheet with what was typed kept
  /// (FM #52), against the field it is about.
  String? _quantityError;
  String? _reasonError;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(stockMoveLabel(context, widget.kind)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('move-quantity'),
          inputFormatters: wholeNumberInput(maxDigits: 5),
          controller: _quantity,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.howMany,
            helperText: context.l10n.onShelfCount(widget.onShelf),
            errorText: _quantityError,
          ),
          onChanged: (_) => setState(() => _quantityError = null),
        ),
        TextField(
          key: const Key('move-reason'),
          controller: _reason,
          decoration: InputDecoration(
            labelText: context.l10n.why,
            // "Why is the count three" has no answer if the lines in the
            // history do not say.
            helperText: context.l10n.requiredGoesInHistory,
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
        key: const Key('move-confirm'),
        onPressed: () {
          final move = StockMovement(
            kind: widget.kind,
            quantity: int.tryParse(_quantity.text.trim()) ?? 0,
            reason: _reason.text.trim(),
          );
          // The same rules the store applies, asked before closing.
          final check = applyStockMove(widget.onShelf, move);
          if (!check.allowed) {
            final said = ruleText(
              context,
              kStockRefusalMessages[check.refusal]!,
            );
            setState(() {
              if (check.refusal == StockRefusal.noReason) {
                _reasonError = said;
              } else {
                _quantityError = said;
              }
            });
            return;
          }
          Navigator.of(context).pop(move);
        },
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
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(context.l10n.stockTake),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recordedCount('${widget.recorded}')),
        const SizedBox(height: 8),
        TextField(
          key: const Key('stocktake-counted'),
          inputFormatters: wholeNumberInput(maxDigits: 5),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.countedOnShelf,
            // The difference is recorded rather than the count being
            // overwritten, so the fact that it was ever wrong survives.
            helperText: context.l10n.differenceGoesInHistory,
            errorText: _error,
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        key: const Key('stocktake-confirm'),
        onPressed: () {
          final counted = int.tryParse(_controller.text.trim());
          // 0 is a real count (the shelf is empty); nothing typed is not.
          if (counted == null) {
            setState(() => _error = context.l10n.stocktakeTypeCount);
            return;
          }
          Navigator.of(context).pop(counted);
        },
        child: Text(context.l10n.correctIt),
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

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final StockLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.shopColors;
    final (Color fg, Color soft) = switch (level) {
      StockLevel.outOfStock => (c.stop, c.stopSoft),
      StockLevel.low => (c.wait, c.waitSoft),
      StockLevel.inStock => (c.good, c.goodSoft),
    };
    return StatusPill(stockLevelLabel(context, level), color: fg, soft: soft);
  }
}
