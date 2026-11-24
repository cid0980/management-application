import 'package:flutter/material.dart';

import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';

import '../../../app/nav.dart';

import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/auth_state.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';
import '../../../data/service_repository.dart';
import '../../../domain/products/stock_movement.dart';
import '../../../domain/common/money.dart';
import '../../../domain/products/product.dart';
import '../../../data/product_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/service/checklist.dart';
import '../../../domain/service/order_state.dart';
import '../../../domain/service/order_validation.dart';
import '../../../domain/service/service_order.dart';
import 'hand_over_page.dart';
import 'service_form_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../../data/printing/documents.dart';
import '../../../data/settings_repository.dart';
import '../../printing/print_sheet.dart';
import '../../widgets/contact_buttons.dart';
import '../ratings/rating_button.dart';
import '../../widgets/margins.dart';
import '../../../l10n/rule_messages.dart';
import '../../../domain/common/contact_links.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/loading.dart';

/// ONE JOB ON THE BENCH
///
/// The page where the two rules that matter actually meet somebody:
///
/// - **the status dropdown cannot say 'Completed'.** It is not hidden or
///   disabled — it is not in the list, because `statusOptionsFor` does not
///   return it for anyone, of any role.
/// - **'Hand the phone back' runs the pre-delivery checklist.** When it is
///   blocked the page names what is still unticked, rather than saying the
///   list is incomplete.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ServiceRepository>();
    final order = repo.byId(id);

    if (order == null) {
      // Loading is not "gone": say which.
      if (repo.loading) {
        return LoadingWords(first: context.l10n.loadingRecord);
      }
      // Older than the live list keeps: ask the server before saying it
      // is gone.
      return FetchingRecord(
        fetch: () => repo.fetchById(id),
        notFound: EmptyState(
          icon: Icons.search_off,
          title: context.l10n.noServiceOrder(id),
          detail: context.l10n.deletedJobCardNote,
        ),
      );
    }

    final isAdmin = context.watch<AuthState>().isAdmin;
    final now = DateTime.now();
    final items = repo.checklistItems;
    final check = canComplete(order, checklistItems: items);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(order: order, now: now),
          const SizedBox(height: 12),
          _StatusPicker(order: order, isAdmin: isAdmin),
          // Near the top, where it is seen: how far the checks are, and the
          // way into the hand-over page.
          _ChecklistCard(order: order, items: items, check: check),
          _VisitCard(order: order, visit: visitOf(order, repo.orders)),
          const SizedBox(height: 4),
          _Block(context.l10n.device, {
            context.l10n.brand: order.brand,
            context.l10n.model: order.model,
            'IMEI': order.imei.isEmpty ? context.l10n.notRecorded : order.imei,
            context.l10n.lock: order.lockType,
            if (order.lockValue.isNotEmpty)
              context.l10n.unlockWith: order.lockValue,
            context.l10n.leftWithIt: order.accessories.isEmpty
                ? context.l10n.nothingValue
                : order.accessories.join(', '),
          }),
          _Block(context.l10n.complaints, {
            // The job card and the final bill are both built from these.
            for (final c in order.complaints) c: ' ',
            if (order.complaintNotes.isNotEmpty)
              context.l10n.notes: order.complaintNotes,
          }),
          _Block(context.l10n.money, {
            context.l10n.estimateQuoted: rupees(order.estimatedPrice),
            if (order.advancePaid > 0)
              context.l10n.advancePaid: rupees(order.advancePaid),
            if (order.advancePaid > 0)
              context.l10n.toCollect: rupees(order.toCollect),
            if (canSeeMargins(context)) ...{
              context.l10n.rawMaterial: rupees(order.rawMaterialCost),
              context.l10n.outsideLabour: rupees(order.outsideLabourCost),
              for (final p in order.partsUsed)
                '${p.name}${p.quantity > 1 ? ' × ${p.quantity}' : ''}': rupees(
                  p.unitCost * p.quantity,
                ),
              context.l10n.costs: rupees(order.costs),
              context.l10n.profitAtEstimate: rupees(order.estimatedProfit),
            },
            // Null, not zero, until it is charged.
            context.l10n.charged: order.finalPrice == null
                ? context.l10n.notChargedYet
                : rupees(order.finalPrice),
            if (canSeeMargins(context))
              context.l10n.profitMade: order.realisedProfit == null
                  ? context.l10n.notChargedYet
                  : rupees(order.realisedProfit),
          }),
          _Block(context.l10n.schedule, {
            context.l10n.cameIn: _date(order.receivedAt),
            context.l10n.promised: _date(order.expectedCompletionAt),
            if (order.completedAt != null)
              context.l10n.handedBack: _date(order.completedAt),
            if (order.pickupPayment != null)
              context.l10n.paidAtPickup:
                  '${rupees(order.pickupPayment!.amount)} · '
                  '${order.pickupPayment!.method}',
            if (order.warrantyUntil != null)
              context.l10n.repairWarranty: order.underWarrantyAt(DateTime.now())
                  ? context.l10n.warrantyUntil(
                      _date(order.warrantyUntil).split(' ').first,
                    )
                  : context.l10n.warrantyEnded(
                      _date(order.warrantyUntil).split(' ').first,
                    ),
            context.l10n.technician: order.technician.isEmpty
                ? context.l10n.nobodyYet
                : order.technician,
          }),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _Actions(order: order, check: check),
    );
  }

  static String _date(DateTime? d) {
    if (d == null) return 'not set';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

/// The allowed status changes, and nothing else.
///
/// 'Completed' is absent from this list for every role: the checklist is the
/// door. 'Received' is absent for staff, because an order past it has been
/// looked at and saying otherwise hides work already done — an admin may put
/// it back.
/// What to tell the customer, for where their phone is now — in the shop's
/// language, signed with the shop's own name.
String serviceCustomerMessage(BuildContext context, ServiceOrder order) {
  final l10n = context.l10n;
  final shop = shopNameOf(context);
  final name = order.customerName;
  final device = order.device;
  final no = order.orderNumber;
  return switch (order.status) {
    'In Progress' => l10n.waServiceInProgress(name, device, no, shop),
    'Parts Awaiting' => l10n.waServiceParts(name, device, no, shop),
    'Awaiting Customer Approval' => l10n.waServiceApproval(
      name,
      device,
      no,
      shop,
    ),
    // Ready says so and names what to bring; once it is handed back the
    // message is a thank-you, not "please collect".
    'Ready' =>
      order.toCollect > 0
          ? l10n.waServiceReadyPay(
              name,
              device,
              no,
              formatIndianNumber(order.toCollect),
              shop,
            )
          : l10n.waServiceReady(name, device, no, shop),
    'Completed' => l10n.waServiceReturned(name, device, no, shop),
    'Returned' => l10n.waServiceReturned(name, device, no, shop),
    _ => l10n.waServiceReceived(name, device, no, shop),
  };
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.order, required this.isAdmin});

  final ServiceOrder order;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    if (order.closed) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Track(step: 3),
              const SizedBox(height: 10),
              Text(
                context.l10n.handedBackOn(
                  ServiceDetailScreen._date(order.completedAt),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Returned has its own button below, which asks why and records when.
    // As a chip here it closed the job with neither.
    final options = statusOptionsFor(
      order.status,
      isAdmin: isAdmin,
    ).where((s) => s != 'Returned').toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.whereIsItNow,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _Track(step: trackStepOf(order.status)),
            const SizedBox(height: 14),
            // The usual next step as one big button: the work is done, so
            // say so — marking Ready offers the WhatsApp to the customer.
            if (!isReady(order.status) && options.contains(kReadyStatus)) ...[
              FilledButton.icon(
                key: const Key('mark-ready'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.shopColors.good,
                  foregroundColor: context.shopColors.onGood,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _set(context, kReadyStatus),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n.markReady),
              ),
              const SizedBox(height: 10),
            ],
            // Every step by name, for the ones between: waiting for parts,
            // waiting for the customer to say yes.
            Text(
              context.l10n.status,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            // One sideways row, not a block of three lines.
            ChoiceRow<String>(
              key: const Key('repair-status'),
              values: options,
              selected: order.status,
              labelOf: (s) => serviceStatusLabel(context, s),
              keyOf: (s) => Key('status-$s'),
              onPicked: (s) => _set(context, s),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.completedIsNotHere,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _set(BuildContext context, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ServiceRepository>().setStatus(
        order.id,
        status,
        isAdmin: isAdmin,
      );
      if (!context.mounted) return;
      // Ready is the moment the customer wants to hear about: offer the
      // message right here, already written with what there is to pay.
      final wa = status == kReadyStatus
          ? whatsAppUri(
              order.customerPhone,
              serviceCustomerMessage(context, order.copyWith(status: status)),
            )
          : null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.statusNamed(serviceStatusLabel(context, status)),
          ),
          action: wa == null
              ? null
              : SnackBarAction(
                  label: context.l10n.tellTheCustomer,
                  onPressed: () =>
                      launchUrl(wa, mode: LaunchMode.externalApplication),
                ),
        ),
      );
    } on StatusNotAllowed catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

/// THE PRE-DELIVERY CHECKLIST
///
/// Labels come from settings; the keys are derived once for the whole list by
/// `checklistEntries`, which resolves collisions. That is why "Display OK" and
/// "Display: OK!" cannot share a checkbox — ticking one used to visibly untick
/// the other, and the order could be saved claiming a check nobody had done.
/// The other phones the customer brought in with this one, and a way to
/// add one more to the same visit.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.order, required this.visit});

  final ServiceOrder order;
  final List<ServiceOrder> visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final others = [
      for (final o in visit)
        if (o.id != order.id) o,
    ];
    // A lone, closed job has nothing to show or add.
    if (others.isEmpty && order.closed) return const SizedBox.shrink();
    return Card(
      key: const Key('visit-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (others.isNotEmpty) ...[
              Text(
                l10n.visitPhones,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.visitPhoneCount(visit.length),
                style: theme.textTheme.bodySmall,
              ),
              for (final o in others)
                ListTile(
                  key: Key('visit-${o.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smartphone),
                  title: Text(o.device.isEmpty ? o.orderNumber : o.device),
                  subtitle: Text(
                    '${o.orderNumber} · ${serviceStatusLabel(context, o.status)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openOther(context, o),
                ),
            ],
            if (!order.closed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('visit-add'),
                  onPressed: () =>
                      openServiceSheet(context, sameVisitAs: order),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(l10n.visitAddPhone),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Over this page where there is a router; a plain push in a test.
  void _openOther(BuildContext context, ServiceOrder o) {
    if (GoRouter.maybeOf(context) != null) {
      openPage(context, '/service/${o.id}');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<ServiceRepository>.value(
            value: context.read<ServiceRepository>(),
            child: ServiceDetailScreen(id: o.id),
          ),
        ),
      );
    }
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.order,
    required this.items,
    required this.check,
  });

  final ServiceOrder order;
  final List<String> items;
  final CompletionCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final entries = checklistEntries(items);
    final ticked = entries.length - check.remaining.length;
    final all = entries.isNotEmpty && ticked == entries.length;
    final colors = context.shopColors;
    return Card(
      key: const Key('handover-card'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Closed: nothing left to tick, the card only says it was done.
        onTap: order.closed ? null : () => _openHandOver(context, order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                all ? Icons.verified_outlined : Icons.checklist,
                color: all ? colors.good : theme.colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.handOverCard,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entries.isEmpty
                          ? l10n.noChecklistConfigured
                          : l10n.checksTicked(ticked, entries.length),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ticked / entries.length,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ],
                ),
              ),
              if (!order.closed) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The hand-over page, and what it means when it comes back done.
Future<void> _openHandOver(BuildContext context, ServiceOrder order) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final done = await openHandOver(context, order.id);
  if (done) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.handedBackPrintBill)));
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.check});

  final ServiceOrder order;
  final CompletionCheck check;

  @override
  Widget build(BuildContext context) {
    return ActionBar(
      key: const Key('repair-actions'),
      children: [
        if (!order.closed) ...[
          OutlinedButton.icon(
            onPressed: () => openServiceSheet(context, existing: order),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.l10n.edit),
          ),
          OutlinedButton.icon(
            onPressed: () => _charge(context),
            icon: const Icon(Icons.currency_rupee),
            label: Text(
              order.finalPrice == null
                  ? context.l10n.setWhatIsCharged
                  : context.l10n.chargedAmount(
                      formatIndianNumber(order.finalPrice!),
                    ),
            ),
          ),
          FilledButton.icon(
            key: const Key('hand-back'),
            // Opens the hand-over page: checks, price, how they paid.
            onPressed: () => _openHandOver(context, order),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.l10n.handThePhoneBack),
          ),
          OutlinedButton.icon(
            onPressed: () => _returnUnrepaired(context),
            icon: const Icon(Icons.undo),
            label: Text(context.l10n.returnedUnrepaired),
          ),
          OutlinedButton.icon(
            key: const Key('use-part'),
            onPressed: () => _usePart(context),
            icon: const Icon(Icons.memory),
            label: Text(context.l10n.usePartFromStock),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            final result = validateJobCard(order);
            if (!result.isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ruleText(context, result.errors.values.first)),
                ),
              );
              return;
            }
            final checklist = context
                .read<SettingsRepository>()
                .settings
                .preDeliveryChecklist
                .values;
            showPrintSheet(
              context,
              title: order.closed
                  ? context.l10n.printFinalBillTitle
                  : context.l10n.printJobCardTitle,
              fileName: order.closed
                  ? 'final-bill-${order.orderNumber}'
                  : 'job-card-${order.orderNumber}',
              // The PIN or pattern is the customer's to share, so it is
              // asked about, and off unless someone turns it on.
              offerLockChoice: !order.closed,
              // Every phone in the visit on one print: the job cards one
              // after another, and the phones handed back on one bill.
              build: (shop, includeLock) {
                final visit = visitOf(
                  order,
                  context.read<ServiceRepository>().orders,
                );
                final handedBack = [
                  for (final o in visit)
                    if (o.closed) o,
                ];
                return order.closed
                    ? handedBack.length > 1
                          ? buildVisitFinalBillPdf(
                              orders: handedBack,
                              shop: shop,
                            )
                          : buildFinalBillPdf(order: order, shop: shop)
                    : buildJobCardPdf(
                        order: order,
                        shop: shop,
                        checklist: checklist,
                        includeLock: includeLock,
                        visit: visit,
                      );
              },
            );
          },
          icon: const Icon(Icons.print_outlined),
          label: Text(
            order.closed
                ? context.l10n.printFinalBill
                : context.l10n.printJobCard,
          ),
        ),
        if (order.closed) RatingButton(order: order),
      ],
    );
  }

  /// A part from the shop's stock fitted on this job: off the shelf with a
  /// "used on a repair" movement that names the job, then onto the job at
  /// today's cost price. Stock first — if the shelf is empty the job is
  /// left as it was.
  Future<void> _usePart(BuildContext context) async {
    final products = _maybeProducts(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (products == null) {
      return;
    }
    final inStock = products.products.where((p) => p.stockCount > 0).toList();
    if (inStock.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noPartsInStock)));
      return;
    }
    final repo = context.read<ServiceRepository>();
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PartPicker(products: inStock),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final moved = await whileBusy(
      context,
      products.move(
        picked.id,
        StockMovement(
          kind: StockMoveKind.usedOnRepair,
          quantity: 1,
          reason: 'Used on ${order.orderNumber}',
          reference: order.id,
          at: DateTime.now(),
        ),
      ),
    );
    if (!moved.allowed) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(ruleText(context, moved.message!))),
      );
      return;
    }
    if (!context.mounted) return;
    if (!await guardRun(
      context,
      () => repo.addPart(
        order.id,
        PartUse(
          productId: picked.id,
          name: picked.title,
          quantity: 1,
          unitCost: picked.costPrice,
          at: DateTime.now(),
        ),
      ),
    )) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.partUsedSaved(picked.title))),
    );
  }

  static ProductRepository? _maybeProducts(BuildContext context) {
    try {
      return context.read<ProductRepository>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _charge(BuildContext context) async {
    final repo = context.read<ServiceRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final price = await showInputSheet<num>(
      context: context,
      builder: (_) => _ChargeDialog(
        // What was already set, or the estimate until something is.
        estimate: order.finalPrice ?? order.estimatedPrice,
      ),
    );
    if (price == null) {
      return;
    }
    if (!context.mounted) return;
    if (!await guardRun(context, () => repo.setFinalPrice(order.id, price))) {
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.chargingAmount(formatIndianNumber(price))),
      ),
    );
  }

  Future<void> _returnUnrepaired(BuildContext context) async {
    final repo = context.read<ServiceRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showInputSheet<String>(
      context: context,
      builder: (_) => const _ReturnDialog(),
    );
    if (reason == null) {
      return;
    }
    if (!context.mounted) return;
    if (!await guardRun(
      context,
      () => repo.markReturned(order.id, reason: reason),
    )) {
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.returnedToCustomer)),
    );
  }
}

