import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/enquiries/enquiry.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/settings/option_learning.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/settings/option_set.dart';
import '../../../l10n/rule_messages.dart';

/// RECORDING A WALK-IN QUESTION
///
/// Short on purpose. A long form at the counter does not get filled in, and an
/// enquiry that was not written down is worth nothing at all — so the only
/// required fields are a number to ring back on and one line saying what was
/// asked.
///
/// The follow-up date is the field that makes the record useful, so the form
/// offers it with a sensible default rather than leaving it empty and hoping.
Future<void> openEnquirySheet(BuildContext context, {Enquiry? existing}) async {
  final repo = context.read<EnquiryRepository>();
  final customers = context.read<CustomerRepository>();
  final settings = context.read<SettingsRepository>();
  final drafts = context.read<DraftStore>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, not inside the tab, so the bottom bar does not
    // sit under the form's own buttons.
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<EnquiryRepository>.value(value: repo),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        Provider<DraftStore>.value(value: drafts),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: EnquiryForm(existing: existing),
      ),
    ),
  );
}

class EnquiryForm extends StatefulWidget {
  const EnquiryForm({super.key, this.existing});

  final Enquiry? existing;

  @override
  State<EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends State<EnquiryForm> {
  final _c = <String, TextEditingController>{};

  Customer? _customer;
  String _about = '';
  DateTime? _followUpAt;
  EnquiryValidation _result = const EnquiryValidation({}, {});
  bool _submitted = false;

  String get _draftKey => draftKey('enquiry', id: widget.existing?.id);

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
      _c['question']!.text = e.question;
      _c['brand']!.text = e.brand;
      _c['model']!.text = e.model;
      _c['budget']!.text = e.budget == 0 ? '' : e.budget.toString();
      _c['quotedPrice']!.text = e.quotedPrice == 0
          ? ''
          : e.quotedPrice.toString();
      _c['handledBy']!.text = e.handledBy;
      _c['notes']!.text = e.notes;
      _about = e.about;
      _followUpAt = e.followUpAt;
    } else {
      // Two days out: long enough that the answer may have changed, short
      // enough that the customer has not gone elsewhere. Editable, and the
      // X next to it clears it for an enquiry answered on the spot.
      final now = DateTime.now();
      _followUpAt = DateTime(now.year, now.month, now.day + 2, 11);
      _restoreDraft();
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

  Future<void> _restoreDraft() async {
    final draft = await context.read<DraftStore>().read(_draftKey);
    if (draft == null || draft.isEmpty || !mounted) return;
    setState(() {
      for (final entry in draft.values.entries) {
        final c = _c[entry.key];
        if (c != null) c.text = (entry.value ?? '').toString();
      }
      _about = (draft.values['about'] ?? '').toString();
    });
    _recompute();
  }

  Enquiry _asEnquiry() => Enquiry(
    id: widget.existing?.id ?? 'new',
    customerId: _customer?.id ?? widget.existing?.customerId,
    customerName: _c['customerName']!.text.trim(),
    customerPhone: _c['customerPhone']!.text.trim(),
    about: _about,
    question: _c['question']!.text.trim(),
    brand: _c['brand']!.text.trim(),
    model: _c['model']!.text.trim(),
    budget: asAmount(_c['budget']!.text),
    quotedPrice: asAmount(_c['quotedPrice']!.text),
    status: widget.existing?.status ?? 'Open',
    outcomeRef: widget.existing?.outcomeRef ?? '',
    notes: _c['notes']!.text.trim(),
    handledBy: _c['handledBy']!.text.trim(),
    askedAt: widget.existing?.askedAt,
    followUpAt: _followUpAt,
    closedAt: widget.existing?.closedAt,
    createdAt: widget.existing?.createdAt,
  );

  void _recompute() {
    setState(() => _result = validateEnquiry(_asEnquiry()));
    context.read<DraftStore>().write(_draftKey, {
      for (final e in _c.entries) e.key: e.value.text,
      'about': _about,
    });
  }

  Future<void> _save() async {
    final enquiry = _asEnquiry();
    final result = validateEnquiry(enquiry);
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

    final repo = context.read<EnquiryRepository>();
    final settings = context.read<SettingsRepository>();
    final customers = context.read<CustomerRepository>();
    final drafts = context.read<DraftStore>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final stored = await guardSave(
      context,
      () => repo.save(
        enquiry.id == 'new'
            ? Enquiry.fromMap('enq-${DateTime.now().millisecondsSinceEpoch}', {
                ...enquiry.toMap(),
                'createdAt': DateTime.now().toIso8601String(),
              })
            : enquiry,
      ),
    );
    if (stored == null) {
      return;
    }
    await drafts.clear(_draftKey);
    unawaited(
      fileCustomer(
        customers,
        name: enquiry.customerName,
        phone: enquiry.customerPhone,
      ),
    );

    // Filed after the save and not waited on: a brand joining a dropdown must
    // never be able to fail the enquiry that was just recorded.
    final filing = settings.learn(
      purchaseValues(brand: enquiry.brand, model: enquiry.model),
    );

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.savedColon(stored.headline))),
    );
    await filing;
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
    final errors = _submitted
        ? ruleTexts(context, _result.errors)
        : const <String, String>{};
    final settings = context.watch<SettingsRepository>().settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.l10n.recordAnEnquiry
              : context.l10n.editEnquiry,
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
          _Section(context.l10n.whoAsked, [
            _field(
              'customerPhone',
              context.l10n.phoneNumber,
              errors,
              keyboard: TextInputType.phone,
              help: context.l10n.pointIsRingingBack,
            ),
            _CustomerMatch(
              phone: _c['customerPhone']!.text,
              picked: _customer,
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
              help: context.l10n.nameOptionalEnough,
            ),
          ]),
          _Section(context.l10n.whatTheyAsked, [
            DropdownButtonFormField<String>(
              key: const Key('enquiry-about'),
              initialValue: _about.isEmpty ? null : _about,
              decoration: InputDecoration(
                labelText: context.l10n.about,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final a in _aboutOptions)
                  DropdownMenuItem(value: a, child: Text(a)),
              ],
              onChanged: (v) {
                setState(() => _about = v ?? '');
                _recompute();
              },
            ),
            const SizedBox(height: 10),
            _field(
              'question',
              context.l10n.whatTheyAsked,
              errors,
              lines: 3,
              help: context.l10n.inTheirWordsHelp,
            ),
            if (errors.containsKey('question')) _ErrorText(errors['question']!),
            _field('brand', context.l10n.brandIfNamed, errors),
            PickRow(
              typed: _c['brand']!.text,
              keyPrefix: 'brand',
              values: byUse(
                settings.list(OptionKind.brands).values,
                context.read<EnquiryRepository>().enquiries.map((e) => e.brand),
              ),
              onPicked: (v) {
                _c['brand']!.text = v;
                _recompute();
              },
            ),
            _field('model', context.l10n.modelIfNamed, errors),
            PickRow(
              typed: _c['model']!.text,
              keyPrefix: 'model',
              values: settings.modelsFor(_c['brand']!.text).sorted,
              onPicked: (v) {
                _c['model']!.text = v;
                _recompute();
              },
            ),
          ]),
          _Section(context.l10n.money, [
            _field(
              'budget',
              context.l10n.whatTheyWouldSpend,
              errors,
              keyboard: TextInputType.number,
              // Zero is not the same as a zero budget.
              help: context.l10n.leaveEmptyIfNotSaid,
            ),
            _field(
              'quotedPrice',
              context.l10n.whatTheyWereQuoted,
              errors,
              keyboard: TextInputType.number,
            ),
            if (errors.containsKey('budget')) _ErrorText(errors['budget']!),
          ]),
          _Section(context.l10n.followUp, [
            ListTile(
              key: const Key('enquiry-followup'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.ringThemBackOn),
              subtitle: Text(
                _followUpAt == null
                    // Not an error: plenty of enquiries are answered on the
                    // spot. But it will not come up again on its own.
                    ? context.l10n.notSetWillNotComeUp
                    : _formatDate(_followUpAt!),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_followUpAt != null)
                    IconButton(
                      key: const Key('enquiry-followup-clear'),
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n.noFollowUpNeeded,
                      onPressed: () {
                        setState(() => _followUpAt = null);
                        _recompute();
                      },
                    ),
                  const Icon(Icons.event),
                ],
              ),
              onTap: _pickFollowUp,
            ),
            _field('handledBy', context.l10n.takenBy, errors),
            _field('notes', context.l10n.notes, errors, lines: 3),
          ]),
          if (_result.hasWarnings) _Warnings(warnings: _result.warnings),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(onPressed: _save, child: Text(context.l10n.save)),
        ),
      ),
    );
  }

  /// The shop's list, plus whatever this record already carries, so a value
  /// from an older build does not vanish from the dropdown — and a dropdown
  /// whose value is not among its items throws.
  List<String> get _aboutOptions {
    final existing = _about.trim();
    if (existing.isEmpty || kEnquiryAbout.contains(existing)) {
      return kEnquiryAbout;
    }
    return [existing, ...kEnquiryAbout];
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(
      () => _followUpAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _followUpAt?.hour ?? 11,
      ),
    );
    _recompute();
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

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
      key: Key('enquiry-$key'),
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
  'question',
  'brand',
  'model',
  'budget',
  'quotedPrice',
  'handledBy',
  'notes',
];

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
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          context.l10n.enquiryNobodyOnNumber,
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
