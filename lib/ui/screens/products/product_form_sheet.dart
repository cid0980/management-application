import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/product_repository.dart';
import '../../widgets/save_guard.dart';
import '../../widgets/shop_ui.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/common/form_draft.dart';
import '../../../domain/inventory/purchase_costing.dart' show asAmount;
import '../../../domain/products/product.dart';
import '../../../domain/products/product_validation.dart';
import '../../../domain/settings/option_learning.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/settings/option_set.dart';
import '../../../l10n/rule_messages.dart';
import '../../widgets/form_jump.dart';

/// ADDING A PRODUCT
///
/// Four short sections: what it is, what it costs, when to reorder, and a
/// photo.
///
/// **There is no stock field on this form.** That is deliberate and it is the
/// one thing worth knowing about this screen. Stock changes through a
/// movement, with a reason, from the detail page — so a new product starts at
/// zero and its first delivery is a `received` line that says where the stock
/// came from. A count typed into a form has no history behind it, and "the
/// system says three and I counted five" then has no answer.
Future<void> openProductSheet(BuildContext context, {Product? existing}) async {
  final repo = context.read<ProductRepository>();
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
        ChangeNotifierProvider<ProductRepository>.value(value: repo),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        Provider<DraftStore>.value(value: drafts),
      ],
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: ProductForm(existing: existing),
      ),
    ),
  );
}

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.existing});

  final Product? existing;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _c = <String, TextEditingController>{};
  final _photos = <String>[];

  String _category = '';
  ProductValidation _result = const ProductValidation({}, {});
  bool _submitted = false;

  String get _draftKey => draftKey('product', id: widget.existing?.id);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _c[f] = TextEditingController()..addListener(_recompute);
    }
    final e = widget.existing;
    if (e != null) {
      _c['name']!.text = e.name;
      _c['brand']!.text = e.brand;
      _c['variant']!.text = e.variant;
      _c['colour']!.text = e.colour;
      _c['sku']!.text = e.sku;
      _c['supplier']!.text = e.supplier;
      _c['costPrice']!.text = _money(e.costPrice);
      _c['sellingPrice']!.text = _money(e.sellingPrice);
      _c['mrp']!.text = _money(e.mrp);
      _c['reorderLevel']!.text = e.reorderLevel == 0 ? '' : '${e.reorderLevel}';
      _c['notes']!.text = e.notes;
      _category = e.category;
      _photos.addAll(e.photos);
    } else {
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

  static String _money(num v) => v == 0 ? '' : v.toString();

  Future<void> _restoreDraft() async {
    final draft = await context.read<DraftStore>().read(_draftKey);
    if (draft == null || draft.isEmpty || !mounted) return;
    setState(() {
      for (final entry in draft.values.entries) {
        final c = _c[entry.key];
        if (c != null) c.text = (entry.value ?? '').toString();
      }
      _category = (draft.values['category'] ?? '').toString();
      final photos = draft.values['photos'];
      if (photos is Iterable) {
        _photos
          ..clear()
          ..addAll(photos.map((p) => '$p'));
      }
    });
    _recompute();
  }

  void _saveDraft() {
    context.read<DraftStore>().write(_draftKey, {
      for (final e in _c.entries) e.key: e.value.text,
      'category': _category,
      'photos': _photos,
    });
  }

  Product _asProduct() => Product(
    id: widget.existing?.id ?? 'new',
    name: _c['name']!.text.trim(),
    brand: _c['brand']!.text.trim(),
    category: _category,
    variant: _c['variant']!.text.trim(),
    colour: _c['colour']!.text.trim(),
    sku: _c['sku']!.text.trim(),
    supplier: _c['supplier']!.text.trim(),
    costPrice: asAmount(_c['costPrice']!.text),
    sellingPrice: asAmount(_c['sellingPrice']!.text),
    mrp: asAmount(_c['mrp']!.text),
    // Whatever the record already has. The form never sets it.
    stockCount: widget.existing?.stockCount ?? 0,
    reorderLevel: int.tryParse(_c['reorderLevel']!.text.trim()) ?? 0,
    photos: List.of(_photos),
    labelNumber: widget.existing?.labelNumber,
    notes: _c['notes']!.text.trim(),
    createdAt: widget.existing?.createdAt,
  );

  void _recompute() {
    final repo = context.read<ProductRepository>();
    setState(() {
      _result = validateProduct(_asProduct(), existing: repo.products);
    });
    _saveDraft();
  }

  Future<void> _save() async {
    final product = _asProduct();
    final repo = context.read<ProductRepository>();
    final result = validateProduct(product, existing: repo.products);
    setState(() {
      _submitted = true;
      _result = result;
    });
    if (!result.isValid) {
      // To the first field that needs something; its error is under it.
      final firstError = ruleText(context, result.errors.values.first);
      final said = ScaffoldMessenger.of(context);
      final jumped = await jumpToFirstError(
        context,
        result.errors.keys.map((rule) => Key('product-$rule')),
      );
      if (!jumped) said.showSnackBar(SnackBar(content: Text(firstError)));
      return;
    }

    final drafts = context.read<DraftStore>();
    final settings = context.read<SettingsRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final stored = await guardSave(
      context,
      () => repo.save(
        product.id == 'new'
            ? Product.fromMap('p-${DateTime.now().millisecondsSinceEpoch}', {
                ...product.toMap(),
                'createdAt': DateTime.now().toIso8601String(),
              })
            : product,
      ),
    );
    if (stored == null) {
      return;
    }
    await drafts.clear(_draftKey);

    // Filed AFTER the save, and nothing waits on it.
    final filing = settings.learn(
      productValues(
        brand: product.brand,
        category: product.category,
        colour: product.colour,
        supplier: product.supplier,
      ),
    );

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          widget.existing == null
              ? context.l10n.savedReceiveStock(stored.title)
              : context.l10n.savedNamed(stored.title),
        ),
      ),
    );

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
    final product = _asProduct();
    final errors = _submitted
        ? ruleTexts(context, _result.errors)
        : <String, String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.l10n.addAProduct
              : context.l10n.editProduct,
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
          _Section(context.l10n.whatItIs, [
            _field(
              'name',
              context.l10n.name,
              errors,
              help: context.l10n.whatTheCounterSearches,
              required: true,
            ),
            _field('brand', context.l10n.brand, errors),
            PickRow(
              typed: _c['brand']!.text,
              keyPrefix: 'brand',
              values: byUse(
                _shopSettings.list(OptionKind.brands).values,
                context.read<ProductRepository>().products.map((p) => p.brand),
              ),
              onPicked: (v) {
                _c['brand']!.text = v;
                _recompute();
              },
            ),
            DropdownButtonFormField<String>(
              key: const Key('product-category'),
              initialValue: _category.isEmpty ? null : _category,
              decoration: InputDecoration(
                labelText: context.l10n.category,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: errors['category'],
              ),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                setState(() => _category = v ?? '');
                _recompute();
              },
            ),
            const SizedBox(height: 10),
            _field('variant', context.l10n.variantFits, errors),
            _field('colour', context.l10n.colour, errors),
            PickRow(
              typed: _c['colour']!.text,
              keyPrefix: 'colour',
              values: _shopSettings.list(OptionKind.colours).sorted,
              onPicked: (v) {
                _c['colour']!.text = v;
                _recompute();
              },
            ),
            _field('sku', 'SKU', errors, help: context.l10n.skuHelp),
            _field('supplier', context.l10n.supplier, errors),
            PickRow(
              typed: _c['supplier']!.text,
              keyPrefix: 'supplier',
              values: _shopSettings.list(OptionKind.suppliers).sorted,
              onPicked: (v) {
                _c['supplier']!.text = v;
                _recompute();
              },
            ),
          ]),
          _Section(context.l10n.pricing, [
            _field(
              'costPrice',
              context.l10n.costPrice,
              errors,
              keyboard: TextInputType.number,
            ),
            _field(
              'sellingPrice',
              context.l10n.sellingPrice,
              errors,
              keyboard: TextInputType.number,
              required: true,
            ),
            _field(
              'mrp',
              context.l10n.printedMaximumMrp,
              errors,
              keyboard: TextInputType.number,
            ),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.profitPerUnitNamed('${product.unitProfit}'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: product.soldAtALoss || product.aboveMrp
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ),
          ]),
          _Section(context.l10n.whenToReorder, [
            _field(
              'reorderLevel',
              context.l10n.reorderLevel,
              errors,
              keyboard: TextInputType.number,
              // Nothing invents a threshold: an alert nobody chose is an
              // alert nobody trusts.
              help: context.l10n.reorderLevelHelp,
            ),
            if (widget.existing != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.onTheShelfNow('${widget.existing!.stockCount}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.newProductStartsAtZero,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ]),
          _Section(context.l10n.photo, [
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  InputChip(
                    label: Text(
                      i == 0
                          ? context.l10n.mainPhoto
                          : context.l10n.photoNumbered('${i + 1}'),
                    ),
                    onDeleted: () {
                      setState(() => _photos.removeAt(i));
                      _recompute();
                    },
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _photos.add('photo://${_photos.length + 1}'));
                  _recompute();
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _photos.isEmpty
                      ? context.l10n.addAPhoto
                      : context.l10n.addAnother,
                ),
              ),
            ),
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

  ShopSettings get _shopSettings =>
      context.watch<SettingsRepository>().settings;

  /// The shop's own list, plus whatever this record already carries.
  ///
  /// A category typed in by an older build, or one an admin has since removed,
  /// must not vanish from the dropdown when somebody opens the form to change
  /// a price — a dropdown whose value is not among its items throws.
  List<String> get _categories {
    final list = _shopSettings.list(OptionKind.categories);
    final existing = _category.trim();
    return [
      ...list.sorted,
      if (existing.isNotEmpty && !list.contains(existing)) existing,
    ];
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
      key: Key('product-$key'),
      controller: _c[key],
      keyboardType: keyboard,
      maxLines: lines,
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
  'brand',
  'variant',
  'colour',
  'sku',
  'supplier',
  'costPrice',
  'sellingPrice',
  'mrp',
  'reorderLevel',
  'notes',
];

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
            // Warnings never block a save: a loss leader and a product with no
            // reorder level are both decisions.
            for (final w in warnings.values) Text('• $w'),
          ],
        ),
      ),
    );
  }
}
