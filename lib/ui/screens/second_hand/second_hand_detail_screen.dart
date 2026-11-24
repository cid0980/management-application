import 'package:flutter/material.dart';

import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nav.dart';

import '../../../data/label_repository.dart';
import '../../widgets/shop_ui.dart';
import '../../../domain/inventory/stock_list.dart';
import '../../widgets/print_errors.dart';
import '../../widgets/empty_state.dart';
import '../../../data/print_server.dart';
import '../../../data/second_hand_repository.dart';
import '../../../domain/inventory/purchase_costing.dart';
import '../../../domain/common/money.dart';
import '../../../domain/inventory/purchase_validation.dart';
import '../../../domain/inventory/second_hand_device.dart';
import '../../../domain/labels/label_target.dart';
import '../../theme/app_theme.dart';
import 'second_hand_form_sheet.dart';
import 'stock_badges.dart';
import '../../../l10n/l10n.dart';
import '../../../app/auth_state.dart';
import '../../../data/printing/documents.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../printing/print_sheet.dart';
import '../../widgets/margins.dart';
import '../sales/sale_form_sheet.dart';
import '../../../l10n/rule_messages.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/loading.dart';

/// ONE PURCHASE RECORD
///
/// What the shop owns, what it cost, what state it is in, and the three things
/// anyone does from here: move it on or off the bench, record it going out,
/// print the declaration.
///
/// The transitions are the repository's, not this screen's. The detail page,
/// the sale and a scan all have to agree about what selling a handset does, so
/// only one of them is allowed to decide.
class SecondHandDetailScreen extends StatelessWidget {
  const SecondHandDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SecondHandRepository>();
    final device = repo.byId(id);

    if (device == null) {
      if (repo.loading) {
        return LoadingWords(first: context.l10n.loadingRecord, record: true);
      }
      return EmptyState(
        icon: Icons.search_off,
        title: context.l10n.noSecondHandRecord(id),
        detail: context.l10n.deletedLabelNote,
      );
    }

    final computed = device.computedGrade;
    final declaration = validateDeclaration(device);

