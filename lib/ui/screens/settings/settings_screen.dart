import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/settings_repository.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shops/shop.dart';
import '../../../domain/service/checklist.dart';
import '../../../domain/settings/option_set.dart';
import '../../../domain/settings/languages.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/language_picker.dart';
import '../../../l10n/display_labels.dart';

/// THE SHOP'S OWN VOCABULARY
///
/// Admin only. Every list the forms offer, plus the pre-delivery checklist and
/// the print server address.
///
/// The thing this page has to make obvious is that **these lists grow by
/// themselves**. Staff do not come here to add a brand — they type it into the
/// intake form and it lands here. This page is for tidying up: removing a
/// supplier the shop stopped using, fixing a spelling that got in, putting the
/// checklist in the right order.
///
/// So every section says what the list is for and where its values come from,
/// and removing something says plainly that records already using it are
/// untouched.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SettingsRepository>();
    final settings = repo.settings;
    final theme = Theme.of(context);

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.settingsCouldNotLoad),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: repo.load,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ShopDetailsSection(),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.listsGrowThemselves,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.listsGrowExplainer,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        for (final kind in OptionKind.values)
          _OptionSection(kind: kind, values: settings.list(kind)),
        _ModelsSection(settings: settings),
        _ChecklistSection(items: settings.preDeliveryChecklist),
        _PrintServerSection(url: settings.printServerUrl),
        _PublicWebAddressSection(url: settings.publicWebAddress),
        // The shop's repair warranty: printed on final bills, and checked when
        // a phone comes back.
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            context.l10n.repairWarranty,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Text(
          context.l10n.repairWarrantyHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final days in const [0, 7, 15, 30, 90])
              ChoiceChip(
                key: Key('warranty-$days'),
                label: Text(
                  days == 0
                      ? context.l10n.warrantyNone
                      : context.l10n.warrantyDaysN(days),
                ),
                selected: settings.repairWarrantyDays == days,
                onSelected: (_) => context
                    .read<SettingsRepository>()
                    .setRepairWarrantyDays(days),
              ),
          ],
        ),
        // Margins are the owner's unless they say otherwise.
        SwitchListTile(
          key: const Key('staff-see-costs'),
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.staffSeeCostsTitle),
          subtitle: Text(context.l10n.staffSeeCostsHint),
          value: settings.staffSeeCosts,
          onChanged: (v) =>
              context.read<SettingsRepository>().setStaffSeeCosts(v),
        ),
        const SizedBox(height: 24),
        _LanguageSection(stored: settings.language),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// THE SHOP'S OWN DETAILS
///
/// Ported from the French Mobiles Flutter port's "The shop" settings. Until
/// now the name, phone, address and GSTIN could only be typed once, when the
/// shop was created — and they print at the top of every bill.
///
/// Admins only (the whole Settings page is), saved to this shop's record and
/// nobody else's. Hidden where there is no shop record to edit (offline).
class _ShopDetailsSection extends StatefulWidget {
  const _ShopDetailsSection();

  @override
  State<_ShopDetailsSection> createState() => _ShopDetailsSectionState();
}

