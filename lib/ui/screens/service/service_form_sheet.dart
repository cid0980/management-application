import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../../data/service_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/settings/option_learning.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../domain/service/order_validation.dart';
import '../../../domain/service/service_order.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/pattern_lock.dart';
import '../../../domain/settings/option_set.dart';
import '../../../l10n/rule_messages.dart';

/// SERVICE INTAKE
///
/// Four sections, in the order the phone is handled at the counter:
///
/// 1. **Customer** — picked from everyone served before, by number, so nobody
///    is added twice.
/// 2. **Device** — brand, model, IMEI, how it is locked, what was left with it.
/// 3. **Issues** — one or more complaints from the shop's shared vocabulary.
///    The job card and the final bill are both built from these.
/// 4. **Estimate & schedule** — the quote, the costs, profit live, and the two
///    dates.
///
/// Both dates are mandatory and checked in ONE place, so "Save" and
/// "Save & Print" cannot disagree about what a valid order is.
/// Returns the saved order, or null when the sheet was closed without one.
Future<ServiceOrder?> openServiceSheet(
  BuildContext context, {
  ServiceOrder? existing,
  IntakePrefill? prefill,
}) async {
  final service = context.read<ServiceRepository>();
  final customers = context.read<CustomerRepository>();
  final settings = context.read<SettingsRepository>();
  final drafts = context.read<DraftStore>();
  return showModalBottomSheet<ServiceOrder>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, not inside the tab, so the bottom bar does not
    // sit under the form's own buttons.
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ServiceRepository>.value(value: service),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        Provider<DraftStore>.value(value: drafts),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: ServiceIntakeForm(existing: existing, prefill: prefill),
      ),
    ),
  );
}

class ServiceIntakeForm extends StatefulWidget {
  const ServiceIntakeForm({super.key, this.existing, this.prefill});

  final ServiceOrder? existing;

  /// From a scan of the phone's barcode. Prefills and stays editable — the
  /// device table is incomplete and can be wrong about a refurbished handset.
  final IntakePrefill? prefill;

  @override
  State<ServiceIntakeForm> createState() => _ServiceIntakeFormState();
}

class _ServiceIntakeFormState extends State<ServiceIntakeForm> {
  final _c = <String, TextEditingController>{};
  final _complaints = <String>[];
  final _accessories = <String>[];

  Customer? _customer;
  String _lockType = 'None';
  String _advanceMethod = 'Cash';
  DateTime? _receivedAt;
  DateTime? _expectedAt;
  OrderValidation _result = const OrderValidation({}, {});
  bool _submitted = false;

