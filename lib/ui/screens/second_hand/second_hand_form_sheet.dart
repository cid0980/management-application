import '../../../data/firestore_errors.dart';
import '../../../l10n/rule_messages.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../widgets/fact_icons.dart';
import '../../widgets/input_rules.dart';

import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../data/label_repository.dart';
import '../../../data/photo_uploader.dart';
import '../../widgets/photo_strip.dart' show pickPhotoSource;
import '../../../data/shop_photos.dart';
import '../../widgets/shop_photo_image.dart';
import '../../../data/print_server.dart';
import '../../../data/second_hand_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/customers/customer.dart';
import '../../../domain/inventory/condition_grade.dart';
import '../../../domain/inventory/imei.dart';
import '../../../domain/inventory/purchase_costing.dart';
import '../../../domain/inventory/purchase_validation.dart';
import '../../../domain/inventory/second_hand_device.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/labels/label_target.dart';
import '../../../domain/settings/option_learning.dart';
import '../../../domain/settings/option_set.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../domain/inventory/stock_state.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/field_help.dart';
import '../../widgets/form_jump.dart';
import '../../widgets/print_errors.dart';
import '../../widgets/imei_scan.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/signature_pad.dart';
import '../../widgets/smart_autocomplete.dart';
import '../../../domain/inventory/stock_list.dart';
import '../../../domain/common/money.dart';
import '../../../domain/settings/model_choices.dart';
import '../../widgets/model_records.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/date_sheet.dart';

/// THE PURCHASE FORM
///
/// Five steps, one screen each, in the order the shop's counter app (the
/// French Mobiles POS) already asks them, so staff find the same questions in
/// the same place: **Seller → Phone → Condition → Price → Photos.** Each step
/// asks only what it must; what is optional is folded away under "Add more
/// details".
///
/// The things worth knowing about this screen:
///
/// - **One validator.** Next checks the step on screen against
///   [validatePurchase]; Save checks everything with the same function and
///   jumps back to the first step with a problem.
/// - **The checklist starts at Working** and staff tap only the faults; the
///   grade follows on every tap, and a hand-picked grade is recorded as such.
/// - **Profit is live**, with the repairs in it.
/// - **Save & print label** saves first, then has the registry assign the
///   sticker number and sends it to the shop printer.
/// - **Dragging the sheet down keeps the draft; the X discards it.**
Future<void> openPurchaseSheet(
  BuildContext context, {
  SecondHandDevice? existing,
  IntakePrefill? prefill,
  SecondHandDevice? sameSellerAs,
}) async {
  final repo = context.read<SecondHandRepository>();
  final settings = context.read<SettingsRepository>();
  final drafts = context.read<DraftStore>();
  // Optional: the form works without them (a test may pump it bare), it just
  // cannot search customers or print a label.
  final customers = _maybe<CustomerRepository>(context);
  final labels = _maybe<LabelRepository>(context);
  final printer = _maybe<PrintServer>(context);
  final photos = _maybe<PhotoUploader>(context);
  Future<Object?> open(
    SecondHandDevice? seller,
  ) => showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, not inside the tab: the title bar and the bottom
    // bar would otherwise take a third of a small phone away from the form.
    useRootNavigator: true,
    builder: (_) => MultiProvider(
      providers: [
        Provider<DraftStore>.value(value: drafts),
        // ChangeNotifierProvider, not Provider: the sheet sits over the list
        // and has to see a stock change made from anywhere else. A plain
        // Provider of a Listenable silently never updates its dependents.
        ChangeNotifierProvider<SecondHandRepository>.value(value: repo),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        if (customers != null)
          ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        if (labels != null)
          ChangeNotifierProvider<LabelRepository>.value(value: labels),
        if (printer != null) Provider<PrintServer>.value(value: printer),
        if (photos != null) Provider<PhotoUploader>.value(value: photos),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: PurchaseForm(
          existing: existing,
          prefill: seller == null ? prefill : null,
          sameSellerAs: seller,
        ),
      ),
    ),
  );

  // "…& buy another from this seller" closes the form with the phone just
  // bought and opens the next one with the seller already filled in.
  var result = await open(sameSellerAs);
  while (result is AnotherPurchase && context.mounted) {
    result = await open(result.saved);
  }
}

/// What the purchase form answers with when another phone is coming from
/// the same seller.
class AnotherPurchase {
  const AnotherPurchase(this.saved);

  final SecondHandDevice saved;
}

