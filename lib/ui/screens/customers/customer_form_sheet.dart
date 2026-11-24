import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/input_rules.dart';
import '../../../domain/common/phone.dart';
import '../../../data/customer_repository.dart';
import '../../widgets/save_guard.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/customers/customer.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/rule_messages.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/shop_ui.dart';

/// ADDING SOMEONE TO THE BOOK
///
/// Short, because a long form at the counter does not get filled in. The
/// number is the only required field: a walk-in who gives nothing else is
/// still a customer, and refusing the record means the repair goes in under
/// nobody.
///
/// A number already in the book is refused with the name it is under, so the
/// person adding it can go and look rather than making a second record.
Future<Customer?> openCustomerSheet(
  BuildContext context, {
  Customer? existing,
  String? phone,
}) {
  final repo = context.read<CustomerRepository>();
  final drafts = context.read<DraftStore>();
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, not inside the tab, so the bottom bar does not
    // sit under the form's own buttons.
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        Provider<DraftStore>.value(value: drafts),
        ChangeNotifierProvider<CustomerRepository>.value(value: repo),
      ],
      child: CustomerForm(existing: existing, initialPhone: phone),
    ),
  );
}

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key, this.existing, this.initialPhone});

  final Customer? existing;

  /// Prefilled when the counter searched a number, found nobody, and chose to
  /// add them. Making them read it out again is how the number got mistyped.
  final String? initialPhone;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _c = <String, TextEditingController>{};
  Map<String, String> _errors = const {};
  bool _submitted = false;

  String get _draftKey => draftKey('customer', id: widget.existing?.id);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _c[f] = TextEditingController()..addListener(_revalidate);
    }
    final e = widget.existing;
    if (e != null) {
      _c['name']!.text = e.name;
      _c['phone']!.text = e.phone;
      _c['altPhone']!.text = e.altPhone;
      _c['email']!.text = e.email;
      _c['address']!.text = e.address;
      _c['notes']!.text = e.notes;
    } else {
      if (widget.initialPhone != null) {
        _c['phone']!.text = widget.initialPhone!;
      }
      _restoreDraft();
    }
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
    // Opened for one number, with a draft about another person: the draft
    // is not this customer. Filling the empty boxes from it would save the
    // new number under someone else's name and address.
    final opened = widget.initialPhone;
    final drafted = '${draft.values['phone'] ?? ''}';
    if (opened != null &&
        normalizePhone(drafted).isNotEmpty &&
        !samePhone(opened, drafted)) {
      return;
    }
    setState(() {
      for (final entry in draft.values.entries) {
        final c = _c[entry.key];
        // A number the counter just typed in beats whatever the draft held.
        if (c != null && c.text.isEmpty) {
          c.text = (entry.value ?? '').toString();
        }
      }
    });
  }

  Customer _asCustomer() => Customer(
    id: widget.existing?.id ?? 'new',
    name: _c['name']!.text.trim(),
    phone: _c['phone']!.text.trim(),
    altPhone: _c['altPhone']!.text.trim(),
    email: _c['email']!.text.trim(),
    address: _c['address']!.text.trim(),
    notes: _c['notes']!.text.trim(),
    walletBalance: widget.existing?.walletBalance ?? 0,
    createdAt: widget.existing?.createdAt,
  );

  void _revalidate() {
    final repo = context.read<CustomerRepository>();
    setState(() {
      _errors = validateCustomer(
        _asCustomer(),
        existing: repo.customers,
      ).errors;
    });
    context.read<DraftStore>().write(_draftKey, {
      for (final e in _c.entries) e.key: e.value.text,
    });
  }

  /// The X. The only thing that throws the draft away — dragging the sheet
  /// down keeps it, because that is as often a slip as a decision.
  Future<void> _discard() async {
    final drafts = context.read<DraftStore>();
    final navigator = Navigator.of(context);
    await drafts.clear(_draftKey);
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _save() async {
    final repo = context.read<CustomerRepository>();
    final drafts = context.read<DraftStore>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final customer = _asCustomer();
    final result = validateCustomer(customer, existing: repo.customers);
    setState(() {
      _submitted = true;
      _errors = result.errors;
    });
    if (!result.isValid) {
      // To the first field that needs something; its error is under it.
      final firstError = ruleText(context, result.errors.values.first);
      final said = ScaffoldMessenger.of(context);
      final jumped = await jumpToFirstError(
        context,
        result.errors.keys.map((rule) => Key('customer-$rule')),
      );
      if (!jumped) said.showSnackBar(SnackBar(content: Text(firstError)));
      return;
    }

    final stored = await guardSave(
      context,
      () => repo.save(
        customer.id == 'new'
            ? Customer.fromMap('c-${DateTime.now().millisecondsSinceEpoch}', {
                ...customer.toMap(),
                'createdAt': DateTime.now().toIso8601String(),
              })
            : customer,
      ),
    );
    if (stored == null) {
      return;
    }
    await drafts.clear(_draftKey);
    if (!mounted) return;
    navigator.pop(stored);
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.savedNamed(stored.display))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = _submitted
        ? ruleTexts(context, _errors)
        : const <String, String>{};
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null
                ? context.l10n.addACustomer
                : context.l10n.edit,
          ),
          leading: IconButton(
            key: const Key('form-close'),
            icon: const Icon(Icons.close),
            tooltip: context.l10n.discardThisDraft,
            onPressed: _discard,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              'phone',
              context.l10n.phoneNumber,
              errors,
              keyboard: TextInputType.phone,
              help: context.l10n.howTheShopFindsThem,
              required: true,
            ),
            _field(
              'name',
              context.l10n.name,
              errors,
              help: context.l10n.nameOptionalHelp,
            ),
            _field(
              'altPhone',
              context.l10n.secondNumber,
              errors,
              keyboard: TextInputType.phone,
            ),
            _field(
              'email',
              context.l10n.email,
              errors,
              keyboard: TextInputType.emailAddress,
            ),
            _field('address', context.l10n.address, errors, lines: 2),
            _field('notes', context.l10n.notes, errors, lines: 3),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: _save,
              child: Text(context.l10n.save),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    Map<String, String> errors, {
    TextInputType? keyboard,
    int lines = 1,
    String? help,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      key: Key('customer-$key'),
      controller: _c[key],
      keyboardType: keyboardFor(key) ?? keyboard,
      maxLines: lines,
      // The app-wide typing rule for this kind of box (input_rules.dart).
      inputFormatters: inputRuleFor(key),
      maxLength: maxDigitsFor(key),
      decoration: InputDecoration(
        label: FieldLabel(label, required: required),
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: errors[key],
        helperText: help,
      ),
    ),
  );
}

const List<String> _fields = [
  'name',
  'phone',
  'altPhone',
  'email',
  'address',
  'notes',
];
