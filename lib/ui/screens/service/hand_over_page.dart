import 'package:flutter/material.dart';

import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';

import '../../../data/service_repository.dart';
import '../../../domain/common/money.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/service/checklist.dart';
import '../../../domain/service/service_order.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/value_labels.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/save_guard.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shop_ui.dart';

/// Opens the hand-over page for [orderId] over the whole app.
///
/// Answers true when the phone was handed back.
Future<bool> openHandOver(BuildContext context, String orderId) async {
  final repo = context.read<ServiceRepository>();
  final done = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<ServiceRepository>.value(
        value: repo,
        child: HandOverPage(orderId: orderId),
      ),
    ),
  );
  return done == true;
}

/// HANDING THE PHONE BACK — ITS OWN PAGE
///
/// The checklist used to sit at the very bottom of the repair page, under
/// the money and the dates, where nobody found it; "Hand the phone back"
/// then refused with a list of what was unticked. Now the button opens this
/// page, which is the whole hand-over in the order it happens at the
/// counter:
///
/// 1. **Check the phone** — every pre-delivery check, big rows, a count.
/// 2. **What they pay** — the price (the estimate filled in), the advance
///    already taken, and what is left to collect.
/// 3. **How they paid** — Cash, UPI or card, when anything is left to pay.
///
/// One button at the bottom. Pressed with something missed, it scrolls to
/// the first unticked check (or the price) and marks it red, rather than
/// refusing from a distance.
class HandOverPage extends StatefulWidget {
  const HandOverPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<HandOverPage> createState() => _HandOverPageState();
}

class _HandOverPageState extends State<HandOverPage> {
  late final TextEditingController _price;
  String _method = 'Cash';
  bool _showMissing = false;
  bool _priceMissing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final order = context.read<ServiceRepository>().byId(widget.orderId);
    final p = order?.finalPrice ?? order?.estimatedPrice ?? 0;
    // A charge below zero (set before the rule existed) is not offered.
    _price = TextEditingController(text: p <= 0 ? '' : '$p');
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _handOver(
    ServiceOrder order,
    List<ChecklistEntry> entries,
  ) async {
    final repo = context.read<ServiceRepository>();
    final navigator = Navigator.of(context);
    final unticked = [
      for (final e in entries)
        if (order.checklist[e.key] != true) e,
    ];
    final priceText = _price.text.trim();
    setState(() {
      _showMissing = unticked.isNotEmpty;
      _priceMissing = priceText.isEmpty;
    });
    if (unticked.isNotEmpty) {
      await jumpToFirstError(context, [
        for (final e in unticked) Key('handover-${e.key}'),
      ]);
      return;
    }
    if (priceText.isEmpty) {
      await jumpToFirstError(context, const [Key('handover-price')]);
      return;
    }
    final price = asAmount(priceText);
    setState(() => _busy = true);
    final result = await guardSave(context, () async {
      if (order.finalPrice != price) {
        await repo.setFinalPrice(order.id, price);
      }
      return repo.complete(order.id, method: _method);
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != null && result.allowed) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repo = context.watch<ServiceRepository>();
    final order = repo.byId(widget.orderId);
    final entries = checklistEntries(repo.checklistItems);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.handThePhoneBack)));
    }
    final ticked = entries.where((e) => order.checklist[e.key] == true).length;
    final allTicked = ticked == entries.length;
    final price = asAmount(_price.text);
    final toCollect = (price - order.advancePaid) < 0
        ? 0
        : price - order.advancePaid;
    // More was taken in advance than the charge: the difference goes back.
    final giveBack = order.advancePaid > price ? order.advancePaid - price : 0;
    final error = theme.colorScheme.error;

    Widget step(int n, String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$n',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?trailing,
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('form-close'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(l10n.handThePhoneBack),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Which phone, and whose.
          Card(
            child: ListTile(
              leading: const Icon(Icons.smartphone),
              title: Text(
                order.device.isEmpty ? order.orderNumber : order.device,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                [
                  order.orderNumber,
                  if (order.customerName.isNotEmpty) order.customerName,
                  if (order.customerPhone.isNotEmpty) order.customerPhone,
                ].join(' · '),
              ),
            ),
          ),

          step(
            1,
            l10n.handOverCheck,
            trailing: Text(
              l10n.checksTicked(ticked, entries.length),
              key: const Key('handover-count'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: allTicked ? context.shopColors.good : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LinearProgressIndicator(
                value: ticked / entries.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Text(l10n.noChecklistConfigured, style: theme.textTheme.bodySmall)
          else
            Card(
              child: Column(
                children: [
                  for (final e in entries)
                    _CheckRow(
                      key: Key('handover-${e.key}'),
                      label: shopValue(context, e.item),
                      ticked: order.checklist[e.key] == true,
                      missing: _showMissing && order.checklist[e.key] != true,
                      onChanged: (v) =>
                          repo.setCheck(order.id, e.key, ticked: v),
                    ),
                ],
              ),
            ),
          if (_showMissing && !allTicked)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(
                l10n.handOverChecksLeft(entries.length - ticked),
                style: TextStyle(color: error, fontWeight: FontWeight.w600),
              ),
            ),

          step(2, l10n.handOverPay),
          TextField(
            key: const Key('handover-price'),
            controller: _price,
            keyboardType: moneyKeyboard,
            inputFormatters: moneyInput(),
            style: theme.textTheme.headlineSmall,
            onChanged: (_) => setState(() => _priceMissing = false),
            decoration: InputDecoration(
              label: FieldLabel(l10n.finalPrice, required: true),
              prefixText: '₹ ',
              border: const OutlineInputBorder(),
              helperText: l10n.zeroIsAllowed,
              errorText: _priceMissing ? l10n.handOverNeedPrice : null,
            ),
          ),
          const SizedBox(height: 8),
          if (order.advancePaid > 0)
            _MoneyLine(l10n.advancePaid, '- ${rupees(order.advancePaid)}'),
          if (giveBack > 0)
            _MoneyLine(
              l10n.changeGiveBack,
              rupees(giveBack),
              key: const Key('handover-give-back'),
              bold: true,
            )
          else
            _MoneyLine(
              l10n.handOverToCollect,
              rupees(toCollect),
              key: const Key('handover-to-collect'),
              bold: true,
            ),

          if (toCollect > 0) ...[
            step(3, l10n.handOverHowPaid),
            ChoiceRow<String>(
              key: const Key('handover-method'),
              values: const ['Cash', 'UPI', 'Card'],
              selected: _method,
              labelOf: (m) => m,
              keyOf: (m) => Key('handover-pay-$m'),
              onPicked: (m) => setState(() => _method = m),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              key: const Key('handover-confirm'),
              // Never greyed out: pressed with something missed, it goes
              // to it.
              onPressed: _busy ? null : () => _handOver(order, entries),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                allTicked
                    ? (toCollect > 0
                          ? l10n.handOverAndCollect(rupees(toCollect))
                          : l10n.handOverButton)
                    : l10n.handOverChecksLeft(entries.length - ticked),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One check: a big row, the whole width taps it. Red when it was missed.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    super.key,
    required this.label,
    required this.ticked,
    required this.missing,
    required this.onChanged,
  });

  final String label;
  final bool ticked;
  final bool missing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return CheckboxListTile(
      value: ticked,
      onChanged: (v) => onChanged(v == true),
      controlAffinity: ListTileControlAffinity.leading,
      tileColor: missing ? error.withValues(alpha: 0.07) : null,
      side: missing ? BorderSide(color: error, width: 2) : null,
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: missing ? error : null,
          decoration: ticked ? TextDecoration.lineThrough : null,
          decorationColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