class _ShopDetailsSectionState extends State<_ShopDetailsSection> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();
  Shop? _shop;
  ShopRepository? _shops;
  num _gstRate = 0;
  bool _saving = false;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    try {
      _shops = context.read<ShopRepository?>();
    } on ProviderNotFoundException {
      _shops = null;
    }
    _load();
  }

  Future<void> _load() async {
    final shops = _shops;
    if (shops == null) return;
    String? id;
    try {
      id = context.read<AuthState>().shopId;
    } on ProviderNotFoundException {
      return;
    }
    if (id == null || id.isEmpty) return;
    final shop = await shops.load(id);
    if (!mounted || shop == null) return;
    setState(() {
      _shop = shop;
      _name.text = shop.name;
      _phone.text = shop.phone;
      _address.text = shop.address;
      _gstin.text = shop.gstin;
      _gstRate = shop.gstRate;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final shop = _shop;
    final shops = _shops;
    if (shop == null || shops == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthState>();
    final saved = context.l10n.shopDetailsSaved;
    final updated = shop.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      gstin: _gstin.text.trim().toUpperCase(),
      gstRate: _gstRate,
    );
    setState(() => _saving = true);
    final result = await shops.updateShop(updated);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _errors = result.ok ? const {} : validateShop(updated).errors;
    });
    if (result.ok) {
      _shop = result.shop ?? updated;
      auth.renameShop(_shop!.name);
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? result.error ?? '')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shop == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    Widget field(
      TextEditingController c,
      String label,
      String key, {
      TextInputType? keyboard,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: Key('shop-$key'),
        controller: c,
        keyboardType: keyboard,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, errorText: _errors[key]),
      ),
    );
    return _Section(
      title: l10n.shopDetailsTitle,
      hint: l10n.shopDetailsHint,
      children: [
        field(_name, l10n.shopName, 'name'),
        field(_phone, l10n.shopPhone, 'phone', keyboard: TextInputType.phone),
        field(_address, l10n.shopAddress, 'address', lines: 2),
        field(_gstin, l10n.shopGstin, 'gstin'),
        // The rate the shop's prices include. Bills show the CGST/SGST split
        // only with a GSTIN as well; used handsets are left out (margin
        // scheme). The accountant decides the rate, not the app.
        Text(l10n.gstRateTitle, style: Theme.of(context).textTheme.titleSmall),
        Text(l10n.gstRateHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final r in const [0, 5, 18])
              ChoiceChip(
                key: Key('gst-$r'),
                label: Text(r == 0 ? l10n.gstOff : '$r%'),
                selected: _gstRate == r,
                onSelected: (_) => setState(() => _gstRate = r),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('shop-save'),
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(l10n.shopDetailsSave),
        ),
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({required this.kind, required this.values});

  final OptionKind kind;
  final OptionSet values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: optionKindLabel(context, kind),
      hint: kOptionKindHints[kind]!,
      trailing: '${values.length}',
      children: [
        if (values.isEmpty)
          Text(
            // An empty list is a real state, not a broken one: a shop may have
            // cleared it, and the next value typed into a form will refill it.
            context.l10n.emptyWillStartAgain,
            style: theme.textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values.sorted)
                InputChip(
                  key: Key('option-${kind.name}-$value'),
                  label: Text(value),
                  // Keyed, so a test can drive the one thing on this page
                  // that is worth being sure about.
                  deleteIcon: Icon(
                    Icons.close,
                    key: Key('remove-${kind.name}-$value'),
                    size: 18,
                  ),
                  onDeleted: () => _remove(context, value),
                ),
            ],
          ),
        const SizedBox(height: 8),
        _AddField(
          hint: context.l10n.addToList(
            optionKindLabel(context, kind).toLowerCase(),
          ),
          fieldKey: 'add-${kind.name}',
          onSubmit: (value) async {
            final repo = context.read<SettingsRepository>();
            final messenger = ScaffoldMessenger.of(context);
            final result = await repo.addOption(kind, value);
            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  result.wroteSomething
                      ? context.l10n.addedValue(value)
                      : result.ok
                      // Case and space do not make a new value.
                      ? context.l10n.alreadyOnTheList(value)
                      : result.error!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _remove(BuildContext context, String value) async {
    final repo = context.read<SettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removeValue(value)),
        content: Text(
          // The thing people actually worry about when they hesitate here.
          context.l10n.stopsBeingOffered,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.keepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await repo.removeOption(kind, value);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.ok ? context.l10n.removedValue(value) : result.error!,
        ),
      ),
    );
  }
}

/// MODELS PER BRAND
///
/// Nested, because a flat list of four hundred models is unusable and
/// "Galaxy A54" under Apple is a mistake nobody catches.
class _ModelsSection extends StatelessWidget {
  const _ModelsSection({required this.settings});

  final ShopSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brands = settings.list(OptionKind.brands).sorted;

