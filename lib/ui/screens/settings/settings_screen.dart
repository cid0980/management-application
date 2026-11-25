import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/input_rules.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';

import 'package:go_router/go_router.dart';

import '../../../app/auth_state.dart';
import '../../../data/settings_repository.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shops/shop.dart';
import '../../../domain/service/checklist.dart';
import '../../../domain/settings/option_set.dart';
import '../../../domain/settings/languages.dart';
import '../../../domain/settings/shop_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/print_errors.dart';
import '../../widgets/shop_ui.dart';
import '../../../data/print_server.dart';
import '../../../data/printing/bluetooth_label_printer.dart';
import '../../../data/printing/label_printer_prefs.dart';
import '../../../domain/printing/tspl.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/input_sheet.dart';
import '../../widgets/busy.dart';
import '../../widgets/loading.dart';
import '../../tour/app_tour.dart';
import '../../../data/reminders/reminder_prefs.dart';

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
    final l10n = context.l10n;

    if (repo.error != null) {
      return ErrorState(
        title: l10n.settingsCouldNotLoad,
        detail: repo.error!,
        onRetry: repo.load,
      );
    }

    LabelPrinterPrefs? printer;
    try {
      printer = context.watch<LabelPrinterPrefs>();
    } on ProviderNotFoundException {
      printer = null;
    }
    ReminderPrefs? reminders;
    try {
      reminders = context.watch<ReminderPrefs>();
    } on ProviderNotFoundException {
      reminders = null;
    }
    final brands = settings.list(OptionKind.brands).length;
    int count(OptionKind k) => settings.list(k).length;
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final language = resolveLanguage(
      stored: settings.language,
      device: device.languageCode,
    );

    Widget item(
      SettingsPage page,
      IconData icon,
      String title, [
      String? subtitle,
    ]) => ListTile(
      key: Key('settings-${page.name}'),
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/admin/settings/${page.name}'),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // First, so it is found by the person who needs it.
        _MenuGroup(
          title: l10n.setGroupHelp,
          children: [
            ListTile(
              key: const Key('settings-tour'),
              leading: const Icon(Icons.tour_outlined, color: AppTheme.primary),
              title: Text(l10n.settingsTour),
              subtitle: Text(l10n.settingsTourSub),
              trailing: const Icon(Icons.play_circle_outline),
              // Every tour, to pick one.
              onTap: () => showTourMenu(context),
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupShop,
          children: [
            item(SettingsPage.shop, Icons.storefront, l10n.shopDetailsTitle),
            item(
              SettingsPage.language,
              Icons.translate,
              l10n.language,
              kLanguageNames[language],
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupLists,
          hint: l10n.listsGrowExplainer,
          children: [
            item(
              SettingsPage.brands,
              Icons.smartphone_outlined,
              l10n.setBrandsModels,
              l10n.setBrandsModelsCount(brands, settings.modelCount),
            ),
            item(
              SettingsPage.memory,
              Icons.memory,
              l10n.setMemory,
              l10n.setMemoryCount(count(OptionKind.ram), count(OptionKind.rom)),
            ),
            for (final (kind, icon) in const [
              (OptionKind.colours, Icons.palette_outlined),
              (OptionKind.accessories, Icons.cable),
              (OptionKind.categories, Icons.category_outlined),
              (OptionKind.suppliers, Icons.local_shipping_outlined),
              (OptionKind.expenseKinds, Icons.payments_outlined),
            ])
              item(
                SettingsPage.forKind(kind)!,
                icon,
                optionKindLabel(context, kind),
                l10n.setItemsCount(count(kind)),
              ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupRepairs,
          children: [
            item(
              SettingsPage.problems,
              Icons.report_problem_outlined,
              optionKindLabel(context, OptionKind.complaintTypes),
              l10n.setItemsCount(count(OptionKind.complaintTypes)),
            ),
            item(
              SettingsPage.locks,
              Icons.lock_outline,
              optionKindLabel(context, OptionKind.lockTypes),
              l10n.setItemsCount(count(OptionKind.lockTypes)),
            ),
            item(
              SettingsPage.checklist,
              Icons.checklist,
              l10n.preDeliveryChecklist,
              l10n.setItemsCount(settings.preDeliveryChecklist.length),
            ),
            item(
              SettingsPage.warranty,
              Icons.verified_outlined,
              l10n.repairWarranty,
              settings.repairWarrantyDays == 0
                  ? l10n.warrantyNone
                  : l10n.warrantyDaysN(settings.repairWarrantyDays),
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupReminders,
          children: [
            item(
              SettingsPage.reminders,
              Icons.notifications_active_outlined,
              l10n.settingsReminders,
              reminders == null
                  ? null
                  : reminders.on
                  ? MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay(hour: reminders.hour, minute: reminders.minute),
                    )
                  : l10n.remindersOff,
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupPrinting,
          children: [
            item(
              SettingsPage.printer,
              Icons.print_outlined,
              l10n.labelPrinter,
              printer == null
                  ? null
                  : printer.usesBluetooth
                  ? printer.name
                  : l10n.lpPhoneMenu,
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupStaff,
          children: [
            // Margins are the owner's unless they say otherwise.
            SwitchListTile(
              key: const Key('staff-see-costs'),
              secondary: const Icon(
                Icons.visibility_outlined,
                color: AppTheme.primary,
              ),
              title: Text(l10n.staffSeeCostsTitle),
              subtitle: Text(l10n.staffSeeCostsHint),
              value: settings.staffSeeCosts,
              onChanged: (v) =>
                  context.read<SettingsRepository>().setStaffSeeCosts(v),
            ),
          ],
        ),
        _MenuGroup(
          title: l10n.setGroupOnline,
          children: [
            item(
              SettingsPage.web,
              Icons.public,
              l10n.publicWebAddressTitle,
              settings.publicWebAddress.isEmpty
                  ? null
                  : settings.publicWebAddress,
            ),
          ],
        ),
        // Which APK this phone has: the GitHub build number.
        Text(
          appBuildLine(l10n),
          key: const Key('settings-build'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// "Build 65 · version 1.0.0": set by the GitHub build
/// (.github/workflows/build-apk.yml). A build made anywhere else says so.
String appBuildLine(AppLocalizations l10n) {
  const build = String.fromEnvironment('BUILD_NUMBER');
  const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  return build.isEmpty
      ? l10n.appBuildLocal(version)
      : l10n.appBuild(build, version);
}

/// The pages Settings opens, one per thing to set. The name is the last
/// part of the address: /admin/settings/brands.
enum SettingsPage {
  shop,
  language,
  brands,
  memory,
  colours,
  accessories,
  categories,
  suppliers,
  problems,
  locks,
  checklist,
  warranty,
  printer,
  reminders,
  expenses,
  web;

  /// The page for a simple list, or null for lists with their own page.
  static SettingsPage? forKind(OptionKind kind) => switch (kind) {
    OptionKind.colours => colours,
    OptionKind.accessories => accessories,
    OptionKind.categories => categories,
    OptionKind.suppliers => suppliers,
    OptionKind.complaintTypes => problems,
    OptionKind.lockTypes => locks,
    OptionKind.expenseKinds => expenses,
    _ => null,
  };

  OptionKind? get kind => switch (this) {
    colours => OptionKind.colours,
    accessories => OptionKind.accessories,
    categories => OptionKind.categories,
    suppliers => OptionKind.suppliers,
    problems => OptionKind.complaintTypes,
    locks => OptionKind.lockTypes,
    expenses => OptionKind.expenseKinds,
    _ => null,
  };

  static SettingsPage? fromName(String? name) =>
      SettingsPage.values.where((p) => p.name == name).firstOrNull;
}

/// The top-bar title for a Settings address, or null when it is not one.
String? settingsTitleFor(BuildContext context, String location) {
  const root = '/admin/settings/';
  if (!location.startsWith(root)) return null;
  final rest = Uri.decodeComponent(location.substring(root.length));
  if (rest.startsWith('models/')) return rest.substring('models/'.length);
  final page = SettingsPage.fromName(rest);
  if (page == null) return null;
  final l10n = context.l10n;
  return switch (page) {
    SettingsPage.shop => l10n.shopDetailsTitle,
    SettingsPage.language => l10n.language,
    SettingsPage.brands => l10n.setBrandsModels,
    SettingsPage.memory => l10n.setMemory,
    SettingsPage.checklist => l10n.preDeliveryChecklist,
    SettingsPage.warranty => l10n.repairWarranty,
    SettingsPage.printer => l10n.labelPrinter,
    SettingsPage.reminders => l10n.settingsReminders,
    SettingsPage.web => l10n.publicWebAddressTitle,
    _ => optionKindLabel(context, page.kind!),
  };
}

/// A titled card of rows on the Settings menu.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.children, this.hint});

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, c) in children.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  c,
                ],
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(hint!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// One Settings page: the setting it is for, and nothing else.
class SettingsPageScreen extends StatelessWidget {
  const SettingsPageScreen({super.key, required this.page});

  final SettingsPage page;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SettingsRepository>();
    final settings = repo.settings;
    final l10n = context.l10n;
    if (repo.error != null) {
      return ErrorState(
        title: l10n.settingsCouldNotLoad,
        detail: repo.error!,
        onRetry: repo.load,
      );
    }
    final List<Widget> body = switch (page) {
      SettingsPage.shop => [const _ShopDetailsSection()],
      SettingsPage.language => [_LanguageSection(stored: settings.language)],
      SettingsPage.brands => [_BrandsSection(settings: settings)],
      SettingsPage.memory => [
        _OptionSection(
          kind: OptionKind.ram,
          values: settings.list(OptionKind.ram),
          showTitle: true,
        ),
        _OptionSection(
          kind: OptionKind.rom,
          values: settings.list(OptionKind.rom),
          showTitle: true,
        ),
      ],
      SettingsPage.checklist => [
        _ChecklistSection(items: settings.preDeliveryChecklist),
      ],
      SettingsPage.warranty => [
        _WarrantySection(days: settings.repairWarrantyDays),
      ],
      SettingsPage.printer => [const _LabelPrinterSection()],
      SettingsPage.reminders => [const _RemindersSection()],
      SettingsPage.web => [
        _PublicWebAddressSection(url: settings.publicWebAddress),
      ],
      _ => [
        _OptionSection(kind: page.kind!, values: settings.list(page.kind!)),
      ],
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: body,
    );
  }
}

/// The repair warranty: printed on final bills, and checked when a phone
/// comes back.
class _WarrantySection extends StatelessWidget {
  const _WarrantySection({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.repairWarranty,
      hint: l10n.repairWarrantyHint,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<int>(
            groupValue: days,
            onChanged: (v) {
              if (v != null) {
                context.read<SettingsRepository>().setRepairWarrantyDays(v);
              }
            },
            child: Column(
              children: [
                for (final (i, d) in const [0, 7, 15, 30, 90].indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  RadioListTile<int>(
                    key: Key('warranty-$d'),
                    value: d,
                    title: Text(
                      d == 0 ? l10n.warrantyNone : l10n.warrantyDaysN(d),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// THE BRANDS, AND THE MODELS UNDER EACH
///
/// Nested, because a flat list of four hundred models is unusable and
/// "Galaxy A54" under Apple is a mistake nobody catches. Tapping a brand
/// opens its models, on a page of their own.
class _BrandsSection extends StatelessWidget {
  const _BrandsSection({required this.settings});

  final ShopSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<SettingsRepository>();
    return _Section(
      title: l10n.setBrandsModels,
      hint: l10n.modelsOfferedHint,
      children: [
        _ListEditor(
          kindKey: OptionKind.brands.name,
          values: settings.list(OptionKind.brands).sorted,
          addHint: l10n.setAddNew,
          empty: l10n.noBrandsYet,
          subtitleFor: (b) => l10n.modelCount(settings.modelsFor(b).length),
          onTap: (b) =>
              context.go('/admin/settings/models/${Uri.encodeComponent(b)}'),
          onAdd: (v) => _addOption(context, OptionKind.brands, v),
          onRemove: (v) => _removeOption(context, OptionKind.brands, v),
          onRename: (old, now) async {
            // The models go with the brand.
            final models = settings.modelsFor(old).values.toList();
            await _renameIn(
              old: old,
              now: now,
              add: (v) => repo.addOption(OptionKind.brands, v),
              remove: (v) => repo.removeOption(OptionKind.brands, v),
            );
            for (final m in models) {
              await repo.addModel(now, m);
            }
          },
        ),
      ],
    );
  }
}

/// The models offered under one brand.
class BrandModelsScreen extends StatelessWidget {
  const BrandModelsScreen({super.key, required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SettingsRepository>();
    final l10n = context.l10n;
    final models = repo.settings.modelsFor(brand);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _Section(
          title: brand,
          hint: l10n.modelsOfferedHint,
          children: [
            _ListEditor(
              kindKey: 'model-$brand',
              values: models.sorted,
              addHint: l10n.addModelUnder(brand),
              fieldKey: 'add-model-$brand',
              empty: l10n.noModelsUnderBrand,
              onAdd: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await whileBusy(
                  context,
                  repo.addModel(brand, v),
                );
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.wroteSomething
                          ? l10n.addedUnderBrand(v, brand)
                          : result.ok
                          ? l10n.alreadyUnderBrand(v, brand)
                          : result.error!,
                    ),
                  ),
                );
              },
              onRemove: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await whileBusy(
                  context,
                  repo.removeModel(brand, v),
                );
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.ok
                          ? l10n.removedModelFrom(v, brand)
                          : result.error!,
                    ),
                  ),
                );
              },
              onRename: (old, now) => _renameIn(
                old: old,
                now: now,
                add: (v) => repo.addModel(brand, v),
                remove: (v) => repo.removeModel(brand, v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _addOption(
  BuildContext context,
  OptionKind kind,
  String value,
) async {
  final repo = context.read<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final result = await whileBusy(context, repo.addOption(kind, value));
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.wroteSomething
            ? l10n.addedValue(value)
            : result.ok
            // Case and space do not make a new value.
            ? l10n.alreadyOnTheList(value)
            : result.error!,
      ),
    ),
  );
}

Future<void> _removeOption(
  BuildContext context,
  OptionKind kind,
  String value,
) async {
  final repo = context.read<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final result = await whileBusy(context, repo.removeOption(kind, value));
  messenger.showSnackBar(
    SnackBar(
      content: Text(result.ok ? l10n.removedValue(value) : result.error!),
    ),
  );
}

/// A LIST, EDITED AS A LIST
///
/// One value per row, in order, each with Rename and Remove; a box at the
/// top to add one; a search box once the list is long. Replaces the cloud
/// of chips, which had no order and no way to fix a typo.
class _ListEditor extends StatefulWidget {
  const _ListEditor({
    required this.kindKey,
    required this.values,
    required this.addHint,
    required this.empty,
    required this.onAdd,
    required this.onRemove,
    required this.onRename,
    this.fieldKey,
    this.subtitleFor,
    this.onTap,
  });

  /// Names the row keys: `option-KIND-VALUE`, `remove-KIND-VALUE`.
  final String kindKey;
  final List<String> values;
  final String addHint;
  final String empty;
  final String? fieldKey;
  final Future<void> Function(String value) onAdd;
  final Future<void> Function(String value) onRemove;
  final Future<void> Function(String old, String now) onRename;
  final String Function(String value)? subtitleFor;
  final void Function(String value)? onTap;

  @override
  State<_ListEditor> createState() => _ListEditorState();
}

/// Asks for the new spelling. Owns its text box, so the box lives exactly
/// as long as the dialog does (including its closing animation).
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InputSheet(
      title: Text(l10n.setRename),
      content: TextField(
        key: const Key('rename-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('rename-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Replaces [old] with [now] in a list that ignores case. When only the
/// capitals change the two are "the same" to the list, so the old one has
/// to go first or the add would be a no-op and the remove would lose it.
Future<void> _renameIn({
  required String old,
  required String now,
  required Future<void> Function(String) add,
  required Future<void> Function(String) remove,
}) async {
  if (old.toLowerCase() == now.toLowerCase()) {
    await remove(old);
    await add(now);
  } else {
    await add(now);
    await remove(old);
  }
}

class _ListEditorState extends State<_ListEditor> {
  String _query = '';

  /// From this many, the list gets a search box.
  static const _searchFrom = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final v in widget.values)
        if (q.isEmpty || v.toLowerCase().contains(q)) v,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AddField(
          hint: widget.addHint,
          fieldKey: widget.fieldKey ?? 'add-${widget.kindKey}',
          onSubmit: widget.onAdd,
        ),
        const SizedBox(height: 12),
        if (widget.values.length >= _searchFrom) ...[
          TextField(
            key: Key('search-${widget.kindKey}'),
            decoration: InputDecoration(
              hintText: l10n.setSearchList,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.values.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(widget.empty, style: theme.textTheme.bodyMedium),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              l10n.setItemsCount(widget.values.length),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noMatchFor(_query)),
                  ),
                for (final (i, v) in shown.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    key: Key('option-${widget.kindKey}-$v'),
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    title: Text(v),
                    subtitle: widget.subtitleFor == null
                        ? null
                        : Text(widget.subtitleFor!(v)),
                    onTap: widget.onTap == null ? null : () => widget.onTap!(v),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('rename-${widget.kindKey}-$v'),
                          tooltip: l10n.setRename,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _rename(context, v),
                        ),
                        IconButton(
                          key: Key('remove-${widget.kindKey}-$v'),
                          tooltip: l10n.remove,
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmRemove(context, v),
                        ),
                        if (widget.onTap != null)
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, String value) async {
    final l10n = context.l10n;
    final confirmed = await confirmSheet(
      context,
      title: l10n.removeValue(value),
      // The thing people actually worry about when they hesitate here.
      body: l10n.stopsBeingOffered,
      yes: l10n.remove,
      no: l10n.keepIt,
    );
    if (confirmed) await widget.onRemove(value);
  }

  Future<void> _rename(BuildContext context, String value) async {
    final now = await showInputSheet<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: value),
    );
    final cleaned = now?.trim() ?? '';
    // Records already saved keep the old spelling; only what is offered
    // from now on changes.
    if (cleaned.isEmpty || cleaned == value) return;
    await widget.onRename(value, cleaned);
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

  /// Still asking for the shop's record.
  bool _loading = true;

  /// Why it could not be read, when it could not.
  String? _loadError;
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
    // After the first frame: _load sets state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  static const _noAccount = '#no-account';
  static const _notFound = '#not-found';

  Future<void> _load() async {
    final shops = _shops;
    String? id;
    try {
      id = context.read<AuthState>().shopId;
    } on ProviderNotFoundException {
      id = null;
    }
    if (shops == null || id == null || id.isEmpty) {
      // Signed in without the shop's account (no internet at sign-in, or
      // the app running on its own): nothing to show or save here.
      setState(() {
        _loading = false;
        _loadError = _noAccount;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    Shop? shop;
    String? problem;
    try {
      shop = await shops.load(id);
      if (shop == null) problem = _notFound;
    } catch (e) {
      problem = '$e';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadError = problem;
      if (shop != null) {
        _shop = shop;
        _name.text = shop.name;
        _phone.text = shop.phone;
        _address.text = shop.address;
        _gstin.text = shop.gstin;
        _gstRate = shop.gstRate;
      }
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
    if (_shop == null) {
      if (_loading) {
        return LoadingWords(first: context.l10n.loadingShopDetails);
      }
      return ErrorState(
        title: context.l10n.shopDetailsCouldNotLoad,
        detail: switch (_loadError) {
          _noAccount => context.l10n.shopDetailsNoAccount,
          _notFound => context.l10n.shopDetailsNotFound,
          final other => other ?? '',
        },
        onRetry: _load,
      );
    }
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
        keyboardType: keyboardFor(key) ?? keyboard,
        maxLines: lines,
        inputFormatters: inputRuleFor(key),
        maxLength: maxDigitsFor(key),
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
        ChoiceRow(
          values: const [0, 5, 18],
          selected: _gstRate,
          labelOf: (r) => r == 0 ? l10n.gstOff : '$r%',
          keyOf: (r) => Key('gst-$r'),
          onPicked: (r) => setState(() => _gstRate = r),
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
  const _OptionSection({
    required this.kind,
    required this.values,
    this.showTitle = false,
  });

  final OptionKind kind;
  final OptionSet values;

  /// On a page with two lists (RAM and storage) each says which it is.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<SettingsRepository>();
    return _Section(
      title: optionKindLabel(context, kind),
      hint: optionKindHint(context, kind),
      showTitle: showTitle,
      children: [
        _ListEditor(
          kindKey: kind.name,
          values: values.sorted,
          addHint: l10n.setAddNew,
          // An empty list is a real state, not a broken one: a shop may have
          // cleared it, and the next value typed into a form will refill it.
          empty: l10n.emptyWillStartAgain,
          onAdd: (v) => _addOption(context, kind, v),
          onRemove: (v) => _removeOption(context, kind, v),
          onRename: (old, now) => _renameIn(
            old: old,
            now: now,
            add: (v) => repo.addOption(kind, v),
            remove: (v) => repo.removeOption(kind, v),
          ),
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
            final result = await whileBusy(
              context,
              repo.setChecklist([...values, value.trim()]),
            );
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
    await whileBusy(context, repo.moveChecklistItem(item, to));
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

/// Which label printer this phone uses. Kept on the phone (see
/// label_printer_prefs.dart): every phone in the shop can have its own.
class _LabelPrinterSection extends StatelessWidget {
  const _LabelPrinterSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    LabelPrinterPrefs? prefs;
    try {
      prefs = context.watch<LabelPrinterPrefs>();
    } on ProviderNotFoundException {
      prefs = null;
    }
    if (prefs == null) return const SizedBox.shrink();
    final p = prefs;
    final bluetooth = p.mode == LabelPrintMode.bluetooth;

    return _Section(
      title: l10n.labelPrinter,
      hint: l10n.lpHint,
      children: [
        SegmentedButton<LabelPrintMode>(
          key: const Key('label-print-mode'),
          segments: [
            ButtonSegment(
              value: LabelPrintMode.bluetooth,
              icon: const Icon(Icons.bluetooth),
              label: Text(l10n.lpBluetooth),
            ),
            ButtonSegment(
              value: LabelPrintMode.phoneMenu,
              icon: const Icon(Icons.print_outlined),
              label: Text(l10n.lpPhoneMenu),
            ),
          ],
          selected: {p.mode},
          onSelectionChanged: (s) => p.setMode(s.first),
        ),
        if (bluetooth) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.print),
              title: Text(p.name.isEmpty ? l10n.lpNone : p.name),
              subtitle: p.address.isEmpty ? null : Text(p.address),
              trailing: OutlinedButton(
                key: const Key('choose-printer'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _choosePrinter(context, p),
                child: Text(l10n.lpChoose),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.lpSize, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          ChoiceRow(
            values: LabelSize.values,
            selected: p.size,
            labelOf: (size) => size.label,
            onPicked: (size) => p.setSize(size),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.lpDarkness}: ${p.darkness}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: p.darkness.toDouble(),
            min: kMinDarkness.toDouble(),
            max: kMaxDarkness.toDouble(),
            divisions: kMaxDarkness - kMinDarkness,
            label: '${p.darkness}',
            onChanged: (v) => p.setDarkness(v.round()),
          ),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          key: const Key('print-test-label'),
          onPressed: () => _printTest(context),
          icon: const Icon(Icons.print_outlined),
          label: Text(l10n.lpTest),
        ),
      ],
    );
  }

  /// The printers this phone is paired with. Pairing itself is done in the
  /// phone's Bluetooth settings, once, like headphones.
  Future<void> _choosePrinter(BuildContext context, LabelPrinterPrefs p) async {
    final l10n = context.l10n;
    final link = PluginBluetoothLink();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => _PrinterPicker(
        load: () async {
          if (!await link.hasPermission) {
            throw BluetoothPrintError.permission;
          }
          if (!await link.isOn) throw BluetoothPrintError.off;
          return link.paired();
        },
        onPicked: (printer) {
          p.setPrinter(address: printer.address, name: printer.name);
          Navigator.of(sheetContext).pop();
        },
        l10n: l10n,
      ),
    );
  }

  /// "Printing…" over the screen while the label goes out.
  Future<void> _printTest(BuildContext context) =>
      whileBusy(context, _sendTest(context), label: context.l10n.printingNow);

  Future<void> _sendTest(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final printer = context.read<PrintServer>();
    final result = await printer.printLabel(
      const LabelPrintJob(
        number: 26000,
        title: 'Test label',
        subtitle: 'Shop Manager',
        price: 999,
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.sent ? l10n.lpTestSent : printErrorText(l10n, result.error!),
        ),
      ),
    );
  }
}

class _PrinterPicker extends StatefulWidget {
  const _PrinterPicker({
    required this.load,
    required this.onPicked,
    required this.l10n,
  });

  final Future<List<PairedPrinter>> Function() load;
  final ValueChanged<PairedPrinter> onPicked;
  final AppLocalizations l10n;

  @override
  State<_PrinterPicker> createState() => _PrinterPickerState();
}

class _PrinterPickerState extends State<_PrinterPicker> {
  late Future<List<PairedPrinter>> _printers = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: FutureBuilder<List<PairedPrinter>>(
          future: _printers,
          builder: (context, snap) {
            final Widget body;
            if (snap.connectionState != ConnectionState.done) {
              body = LoadingWords(first: l10n.loadingPrinters);
            } else if (snap.hasError) {
              body = Text(printErrorText(l10n, '${snap.error}'));
            } else if (snap.data!.isEmpty) {
              body = Text(l10n.lpPairFirst);
            } else {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final printer in snap.data!)
                    ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(
                        printer.name.isEmpty ? printer.address : printer.name,
                      ),
                      subtitle: Text(printer.address),
                      onTap: () => widget.onPicked(printer),
                    ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.lpChoose,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _printers = widget.load()),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.lpRefresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                body,
              ],
            );
          },
        ),
      ),
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
              final result = await whileBusy(
                context,
                repo.setPublicWebAddress(_controller.text),
              );
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
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: widget.hint, isDense: true),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: Key('${widget.fieldKey}-go'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.add),
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
    this.showTitle = false,
  });

  final String title;
  final String hint;
  final List<Widget> children;

  /// The page's top bar already names a single setting; a page holding two
  /// shows each one's name.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
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
            final result = await whileBusy(
              context,
              repo.setLanguage(codeOf(language)),
            );
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

/// Settings › Reminders: the morning summary on or off, and when.
class _RemindersSection extends StatelessWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ReminderPrefs? prefs;
    try {
      prefs = context.watch<ReminderPrefs>();
    } on ProviderNotFoundException {
      prefs = null;
    }
    final p = prefs;
    if (p == null) return const SizedBox.shrink();
    final format = MaterialLocalizations.of(context);
    const times = [480, 510, 540, 570, 600, 630, 660];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('reminders-on'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsReminders),
          value: p.on,
          onChanged: p.setOn,
        ),
        Text(l10n.remindersHelp, style: Theme.of(context).textTheme.bodySmall),
        if (p.on) ...[
          const SizedBox(height: 16),
          Text(l10n.remindersAt, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          ChoiceRow<int>(
            key: const Key('reminders-time'),
            values: [...times, if (!times.contains(p.minutes)) p.minutes],
            selected: p.minutes,
            labelOf: (m) => format.formatTimeOfDay(
              TimeOfDay(hour: m ~/ 60, minute: m % 60),
            ),
            keyOf: (m) => Key('reminders-at-$m'),
            onPicked: p.setMinutes,
          ),
        ],
      ],
    );
  }
}