T? _maybe<T>(BuildContext context) {
  try {
    return Provider.of<T>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

class PurchaseForm extends StatefulWidget {
  const PurchaseForm({
    super.key,
    this.existing,
    this.prefill,
    this.sameSellerAs,
  });

  final SecondHandDevice? existing;

  /// Another phone from the seller of this one: the seller step is filled in
  /// (name, numbers, ID, ID photos, signature) and the form opens on the
  /// phone step.
  final SecondHandDevice? sameSellerAs;

  /// From a scan of the phone's barcode. Prefills and stays editable — the
  /// device table is incomplete and can be wrong about a refurbished handset.
  final IntakePrefill? prefill;

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

/// The steps, in order.
const int _kSeller = 0;
const int _kPhone = 1;
const int _kCondition = 2;
const int _kPrice = 3;
const int _kPhotos = 4;

/// The seller's declaration and signature: a step of its own, not hidden
/// under the photos where nobody scrolled to it.
const int _kSign = 5;

class _PurchaseFormState extends State<PurchaseForm> {
  final _c = <String, TextEditingController>{};
  final _answers = <String, bool?>{};
  final _repairs = <RepairCost>[];

  /// One per slot of [kPhotoSlots]; empty where none was taken.
  final _photos = List<String>.filled(kPhotoSlots.length, '');

  /// The seller's ID card: front, back.
  final _idCards = List<String>.filled(2, '');

  String? _gradeOverride;
  bool _stillBeingRepaired = false;
  String? _signature;

  /// Somebody looked at the seller's government photo ID.
  bool _idVerified = false;

  /// How the seller was paid now (the rest, if any, is paid later).
  String _payMethod = 'Cash';

  /// The tick was tried without the ID card photos: they are asked for
  /// right under it.
  bool _askIdPhotos = false;

  /// The ID card photos came from this seller's earlier purchase (its
  /// date), so nobody photographs the same card again.
  DateTime? _idFromEarlier;

  bool get _idPhotosComplete => _idCards.every((p) => p.trim().isNotEmpty);

  /// When the seller agreed to the declaration; null until they do.
  DateTime? _agreedAt;
  String? _sellerCustomerId;
  DateTime _purchasedAt = _today();
  ValidationResult _result = const ValidationResult({}, {});
  bool _submitted = false;

  /// "+ Add new customer" is open on the Seller step.
  bool _addingCustomer = false;

  /// What was typed when "+ Add … as a new customer" was tapped, so the new
  /// customer form opens with it already filled in.
  String _newCustomerSeed = '';

  /// The one search box for the seller: name or phone.
  final _sellerQuery = TextEditingController();

  /// Which step is on screen.
  int _step = _kSeller;

  /// Steps someone has tried to leave with Next. Errors show only for these
  /// (and for everything once Save is pressed): a step that shouts in red
  /// before anyone has typed a word feels like being told off.
  final _tried = <int>{};

  /// Steps whose "more details" fold has been opened.
  final _open = <int>{};

  /// Which step each field lives on, so Next checks only that step and a
  /// failed Save can jump to where the problem is.
  static const Map<int, Set<String>> _stepFields = {
    _kSeller: {'sellerName', 'sellerPhone', 'sellerAltPhone', 'sellerIdProof'},
    _kPhone: {
      'brand',
      'model',
      'ram',
      'rom',
      'imei',
      'imei2',
      'serial',
      'colour',
    },
    _kCondition: {'grade', 'notes', 'batteryHealth'},
    _kPrice: {
      'purchasePrice',
      'paidNow',
      'askingPrice',
      'purchasedAt',
      'supplier',
      'otherCost',
      'repairs',
      'status',
    },
    _kPhotos: {'photos'},
    _kSign: {'sellerSignature', 'sellerIdVerified'},
  };

  /// The optional ones, kept folded away until someone wants them.
  static const Set<String> _folded = {
    'colour',
    'otherCost',
    'repairs',
    'sellerIdProof',
  };

  static int _stepOf(String field) => _stepFields.entries
      .firstWhere(
        (e) => e.value.contains(field),
        orElse: () => const MapEntry(_kSign, <String>{}),
      )
      .key;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Shows [step], opening its fold if one of its folded fields is wrong.
  void _goTo(int step, {Iterable<String> problems = const []}) {
    setState(() {
      _step = step;
      if (problems.any(_folded.contains)) _open.add(step);
    });
  }

  /// Next: only this step's own required fields are checked.
  void _next() {
    final problems = _check(_asDevice()).errors.keys
        .where((k) => _stepOf(k) == _step)
        .toList();
    setState(() => _tried.add(_step));
    if (problems.isNotEmpty) {
      _goTo(_step, problems: problems);
      // To the first box on this step that needs something.
      unawaited(jumpToFirstError(context, problems.expand(_errorKeys)));
      return;
    }
    _goTo(_step + 1);
  }

  String get _draftKey => draftKey('second_hand', id: widget.existing?.id);

  /// The boxes an error belongs to, by their widget keys.
  static List<Key> _errorKeys(String rule) => switch (rule) {
    // Whichever seller box is showing: the search, or the typed pair.
    'sellerName' || 'sellerPhone' => [
      const Key('purchase-sellerSearch'),
      Key('purchase-$rule'),
    ],
    'purchasedAt' => [const Key('purchase-date')],
    'photos' => [const Key('photo-front')],
    'sellerSignature' => [const Key('signature-pad')],
    'sellerIdVerified' => [const Key('idcard-front')],
    _ => [Key('purchase-$rule')],
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    for (final field in _fields) {
      _c[field] = TextEditingController()..addListener(_recompute);
    }
    if (e != null) {
      _c['brand']!.text = e.brand;
      _c['model']!.text = e.model;
      _c['ram']!.text = e.ram;
      _c['rom']!.text = e.rom;
      _c['colour']!.text = e.colour;
      _c['imei']!.text = e.imei;
      _c['imei2']!.text = e.imei2;
      _c['serial']!.text = e.serial;
      _c['batteryHealth']!.text = e.batteryHealth?.toString() ?? '';
      _c['purchasePrice']!.text = _money(e.purchasePrice);
      _c['otherCost']!.text = _money(e.otherCost);
      _c['askingPrice']!.text = _money(e.askingPrice);
      _c['supplier']!.text = e.supplier;
      _c['sellerName']!.text = e.sellerName;
      _c['sellerPhone']!.text = e.sellerPhone;
      _c['sellerAltPhone']!.text = e.sellerAltPhone;
      _c['sellerIdProof']!.text = e.sellerIdProof;
      _c['notes']!.text = e.notes;
      _c[kWarrantyExpiry]!.text = e.gradeDetails[kWarrantyExpiry] ?? '';
      _c[kAccessories]!.text = e.gradeDetails[kAccessories] ?? '';
      _c[kConditionDescription]!.text =
          e.gradeDetails[kConditionDescription] ?? '';
      _answers.addAll(e.conditionAnswers);
      _repairs.addAll(e.repairs);
      _fill(_photos, e.photos);
      _fill(_idCards, e.idCardPhotos);
      _gradeOverride = e.gradeOverridden ? e.grade : null;
      _stillBeingRepaired = e.isBeingRepaired;
      _signature = e.sellerSignature;
      _idVerified = e.sellerIdVerified;
      _agreedAt = e.agreementAcceptedAt;
      _sellerCustomerId = e.sellerCustomerId;
      _purchasedAt = e.purchasedAt ?? _today();
    } else {
      _restoreDraft();
      _applyIncoming();
    }
    // What this form looks like before anyone types: a draft that matches it
    // was not "carried on from" anything.
    _fresh = _draftValues();
    _recompute();
  }

  /// What was handed to the form — a scanned phone, the seller of the phone
  /// just bought. Applied at the start and again after the draft loads, so
  /// it beats a stale draft: the phone in the hand is more current than
  /// whatever was half-typed yesterday. (The draft loads after a moment, and
  /// used to overwrite the scan.)
  void _applyIncoming() {
    {
      final prefill = widget.prefill;
      if (prefill != null && !prefill.isEmpty) {
        if (prefill.imei.isNotEmpty) _c['imei']!.text = prefill.imei;
        if (prefill.brand.isNotEmpty) _c['brand']!.text = prefill.brand;
        if (prefill.model.isNotEmpty) _c['model']!.text = prefill.model;
      }
      final seller = widget.sameSellerAs;
      if (seller != null) {
        _c['sellerName']!.text = seller.sellerName;
        _c['sellerPhone']!.text = seller.sellerPhone;
        _c['sellerAltPhone']!.text = seller.sellerAltPhone;
        _c['sellerIdProof']!.text = seller.sellerIdProof;
        _c['supplier']!.text = seller.supplier;
        _fill(_idCards, seller.idCardPhotos);
        _signature = seller.sellerSignature;
        _idVerified = seller.sellerIdVerified;
        _agreedAt = seller.agreementAcceptedAt;
        _sellerCustomerId = seller.sellerCustomerId;
        _purchasedAt = seller.purchasedAt ?? _purchasedAt;
        // The seller is done: straight to the phone.
        _step = _kPhone;
      }
    }
  }

  late Map<String, Object?> _fresh;

  @override
  void dispose() {
    _sellerQuery.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _money(num v) => v == 0 ? '' : v.toString();

  static void _fill(List<String> slots, Iterable<Object?> from) {
    var i = 0;
    for (final v in from) {
      if (i >= slots.length) break;
      slots[i++] = v == null ? '' : '$v';
    }
  }

  /// An unfinished purchase was picked up again: said at the top, with a
  /// way to start fresh (FM #20).
  bool _resumed = false;

  Future<void> _restoreDraft() async {
    final draft = await context.read<DraftStore>().read(_draftKey);
    if (draft == null || draft.isEmpty || !mounted) return;
    // Something the person did — not today's date, an empty photo list or
    // an unanswered checklist, which every new form saves on opening.
    final anything = draft.values.entries.any(
      (e) => e.key != 'purchasedAt' && '${e.value}' != '${_fresh[e.key]}',
    );
    setState(() {
      _resumed = anything;
      for (final entry in draft.values.entries) {
        if (_c.containsKey(entry.key)) {
          _c[entry.key]!.text = (entry.value ?? '').toString();
        }
      }
      final answers = draft.values['conditionAnswers'];
      if (answers is Map) {
        answers.forEach((k, v) => _answers['$k'] = v as bool?);
      }
      _stillBeingRepaired = draft.values['stillBeingRepaired'] == true;
      final photos = draft.values['photos'];
      if (photos is Iterable) _fill(_photos, photos);
      final cards = draft.values['idCardPhotos'];
      if (cards is Iterable) _fill(_idCards, cards);
      final customer = draft.values['sellerCustomerId'];
      if (customer is String && customer.isNotEmpty) {
        _sellerCustomerId = customer;
      }
      final date = DateTime.tryParse('${draft.values['purchasedAt'] ?? ''}');
      if (date != null) _purchasedAt = date;
      final signature = draft.values['sellerSignature'];
      if (signature is String && signature.isNotEmpty) _signature = signature;
      _idVerified = draft.values['sellerIdVerified'] == true;
      _agreedAt = DateTime.tryParse(
        '${draft.values['agreementAcceptedAt'] ?? ''}',
      );
      // The scan or the carried-over seller still wins over the draft.
      _applyIncoming();
    });
    _recompute();
  }

  void _saveDraft() {
    context.read<DraftStore>().write(_draftKey, _draftValues());
  }

  Map<String, Object?> _draftValues() => {
    for (final entry in _c.entries) entry.key: entry.value.text,
    'conditionAnswers': _answers,
    'stillBeingRepaired': _stillBeingRepaired,
    'photos': _photos,
    'idCardPhotos': _idCards,
    'sellerCustomerId': _sellerCustomerId ?? '',
    'purchasedAt': _purchasedAt.toIso8601String(),
    'sellerSignature': _signature ?? '',
    'sellerIdVerified': _idVerified,
    'agreementAcceptedAt': _agreedAt?.toIso8601String() ?? '',
  };

  /// The form as the record it would be saved as. Built on every keystroke, so
  /// the grade, the profit and the validation all read the same thing the save
  /// will write — nothing is computed twice in two places.
  SecondHandDevice _asDevice() {
    final lists = context.read<SettingsRepository>().settings;
    // "apple" typed is saved as the shop's "Apple": one spelling per phone, so
    // search and the lists never split one brand into two.
    String spelled(OptionSet list, String key) {
      final typed = _c[key]!.text.trim();
      return list.canonical(typed) ?? typed;
    }

    final brand = spelled(lists.list(OptionKind.brands), 'brand');
    final checklist = checklistFor(brand);
    final grade = gradeForSave(
      override: _gradeOverride,
      answers: _answers,
      checklist: checklist,
    );
    return SecondHandDevice(
      id: widget.existing?.id ?? 'new',
      brand: brand,
      model: spelled(lists.modelsFor(brand), 'model'),
      // Only an old record still carries the one-box variant.
      variant:
          widget.existing?.ram.isEmpty == true &&
              widget.existing?.rom.isEmpty == true &&
              _c['ram']!.text.trim().isEmpty &&
              _c['rom']!.text.trim().isEmpty
          ? widget.existing!.variant
          : '',
      ram: spelled(lists.list(OptionKind.ram), 'ram'),
      rom: spelled(lists.list(OptionKind.rom), 'rom'),
      colour: spelled(lists.list(OptionKind.colours), 'colour'),
      imei: normalizeImei(_c['imei']!.text),
      imei2: normalizeImei(_c['imei2']!.text),
      serial: _c['serial']!.text.trim(),
      batteryHealth: batteryPercent(_c['batteryHealth']!.text),
      status: statusForSave(
        current: widget.existing?.status,
        stillBeingRepaired: _stillBeingRepaired,
      ),
      grade: grade,
      gradeOverridden: _gradeOverride != null,
      conditionAnswers: answersForSave(_answers, checklist: checklist),
      gradeDetails: {
        for (final key in _detailKeysFor(grade))
          if (_c[key]!.text.trim().isNotEmpty) key: _c[key]!.text.trim(),
      },
      repairs: List.of(_repairs),
      purchasePrice: asAmount(_c['purchasePrice']!.text),
      otherCost: asAmount(_c['otherCost']!.text),
      askingPrice: asAmount(_c['askingPrice']!.text),
      soldPrice: widget.existing?.soldPrice,
      photos: List.of(_photos),
      idCardPhotos: List.of(_idCards),
      supplier: spelled(lists.list(OptionKind.suppliers), 'supplier'),
      sellerCustomerId: _sellerCustomerId,
      sellerName: _c['sellerName']!.text.trim(),
      sellerPhone: _c['sellerPhone']!.text.trim(),
      sellerAltPhone: _c['sellerAltPhone']!.text.trim(),
      sellerIdProof: _c['sellerIdProof']!.text.trim(),
      sellerSignature: _signature,
      sellerIdVerified: _idVerified,
      agreementAcceptedAt: _agreedAt,
      labelNumber: widget.existing?.labelNumber,
      notes: _c['notes']!.text.trim(),
      purchasedAt: _purchasedAt,
      soldAt: widget.existing?.soldAt,
      createdAt: widget.existing?.createdAt,
      // A new purchase: what was handed over now. Empty "Paid now" is paid
      // in full. An edit keeps the payments as they are.
      sellerPayments:
          widget.existing?.sellerPayments ??
          (widget.existing != null
              ? null
              : [
                  if (_paidNow > 0)
                    SellerPayment(
                      amount: _paidNow,
                      method: _payMethod,
                      at: _purchasedAt,
                    ),
                ]),
      batchId:
          widget.existing?.batchId ??
          switch (widget.sameSellerAs) {
            final b? => b.inBatch ? b.batchId : b.id,
            null => '',
          },
    );
  }

  /// Paid to the seller now: what was typed, or the whole price.
  num get _paidNow => _c['paidNow']!.text.trim().isEmpty
      ? asAmount(_c['purchasePrice']!.text)
      : asAmount(_c['paidNow']!.text);

  /// What a grade asks to be said about it — the warranty and accessories of
  /// an A, the wear or damage of anything less.
  static List<String> _detailKeysFor(String grade) => grade == kGradeA
      ? const [kWarrantyExpiry, kAccessories]
      : const [kConditionDescription];

  void _recompute() {
    final device = _asDevice();
    setState(() => _result = _check(device));
    _saveDraft();
  }

  /// The purchase rules, plus the one only the shop's stock can answer:
  /// the same IMEI on a phone still in stock is a double entry (or worse).
  ValidationResult _check(SecondHandDevice device) {
    final raw = validatePurchase(device);
    // What was typed, not what was kept: 150 used to become "nothing" before
    // the check and go through.
    final typedBattery = _c['batteryHealth']!.text.trim();
    final battery = int.tryParse(typedBattery);
    final checked =
        typedBattery.isNotEmpty &&
            (battery == null || battery < 1 || battery > 100)
        ? ValidationResult({
            ...raw.errors,
            'batteryHealth': 'Battery health is 1 to 100%',
          }, raw.warnings)
        : raw;
    // Never more handed over than the phone costs.
    final paidCheck = widget.existing == null && _paidNow > device.purchasePrice
        ? ValidationResult({
            ...checked.errors,
            'paidNow': 'Paid now cannot be more than the price',
          }, checked.warnings)
        : checked;
    // A new purchase is a declaration the seller signs; an old record from
    // before signing was asked for can still be corrected.
    final base = widget.existing == null && (_signature ?? '').isEmpty
        ? ValidationResult({
            ...paidCheck.errors,
            'sellerSignature':
                'The seller has to sign before the phone is bought',
          }, paidCheck.warnings)
        : paidCheck;
    final withId = _idVerified && !_idPhotosComplete
        ? _withIdError(base)
        : base;
    return _withImeiClash(device, withId);
  }

  ValidationResult _withImeiClash(
    SecondHandDevice device,
    ValidationResult base,
  ) {
    if (device.imei.isEmpty || base.errors.containsKey('imei')) return base;
    final clash = context.read<SecondHandRepository>().devices.any(
      (d) => d.id != device.id && !d.isSold && d.imei == device.imei,
    );
    if (!clash) return base;
    return ValidationResult({
      ...base.errors,
      'imei': 'This IMEI is already on a phone in stock',
    }, base.warnings);
  }

  ValidationResult _withIdError(ValidationResult base) => ValidationResult({
    ...base.errors,
    'sellerIdVerified': 'Add both sides of the ID card',
  }, base.warnings);

  Future<void> _save({required bool printLabel, bool another = false}) async {
    var device = _asDevice();
    final result = _check(device);
    setState(() {
      _submitted = true;
      _result = result;
    });
    if (!result.isValid) {
      // Back to the earliest step with something wrong, and say what.
      final step = result.errors.keys
          .map(_stepOf)
          .reduce((a, b) => a < b ? a : b);
      final here = result.errors.entries.where((e) => _stepOf(e.key) == step);
      _goTo(step, problems: here.map((e) => e.key));
      final messenger = ScaffoldMessenger.of(context);
      final said = here.first.value;
      final jumped = await jumpToFirstError(
        context,
        here.map((e) => e.key).expand(_errorKeys),
      );
      if (!jumped) messenger.showSnackBar(SnackBar(content: Text(said)));
      return;
    }

    final repo = context.read<SecondHandRepository>();
    final drafts = context.read<DraftStore>();
    final settings = context.read<SettingsRepository>();
    final labels = _maybe<LabelRepository>(context);
    final printer = _maybe<PrintServer>(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.maybeOf(context);
    final l10n = context.l10n;

    // Saved first, always: a label printed for unsaved state is a sticker for
    // a record that does not exist.
    // "Saving…" while it goes; a failure is said, and the form stays open
    // with everything still in it.
    final newId = 'sh-${DateTime.now().millisecondsSinceEpoch}';
    // The first phone of a batch names it.
    if (another && device.id == 'new' && !device.inBatch) {
      device = device.copyWith(batchId: newId);
    }
    final earlier = widget.sameSellerAs;
    final stored = await guardSave(context, () async {
      // The phone this one was added to joins the batch too, if it was alone.
      if (earlier != null && !earlier.inBatch) {
        await repo.save(earlier.copyWith(batchId: earlier.id));
      }
      return repo.save(
        device.id == 'new'
            ? SecondHandDevice.fromMap(newId, {
                ...device.toMap(),
                'createdAt': DateTime.now().toIso8601String(),
              })
            : device,
      );
    });
    if (stored == null) return;
    await drafts.clear(_draftKey);

    // Filed AFTER the save, and nothing waits on it: a brand joining a
    // dropdown must never be able to fail the purchase that was just made.
    final filing = settings.learn(
      purchaseValues(
        brand: device.brand,
        model: device.model,
        ram: device.ram,
        rom: device.rom,
        colour: device.colour,
        supplier: device.supplier,
      ),
    );

    if (!mounted) return;
    var said = l10n.savedNamed(stored.title);
    if (printLabel && labels != null) {
      // "Printing…" over the form while the number is minted and sent.
      said = await whileBusy(context, () async {
        // Through the registry, which is the only thing that mints a number.
        final assignment = await labels.assign(
          LabelTargetKind.secondHand,
          stored.id,
        );
        if (!assignment.ok) return assignment.error!;
        final number = assignment.entry!.number;
        final sent = await printer?.printLabel(
          LabelPrintJob(
            number: number,
            title: stored.title,
            price: stored.askingPrice,
          ),
        );
        // The number is assigned either way: a failed print is not a failed
        // assignment, and the label can be reprinted from the phone's page.
        return sent == null || sent.sent
            ? l10n.labelPrinted('$number')
            : '${printErrorText(l10n, sent.error!)} — label $number';
      }(), label: l10n.printingNow);
    }
    if (!mounted) return;
    navigator.pop(another ? AnotherPurchase(stored) : null);
    messenger.showSnackBar(
      SnackBar(
        content: Text(another ? '$said · ${l10n.buyNextFromSeller}' : said),
        action: another || widget.existing != null || router == null
            ? null
            : SnackBarAction(
                key: const Key('saved-open'),
                label: l10n.openSaved,
                onPressed: () =>
                    router.go('/inventory/second-hand/${stored.id}'),
              ),
      ),
    );

    final filed = await filing;
    if (!filed.wroteSomething) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.addedToShopLists(filed.added))),
    );
  }

  /// The X. The only thing that throws the draft away.
  Future<void> _discard() async {
    // Five steps of typing are not thrown away on one tap (FM #20).
    final typed = _c.values.any((c) => c.text.trim().isNotEmpty);
    if (typed) {
      final sure = await confirmSheet(
        context,
        title: context.l10n.discardPurchaseTitle,
        body: context.l10n.discardPurchaseBody,
        yes: context.l10n.discardPurchaseYes,
        no: context.l10n.keepIt,
        yesKey: const Key('discard-confirm'),
      );
      if (!sure || !mounted) return;
    }
    await context.read<DraftStore>().clear(_draftKey);
    if (mounted) Navigator.of(context).pop();
  }

  /// "Start fresh": the picked-up draft is cleared and the form is empty.
  Future<void> _startFresh() async {
    await context.read<DraftStore>().clear(_draftKey);
    if (!mounted) return;
    setState(() {
      for (final c in _c.values) {
        c.clear();
      }
      _answers.clear();
      _repairs.clear();
      _photos.fillRange(0, _photos.length, '');
      _idCards.fillRange(0, _idCards.length, '');
      _sellerCustomerId = null;
      _signature = null;
      _idVerified = false;
      _agreedAt = null;
      _stillBeingRepaired = false;
      _purchasedAt = _today();
      _step = _kSeller;
      _resumed = false;
    });
    _recompute();
  }

  @override
  Widget build(BuildContext context) {
    final device = _asDevice();
    final errors = <String, String>{
      for (final e in _result.errors.entries)
        if (_submitted || _tried.contains(_stepOf(e.key)))
          e.key: ruleText(context, e.value),
    };
    final steps = [
      _sellerStep(errors),
      _phoneStep(errors, device),
      _conditionStep(errors, device),
      _priceStep(errors, device),
      _photosStep(errors),
      _signStep(errors),
    ];
    final last = _step == steps.length - 1;

    final theme = Theme.of(context);
    final labels = [
      context.l10n.seller,
      context.l10n.wizPhone,
      context.l10n.wizCondition,
      context.l10n.wizMoney,
      context.l10n.photos,
      context.l10n.wizDeclaration,
    ];
    // Soft white fields on the blush page: a thin line rather than a heavy
    // outline, and green when the field is being typed into.
    OutlineInputBorder line(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    final fields = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppTheme.surface,
        border: line(AppTheme.borderSubtle),
        enabledBorder: line(AppTheme.borderSubtle),
        focusedBorder: line(AppTheme.action, 2),
        errorBorder: line(theme.colorScheme.error),
        focusedErrorBorder: line(theme.colorScheme.error, 2),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormHeader(
              title: widget.existing == null
                  ? context.l10n.takeInAHandset
                  : context.l10n.editPurchase,
              stepText: context.l10n.wizStepOf(
                '${_step + 1}',
                '${steps.length}',
              ),
              stepName: labels[_step],
              onClose: _discard,
              bar: _StepBar(
                step: _step,
                labels: labels,
                // A tick means finished, not merely passed over: a step
                // skipped by tapping ahead keeps its icon until it is done.
                done: {
                  for (var i = 0; i < steps.length; i++)
                    if (i < _step &&
                        !_result.errors.keys.any((k) => _stepOf(k) == i))
                      i,
                },
                onTap: (i) => _goTo(i),
              ),
            ),
            Expanded(
              child: Theme(
                data: fields,
                child: ListView(
                  // A fresh scroll position per step: Next lands at the top.
                  key: ValueKey('step-body-$_step'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_resumed)
                      Card(
                        key: const Key('purchase-resumed'),
                        color: theme.colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(context.l10n.purchaseResumed),
                          trailing: TextButton(
                            key: const Key('purchase-start-fresh'),
                            onPressed: _startFresh,
                            child: Text(context.l10n.startFresh),
                          ),
                        ),
                      ),
                    ...steps[_step],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: !last
              ? Row(
                  children: [
                    if (_step > 0) ...[
                      _BackCircle(onPressed: () => _goTo(_step - 1)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        key: const Key('wizard-next'),
                        style: _pill,
                        onPressed: _next,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(context.l10n.wizNext),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _BackCircle(onPressed: () => _goTo(_step - 1)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => _save(printLabel: false),
                            child: Text(context.l10n.save),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // The main one: it puts the phone on the shelf with its
                    // sticker.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: _pill,
                        onPressed: () => _save(printLabel: true),
                        icon: const Icon(Icons.print_outlined),
                        label: Text(context.l10n.saveAndPrintLabel),
                      ),
                    ),
                    // The same person is selling more than one phone.
                    if (widget.existing == null)
                      TextButton.icon(
                        key: const Key('purchase-save-another'),
                        onPressed: () => _save(printLabel: true, another: true),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(context.l10n.saveBuyAnotherFromSeller),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  static final ButtonStyle _pill = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: const StadiumBorder(),
  );

  // ── Step 1: the seller ─────────────────────────────────────────────────
  //
  // First, as on the counter: the person is standing there, and someone who
  // has sold or bought here before fills the whole step with one tap.
  List<Widget> _sellerStep(Map<String, String> errors) {
    final theme = Theme.of(context);
    final customers = _maybe<CustomerRepository>(context);
    final picked = _sellerCustomerId != null;
    return [
      _StepTitle(
        icon: Icons.person_outline,
        title: context.l10n.wizSellerTitle,
      ),
      const SizedBox(height: 12),
      if (customers == null)
        // No customer book to search (offline, or a test pumping the form
        // bare): the seller is typed in by hand.
        _Panel([
          _SellerField(
            fieldKey: 'sellerName',
            label: context.l10n.fieldSellerName,
            help: context.l10n.helpSellerSearch,
            controller: _c['sellerName']!,
            error: errors['sellerName'],
            customers: null,
            onPicked: _pickCustomer,
          ),
          _SellerField(
            fieldKey: 'sellerPhone',
            label: context.l10n.fieldSellerPhone,
            help: context.l10n.helpSellerPhone,
            controller: _c['sellerPhone']!,
            error: errors['sellerPhone'],
            customers: null,
            keyboard: TextInputType.phone,
            onPicked: _pickCustomer,
          ),
          _altPhone(errors),
        ])
      else if (_addingCustomer)
        _NewCustomer(
          name: _looksLikePhone(_newCustomerSeed) ? '' : _newCustomerSeed,
          phone: _looksLikePhone(_newCustomerSeed) ? _newCustomerSeed : '',
          onCancel: () => setState(() => _addingCustomer = false),
          onSave: (c) async {
            final saved = await guardSave(context, () => customers.save(c));
            if (saved == null || !mounted) return;
            setState(() => _addingCustomer = false);
            _pickCustomer(saved);
          },
        )
      else if (_hasSeller)
        _Panel([
          _SellerCard(
            name: _c['sellerName']!.text.trim(),
            phone: _c['sellerPhone']!.text.trim(),
            fromCustomers: picked,
            // How many phones this number has sold the shop before: a
            // regular is worth knowing, and so is a stranger with five.
            soldBefore: _soldBefore(_c['sellerPhone']!.text),
            onChange: _clearSeller,
          ),
          const SizedBox(height: 12),
          _altPhone(errors),
        ])
      else
        _Panel([
          // Search first, select if they are there, add if they are not.
          SmartAutocomplete<Customer>(
            fieldKey: const Key('purchase-sellerSearch'),
            controller: _sellerQuery,
            loading: customers.loading,
            keyboardType: TextInputType.text,
            search: (q) => suggestCustomers(customers.customers, q, limit: 5),
            titleOf: (c) => c.name.isEmpty ? c.phone : c.name,
            subtitleOf: (c) => c.name.isEmpty ? null : c.phone,
            leadingOf: (c) => CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(c.initials),
            ),
            optionKey: (c) => Key('customer-${c.id}'),
            onSelected: _pickCustomer,
            // The same person is the same number, and a name typed exactly
            // is somebody already on the books: no second record either way.
            isExisting: (q) =>
                findByPhone(customers.customers, q) != null ||
                customers.customers.any(
                  (c) => c.name.trim().toLowerCase() == q.trim().toLowerCase(),
                ),
            createKey: const Key('add-customer'),
            createLabel: context.l10n.addAsNewCustomer,
            onCreate: (q) => setState(() {
              _newCustomerSeed = q;
              _addingCustomer = true;
            }),
            decoration: InputDecoration(
              label: FieldLabel(context.l10n.sellerSearchLabel, required: true),
              hintText: context.l10n.sellerSearchHint,
              prefixIcon: const Icon(Icons.search),
              errorText: errors['sellerName'] ?? errors['sellerPhone'],
              suffixIcon: HelpButton(
                title: context.l10n.sellerSearchLabel,
                body: context.l10n.helpSellerSearch,
              ),
            ),
          ),
        ]),
      _MoreDetails(
        step: _kSeller,
        open: _open.contains(_kSeller),
        onToggle: () => _toggleMore(_kSeller),
        children: [
          _field(
            'sellerIdProof',
            context.l10n.idProof,
            context.l10n.helpIdProof,
            errors,
          ),
        ],
      ),
    ];
  }

  bool get _hasSeller =>
      _c['sellerName']!.text.trim().isNotEmpty ||
      _c['sellerPhone']!.text.trim().isNotEmpty;

  static bool _looksLikePhone(String s) =>
      RegExp(r'^[+\d][\d\s-]*$').hasMatch(s.trim());

  Widget _altPhone(Map<String, String> errors) => _field(
    'sellerAltPhone',
    context.l10n.fieldAltPhone,
    context.l10n.helpAltPhone,
    errors,
    keyboard: TextInputType.phone,
  );

  /// "Change": back to an empty search box. What came with a picked customer
  /// goes with them, so the next seller does not inherit their ID.
  void _clearSeller() {
    final fromCustomer = _sellerCustomerId != null;
    setState(() {
      _sellerCustomerId = null;
      _sellerQuery.clear();
      _c['sellerName']!.clear();
      _c['sellerPhone']!.clear();
      _c['sellerAltPhone']!.clear();
      if (fromCustomer) _c['sellerIdProof']!.clear();
    });
    _recompute();
  }

  /// Someone who has been to the shop before: their name, numbers and ID
  /// come with them.
  void _pickCustomer(Customer c) {
    _sellerCustomerId = c.id;
    _c['sellerName']!.text = c.name;
    _c['sellerPhone']!.text = c.phone;
    _c['sellerAltPhone']!.text = c.altPhone;
    if (c.idType.isNotEmpty || c.idNumber.isNotEmpty) {
      _c['sellerIdProof']!.text = [
        c.idType,
        c.idNumber,
      ].where((p) => p.isNotEmpty).join(' ');
    }
    _fillIdFromEarlier(c);
    FocusScope.of(context).unfocus();
    _recompute();
  }

  /// A seller who has sold here before: their ID card photos from the last
  /// purchase are used again, rather than photographing the same card. A
  /// purchase older than the live list is asked of the server.
  void _fillIdFromEarlier(Customer c) {
    if (_idCards.any((p) => p.isNotEmpty)) return;
    final repo = context.read<SecondHandRepository>();
    if (_useIdFrom(c, repo.devices) || repo.liveSince == null) return;
    repo
        .fetchOlder(sellerCustomerId: c.id, sellerPhone: c.phone)
        .then((older) {
          if (mounted && !_idCards.any((p) => p.isNotEmpty)) {
            _useIdFrom(c, older);
          }
        })
        .catchError((Object _) {});
  }

  /// Fills the ID card from [c]'s latest purchase among [devices] that has
  /// both sides; false when there is none.
  bool _useIdFrom(Customer c, Iterable<SecondHandDevice> devices) {
    final earlier =
        devices
            .where(
              (d) =>
                  d.id != widget.existing?.id &&
                  (d.sellerCustomerId == c.id ||
                      samePhone(d.sellerPhone, c.phone)) &&
                  d.idCardPhotos.where((p) => p.isNotEmpty).length >= 2,
            )
            .toList()
          ..sort(
            (a, b) => (b.purchasedAt ?? DateTime(2000)).compareTo(
              a.purchasedAt ?? DateTime(2000),
            ),
          );
    if (earlier.isEmpty) return false;
    final last = earlier.first;
    setState(() {
      _fill(_idCards, last.idCardPhotos);
      _idFromEarlier = last.purchasedAt ?? DateTime.now();
    });
    return true;
  }

  // ── Step 2: which phone ────────────────────────────────────────────────
  List<Widget> _phoneStep(Map<String, String> errors, SecondHandDevice device) {
    final brandTyped = _c['brand']!.text.trim().isNotEmpty;
    final apple = isApple(device.brand);
    final seller = widget.sameSellerAs;
    return [
      if (seller != null)
        Card(
          key: const Key('purchase-batch-banner'),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.add_to_photos_outlined),
            title: Text(
              context.l10n.buyAnotherFrom(
                seller.sellerName.isEmpty
                    ? seller.sellerPhone
                    : seller.sellerName,
              ),
            ),
            subtitle: Text(context.l10n.buyAnotherSameSeller),
          ),
        ),
      _StepTitle(
        icon: Icons.smartphone_outlined,
        title: context.l10n.wizPhoneTitle,
      ),
      const SizedBox(height: 12),
      _Panel([
        _PickField(
          fieldKey: 'brand',
          required: true,
          label: context.l10n.brand,
          help: context.l10n.helpBrand,
          controller: _c['brand']!,
          error: errors['brand'],
          newHint: _newHint(_brands, 'brand'),
          matched: _brands.contains(_c['brand']!.text),
          // A real one from the shop's own list, so the example is never a
          // brand this shop does not sell.
          example: _exampleFrom(_brands, 'Samsung'),
          // The brands this shop buys most, first.
          values: byUse(_brands.values, [
            for (final d in context.read<SecondHandRepository>().devices)
              d.brand,
          ]),
          onPicked: (v) => _pick('brand', v),
          createLabel: context.l10n.addAsNewBrand,
          onCreate: (v) => _addToList(
            'brand',
            v,
            () => _settings.addOption(OptionKind.brands, v),
          ),
        ),
        _PickField(
          fieldKey: 'model',
          required: true,
          label: context.l10n.model,
          help: context.l10n.helpModel,
          controller: _c['model']!,
          error: errors['model'],
          newHint: brandTyped ? _newHint(_models, 'model') : null,
          matched: _models.contains(_c['model']!.text),
          // This brand's models only.
          values: modelChoices(
            _models,
            _c['brand']!.text,
            modelRecords(context),
          ),
          emptyHint: brandTyped
              ? context.l10n.noModelsYet(_c['brand']!.text.trim())
              : null,
          waiting: brandTyped ? null : context.l10n.pickBrandFirst,
          // The chosen brand's own first model, once there is a brand.
          example: _exampleFrom(_models, 'Galaxy A54'),
          onPicked: (v) => _pick('model', v),
          createLabel: context.l10n.addAsNewModel,
          onCreate: brandTyped
              ? (v) => _addToList(
                  'model',
                  v,
                  () => _settings.addModel(_c['brand']!.text.trim(), v),
                )
              : null,
        ),
        _PickField(
          fieldKey: 'ram',
          required: true,
          label: context.l10n.optionRam,
          help: context.l10n.helpRam,
          controller: _c['ram']!,
          error: errors['ram'],
          newHint: _newHint(_ram, 'ram'),
          matched: _ram.contains(_c['ram']!.text),
          example: '6GB',
          values: _ram.sorted,
          onPicked: (v) => _pick('ram', v),
          createLabel: context.l10n.addAsNewRam,
          onCreate: (v) => _addToList(
            'ram',
            v,
            () => _settings.addOption(OptionKind.ram, v),
          ),
        ),
        _PickField(
          fieldKey: 'rom',
          required: true,
          label: context.l10n.optionRom,
          help: context.l10n.helpRom,
          controller: _c['rom']!,
          error: errors['rom'],
          newHint: _newHint(_rom, 'rom'),
          matched: _rom.contains(_c['rom']!.text),
          example: '128GB',
          values: _rom.sorted,
          onPicked: (v) => _pick('rom', v),
          createLabel: context.l10n.addAsNewRom,
          onCreate: (v) => _addToList(
            'rom',
            v,
            () => _settings.addOption(OptionKind.rom, v),
          ),
        ),
        const SizedBox(height: 8),
        _field(
          'imei',
          'IMEI',
          context.l10n.helpImei,
          errors,
          keyboard: TextInputType.number,
          required: true,
          hint: _imeiHelp(_c['imei']!.text),
          // Fifteen digits nobody types right: scan them instead. One go
          // fills both IMEIs when the box has two.
          action: ImeiScanButton(
            onScanned: (first, second) {
              _c['imei']!.text = first;
              if (second != null) _c['imei2']!.text = second;
              _recompute();
            },
          ),
        ),
        _field(
          'imei2',
          context.l10n.imei2,
          context.l10n.helpImei2,
          errors,
          keyboard: TextInputType.number,
        ),
        _field(
          'serial',
          context.l10n.serial,
          apple ? context.l10n.helpSerialApple : context.l10n.helpSerial,
          errors,
          hint: apple ? context.l10n.serialAppleHint : null,
          required: apple,
          // Printed as a barcode on the box label: scanned, not typed.
          action: SerialScanButton(
            apple: apple,
            onScanned: (serial) {
              _c['serial']!.text = serial;
              _recompute();
            },
          ),
        ),
      ]),
      _MoreDetails(
        step: _kPhone,
        open: _open.contains(_kPhone),
        onToggle: () => _toggleMore(_kPhone),
        children: [
          _PickField(
            fieldKey: 'colour',
            label: context.l10n.colour,
            help: context.l10n.helpColour,
            controller: _c['colour']!,
            error: errors['colour'],
            newHint: _newHint(_colours, 'colour'),
            matched: _colours.contains(_c['colour']!.text),
            values: _colours.values,
            swatches: true,
            example: _exampleFrom(_colours, 'Black'),
            onPicked: (v) => _pick('colour', v),
            createLabel: context.l10n.addAsNewColour,
            onCreate: (v) => _addToList(
              'colour',
              v,
              () => _settings.addOption(OptionKind.colours, v),
            ),
          ),
        ],
      ),
    ];
  }

  int _soldBefore(String phone) {
    final number = normalizePhone(phone);
    if (number.isEmpty) return 0;
    return context
        .read<SecondHandRepository>()
        .devices
        .where(
          (d) =>
              d.id != widget.existing?.id &&
              normalizePhone(d.sellerPhone) == number,
        )
        .length;
  }

  // ── Step 3: condition and grade ────────────────────────────────────────
  List<Widget> _conditionStep(
    Map<String, String> errors,
    SecondHandDevice device,
  ) {
    final theme = Theme.of(context);
    final brand = device.brand;
    final checklist = checklistFor(brand);
    final grade = gradeFrom(_answers, checklist: checklist);
    final shown = _gradeOverride ?? grade.grade;
    final apple = isApple(brand);

    Widget group(String title, List<ConditionItem> items) {
      final byCategory = <String, List<ConditionItem>>{};
      for (final item in items) {
        byCategory.putIfAbsent(item.category, () => []).add(item);
      }
      return _Panel([
        Text(title, style: theme.textTheme.titleSmall),
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Text(
              checklistCategoryLabel(context, entry.key).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Column(
            children: [
              for (final item in entry.value)
                _CheckTile(
                  item: item,
                  label: checklistLabel(context, item.key, item.label),
                  passed: passed(item, _answers),
                  onChanged: (ok) {
                    setState(() => _answers[item.key] = ok);
                    _recompute();
                  },
                ),
            ],
          ),
        ],
      ]);
    }

    return [
      _StepTitle(
        icon: Icons.fact_check_outlined,
        title: context.l10n.wizConditionTitle,
        help: context.l10n.helpChecklist,
      ),
      const SizedBox(height: 12),
      KeyedSubtree(
        key: const Key('purchase-grade'),
        child: _GradePicker(
          shown: shown,
          manual: _gradeOverride != null,
          faults: grade.faults,
          onPick: (g) {
            // Tapping the letter already chosen by hand gives it back to the
            // checklist.
            setState(
              () => _gradeOverride =
                  _gradeOverride == g ||
                      (_gradeOverride == null && g == grade.grade)
                  ? null
                  : g,
            );
            _recompute();
          },
        ),
      ),
      const SizedBox(height: 12),
      // Battery health is the number buyers ask about first, so it is asked
      // here, as a number, rather than as a pass/fail check.
      _Panel([
        _field(
          'batteryHealth',
          context.l10n.batteryHealthLabel,
          context.l10n.batteryHealthHelp,
          errors,
          keyboard: TextInputType.number,
          hint: context.l10n.batteryHealthHint,
        ),
      ]),
      const SizedBox(height: 12),
      if (_c['brand']!.text.trim().isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.checklistNeedsBrand,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      group(context.l10n.checksCommon, kCommonChecks),
      const SizedBox(height: 12),
      group(
        apple ? context.l10n.checksIphone : context.l10n.checksAndroid,
        apple ? kIphoneChecks : kAndroidChecks,
      ),
      const SizedBox(height: 16),
      _Panel([
        HelpTitle(
          text: context.l10n.notesFeatures,
          help: context.l10n.helpGradeDetails,
          style: theme.textTheme.titleSmall,
        ),
        if (shown == kGradeA) ...[
          _DateField(
            fieldKey: kWarrantyExpiry,
            label: context.l10n.warrantyExpiry,
            controller: _c[kWarrantyExpiry]!,
            optional: true,
          ),
          _field(
            kAccessories,
            context.l10n.accessoriesIncluded,
            context.l10n.helpGradeDetails,
            errors,
          ),
        ] else
          _field(
            kConditionDescription,
            switch (shown) {
              kGradeB => context.l10n.describeWear,
              kGradeC => context.l10n.describeCondition,
              _ => context.l10n.describeDamage,
            },
            context.l10n.helpGradeDetails,
            errors,
            lines: 2,
          ),
        _field(
          'notes',
          context.l10n.notes,
          context.l10n.helpNotes,
          errors,
          lines: 2,
        ),
      ]),
    ];
  }

  // ── Step 4: the money ──────────────────────────────────────────────────
  List<Widget> _priceStep(Map<String, String> errors, SecondHandDevice device) {
    return [
      _StepTitle(icon: Icons.currency_rupee, title: context.l10n.wizMoneyTitle),
      const SizedBox(height: 12),
      // The shop's own memory of this model's prices, before one is said.
      Builder(
        builder: (context) {
          final h = priceHistoryFor(
            context.read<SecondHandRepository>().devices,
            brand: device.brand,
            model: device.model,
            excludeId: widget.existing?.id,
          );
          if (h == null) return const SizedBox.shrink();
          final paid = h.paidLow == h.paidHigh
              ? rupees(h.paidLow)
              : '${rupees(h.paidLow)}–${rupees(h.paidHigh)}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: const Key('price-history'),
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(context.l10n.pricePaidBefore(h.bought, paid)),
                subtitle: h.soldAverage == null
                    ? null
                    : Text(
                        context.l10n.priceSoldBefore(
                          h.sold,
                          rupees(h.soldAverage),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      _Panel([
        _field(
          'purchasePrice',
          context.l10n.paidToSeller,
          context.l10n.helpPaid,
          errors,
          keyboard: TextInputType.number,
          money: true,
          required: true,
        ),
        // An advance now and the rest later: only what was handed over.
        if (widget.existing == null) ...[
          _field(
            'paidNow',
            context.l10n.paidNowLabel,
            context.l10n.paidNowHelp,
            errors,
            keyboard: TextInputType.number,
            money: true,
          ),
          ChoiceRow(
            key: const Key('purchase-pay-method'),
            values: const ['Cash', 'UPI'],
            selected: _payMethod,
            labelOf: (m) => m,
            onPicked: (m) => setState(() => _payMethod = m),
          ),
          if (asAmount(_c['purchasePrice']!.text) - _paidNow > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.l10n.balanceToSeller(
                  rupees(asAmount(_c['purchasePrice']!.text) - _paidNow),
                ),
                key: const Key('purchase-balance'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        _field(
          'askingPrice',
          context.l10n.fieldAskingPrice,
          context.l10n.helpAsking,
          errors,
          keyboard: TextInputType.number,
          money: true,
          required: true,
        ),
        // Live, with the repairs in it — the reason to cost repairs here.
        KeyedSubtree(
          key: const Key('purchase-profit'),
          child: _ProfitLine(costing: device.costing),
        ),
        const SizedBox(height: 14),
        _DateTile(
          label: context.l10n.purchaseDate,
          help: context.l10n.helpPurchaseDate,
          value: _purchasedAt,
          error: errors['purchasedAt'],
          onChanged: (d) {
            setState(() => _purchasedAt = d);
            _recompute();
          },
        ),
        const SizedBox(height: 8),
        _PickField(
          fieldKey: 'supplier',
          label: context.l10n.fieldSupplier,
          help: context.l10n.helpSupplier,
          controller: _c['supplier']!,
          error: errors['supplier'],
          newHint: _newHint(_suppliers, 'supplier'),
          matched: _suppliers.contains(_c['supplier']!.text),
          values: _suppliers.values,
          example: _exampleFrom(_suppliers, 'Local market'),
          onPicked: (v) => _pick('supplier', v),
          createLabel: context.l10n.addAsNewSupplier,
          onCreate: (v) => _addToList(
            'supplier',
            v,
            () => _settings.addOption(OptionKind.suppliers, v),
          ),
        ),
      ]),
      _MoreDetails(
        step: _kPrice,
        open: _open.contains(_kPrice),
        onToggle: () => _toggleMore(_kPrice),
        children: [
          _field(
            'otherCost',
            context.l10n.otherCosts,
            context.l10n.helpOtherCost,
            errors,
            keyboard: TextInputType.number,
            money: true,
          ),
          // Costed here, not as a service order: a service order assumes a
          // customer owes money, which lands this in Due Payments as a debt
          // and in Reports as revenue nobody paid.
          HelpTitle(
            text: context.l10n.repairs,
            help: context.l10n.helpRepairs,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (var i = 0; i < _repairs.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_repairs[i].description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rupees(_repairs[i].amount),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: context.shopColors.stop,
                    ),
                    onPressed: () {
                      setState(() => _repairs.removeAt(i));
                      _recompute();
                    },
                  ),
                ],
              ),
            ),
          if (errors.containsKey('repairs')) _ErrorText(errors['repairs']!),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addRepair,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addARepair),
            ),
          ),
          const SizedBox(height: 8),
          _HelpSwitch(
            value: _stillBeingRepaired,
            title: context.l10n.stillOnTheBench,
            subtitle: context.l10n.stillOnTheBenchHint,
            help: context.l10n.helpBench,
            onChanged: (v) {
              setState(() => _stillBeingRepaired = v);
              _recompute();
            },
          ),
        ],
      ),
      if (_result.hasWarnings) _Warnings(warnings: _result.warnings),
    ];
  }

  // ── Step 5: photos ─────────────────────────────────────────────────────
  //
  // Last, as on the counter: the phone has been handled and checked, and the
  // photos show it as it was bought. Only the front is required.
  List<Widget> _photosStep(Map<String, String> errors) {
    final slotLabels = [
      context.l10n.photoSlotFront,
      context.l10n.photoSlotBack,
      context.l10n.photoSlotLeft,
      context.l10n.photoSlotRight,
      context.l10n.photoSlotTopBottom,
      context.l10n.photoSlotExtra,
    ];
    return [
      _StepTitle(
        icon: Icons.photo_camera_outlined,
        title: context.l10n.wizPhotosTitle,
        help: context.l10n.helpPhotos,
      ),
      const SizedBox(height: 12),
      _PhotoGrid(
        prefix: 'photo',
        keys: kPhotoSlots,
        labels: slotLabels,
        values: _photos,
        required: const {0},
        errorAt: errors.containsKey('photos') ? 0 : null,
        pick: _photoPicker(),
        onChanged: (i, v) {
          setState(() => _photos[i] = v);
          _recompute();
        },
      ),
      if (errors.containsKey('photos'))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _ErrorText(errors['photos']!),
        ),
    ];
  }

  /// The declaration read to the seller, the ID check and the signature —
  /// its own step, last, once the price is agreed.
  List<Widget> _signStep(Map<String, String> errors) => [
    // Last, as on the counter: the price is agreed, so the declaration's
    // "the amount stated above" means something when it is read out.
    _Declaration(
      terms: [
        context.l10n.purchaseTerm1,
        context.l10n.purchaseTerm2,
        context.l10n.purchaseTerm3,
        context.l10n.purchaseTerm4,
        context.l10n.purchaseTerm5,
        context.l10n.purchaseTerm6,
        context.l10n.purchaseTerm7,
        context.l10n.purchaseTerm8,
        context.l10n.purchaseTerm9,
      ],
      agreed: _agreedAt != null,
      idVerified: _idVerified,
      signature: _signature,
      signatureError: errors['sellerSignature'],
      onAgreed: (v) {
        setState(() => _agreedAt = v ? DateTime.now() : null);
        _recompute();
      },
      onIdVerified: (v) {
        setState(() {
          if (v && !_idPhotosComplete) {
            // No ticking "I checked their ID" with no ID to show for it:
            // the two photos are asked for, here.
            _askIdPhotos = true;
            _idVerified = false;
          } else {
            _idVerified = v;
          }
        });
        _recompute();
      },
      idPhotos:
          _askIdPhotos ||
              _idFromEarlier != null ||
              _idCards.any((p) => p.isNotEmpty) ||
              errors.containsKey('sellerIdVerified')
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_idPhotosComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ErrorText(context.l10n.idPhotosFirst),
                  ),
                if (_idFromEarlier != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.l10n.idFromEarlier(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(_idFromEarlier!),
                      ),
                      key: const Key('idcard-from-earlier'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                _PhotoGrid(
                  prefix: 'idcard',
                  keys: const ['front', 'back'],
                  labels: [context.l10n.idCardFront, context.l10n.idCardBack],
                  values: _idCards,
                  required: const {0, 1},
                  pick: _photoPicker(),
                  onChanged: (i, v) {
                    setState(() {
                      _idCards[i] = v;
                      _idFromEarlier = null;
                    });
                    _recompute();
                  },
                ),
              ],
            )
          : null,
      onSigned: (dataUrl) {
        setState(() => _signature = dataUrl);
        _recompute();
      },
    ),
  ];

  /// Take or choose a real photo, when this build can upload one. Null when
  /// it cannot, and the tile records that the photo was taken instead.
  Future<String?> Function(PhotoProgress onProgress)? _photoPicker() {
    final uploader = _maybe<PhotoUploader>(context);
    if (uploader == null || !uploader.isConfigured) return null;
    return (onProgress) async {
      final messenger = ScaffoldMessenger.of(context);
      final lang = Localizations.localeOf(context).languageCode;
      final l10n = context.l10n;
      final camera = await pickPhotoSource(context);
      if (camera == null) return null;
      try {
        final url = await uploader.pickAndUpload(
          camera: camera,
          onProgress: onProgress,
        );
        if (url != null) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.photoSaved)));
        }
        return url;
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(ruleTextIn(lang, plainError(e)))),
        );
        return null;
      }
    };
  }

  void _toggleMore(int step) => setState(
    () => _open.contains(step) ? _open.remove(step) : _open.add(step),
  );

  ShopSettings get _shopSettings =>
      context.watch<SettingsRepository>().settings;

  OptionSet get _brands => _shopSettings.list(OptionKind.brands);
  OptionSet get _models => _shopSettings.modelsFor(_c['brand']!.text);
  OptionSet get _colours => _shopSettings.list(OptionKind.colours);
  OptionSet get _suppliers => _shopSettings.list(OptionKind.suppliers);

  /// A shop made before RAM and storage were lists has no such field in its
  /// settings yet, so it is offered the counter app's own list until its
  /// first save files one.
  OptionSet get _ram => _orDefault(OptionKind.ram, kDefaultRam);
  OptionSet get _rom => _orDefault(OptionKind.rom, kDefaultRom);

  OptionSet _orDefault(OptionKind kind, List<String> fallback) {
    final list = _shopSettings.list(kind);
    return list.isEmpty ? OptionSet(fallback) : list;
  }

  /// "New — will be added to your list" under a field holding something the
  /// shop has not seen, so nobody wonders whether they spelled it wrong.
  String? _newHint(OptionSet list, String key) =>
      list.isNew(_c[key]!.text) ? context.l10n.newToShopList : null;

  String _exampleFrom(OptionSet list, String fallback) =>
      list.isEmpty ? fallback : list.values.first;

  SettingsRepository get _settings => context.read<SettingsRepository>();

  /// "+ Add … as a new brand": it goes into the shop's list now, so it is
  /// there to pick next time — and into the field.
  ///
  /// A failed write does not lose what was typed: the field keeps it, and
  /// the save files it as it always has.
  Future<void> _addToList(
    String key,
    String value,
    Future<OptionWriteResult> Function() write,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    final result = await write();
    if (!mounted) return;
    _pick(key, value);
    if (!result.ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.couldNotAddToList(result.error!))),
      );
    }
  }

  void _pick(String key, String value) {
    // read, not watch: this runs from a tap, outside a build.
    final lists = context.read<SettingsRepository>().settings;
    final oldModels = lists.modelsFor(_c['brand']!.text);
    _c[key]!.text = value;
    final model = _c['model']!.text;
    final newModels = lists.modelsFor(_c['brand']!.text);
    // Picking a different brand empties a model that belonged to the old one
    // — but not a model typed by hand, which may be the new brand's.
    if (key == 'brand' &&
        oldModels.contains(model) &&
        !newModels.contains(model)) {
      _c['model']!.clear();
    }
    _recompute();
  }

  String? _imeiHelp(String imei) {
    if (imei.isEmpty) return null;
    if (!looksLikeImei(imei)) return null;
    final tac = tacOf(imei);
    // The TAC is what the device database is keyed on, so a scan can prefill
    // brand and model instead of a dropdown of four hundred models.
    return 'TAC $tac${imei.length == 15 && !passesLuhn(imei) ? ' · check digit does not add up' : ''}';
  }

  Future<void> _addRepair() async {
    final repair = await showInputSheet<RepairCost>(
      context: context,
      builder: (_) => const _RepairDialog(),
    );
    if (repair == null) return;
    setState(() => _repairs.add(repair));
    _recompute();
  }

  /// Every field has its "?" at the right edge, in the same place every
  /// time, so it is found once and then always.
  Widget _field(
    String key,
    String label,
    String help,
    Map<String, String> errors, {
    TextInputType? keyboard,
    int lines = 1,
    String? hint,
    bool money = false,
    Widget? action,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        textInputAction: lines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        // Keyed so a test can drive the field by name. The label alone is not
        // enough: Material renders it in more than one place.
        key: Key('purchase-$key'),
        controller: _c[key],
        keyboardType: keyboardFor(key) ?? keyboard,
        maxLines: lines,
        // The app-wide typing rule for this kind of box (input_rules.dart).
        inputFormatters: inputRuleFor(key),
        maxLength: maxDigitsFor(key),
        // Money is the number people check twice, so it is written big.
        style: money
            ? Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)
            : null,
        decoration: InputDecoration(
          // The same icon as on the record page.
          prefixIcon: fieldIcon(key) == null ? null : Icon(fieldIcon(key)),
          label: FieldLabel(label, required: required),
          floatingLabelBehavior: money ? FloatingLabelBehavior.always : null,
          // The ₹ in front says "money" before the label is read.
          prefixText: money ? '₹ ' : null,
          errorText: errors[key],
          helperText: hint,
          suffixIcon: action == null
              ? HelpButton(title: label, body: help)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    action,
                    HelpButton(title: label, body: help),
                  ],
                ),
        ),
      ),
    );
  }
}