  String get _draftKey => draftKey('service', id: widget.existing?.id);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _c[f] = TextEditingController()..addListener(_recompute);
    }
    final e = widget.existing;
    if (e != null) {
      _c['customerPhone']!.text = e.customerPhone;
      _c['customerName']!.text = e.customerName;
      _c['brand']!.text = e.brand;
      _c['model']!.text = e.model;
      _c['imei']!.text = e.imei;
      _c['lockValue']!.text = e.lockValue;
      _c['complaintNotes']!.text = e.complaintNotes;
      _c['estimatedPrice']!.text = _money(e.estimatedPrice);
      _c['rawMaterialCost']!.text = _money(e.rawMaterialCost);
      _c['outsideLabourCost']!.text = _money(e.outsideLabourCost);
      _c['advancePaid']!.text = _money(e.advancePaid);
      _c['technician']!.text = e.technician;
      _complaints.addAll(e.complaints);
      _accessories.addAll(e.accessories);
      _lockType = e.lockType;
      _advanceMethod = e.advanceMethod;
      _receivedAt = e.receivedAt;
      _expectedAt = e.expectedCompletionAt;
    } else {
      // A phone handed over now, promised in three days: the usual case, so
      // the form starts there rather than empty. Both are still editable, and
      // both are still validated.
      final now = DateTime.now();
      _receivedAt = now;
      _expectedAt = DateTime(now.year, now.month, now.day + 3, 18);
      _restoreDraft();
      // After the draft, so a scan beats a stale draft: the phone in the hand
      // is more current than whatever was half-typed yesterday.
      final prefill = widget.prefill;
      if (prefill != null && !prefill.isEmpty) {
        if (prefill.imei.isNotEmpty) _c['imei']!.text = prefill.imei;
        if (prefill.brand.isNotEmpty) _c['brand']!.text = prefill.brand;
        if (prefill.model.isNotEmpty) _c['model']!.text = prefill.model;
        if (prefill.customerPhone.isNotEmpty) {
          _c['customerPhone']!.text = prefill.customerPhone;
        }
        if (prefill.customerName.isNotEmpty) {
          _c['customerName']!.text = prefill.customerName;
        }
        if (prefill.notes.isNotEmpty) {
          _c['complaintNotes']!.text = prefill.notes;
        }
      }
    }
    _recompute();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _money(num v) => v == 0 ? '' : v.toString();

  Future<void> _restoreDraft() async {
    final draft = await context.read<DraftStore>().read(_draftKey);
    if (draft == null || draft.isEmpty || !mounted) return;
    setState(() {
      for (final entry in draft.values.entries) {
        final c = _c[entry.key];
        if (c != null) c.text = (entry.value ?? '').toString();
      }
      final complaints = draft.values['complaints'];
      if (complaints is Iterable) {
        _complaints
          ..clear()
          ..addAll(complaints.map((c) => '$c'));
      }
      final accessories = draft.values['accessories'];
      if (accessories is Iterable) {
        _accessories
          ..clear()
          ..addAll(accessories.map((a) => '$a'));
      }
      _lockType = (draft.values['lockType'] ?? 'None').toString();
    });
    _recompute();
  }

  void _saveDraft() {
    context.read<DraftStore>().write(_draftKey, {
      for (final e in _c.entries) e.key: e.value.text,
      'complaints': _complaints,
      'accessories': _accessories,
      'lockType': _lockType,
    });
  }

  ServiceOrder _asOrder() => ServiceOrder(
    id: widget.existing?.id ?? 'new',
    orderNumber: widget.existing?.orderNumber ?? '',
    customerId: _customer?.id ?? widget.existing?.customerId,
    customerName: _c['customerName']!.text.trim(),
    customerPhone: _c['customerPhone']!.text.trim(),
    brand: _c['brand']!.text.trim(),
    model: _c['model']!.text.trim(),
    imei: _c['imei']!.text.replaceAll(RegExp(r'\D'), ''),
    lockType: _lockType,
    lockValue: _c['lockValue']!.text.trim(),
    accessories: List.of(_accessories),
    complaints: List.of(_complaints),
    complaintNotes: _c['complaintNotes']!.text.trim(),
    estimatedPrice: asAmount(_c['estimatedPrice']!.text),
    rawMaterialCost: asAmount(_c['rawMaterialCost']!.text),
    outsideLabourCost: asAmount(_c['outsideLabourCost']!.text),
    finalPrice: widget.existing?.finalPrice,
    warrantyDays: widget.existing?.warrantyDays ?? 0,
    // Kept through an edit: they were written by the job page, not this form.
    partsUsed: widget.existing?.partsUsed ?? const [],
    pickupPayment: widget.existing?.pickupPayment,
    advancePaid: asAmount(_c['advancePaid']!.text),
    advanceMethod: _advanceMethod,
    status: widget.existing?.status ?? 'Received',
    technician: _c['technician']!.text.trim(),
    checklist: widget.existing?.checklist ?? const {},
    receivedAt: _receivedAt,
    expectedCompletionAt: _expectedAt,
    completedAt: widget.existing?.completedAt,
    createdAt: widget.existing?.createdAt,
  );

  void _recompute() {
    setState(() => _result = validateOrder(_asOrder()));
    _saveDraft();
  }

  /// Both save paths come through here, so neither can have its own idea of
  /// what a valid order is.
  Future<void> _save({required bool print}) async {
    final order = _asOrder();
    final result = print ? validateJobCard(order) : validateOrder(order);
    setState(() {
      _submitted = true;
      _result = result;
    });
    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ruleText(context, result.errors.values.first))),
      );
      return;
    }

    final repo = context.read<ServiceRepository>();
    final drafts = context.read<DraftStore>();
    final settings = context.read<SettingsRepository>();
    final customers = context.read<CustomerRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Printing saves first, always.
    final stored = await guardSave(
      context,
      () => repo.save(
        order.id == 'new'
            ? ServiceOrder.fromMap(
                'so-${DateTime.now().millisecondsSinceEpoch}',
                {
                  ...order.toMap(),
                  'createdAt': DateTime.now().toIso8601String(),
                },
              )
            : order,
      ),
    );
    if (stored == null) {
      return;
    }
    await drafts.clear(_draftKey);

    // The customer joins the book if they are new — after the save, unawaited.
    unawaited(
      fileCustomer(
        customers,
        name: order.customerName,
        phone: order.customerPhone,
      ),
    );

    // Filed AFTER the save, and nothing waits on it. A brand joining a
    // dropdown must never be able to fail the order that was just taken in.
    final filing = settings.learn(
      serviceIntakeValues(
        brand: order.brand,
        model: order.model,
        complaints: order.complaints,
        accessories: order.accessories,
        lockType: order.lockType,
      ),
    );

    if (!mounted) return;
    navigator.pop(stored);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          print
              ? context.l10n.savedJobCard(stored.orderNumber)
              : context.l10n.savedNamed(stored.orderNumber),
        ),
      ),
    );

    // Reported separately, once it lands, because it is not what anybody is
    // waiting for.
    final filed = await filing;
    if (!mounted || !filed.wroteSomething) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.addedToShopLists('${filed.added}'))),
    );
  }

  Future<void> _discard() async {
    final drafts = context.read<DraftStore>();
    final navigator = Navigator.of(context);
    await drafts.clear(_draftKey);
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = _asOrder();
    final errors = _submitted
        ? ruleTexts(context, _result.errors)
        : <String, String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.l10n.takeInARepair
              : context.l10n.editNamed(widget.existing!.orderNumber),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.discardThisDraft,
          onPressed: _discard,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Section(context.l10n.customer, [
            _field(
              'customerPhone',
              context.l10n.phoneNumber,
              errors,
              keyboard: TextInputType.phone,
              help: context.l10n.findsWhoeverBeenHere,
            ),
            _CustomerMatch(
              phone: _c['customerPhone']!.text,
              onPicked: (c) {
                setState(() {
                  _customer = c;
                  _c['customerName']!.text = c.name;
                  _c['customerPhone']!.text = c.phone;
                });
                _recompute();
              },
            ),
            _field(
              'customerName',
              context.l10n.name,
              errors,
              help: context.l10n.nameOptionalHelp,
            ),
            if (errors.containsKey('customer')) _ErrorText(errors['customer']!),
          ]),
          _Section(context.l10n.device, [
            _field('brand', 'Brand', errors),
            // Suggestions, not a dropdown: a brand the shop has never seen is
            // typed in and joins the list on save.
            _Suggestions(
              values: byUse(
                _shopSettings.list(OptionKind.brands).values,
                context.read<ServiceRepository>().orders.map((o) => o.brand),
              ),
              onPicked: (v) {
                _c['brand']!.text = v;
                _recompute();
              },
            ),
            _field('model', 'Model', errors),
            _Suggestions(
              // Only this brand's models. A flat list of four hundred is
              // unusable, and "Galaxy A54" under Apple is a mistake nobody
              // catches.
              values: _shopSettings.modelsFor(_c['brand']!.text).sorted,
              onPicked: (v) {
                _c['model']!.text = v;
                _recompute();
              },
            ),
            _field(
              'imei',
              'IMEI — off the phone, not the box',
              errors,
              keyboard: TextInputType.number,
            ),
            // A phone this shop fixed before, still under its warranty: said
            // at the counter, so a warranty claim is not charged again.
            Builder(
              builder: (context) {
                final hit = warrantyMatch(
                  context.read<ServiceRepository>().orders,
                  _c['imei']!.text,
                  now: DateTime.now(),
                  excludeId: widget.existing?.id,
                );
                if (hit == null) return const SizedBox.shrink();
                String d(DateTime t) =>
                    '${t.day.toString().padLeft(2, '0')}/'
                    '${t.month.toString().padLeft(2, '0')}/${t.year}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    key: const Key('warranty-hit'),
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(
                        context.l10n.warrantyReturning(
                          d(hit.completedAt!),
                          hit.orderNumber,
                          d(hit.warrantyUntil!),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Four or five answers: one tap each, no menu to open.
            Text(
              context.l10n.lock,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              key: const Key('service-lockType'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in _lockTypeOptions)
                  ChoiceChip(
                    key: Key('lock-$t'),
                    label: Text(t),
                    selected: _lockType == t,
                    onSelected: (_) {
                      setState(() => _lockType = t);
                      _recompute();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // A phone that cannot be unlocked cannot be tested, and an
            // untested job comes straight back.
            // A pattern is drawn, not typed: the person at the counter is
            // copying a shape off the phone in front of them.
            if (_lockType == 'Pattern') ...[
              Text(
                context.l10n.patternTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Center(
                child: PatternLock(
                  value: _c['lockValue']!.text,
                  onChanged: (v) {
                    _c['lockValue']!.text = v;
                    _recompute();
                  },
                ),
              ),
              if (errors['lockValue'] != null)
                Text(
                  errors['lockValue']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
            ] else if (_lockType != 'None')
              _field('lockValue', context.l10n.code, errors),
            Text(context.l10n.leftWithTheDevice),
            Wrap(
              spacing: 6,
              children: [
                for (final a in _accessoryOptions)
                  FilterChip(
                    label: Text(a),
                    selected: _accessories.contains(a),
                    onSelected: (on) {
                      setState(
                        () => on ? _accessories.add(a) : _accessories.remove(a),
                      );
                      _recompute();
                    },
                  ),
              ],
            ),
          ]),
          _Section(context.l10n.issuesAndComplaints, [
            // The job card and the final bill are both built from these, which
            // is why they come off one shared list rather than being typed.
            Wrap(
              spacing: 6,
              children: [
                for (final c in _complaintOptions)
                  FilterChip(
                    label: Text(c),
                    selected: _complaints.contains(c),
                    onSelected: (on) {
                      setState(
                        () => on ? _complaints.add(c) : _complaints.remove(c),
                      );
                      _recompute();
                    },
                  ),
              ],
            ),
            if (errors.containsKey('complaints'))
              _ErrorText(errors['complaints']!),
            const SizedBox(height: 10),
            _field(
              'complaintNotes',
              context.l10n.whatTheCustomerSaid,
              errors,
              lines: 3,
            ),
          ]),
          _Section(context.l10n.estimateAndSchedule, [
            _field(
              'estimatedPrice',
              context.l10n.estimateQuoted,
              errors,
              keyboard: TextInputType.number,
            ),
            _field(
              'advancePaid',
              context.l10n.advancePaid,
              errors,
              keyboard: TextInputType.number,
            ),
            // How the advance came in, for the day's report.
            if (asAmount(_c['advancePaid']!.text) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final m in const ['Cash', 'UPI', 'Card'])
                      ChoiceChip(
                        key: Key('advance-$m'),
                        label: Text(m),
                        selected: _advanceMethod == m,
                        onSelected: (_) => setState(() => _advanceMethod = m),
                      ),
                  ],
                ),
              ),
            _field(
              'rawMaterialCost',
              context.l10n.rawMaterial,
              errors,
              keyboard: TextInputType.number,
            ),
            _field(
              'outsideLabourCost',
              context.l10n.outsideLabour,
              errors,
              keyboard: TextInputType.number,
            ),
            if (errors.containsKey('costs')) _ErrorText(errors['costs']!),
            // Live, so a quote below cost is visible before it is given.
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.costsProfitNamed(
                    '${order.costs}',
                    '${order.estimatedProfit}',
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: order.quotedAtALoss
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _field('technician', 'Technician', errors),
            _DateRow(
              label: context.l10n.deviceCameIn,
              fieldKey: 'service-receivedAt',
              value: _receivedAt,
              error: errors['receivedAt'],
              onPicked: (d) {
                setState(() => _receivedAt = d);
                _recompute();
              },
            ),
            _DateRow(
              label: context.l10n.promisedToCustomer,
              fieldKey: 'service-expectedAt',
              value: _expectedAt,
              error: errors['expectedCompletionAt'],
              onPicked: (d) {
                setState(() => _expectedAt = d);
                _recompute();
              },
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
                  onPressed: () => _save(print: true),
                  child: Text(context.l10n.saveAndPrint),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(print: false),
                  child: Text(context.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ShopSettings get _shopSettings =>
      context.watch<SettingsRepository>().settings;

  /// The shop's list, plus whatever this record already carries.
  ///
  /// A value written by an older build, or one an admin has since removed from
  /// settings, must not vanish from the chips when somebody opens the form to
  /// change a price — and for a dropdown it must not vanish at all, because a
  /// value that is not among its items throws.
  List<String> _withExisting(OptionKind kind, Iterable<String> current) {
    final list = _shopSettings.list(kind);
    return [
      ...list.values,
      for (final value in current)
        if (value.trim().isNotEmpty && !list.contains(value)) value,
    ];
  }

  List<String> get _lockTypeOptions {
    final values = _withExisting(OptionKind.lockTypes, [_lockType]);
    // 'None' has to be offerable even if somebody removed it from settings:
    // it is the value a form opens on.
    return values.contains('None') ? values : ['None', ...values];
  }

  List<String> get _complaintOptions =>
      _withExisting(OptionKind.complaintTypes, _complaints);

  List<String> get _accessoryOptions =>
      _withExisting(OptionKind.accessories, _accessories);

  Widget _field(
    String key,
    String label,
    Map<String, String> errors, {
    TextInputType? keyboard,
    int lines = 1,
    String? help,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      key: Key('service-$key'),
      controller: _c[key],
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: errors[key],
        helperText: help,
      ),
    ),
  );
}

const List<String> _fields = [
  'customerPhone',
  'customerName',
  'brand',
  'model',
  'imei',
  'lockValue',
  'complaintNotes',
  'estimatedPrice',
  'rawMaterialCost',
  'outsideLabourCost',
  'advancePaid',
  'technician',
];

/// Whoever has been here before, found by the number being typed.
///
/// Shown as soon as there is enough of a number to narrow it down, so the
/// person at the counter is picked rather than added again.
class _CustomerMatch extends StatelessWidget {
  const _CustomerMatch({required this.phone, required this.onPicked});

  final String phone;
  final ValueChanged<Customer> onPicked;

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return const SizedBox.shrink();

    final matches = suggestCustomers(
      context.watch<CustomerRepository>().customers,
      digits,
      limit: 4,
    );
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          context.l10n.nobodyOnThatNumber,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        children: [
          for (final c in matches)
            ActionChip(
              avatar: const Icon(Icons.person_outline, size: 16),
              label: Text(c.display),
              onPressed: () => onPicked(c),
            ),
        ],
      ),
    );
  }
}

/// One of the two mandatory dates.
///
/// A row rather than a text field: a date typed by hand is how an unparseable
/// value got into the record in the first place, where it then read as neither
/// overdue nor due nor anything else.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.onPicked,
    this.error,
  });

  final String label;
  final String fieldKey;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            key: Key(fieldKey),
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(
              value == null ? context.l10n.notSetTitle : _format(value!),
            ),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                onPicked(
                  DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    value?.hour ?? 18,
                    value?.minute ?? 0,
                  ),
                );
              }
            },
          ),
          if (error != null)
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  static String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// The shop's list, offered as chips next to a free-text field.
///
/// Chips rather than a dropdown, because the field has to stay typeable: a
/// brand the shop has never seen is typed in and joins the list on save. A
/// dropdown would make that impossible, which is how the list stopped growing
/// in the first place.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.values, required this.onPicked});

  final List<String> values;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final value in values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(value),
                  onPressed: () => onPicked(value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [FormSection(title), ...children],
  );
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
            // Warnings never block a save: a goodwill repair and a phone taken
            // in at closing time are decisions, not mistakes.
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