    final theme = Theme.of(context);
    final (Color soft, Color strong) = stateColours(context, device.status);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // The photos first: what the phone looks like settles most
          // questions at the counter before any number does.
          if (device.photos.any((p) => p.startsWith('http'))) ...[
            SizedBox(
              height: 132,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in device.photos)
                    if (p.startsWith('http'))
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            p,
                            width: 110,
                            height: 132,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 110,
                              color: AppTheme.page,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Who it is and whether it can go out — before any number.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: device.grade == null
                        ? Icon(Icons.smartphone, color: strong, size: 30)
                        : Text(
                            '${device.grade}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: strong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StateChip(status: device.status),
                            // How long it has sat here; amber after 30 days.
                            if (!device.isSold &&
                                daysInStock(device, DateTime.now()) != null)
                              StatusPill(
                                context.l10n.stockDays(
                                  daysInStock(device, DateTime.now())!,
                                ),
                                color: isStale(device, DateTime.now())
                                    ? context.shopColors.wait
                                    : context.shopColors.done,
                                soft: isStale(device, DateTime.now())
                                    ? context.shopColors.waitSoft
                                    : context.shopColors.doneSoft,
                                icon: Icons.schedule,
                              ),
                            if (device.labelNumber != null)
                              Text(
                                context.l10n.labelNamed(
                                  '${device.labelNumber}',
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // What to do with it, right under who it is — part of the page,
          // not a bar pinned over it.
          _Actions(device: device, declaration: declaration),
          const SizedBox(height: 12),
          _BatchCard(device: device, batch: batchOf(device, repo.devices)),
          _MoneyCard(device: device),
          _Block(Icons.smartphone_outlined, context.l10n.device, {
            context.l10n.brand: device.brand,
            context.l10n.model: device.model,
            if (device.ram.isNotEmpty) context.l10n.optionRam: device.ram,
            if (device.rom.isNotEmpty) context.l10n.optionRom: device.rom,
            // A record from before RAM and storage were asked apart.
            if (device.ram.isEmpty && device.rom.isEmpty)
              context.l10n.fieldVariant: device.variant,
            context.l10n.colour: device.colour,
            'IMEI': device.imei,
            if (device.imei2.isNotEmpty) context.l10n.imei2: device.imei2,
            if (device.serial.isNotEmpty) context.l10n.serial: device.serial,
          }),
          if (device.repairs.isNotEmpty)
            _Block(Icons.build_outlined, context.l10n.repairs, {
              for (final r in device.repairs) r.description: rupees(r.amount),
            }),
          _Block(Icons.fact_check_outlined, context.l10n.condition, {
            context.l10n.storedGrade: device.grade ?? context.l10n.notGraded,
            if (device.batteryHealth != null)
              context.l10n.batteryHealthLabel.replaceAll(' %', ''): context.l10n
                  .batteryHealthValue(device.batteryHealth!),
            context.l10n.fromTheChecklist: computed.grade,
            if (device.gradeOverridden)
              context.l10n.setByHand: context.l10n.yes,
            context.l10n.checklistTitle: computed.faults.isEmpty
                ? context.l10n.noFaults
                : context.l10n.faultsFound(computed.faults.join(', ')),
            for (final e in device.gradeDetails.entries)
              switch (e.key) {
                kWarrantyExpiry => context.l10n.warrantyExpiry,
                kAccessories => context.l10n.accessoriesIncluded,
                _ => context.l10n.notesFeatures,
              }: e.value,
          }),
          _Block(Icons.person_outline, context.l10n.seller, {
            context.l10n.name: device.sellerName,
            context.l10n.shopPhone: device.sellerPhone,
            if (device.sellerAltPhone.isNotEmpty)
              context.l10n.fieldAltPhone: device.sellerAltPhone,
            if (device.supplier.isNotEmpty)
              context.l10n.fieldSupplier: device.supplier,
            if (device.purchasedAt != null)
              context.l10n.purchaseDate: MaterialLocalizations.of(context)
                  .formatMediumDate(device.purchasedAt!),
            context.l10n.idProof: device.sellerIdProof.isEmpty
                ? context.l10n.notRecorded
                : device.sellerIdProof,
            context.l10n.signed: (device.sellerSignature ?? '').isEmpty
                ? context.l10n.no
                : context.l10n.yes,
          }),
          if (device.notes.isNotEmpty)
            _Block(Icons.notes, context.l10n.notes, {'': device.notes}),
        ],
      ),
    );
  }
}