/// Owns its controller, because the dialog's widgets keep rebuilding while the
/// route animates out.
class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog({required this.estimate});

  final num estimate;

  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  late final _controller = TextEditingController(
    text: widget.estimate == 0 ? '' : widget.estimate.toString(),
  );

  /// Shown under the box when Set is pressed with nothing in it. The sheet
  /// stays open with what was typed.
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(context.l10n.whatIsBeingCharged),
    content: TextField(
      key: const Key('charge-amount'),
      inputFormatters: moneyInput(),
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.l10n.finalPrice,
        // Zero is allowed and has to be said: a completed order with no
        // price is a phone handed back for free, which is sometimes true
        // and never implicit.
        helperText: context.l10n.zeroIsAllowed,
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
          // Empty is not zero: say "0" for a free repair.
          if (_controller.text.trim().isEmpty) {
            setState(() => _error = context.l10n.handOverNeedPrice);
            return;
          }
          Navigator.of(context).pop(asAmount(_controller.text));
        },
        child: Text(context.l10n.setButton),
      ),
    ],
  );
}

class _ReturnDialog extends StatefulWidget {
  const _ReturnDialog();

  @override
  State<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<_ReturnDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputSheet(
    title: Text(context.l10n.returnedWithoutRepair),
    content: TextField(
      key: const Key('return-reason'),
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.l10n.why,
        // No checklist here: there is nothing to verify on a phone nobody
        // worked on. The reason is what the record needs instead.
        helperText: context.l10n.goesOnTheRecord,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.returnIt),
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

/// "₹1300 to collect — how did they pay?" Cash, UPI or card, recorded with
/// the day so Reports can count it against the drawer or the bank. Null when
/// dismissed: nothing is handed back without saying how it was paid.
Future<String?> askPaymentMethod(BuildContext context, num amount) =>
    showInputSheet<String>(
      context: context,
      builder: (context) => PickSheet(
        title: Text(context.l10n.howPaidAmount(formatIndianNumber(amount))),
        children: [
          for (final (m, icon) in const [
            ('Cash', Icons.payments_outlined),
            ('UPI', Icons.qr_code_2),
            ('Card', Icons.credit_card),
          ])
            ListTile(
              key: Key('pay-$m'),
              leading: Icon(icon),
              title: Text(m, style: Theme.of(context).textTheme.titleMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
    );

/// Products with something on the shelf, searchable, one tap to pick.
class _PartPicker extends StatefulWidget {
  const _PartPicker({required this.products});

  final List<Product> products;

  @override
  State<_PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<_PartPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final rows = widget.products.where((p) => p.matches(_query)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('part-search'),
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.usePartFromStock,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final p in rows)
                  ListTile(
                    key: Key('part-${p.id}'),
                    title: Text(p.title),
                    subtitle: Text(
                      context.l10n.nowOnTheShelf('${p.stockCount}'),
                    ),
                    onTap: () => Navigator.of(context).pop(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The top of the job: where it stands, the phone, what is wrong with it,
/// and the customer with Call and WhatsApp.
class _Header extends StatelessWidget {
  const _Header({required this.order, required this.now});

  final ServiceOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final c = context.shopColors;
    final lifecycle = order.lifecycleAt(now);
    final (Color fg, Color soft) = switch (lifecycle) {
      OrderLifecycle.overdue => (c.stop, c.stopSoft),
      OrderLifecycle.closed => (c.done, c.doneSoft),
      OrderLifecycle.open when isReady(order.status) => (c.good, c.goodSoft),
      OrderLifecycle.open => (AppTheme.primary, AppTheme.surfaceSubtle),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (order.orderNumber.isNotEmpty)
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                StatusPill(
                  serviceStatusLabel(context, order.status),
                  color: fg,
                  soft: soft,
                ),
                if (lifecycle == OrderLifecycle.overdue)
                  StatusPill(
                    orderLifecycleLabel(context, lifecycle),
                    color: c.stop,
                    soft: c.stopSoft,
                    icon: Icons.schedule,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.device.isEmpty ? order.title : order.device,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (order.complaints.isNotEmpty)
              Text(
                order.complaints.join(', '),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              order.customerName.isEmpty
                  ? l10n.noNameGiven
                  : order.customerName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (order.customerPhone.isNotEmpty)
              Text(
                formatPhone(order.customerPhone),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 10),
            ContactButtons(
              phone: order.customerPhone,
              message: serviceCustomerMessage(context, order),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a job is, in the four steps the customer cares about:
/// 0 received, 1 being worked on (waiting for parts or for a yes counts),
/// 2 ready, 3 handed back.
int trackStepOf(String status) => switch (status) {
  'Received' => 0,
  'Ready' => 2,
  'Completed' || 'Returned' => 3,
  _ => 1,
};

/// Received → Working → Ready → Handed back, with the current step marked.
class _Track extends StatelessWidget {
  const _Track({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final labels = [
      l10n.trackReceived,
      l10n.trackWorking,
      l10n.homeReady,
      l10n.trackHandedBack,
    ];
    Widget dot(int i) {
      final done = i < step;
      final here = i == step;
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || here ? AppTheme.primary : AppTheme.surface,
          border: Border.all(
            color: done || here ? AppTheme.primary : AppTheme.borderSubtle,
            width: 2,
          ),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : here
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      );
    }

    return Semantics(
      label: labels[step.clamp(0, 3)],
      child: Column(
        key: Key('track-$step'),
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i <= step
                          ? AppTheme.primary
                          : AppTheme.borderSubtle,
                    ),
                  ),
                dot(i),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: switch (i) {
                      0 => TextAlign.left,
                      3 => TextAlign.right,
                      _ => TextAlign.center,
                    },
                    maxLines: 2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: i == step ? FontWeight.w700 : null,
                      color: i == step ? AppTheme.text : AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