const List<String> _fields = [
  'brand',
  'model',
  'ram',
  'rom',
  'colour',
  'imei',
  'imei2',
  'serial',
  'purchasePrice',
  'paidNow',
  'otherCost',
  'askingPrice',
  'supplier',
  'sellerName',
  'sellerPhone',
  'sellerAltPhone',
  'sellerIdProof',
  'notes',
  kWarrantyExpiry,
  kAccessories,
  kConditionDescription,
  'batteryHealth',
];

/// The seller's name or phone, with the shop's customers matching what is
/// typed listed underneath — the same as the counter app's customer search.
/// Tapping one fills in the whole seller.
class _SellerField extends StatefulWidget {
  const _SellerField({
    required this.fieldKey,
    required this.label,
    required this.help,
    required this.controller,
    required this.error,
    required this.customers,
    required this.onPicked,
    this.keyboard,
  });

  final String fieldKey;
  final String label;
  final String help;
  final TextEditingController controller;
  final String? error;
  final CustomerRepository? customers;
  final ValueChanged<Customer> onPicked;
  final TextInputType? keyboard;

  @override
  State<_SellerField> createState() => _SellerFieldState();
}

class _SellerFieldState extends State<_SellerField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typed = widget.controller.text.trim();
    final matches =
        widget.customers == null || typed.isEmpty || !_focus.hasFocus
        ? const <Customer>[]
        : suggestCustomers(widget.customers!.customers, typed, limit: 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              textInputAction: TextInputAction.search,
              key: Key('purchase-${widget.fieldKey}'),
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: keyboardFor(widget.fieldKey) ?? widget.keyboard,
              textCapitalization: TextCapitalization.words,
              inputFormatters: inputRuleFor(widget.fieldKey),
              maxLength: maxDigitsFor(widget.fieldKey),
              decoration: InputDecoration(
                label: FieldLabel(widget.label, required: true),
                hintText: context.l10n.sellerSearch,
                prefixIcon: const Icon(Icons.search),
                errorText: widget.error,
                suffixIcon: HelpButton(title: widget.label, body: widget.help),
              ),
            ),
            if (matches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                // A Material of its own, so a row's tap ripple shows.
                child: Material(
                  color: theme.colorScheme.surface,
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < matches.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ListTile(
                          key: Key('customer-${matches[i].id}'),
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text(
                              matches[i].initials,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            matches[i].name.isEmpty
                                ? matches[i].phone
                                : matches[i].name,
                          ),
                          subtitle: Text(matches[i].phone),
                          onTap: () {
                            widget.onPicked(matches[i]);
                            _focus.unfocus();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The seller, once chosen: who they are, whether they came from the
/// customer book, and a way to choose someone else.
class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.name,
    required this.phone,
    required this.fromCustomers,
    required this.onChange,
    this.soldBefore = 0,
  });

  final String name;
  final String phone;
  final bool fromCustomers;
  final int soldBefore;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    final title = name.isEmpty ? phone : name;
    final initials = title
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      key: const Key('seller-card'),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (name.isNotEmpty && phone.isNotEmpty)
                  Text(phone, style: theme.textTheme.bodyMedium),
                if (soldBefore > 0)
                  Text(
                    context.l10n.sellerSoldBefore(soldBefore),
                    key: const Key('seller-sold-before'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (fromCustomers)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, size: 16, color: c.good),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            context.l10n.sellerPicked,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.good,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            key: const Key('change-seller'),
            onPressed: onChange,
            child: Text(context.l10n.changeSeller),
          ),
        ],
      ),
    );
  }
}