/// The money, with the answer first: what it sells for and what the shop
/// makes. The working sits underneath for whoever wants to check it.
class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.device});

  final SecondHandDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final costing = device.costing;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final realised = costing.realisedProfit;

    Widget line(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: muted)),
          Text(value, style: style ?? theme.textTheme.bodyMedium),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.isSold
                  ? context.l10n.soldPrice
                  : context.l10n.fieldAskingPrice,
              style: muted,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    rupees(
                      device.isSold ? device.soldPrice : costing.askingPrice,
                    ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Null, not zero: a handset still on the shelf has made
                // nothing yet, so it shows what it is expected to make.
                if (canSeeMargins(context))
                  ProfitPill(profit: realised ?? costing.expectedProfit),
              ],
            ),
            if (canSeeMargins(context)) ...[
              const Divider(height: 24),
              line(context.l10n.paidToSeller, rupees(costing.purchasePrice)),
              line(context.l10n.repairs, rupees(costing.repairTotal)),
              line(context.l10n.otherCosts, rupees(costing.otherCost)),
              line(
                context.l10n.totalCost,
                rupees(costing.totalCost),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.device, required this.declaration});

  final SecondHandDevice device;
  final ValidationResult declaration;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SecondHandRepository>();

    final colours = context.shopColors;

    // Secondary actions as equal tiles, two to a row: easier to hit, and the
    // icon carries the meaning for someone who reads slowly.
    final tiles = <_Tile>[
      if (!device.isSold) ...[
        _Tile(
          icon: Icons.edit_outlined,
          label: context.l10n.edit,
          onTap: () => openPurchaseSheet(context, existing: device),
        ),
        _Tile(
          icon: device.isBeingRepaired
              ? Icons.check_circle_outline
              : Icons.build_outlined,
          label: device.isBeingRepaired
              ? context.l10n.repairFinished
              : context.l10n.sendToTheBench,
          onTap: () => _run(
            context,
            () => repo.setRepairing(
              device.id,
              repairing: !device.isBeingRepaired,
            ),
            device.isBeingRepaired
                ? context.l10n.backOnTheShelf
                : context.l10n.movedToTheBench,
          ),
        ),
      ],
      // Through the registry, which is the only thing that mints a number.
      // This screen cannot invent one.
      // A sold phone gets no new sticker (FM #36); one it already has can
      // still be printed again.
      if (!device.isSold || device.labelNumber != null)
        _Tile(
          icon: Icons.qr_code_2,
          label: device.labelNumber == null
              ? context.l10n.assignAndPrintLabel
              : context.l10n.reprintLabel('${device.labelNumber}'),
          onTap: () => _label(context),
        ),
      _Tile(
        icon: Icons.print_outlined,
        label: context.l10n.printDeclaration,
        // Printing is offered either way: the message explains what is
        // missing, which is more use than a disabled button.
        onTap: () {
          if (!declaration.isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ruleText(context, declaration.errors.values.first),
                ),
              ),
            );
            return;
          }
          // In English on paper, whatever the app's language: the print font
          // has no Tamil or Hindi letters.
          final en = AppLocalizationsEn();
          showPrintSheet(
            context,
            title: context.l10n.printDeclarationTitle,
            fileName: 'declaration-${device.id}',
            build: (shop, _) => buildPurchaseDeclarationPdf(
              device: device,
              // Every phone bought from this seller in the same go.
              batch: batchOf(
                device,
                context.read<SecondHandRepository>().devices,
              ),
              shop: shop,
              staffName: context.read<AuthState>().user?.name ?? '',
              terms: [
                en.purchaseTerm1,
                en.purchaseTerm2,
                en.purchaseTerm3,
                en.purchaseTerm4,
                en.purchaseTerm5,
                en.purchaseTerm6,
                en.purchaseTerm7,
                en.purchaseTerm8,
                en.purchaseTerm9,
              ],
            ),
          );
        },
      ),
    ];

    // tiles: [edit, bench, label, declaration] — or [label, declaration]
    // once sold.
    final main = device.isSold ? [tiles[0]] : [tiles[1], tiles[2]];
    final more = device.isSold ? [tiles[1]] : [tiles[0], tiles[3]];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: SizedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selling makes a bill, with this handset already on it: the
              // bill is what puts the money in today's takings, records who
              // bought it and how they paid, and marks it sold. "Mark sold"
              // used to be the only button here and did none of that.
              if (!device.isSold && device.stockState == 'available') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('sell-make-bill'),
                    // Green: this is money coming in.
                    style: FilledButton.styleFrom(
                      backgroundColor: colours.good,
                      foregroundColor: colours.onGood,
                    ),
                    onPressed: () => openSaleSheet(
                      context,
                      initialItems: [handsetLine(device)],
                    ),
                    icon: const Icon(Icons.point_of_sale_outlined),
                    label: Text(context.l10n.sellMakeBill),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // The two things done most with a phone on the shelf, as two
              // clear buttons; the rest as quiet links under them.
              Row(
                children: [
                  for (final (i, t) in main.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: t.onTap,
                        icon: Icon(t.icon, size: 20),
                        label: Text(
                          t.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final t in more)
                    TextButton.icon(
                      onPressed: t.onTap,
                      icon: Icon(t.icon, size: 18),
                      label: Text(t.label),
                    ),
                  // Sold some other way — to a dealer, at a mela — with no
                  // bill from this shop. Kept, but last and plainly named.
                  if (!device.isSold)
                    TextButton(
                      key: const Key('sold-without-bill'),
                      onPressed: () => _markSold(context, repo),
                      child: Text(context.l10n.soldWithoutBill),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markSold(
    BuildContext context,
    SecondHandRepository repo,
  ) async {
    final price = await showInputSheet<num>(
      context: context,
      builder: (_) => _SoldPriceDialog(askingPrice: device.askingPrice),
    );
    if (price == null || !context.mounted) return;
    await _run(
      context,
      () => repo.markSold(device.id, soldPrice: price),
      context.l10n.markedSold,
    );
  }

  /// Assign a label, or print the one this handset already has again.
  ///
  /// A record that already has a label keeps its number: a second number for
  /// one handset is a second sticker that resolves somewhere the first did
  /// not. So this either assigns or reprints, never both.
  /// "Printing…" over the screen while the label goes out.
  Future<void> _label(BuildContext context) =>
      whileBusy(context, _sendLabel(context), label: context.l10n.printingNow);

  Future<void> _sendLabel(BuildContext context) async {
    final labels = context.read<LabelRepository>();
    final printer = context.read<PrintServer>();
    final messenger = ScaffoldMessenger.of(context);

    final assignment = await labels.assign(
      LabelTargetKind.secondHand,
      device.id,
    );
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
        title: view?.title ?? device.title,
        subtitle: view?.subtitle ?? '',
        price: view?.price ?? device.askingPrice,
      ),
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.sent
              ? assignment.alreadyLabelled
                    ? 'Label ${entry.number} sent to the printer again'
                    : 'Label ${entry.number} assigned and sent to the printer'
              // The number is assigned either way: a failed print is not a failed
              // assignment, and reassigning would burn a second number.
              : '${printErrorText(printL10n, result.error!)} — the label is still ${entry.number}',
        ),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on SoldDeviceLocked catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

/// The dialog owns its own controller.
///
/// It has to: the dialog's widgets keep rebuilding while the route animates
/// out, so a controller disposed by the caller the moment it pops is used
/// after being disposed.
class _SoldPriceDialog extends StatefulWidget {
  const _SoldPriceDialog({required this.askingPrice});

  final num askingPrice;

  @override
  State<_SoldPriceDialog> createState() => _SoldPriceDialogState();
}

class _SoldPriceDialogState extends State<_SoldPriceDialog> {
  late final _controller = TextEditingController(
    text: widget.askingPrice.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputSheet(
      title: Text(context.l10n.whatDidItGoOutAt),
      content: TextField(
        key: const Key('sold-price'),
        inputFormatters: moneyInput(),
        controller: _controller,
        keyboardType: moneyKeyboard,
        decoration: InputDecoration(labelText: context.l10n.soldPrice),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          // The asking price is only the default. What it actually went out at
          // is the figure Reports may use, so it is asked for every time.
          onPressed: () =>
              Navigator.of(context).pop(asAmount(_controller.text)),
          child: Text(context.l10n.markSold),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.icon, this.title, this.rows);

  final IconData icon;
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

/// The other phones bought from this seller at the same time, and a way to
/// buy one more from them.
class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.device, required this.batch});

  final SecondHandDevice device;
  final List<SecondHandDevice> batch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final others = [
      for (final d in batch)
        if (d.id != device.id) d,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        key: const Key('batch-card'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (others.isNotEmpty) ...[
                Text(
                  l10n.boughtTogether,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.boughtTogetherCount(batch.length),
                  style: theme.textTheme.bodySmall,
                ),
                for (final d in others)
                  ListTile(
                    key: Key('batch-${d.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.smartphone),
                    title: Text(d.title),
                    subtitle: Text(rupees(d.purchasePrice)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, d),
                  ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('batch-add'),
                  onPressed: () =>
                      openPurchaseSheet(context, sameSellerAs: device),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(l10n.buyAnotherFromSeller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, SecondHandDevice d) {
    if (GoRouter.maybeOf(context) != null) {
      openPage(context, '/inventory/second-hand/${d.id}');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<SecondHandRepository>.value(
            value: context.read<SecondHandRepository>(),
            child: SecondHandDetailScreen(id: d.id),
          ),
        ),
      );
    }
  }
}