    return _Section(
      title: context.l10n.modelsByBrand,
      hint: context.l10n.modelsOfferedHint,
      trailing: '${settings.modelCount}',
      children: [
        if (brands.isEmpty)
          Text(context.l10n.noBrandsYet, style: theme.textTheme.bodySmall)
        else
          for (final brand in brands)
            ExpansionTile(
              key: Key('models-$brand'),
              tilePadding: EdgeInsets.zero,
              title: Text(brand),
              subtitle: Text(
                context.l10n.modelCount('${settings.modelsFor(brand).length}'),
                style: theme.textTheme.bodySmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (settings.modelsFor(brand).isEmpty)
                        Text(
                          context.l10n.noModelsUnderBrand,
                          style: theme.textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final model
                                in settings.modelsFor(brand).sorted)
                              InputChip(
                                key: Key('model-$brand-$model'),
                                label: Text(model),
                                deleteIcon: Icon(
                                  Icons.close,
                                  key: Key('remove-model-$brand-$model'),
                                  size: 18,
                                ),
                                onDeleted: () async {
                                  final repo = context
                                      .read<SettingsRepository>();
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final result = await repo.removeModel(
                                    brand,
                                    model,
                                  );
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.ok
                                            ? context.l10n.removedModelFrom(
                                                model,
                                                brand,
                                              )
                                            : result.error!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      _AddField(
                        hint: context.l10n.addModelUnder(brand),
                        fieldKey: 'add-model-$brand',
                        onSubmit: (value) async {
                          final repo = context.read<SettingsRepository>();
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await repo.addModel(brand, value);
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result.wroteSomething
                                    ? context.l10n.addedUnderBrand(value, brand)
                                    : result.ok
                                    ? context.l10n.alreadyUnderBrand(
                                        value,
                                        brand,
                                      )
                                    : result.error!,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

/// THE PRE-DELIVERY CHECKLIST
///
/// The one list here whose **order matters**: it is the order somebody works
/// through a phone before handing it back, so it is moved rather than sorted.
///
/// The warning about two labels sharing a checkbox is shown here because this
/// is the only place the labels can be chosen, and it is the only place the
/// collision can be avoided.
class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({required this.items});

  final OptionSet items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = items.values;
    final entries = checklistEntries(values);
    // Two labels that slug to the same key would have shared a checkbox.
    // `checklistEntries` resolves it, and saying so here is how an admin knows
    // why their two labels look the same.
    final collisions = <String>[
      for (final entry in entries)
        if (entry.key != checklistKey(entry.item)) entry.item,
    ];

    return _Section(
      title: context.l10n.preDeliveryChecklist,
      hint: context.l10n.checklistHint,
      trailing: '${values.length}',
      children: [
        if (values.isEmpty)
          Text(
            // Stated plainly, because it quietly turns the gate off.
            context.l10n.checklistEmptyCharged,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          for (var i = 0; i < values.length; i++)
            ListTile(
              key: Key('checklist-${values[i]}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text('${i + 1}'),
              title: Text(values[i]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('checklist-up-${values[i]}'),
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: context.l10n.moveUp,
                    onPressed: i == 0
                        ? null
                        : () => _move(context, values[i], i - 1),
                  ),
                  IconButton(
                    key: Key('checklist-down-${values[i]}'),
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: context.l10n.moveDown,
                    onPressed: i == values.length - 1
                        ? null
                        : () => _move(context, values[i], i + 1),
                  ),
                  IconButton(
                    key: Key('checklist-remove-${values[i]}'),
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.remove,
                    onPressed: () => _remove(context, values[i]),
                  ),
                ],
              ),
            ),
        if (collisions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.checklistCollisions(collisions.join(', ')),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _AddField(
          hint: context.l10n.addACheck,
          fieldKey: 'add-checklist',
          onSubmit: (value) async {
            final repo = context.read<SettingsRepository>();
            final messenger = ScaffoldMessenger.of(context);
            final result = await repo.setChecklist([...values, value.trim()]);
            messenger.showSnackBar(
              SnackBar(
                content: Text(result.ok ? 'Added "$value"' : result.error!),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _move(BuildContext context, String item, int to) async {
    final repo = context.read<SettingsRepository>();
    await repo.moveChecklistItem(item, to);
  }

  Future<void> _remove(BuildContext context, String item) async {
    final repo = context.read<SettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await repo.setChecklist([
      for (final v in items.values)
        if (v != item) v,
    ]);
    messenger.showSnackBar(
      SnackBar(content: Text(result.ok ? 'Removed "$item"' : result.error!)),
    );
  }
}

class _PrintServerSection extends StatefulWidget {
  const _PrintServerSection({required this.url});

  final String url;

  @override
  State<_PrintServerSection> createState() => _PrintServerSectionState();
}

class _PrintServerSectionState extends State<_PrintServerSection> {
  late final _controller = TextEditingController(text: widget.url);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.l10n.labelPrinter,
      hint: context.l10n.printServerHint,
      children: [
        TextField(
          key: const Key('print-server-url'),
          controller: _controller,
          decoration: InputDecoration(
            labelText: context.l10n.printServerAddress,
            hintText: 'http://192.168.1.50:8080',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('save-print-server'),
            onPressed: () async {
              final repo = context.read<SettingsRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final saved = context.l10n.printServerSaved;
              final result = await repo.setPrintServerUrl(_controller.text);
              messenger.showSnackBar(
                SnackBar(content: Text(result.ok ? saved : result.error!)),
              );
            },
            child: Text(context.l10n.saveAddress),
          ),
        ),
      ],
    );
  }
}

class _PublicWebAddressSection extends StatefulWidget {
  const _PublicWebAddressSection({required this.url});

  final String url;

  @override
  State<_PublicWebAddressSection> createState() =>
      _PublicWebAddressSectionState();
}

class _PublicWebAddressSectionState extends State<_PublicWebAddressSection> {
  late final _controller = TextEditingController(text: widget.url);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.publicWebAddressTitle,
      hint: l10n.publicWebAddressHint,
      children: [
        TextField(
          key: const Key('public-web-address'),
          controller: _controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.publicWebAddress,
            hintText: 'https://your-shop.web.app',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('save-public-web-address'),
            onPressed: () async {
              final repo = context.read<SettingsRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final result = await repo.setPublicWebAddress(_controller.text);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    result.ok ? l10n.publicWebAddressSaved : result.error!,
                  ),
                ),
              );
            },
            child: Text(l10n.saveAddress),
          ),
        ),
      ],
    );
  }
}

/// One free-text box that adds a value. Submitting clears it, so a second
/// value can go straight in.
class _AddField extends StatefulWidget {
  const _AddField({
    required this.hint,
    required this.fieldKey,
    required this.onSubmit,
  });

  final String hint;
  final String fieldKey;
  final Future<void> Function(String value) onSubmit;

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    // A blank value is never filed: an empty entry in a dropdown is a trap.
    if (value.isEmpty) return;
    _controller.clear();
    await widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: Key(widget.fieldKey),
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: Key('${widget.fieldKey}-go'),
          icon: const Icon(Icons.add),
          tooltip: widget.hint,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.hint,
    required this.children,
    this.trailing,
  });

  final String title;
  final String hint;
  final List<Widget> children;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            if (trailing != null)
              Text(trailing!, style: theme.textTheme.labelSmall),
          ],
        ),
        Text(hint, style: theme.textTheme.bodySmall),
        const Divider(),
        ...children,
      ],
    );
  }
}