/// "+ Add new customer", inline: name, phone, the ID they showed and its
/// number, as the counter app asks. Saved to the shop's customers and picked
/// as the seller in one go.
class _NewCustomer extends StatefulWidget {
  const _NewCustomer({
    required this.name,
    required this.phone,
    required this.onCancel,
    required this.onSave,
  });

  final String name;
  final String phone;
  final VoidCallback onCancel;
  final Future<void> Function(Customer) onSave;

  @override
  State<_NewCustomer> createState() => _NewCustomerState();
}

class _NewCustomerState extends State<_NewCustomer> {
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  final _idNumber = TextEditingController();
  final _address = TextEditingController();
  String _idType = kIdTypes.first;
  Map<String, String> _errors = const {};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idNumber.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final customer = Customer(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      idType: _idType,
      idNumber: _idNumber.text.trim(),
      address: _address.text.trim(),
    );
    final errors = <String, String>{
      if (customer.name.isEmpty) 'name': context.l10n.fieldSellerName,
      // The same check as Customers > Add: a number already in the book is
      // that customer, not a second record (FM #9).
      ...ruleTexts(
        context,
        validateCustomer(
          customer,
          existing: _maybe<CustomerRepository>(context)?.customers ?? const [],
        ).errors,
      ),
    };
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(customer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.addNewCustomer,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.cancel,
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              textInputAction: TextInputAction.next,
              key: const Key('new-customer-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.fieldSellerName,
                errorText: _errors.containsKey('name') ? _errors['name'] : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              textInputAction: TextInputAction.next,
              key: const Key('new-customer-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: phoneInput(),
              maxLength: kPhoneDigits,
              decoration: InputDecoration(
                labelText: context.l10n.fieldSellerPhone,
                errorText: _errors['phone'],
              ),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.idTypeLabel, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            ChoiceRow(
              values: kIdTypes,
              selected: _idType,
              labelOf: (t) => t,
              onPicked: (t) => setState(() => _idType = t),
            ),
            const SizedBox(height: 10),
            TextField(
              textInputAction: TextInputAction.next,
              key: const Key('new-customer-id'),
              controller: _idNumber,
              decoration: InputDecoration(
                labelText: context.l10n.idNumberLabel,
                suffixIcon: HelpButton(
                  title: context.l10n.idNumberLabel,
                  body: context.l10n.helpIdNumber,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              textInputAction: TextInputAction.next,
              key: const Key('new-customer-address'),
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.address,
                helperText: context.l10n.addressOptionalHelp,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('new-customer-save'),
              onPressed: _saving ? null : _save,
              child: Text(context.l10n.saveAndSelect),
            ),
          ],
        ),
      ),
    );
  }
}

