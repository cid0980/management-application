import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/service_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/service/checklist.dart';
import '../../../domain/service/order_state.dart';
import '../../../domain/service/order_validation.dart';
import '../../../domain/service/service_order.dart';
import 'service_form_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../../data/printing/documents.dart';
import '../../../data/settings_repository.dart';
import '../../printing/print_sheet.dart';
import '../../widgets/contact_buttons.dart';
import '../ratings/rating_button.dart';
import '../../widgets/margins.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${context.l10n.noServiceOrder(id)}\n\n'
            '${context.l10n.deletedJobCardNote}',
            textAlign: TextAlign.center,
          ),
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
          Text(order.device, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [
              order.orderNumber,
              orderLifecycleLabel(context, order.lifecycleAt(now)),
              serviceStatusLabel(context, order.status),
            ].where((p) => p.isNotEmpty).join(' · '),
          ),
          const SizedBox(height: 16),
          _StatusPicker(order: order, isAdmin: isAdmin),
          _Block(context.l10n.customer, {
            context.l10n.name: order.customerName.isEmpty
                ? context.l10n.noNameGiven
                : order.customerName,
            context.l10n.shopPhone: formatPhone(order.customerPhone),
          }),
          const SizedBox(height: 4),
          ContactButtons(
            phone: order.customerPhone,
            message: _customerMessage(context, order),
          ),
          const SizedBox(height: 12),
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
            context.l10n.estimateQuoted: '₹${order.estimatedPrice}',
            if (order.advancePaid > 0)
              context.l10n.advancePaid: '₹${order.advancePaid}',
            if (order.advancePaid > 0)
              context.l10n.toCollect: '₹${order.toCollect}',
            if (canSeeMargins(context)) ...{
              context.l10n.rawMaterial: '₹${order.rawMaterialCost}',
              context.l10n.outsideLabour: '₹${order.outsideLabourCost}',
              context.l10n.costs: '₹${order.costs}',
              context.l10n.profitAtEstimate: '₹${order.estimatedProfit}',
            },
            // Null, not zero, until it is charged.
            context.l10n.charged: order.finalPrice == null
                ? context.l10n.notChargedYet
                : '₹${order.finalPrice}',
            if (canSeeMargins(context))
              context.l10n.profitMade: order.realisedProfit == null
                  ? context.l10n.notChargedYet
                  : '₹${order.realisedProfit}',
          }),
          _Block(context.l10n.schedule, {
            context.l10n.cameIn: _date(order.receivedAt),
            context.l10n.promised: _date(order.expectedCompletionAt),
            if (order.completedAt != null)
              context.l10n.handedBack: _date(order.completedAt),
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
          const SizedBox(height: 16),
          _Checklist(order: order, items: items, check: check),
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
String _customerMessage(BuildContext context, ServiceOrder order) {
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
          ? l10n.waServiceReadyPay(name, device, no, '${order.toCollect}', shop)
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
          padding: const EdgeInsets.all(12),
          child: Text(
            context.l10n.handedBackOn(
              ServiceDetailScreen._date(order.completedAt),
            ),
            style: Theme.of(context).textTheme.bodySmall,
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
              context.l10n.status,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in options)
                  ChoiceChip(
                    label: Text(serviceStatusLabel(context, s)),
                    selected: order.status == s,
                    onSelected: order.status == s
                        ? null
                        : (_) => _set(context, s),
                  ),
              ],
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.statusNamed(serviceStatusLabel(context, status)),
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
class _Checklist extends StatelessWidget {
  const _Checklist({
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
    final entries = checklistEntries(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.preDeliveryChecklist,
          style: theme.textTheme.titleSmall,
        ),
        const Divider(),
        if (entries.isEmpty)
          // A shop with no checklist configured has nothing to verify, so an
          // empty list passes rather than stopping every order in the shop.
          Text(
            context.l10n.noChecklistConfigured,
            style: theme.textTheme.bodySmall,
          )
        else ...[
          Text(
            '${entries.length - check.remaining.length} of ${entries.length} '
            'ticked',
            style: theme.textTheme.bodySmall,
          ),
          for (final e in entries)
            CheckboxListTile(
              key: Key('check-${e.key}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: order.checklist[e.key] == true,
              title: Text(e.item),
              onChanged: order.closed
                  ? null
                  : (v) => context.read<ServiceRepository>().setCheck(
                      order.id,
                      e.key,
                      ticked: v == true,
                    ),
            ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.check});

  final ServiceOrder order;
  final CompletionCheck check;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
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
                      : context.l10n.chargedAmount('${order.finalPrice}'),
                ),
              ),
              FilledButton.icon(
                // Offered even when blocked: the message names what is left,
                // which is more use than a disabled button.
                onPressed: () => _complete(context),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n.handThePhoneBack),
              ),
              OutlinedButton.icon(
                onPressed: () => _returnUnrepaired(context),
                icon: const Icon(Icons.undo),
                label: Text(context.l10n.returnedUnrepaired),
              ),
            ],
            OutlinedButton.icon(
              onPressed: () {
                final result = validateJobCard(order);
                if (!result.isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.errors.values.first)),
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
                  build: (shop, includeLock) => order.closed
                      ? buildFinalBillPdf(order: order, shop: shop)
                      : buildJobCardPdf(
                          order: order,
                          shop: shop,
                          checklist: checklist,
                          includeLock: includeLock,
                        ),
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
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final repo = context.read<ServiceRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await repo.complete(order.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.allowed
              ? l10n.handedBackPrintBill
              : _blockedMessage(result, l10n),
        ),
      ),
    );
  }

  /// Names what is still unticked. "The checklist is incomplete" sends someone
  /// scrolling a list of thirteen looking for the one they missed.
  static String _blockedMessage(CompletionCheck check, AppLocalizations l10n) {
    if (check.blocks.contains(CompletionBlock.checklistIncomplete) &&
        check.remaining.isNotEmpty) {
      final named = check.remaining.take(3).join(', ');
      final more = check.remaining.length - 3;
      return more > 0
          ? l10n.stillToCheckMore(named, more)
          : l10n.stillToCheck(named);
    }
    return check.firstMessage ?? l10n.cannotHandBackYet;
  }

  Future<void> _charge(BuildContext context) async {
    final repo = context.read<ServiceRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final price = await showDialog<num>(
      context: context,
      builder: (_) => _ChargeDialog(estimate: order.estimatedPrice),
    );
    if (price == null) return;
    await repo.setFinalPrice(order.id, price);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.chargingAmount('$price'))),
    );
  }

  Future<void> _returnUnrepaired(BuildContext context) async {
    final repo = context.read<ServiceRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReturnDialog(),
    );
    if (reason == null) return;
    await repo.markReturned(order.id, reason: reason);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.whatIsBeingCharged),
    content: TextField(
      key: const Key('charge-amount'),
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.l10n.finalPrice,
        // Zero is allowed and has to be said: a completed order with no
        // price is a phone handed back for free, which is sometimes true
        // and never implicit.
        helperText: context.l10n.zeroIsAllowed,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(asAmount(_controller.text)),
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
  Widget build(BuildContext context) => AlertDialog(
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
                  width: 160,
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