/// THE LANGUAGE THE SHOP WORKS IN
///
/// Changed here, and it takes effect on the next frame — no restart, because
/// an owner trying Tamil wants to see Tamil, not to be told to close the app.
///
/// It belongs to the shop, not to the phone: the other till is reading the
/// same settings document and changes with it. That is deliberate. A till
/// where two staff see two different words for the same button is a till
/// where they cannot help each other.
class _LanguageSection extends StatelessWidget {
  const _LanguageSection({required this.stored});

  /// What the shop has stored, which may be empty, and may be a language this
  /// build does not have — see `languages.dart`.
  final String stored;

  @override
  Widget build(BuildContext context) {
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final selected = resolveLanguage(
      stored: stored,
      device: device.languageCode,
    );

    return _Section(
      title: context.l10n.language,
      hint: context.l10n.languageHint,
      children: [
        LanguagePicker(
          selected: selected,
          // The section heading above already explains what this is.
          showHint: false,
          onChanged: (language) async {
            final repo = context.read<SettingsRepository>();
            final messenger = ScaffoldMessenger.of(context);
            final result = await repo.setLanguage(codeOf(language));
            if (!context.mounted) return;
            // Read after the save, so the confirmation is in the language
            // that was just chosen rather than the one being left behind.
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  result.ok ? context.l10n.languageSaved : result.error!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