/// One checklist line: its words, and two answers. "Working / Not working",
/// or "Yes / No" for a fault question, where "Yes" is the fault and so is the
/// red one. Starts on the passing answer; tap the other to mark a fault.
/// One check as a tile: what it is, and a tick or a cross. Every check
/// starts as passing, so staff tap only what is wrong — one tap flips it.
///
/// The key names the answer the tap gives, so a test (or anyone reading the
/// tree) can tell which way a tap will go: `-no` marks a fault, `-yes` takes
/// it back.
class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.item,
    required this.label,
    required this.passed,
    required this.onChanged,
  });

  final ConditionItem item;
  final String label;
  final bool passed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    final working = item.kind == CheckKind.working;
    // The two answers, the good one first. For a question ("iCloud locked?")
    // the good answer is No.
    final good = working ? context.l10n.checkWorks : context.l10n.answerNo;
    final bad = working ? context.l10n.checkNotWorking : context.l10n.answerYes;

    // The button that would change the answer carries the key a tap on the
    // old tile had: check-<item>-no when it passes, -yes when it fails.
    Widget answer(String text, bool forGood) {
      final on = passed == forGood;
      final colour = forGood ? c.good : c.stop;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Material(
          color: on ? colour : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: on ? null : Key('check-${item.key}-${passed ? 'no' : 'yes'}'),
            borderRadius: BorderRadius.circular(10),
            onTap: on ? null : () => onChanged(forGood),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? colour : AppTheme.border),
              ),
              child: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: on ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: passed ? null : c.stop,
              ),
            ),
          ),
          answer(good, true),
          answer(bad, false),
        ],
      ),
    );
  }
}

/// Grade A–D as four big buttons, the one in force filled in its colour.
/// Says whether the checklist worked it out or a person chose it, and names
/// the faults behind it.
class _GradePicker extends StatelessWidget {
  const _GradePicker({
    required this.shown,
    required this.manual,
    required this.faults,
    required this.onPick,
  });

  final String shown;
  final bool manual;
  final List<String> faults;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    Color colourOf(String g) => switch (g) {
      kGradeA => c.good,
      kGradeB => theme.colorScheme.secondary,
      kGradeC => c.wait,
      _ => c.stop,
    };

    final strong = colourOf(shown);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The grade in force, big, in its own colour.
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: strong,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  shown,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gradeTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      manual
                          ? context.l10n.gradeManual
                          : context.l10n.gradeAuto,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      faults.isEmpty
                          ? context.l10n.noFaults
                          : context.l10n.faultsFound(faults.join(', ')),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: faults.isEmpty ? c.good : c.stop,
                      ),
                    ),
                  ],
                ),
              ),
              HelpButton(
                title: context.l10n.gradeTitle,
                body: context.l10n.helpGrade,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // To choose a different grade by hand.
          Row(
            children: [
              for (final g in kGradeOrder) ...[
                if (g != kGradeA) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: Key('grade-$g'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: EdgeInsets.zero,
                      shape: const StadiumBorder(),
                      backgroundColor: shown == g
                          ? colourOf(g)
                          : theme.colorScheme.surface,
                      foregroundColor: shown == g ? Colors.white : colourOf(g),
                      side: BorderSide(color: colourOf(g)),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: () => onPick(g),
                    child: Text(g),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The purchase date: today, unless someone changes it. A tap opens the
/// calendar; nothing is typed.
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.help,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final String help;
  final DateTime value;
  final String? error;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: const Key('purchase-date'),
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await pickDateSheet(
          context,
          initial: value,
          first: DateTime(2015),
          last: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          label: FieldLabel(label, required: true),
          errorText: error,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: HelpButton(title: label, body: help),
        ),
        child: Text(
          MaterialLocalizations.of(context).formatMediumDate(value),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// A date typed as text — the warranty expiry, which is optional and often
/// only roughly known.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.optional = false,
  });

  final String fieldKey;
  final String label;
  final TextEditingController controller;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        textInputAction: TextInputAction.next,
        key: Key('purchase-$fieldKey'),
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clear,
                ),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await pickDateSheet(
            context,
            initial: DateTime.tryParse(controller.text) ?? now,
            first: DateTime(now.year - 2),
            last: DateTime(now.year + 3),
          );
          if (picked != null) {
            controller.text = picked.toIso8601String().substring(0, 10);
          }
        },
      ),
    );
  }
}

/// Named photo slots, two to a row. An empty slot is a dashed tile with a
/// camera; a taken one turns green with a tick and can be removed.
///
/// With a [pick] (a shop with Firebase Storage — see photo_uploader.dart) a
/// tap takes a real photo; without one it records that the photo was taken,
/// so a purchase can still be saved.
class _PhotoGrid extends StatefulWidget {
  const _PhotoGrid({
    required this.prefix,
    required this.keys,
    required this.labels,
    required this.values,
    required this.onChanged,
    this.required = const {},
    this.errorAt,
    this.pick,
  });

  /// Takes a real photo and returns its address, telling [PhotoProgress]
  /// how it is getting on. Without it, a tap records that the photo was
  /// taken.
  final Future<String?> Function(PhotoProgress onProgress)? pick;

  final String prefix;
  final List<String> keys;
  final List<String> labels;
  final List<String> values;
  final void Function(int index, String value) onChanged;
  final Set<int> required;
  final int? errorAt;

  @override
  State<_PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<_PhotoGrid> {
  /// The slot a photo is on its way to, and how far it has got.
  int? _busy;
  PhotoStage? _stage;
  double? _fraction;

  String get prefix => widget.prefix;
  List<String> get keys => widget.keys;
  List<String> get labels => widget.labels;
  List<String> get values => widget.values;
  Set<int> get required => widget.required;
  int? get errorAt => widget.errorAt;

  String _busyText(BuildContext context) {
    final l10n = context.l10n;
    final f = _fraction;
    return switch (_stage) {
      PhotoStage.shrinking => l10n.photoShrinking,
      PhotoStage.uploading when f != null => l10n.photoUploading(
        (f * 100).round(),
      ),
      _ => l10n.photoUploadingStart,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (var i = 0; i < keys.length; i++)
          Material(
            color: values[i].isNotEmpty
                ? c.goodSoft
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: Key('$prefix-${keys[i]}'),
              borderRadius: BorderRadius.circular(18),
              onTap: _busy != null
                  ? null
                  : () async {
                      final take = widget.pick;
                      if (take == null) {
                        widget.onChanged(
                          i,
                          values[i].isNotEmpty
                              ? values[i]
                              : '$prefix://${keys[i]}',
                        );
                        return;
                      }
                      try {
                        final url = await take((stage, fraction) {
                          if (!mounted) return;
                          setState(() {
                            _busy = i;
                            _stage = stage;
                            _fraction = fraction;
                          });
                        });
                        if (url != null) widget.onChanged(i, url);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _busy = null;
                            _stage = null;
                            _fraction = null;
                          });
                        }
                      }
                    },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: errorAt == i
                        ? theme.colorScheme.error
                        : values[i].isNotEmpty
                        ? c.good
                        : required.contains(i)
                        ? theme.colorScheme.primary
                        : AppTheme.borderSubtle,
                    width: errorAt == i || required.contains(i) ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // The photo itself, once there is a real one.
                    if (isShopPhoto(values[i]))
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: ShopPhotoImage(values[i]),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            values[i].isNotEmpty
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            size: 30,
                            color: values[i].isNotEmpty
                                ? c.good
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            required.contains(i)
                                ? context.l10n.required
                                : context.l10n.tapToAddPhoto,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: required.contains(i)
                                  ? theme.colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (values[i].isNotEmpty && _busy != i)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          icon: Icon(Icons.close, color: c.stop),
                          onPressed: () => widget.onChanged(i, ''),
                        ),
                      ),
                    // A photo on its way: which step, and how far.
                    if (_busy == i)
                      Positioned.fill(
                        child: Container(
                          key: Key('$prefix-${keys[i]}-uploading'),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.92,
                            ),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  value: _stage == PhotoStage.uploading
                                      ? _fraction
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _busyText(context),
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One of the shop's lists as a field: a box to type in, and the list in one
/// sideways row under it ([PickRow]) — the same as New repair.
class _PickField extends StatelessWidget {
  const _PickField({
    required this.fieldKey,
    required this.label,
    required this.help,
    required this.controller,
    required this.error,
    required this.newHint,
    required this.matched,
    required this.values,
    required this.example,
    required this.onPicked,
    this.waiting,
    this.swatches = false,
    this.createLabel,
    this.onCreate,
    this.emptyHint,
    this.required = false,
  });

  /// Must be filled to save: a red * on the label.
  final bool required;

  /// Said under the box when the list has nothing to offer yet.
  final String? emptyHint;

  final String fieldKey;
  final String label;
  final String help;
  final TextEditingController controller;
  final String? error;

  /// "New — will be added to your list", for something the shop never had.
  final String? newHint;

  /// The field holds a value from the shop's list.
  final bool matched;

  /// The whole list, in the order it is offered. Typing narrows it.
  final List<String> values;

  /// Shown greyed in the empty box — "e.g. Samsung".
  final String example;
  final ValueChanged<String> onPicked;

  /// Shown under the box when this field needs an earlier one first.
  final String? waiting;

  /// Colours carry a dot of their colour.
  final bool swatches;

  /// The words on the "+ Add" chip, and what it does.
  final String Function(String value)? createLabel;
  final FutureOr<void> Function(String value)? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    final typed = controller.text.trim();
    final key = normalizeOption(typed);
    // "New" only once nothing on the list matches what is typed: while it
    // still might be one of them, the row is the answer, not a warning.
    final anyMatch = values.any((v) => normalizeOption(v).contains(key));
    final create = onCreate;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            textInputAction: TextInputAction.next,
            // Keyed so a test can drive the field by name.
            key: Key('purchase-$fieldKey'),
            controller: controller,
            enabled: waiting == null,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              label: FieldLabel(label, required: required),
              hintText: context.l10n.exampleHint(example),
              errorText: error,
              helperText:
                  waiting ??
                  (values.isEmpty && typed.isEmpty ? emptyHint : null) ??
                  (anyMatch ? null : newHint),
              helperMaxLines: 2,
              helperStyle: waiting != null
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.bodySmall?.copyWith(color: c.wait),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (matched) Icon(Icons.check_circle, color: c.good),
                  HelpButton(title: label, body: help),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (waiting == null)
            PickRow(
              values: values,
              typed: typed,
              keyPrefix: fieldKey,
              onPicked: onPicked,
              leadingOf: swatches ? (v) => _Swatch(name: v) : null,
              addLabel: createLabel,
              onAdd: create == null ? null : (v) => create(v),
            ),
        ],
      ),
    );
  }
}

/// A dot in the colour a name says, for the colours the shop sees most. A
/// colour it does not know gets a plain ring, not a guess.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.name});

  final String name;

  static const Map<String, Color> _known = {
    'black': Color(0xFF1F1F1F),
    'white': Color(0xFFFFFFFF),
    'blue': Color(0xFF1E5BD6),
    'green': Color(0xFF2E8B57),
    'red': Color(0xFFD32F2F),
    'gold': Color(0xFFD4AF37),
    'silver': Color(0xFFC0C0C0),
    'grey': Color(0xFF8A8F98),
    'gray': Color(0xFF8A8F98),
    'purple': Color(0xFF7B3FBF),
    'pink': Color(0xFFE91E63),
    'yellow': Color(0xFFFBC02D),
    'orange': Color(0xFFF57C00),
    'brown': Color(0xFF6D4C41),
  };

  @override
  Widget build(BuildContext context) {
    // "Midnight Black", "Ocean Blue": the colour word inside the shop's own
    // name. A name with none ("Aurora") is an empty ring.
    final key = normalizeOption(name);
    final colour =
        _known[key] ??
        [
          for (final w in key.split(RegExp(r'[^a-z]+')))
            if (_known[w] != null) _known[w]!,
        ].firstOrNull;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: colour ?? Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// The four steps across the blue header: a bar for each, filled up to the
/// current one, with its name underneath. Any step can be tapped to go back
/// to it — or forward, for someone who knows the form.
/// The top of the form: the X, the title, which step this is, and the bar.
class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.stepText,
    required this.stepName,
    required this.onClose,
    required this.bar,
  });

  final String title;
  final String stepText;
  final String stepName;
  final VoidCallback onClose;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.discardThisDraft,
                style: IconButton.styleFrom(backgroundColor: AppTheme.surface),
                key: const Key('form-close'),
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stepText, style: theme.textTheme.bodySmall),
              Text(
                ' · $stepName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          bar,
        ],
      ),
    );
  }
}

/// Five round steps joined by a line. Done steps are green ticks, the one on
/// screen is rose, the rest wait in white. Each can be tapped to go back to
/// it.
class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.step,
    required this.labels,
    required this.done,
    required this.onTap,
  });

  final int step;
  final List<String> labels;
  final Set<int> done;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Segments, one per step, with the step's name under it: where you are
    // and what is left, at a glance. Each segment is a button back to its
    // step.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            // The step being filled gets the room for its name; the others
            // show their number, so nothing is cut to "Cond…" (FM #42).
            Expanded(
              flex: i == step ? 4 : 1,
              child: Semantics(
                label: labels[i],
                selected: i == step,
                button: true,
                child: InkWell(
                  key: Key('step-$i'),
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i == step || done.contains(i)
                                ? AppTheme.action
                                : AppTheme.borderSubtle,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (i != step && done.contains(i)) ...[
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: context.shopColors.good,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: Text(
                                i == step
                                    ? '${i + 1} · ${labels[i]}'
                                    : '${i + 1}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: i == step
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: i == step
                                      ? AppTheme.text
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Back, as a round white button beside the big green one.
class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        onPressed: onPressed,
        child: Icon(Icons.arrow_back, semanticLabel: context.l10n.wizBack),
      ),
    );
  }
}

/// The step's one question, in plain words, big.
class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.icon, required this.title, this.help});

  final IconData icon;
  final String title;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (help != null) HelpButton(title: title, body: help!),
        ],
      ),
    );
  }
}

/// The white card the step's must-have fields sit on.
/// The step's must-have fields. No card behind them any more: each field is
/// its own white box on the page.
class _Panel extends StatelessWidget {
  const _Panel(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// The optional fields of a step, folded away under one row. Closed unless
/// someone opens it — or one of its fields has a problem, in which case it
/// opens itself so the problem is not hidden.
class _MoreDetails extends StatelessWidget {
  const _MoreDetails({
    required this.step,
    required this.open,
    required this.onToggle,
    required this.children,
  });

  final int step;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: Key('more-$step'),
              borderRadius: BorderRadius.circular(16),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      open
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        open
                            ? context.l10n.wizHideDetails
                            : context.l10n.wizMoreDetails,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _Panel(children),
            ),
        ],
      ),
    );
  }
}

/// A switch with its "?" beside it. The whole row toggles, so a tap on the
/// words works as well as a tap on the switch.
class _HelpSwitch extends StatelessWidget {
  const _HelpSwitch({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.help,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final String help;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            title: Text(title),
            subtitle: Text(subtitle),
            onChanged: onChanged,
          ),
        ),
        HelpButton(title: title, body: help),
      ],
    );
  }
}

/// Profit, live, with the repairs in it — green while it is a profit, red
/// the moment the price would lose money.
class _ProfitLine extends StatelessWidget {
  const _ProfitLine({required this.costing});

  final Costing costing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.shopColors;
    final loss = costing.atALoss;
    final strong = loss ? c.stop : c.good;
    final margin = costing.expectedMargin;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: loss ? c.stopSoft : c.goodSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            loss ? Icons.trending_down : Icons.trending_up,
            color: strong,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loss ? context.l10n.lossTitle : context.l10n.profitTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: strong),
                ),
                Text(
                  '${rupees(costing.expectedProfit.abs())}'
                  // A margin is a share of the price; on a loss it reads as
                  // "-400%", which says nothing useful, so it is left off.
                  '${margin == null || loss ? '' : '  (${(margin * 100).toStringAsFixed(0)}%)'}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: strong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${context.l10n.costNamed(formatIndianNumber(costing.totalCost))}'
                  ' (${rupees(costing.purchasePrice)}'
                  ' + ${rupees(costing.repairTotal)}'
                  ' + ${rupees(costing.otherCost)})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          HelpButton(
            title: context.l10n.profitTitle,
            body: context.l10n.helpProfit,
          ),
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
      color: context.shopColors.waitSoft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.worthALook, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            // Warnings never block a save: a clearance price and a phone
            // bought at closing time are decisions, not mistakes.
            for (final w in warnings.values) Text('• ${ruleText(context, w)}'),
          ],
        ),
      ),
    );
  }
}

/// The seller's declaration, ported from the French Mobiles Flutter port:
/// the lines read out to the seller, a tick that they agreed, a tick that
/// their ID was looked at, and their signature.
class _Declaration extends StatelessWidget {
  const _Declaration({
    required this.terms,
    required this.agreed,
    required this.idVerified,
    required this.signature,
    required this.signatureError,
    required this.onAgreed,
    required this.onIdVerified,
    required this.onSigned,
    this.idPhotos,
  });

  /// The ID card photos, under the tick they prove.
  final Widget? idPhotos;

  final List<String> terms;
  final bool agreed;
  final bool idVerified;
  final String? signature;
  final String? signatureError;
  final ValueChanged<bool> onAgreed;
  final ValueChanged<bool> onIdVerified;
  final ValueChanged<String?> onSigned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HelpTitle(
            icon: Icons.gavel_outlined,
            text: l10n.declarationTitle,
            help: l10n.helpDeclaration,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(l10n.declarationHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var i = 0; i < terms.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${i + 1}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(terms[i], style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          _TickRow(
            key: const Key('declaration-agreed'),
            value: agreed,
            title: l10n.declarationAgreed,
            onChanged: onAgreed,
          ),
          _TickRow(
            key: const Key('declaration-id-checked'),
            value: idVerified,
            title: l10n.idCheckedTitle,
            subtitle: l10n.idCheckedHint,
            onChanged: onIdVerified,
          ),
          if (idPhotos != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
              child: idPhotos!,
            ),
          const SizedBox(height: 12),
          SignatureField(
            value: signature,
            onChanged: onSigned,
            required: true,
            error: signatureError,
          ),
        ],
      ),
    );
  }
}

/// A big tick box with its words; the whole row is the target.
class _TickRow extends StatelessWidget {
  const _TickRow({
    super.key,
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
  });

  final bool value;
  final String title;
  final String? subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.shopColors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 30,
              color: value ? c.good : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
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

/// The dialog owns its own controllers.
///
/// It has to: the dialog's widgets keep rebuilding while the route animates
/// out, so controllers disposed by the caller the moment it pops are used
/// after being disposed.
class _RepairDialog extends StatefulWidget {
  const _RepairDialog();

  @override
  State<_RepairDialog> createState() => _RepairDialogState();
}

class _RepairDialogState extends State<_RepairDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputSheet(
      title: Text(context.l10n.repairDoneBeforeResale),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            textInputAction: TextInputAction.next,
            key: const Key('repair-description'),
            controller: _description,
            decoration: InputDecoration(labelText: context.l10n.whatWasDone),
          ),
          TextField(
            textInputAction: TextInputAction.next,
            key: const Key('repair-amount'),
            inputFormatters: moneyInput(),
            controller: _amount,
            keyboardType: moneyKeyboard,
            decoration: InputDecoration(labelText: context.l10n.cost),
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
            RepairCost(
              description: _description.text.trim(),
              amount: asAmount(_amount.text),
            ),
          ),
          child: Text(context.l10n.add),
        ),
      ],
    );
  }
}
