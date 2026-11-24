import 'package:flutter/material.dart';

import '../../l10n/value_labels.dart';

import '../../domain/settings/option_set.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// THE SHOP'S BUILDING BLOCKS
///
/// The few shapes every page is made of, so a list, a record and a form look
/// like one app: the navy search block under the top bar, a status pill, the
/// row of counted tabs, and the labelled card that reads like a paper job
/// card. Colours come from the theme; meaning colours from `ShopColors`.

/// The navy block under a page's top bar, holding its search box — the same
/// shape as Home's. [onScan] puts a scan button at the end of the box.
class NavySearchBlock extends StatelessWidget {
  const NavySearchBlock({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onScan,
    this.trailing,
    this.fieldKey,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScan;

  /// Something after the box, on the navy: a help button, a filter.
  final Widget? trailing;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: fieldKey,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: hint,
                  hintMaxLines: 1,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: onScan == null
                      ? null
                      : IconButton(
                          tooltip: context.l10n.tabScan,
                          onPressed: onScan,
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: AppTheme.primary,
                          ),
                        ),
                  border: _noLine,
                  enabledBorder: _noLine,
                  focusedBorder: _noLine,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static final _noLine = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );
}

/// A small rounded label: a status, a grade, "2 days late". Strong words on a
/// soft background of the same colour, with an optional icon.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.text, {
    super.key,
    required this.color,
    required this.soft,
    this.icon,
  });

  final String text;
  final Color color;
  final Color soft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

/// One counted tab in a row of them: a dot, the name, how many. The picked
/// one is filled with its colour.
class CountChip extends StatelessWidget {
  const CountChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.color,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  /// The meaning colour; navy when the tab has none (Open, All).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c : AppTheme.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c : AppTheme.borderSubtle),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 5, count == null ? 12 : 5, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : c,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.text,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : c,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sideways-scrolling row of [CountChip]s.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          c,
        ],
      ],
    ),
  );
}

/// A card of label / value rows with a title — a record read like a paper
/// job card. Rows whose value is empty are left out.
class FactsCard extends StatelessWidget {
  const FactsCard({
    super.key,
    required this.title,
    required this.rows,
    this.trailing,
    this.footer,
  });

  final String title;
  final List<FactRow> rows;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = rows.where((r) => !r.isEmpty).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            for (final r in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          r.child ??
                          Text(
                            r.value!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: r.color,
                              fontWeight: r.bold
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            if (footer != null) ...[const SizedBox(height: 6), footer!],
          ],
        ),
      ),
    );
  }
}

class FactRow {
  const FactRow(this.label, this.value, {this.color, this.bold = false})
    : child = null;
  const FactRow.widget(this.label, Widget this.child)
    : value = null,
      color = null,
      bold = false;

  final String label;
  final String? value;
  final Widget? child;
  final Color? color;
  final bool bold;

  bool get isEmpty => child == null && (value == null || value!.trim().isEmpty);
}

/// A bold section heading inside a form, with a thin line after it.
class FormSection extends StatelessWidget {
  const FormSection(this.title, {super.key, this.required = false});

  final String title;

  /// Something in this section must be filled to save: a red * after it.
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Row(
      children: [
        Flexible(
          // The * is part of the title, so when a long title wraps (Tamil,
          // Hindi) it stays after the last word instead of drifting off to
          // the edge (FM #58).
          child: Text.rich(
            TextSpan(
              text: title,
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

/// The buttons at the foot of a record page. The one filled button — the
/// next step — runs full width; the rest sit in one row under it that
/// scrolls sideways, so the bar stays two rows high however many there are
/// and never covers the record.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final primary = children.whereType<FilledButton>().toList();
    final others = children.where((w) => w is! FilledButton).toList();
    return Material(
      color: AppTheme.surface,
      shape: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (others.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final (i, w) in others.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        OutlinedButtonTheme(
                          data: OutlinedButtonThemeData(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                          ),
                          child: w,
                        ),
                      ],
                    ],
                  ),
                ),
              for (final p in primary) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: p,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled card holding a short list of linked rows — a customer's repairs,
/// bills, enquiries. Says [empty] instead of showing nothing.
class ListSection extends StatelessWidget {
  const ListSection({
    super.key,
    required this.title,
    required this.children,
    required this.empty,
  });

  final String title;
  final List<Widget> children;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (children.isNotEmpty)
                    Text(
                      '${children.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Text(
                  empty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              for (final (i, c) in children.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 16),
                c,
              ],
          ],
        ),
      ),
    );
  }
}

/// The top of a record page: its state as pills, then what it is in big
/// words, and an optional line under it.
class RecordTitleCard extends StatelessWidget {
  const RecordTitleCard({
    super.key,
    required this.title,
    this.pills = const [],
    this.subtitle,
  });

  final String title;
  final List<Widget> pills;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pills.isNotEmpty) ...[
              Wrap(spacing: 6, runSpacing: 6, children: pills),
              const SizedBox(height: 10),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// THE PICK ROW
///
/// The shop's own choices in one line under a text box, scrolled sideways —
/// brand, model, RAM, storage, colour, supplier. Every form picks this way, so
/// a choice never spreads into a block of bubbles and the box stays typeable:
/// something the shop has never had is typed and joins the list.
///
/// Typing narrows the row, what starts with the typing first. When the box
/// holds one of the choices, the whole row is back with that one marked, so a
/// wrong tap is put right with one more tap. [onAdd] puts "+ Add …" at the end
/// for something typed that is not on the list.
///
/// Keys, for tests: `option-<keyPrefix>-<value>` and `create-<keyPrefix>`.
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.values,
    required this.onPicked,
    this.typed = '',
    this.keyPrefix,
    this.leadingOf,
    this.addLabel,
    this.onAdd,
  });

  /// In the order they are offered: most used, or by name/size.
  final List<String> values;
  final ValueChanged<String> onPicked;

  /// What is in the box now.
  final String typed;
  final String? keyPrefix;

  /// A small mark before a choice — a colour's dot.
  final Widget Function(String value)? leadingOf;
  final String Function(String typed)? addLabel;
  final ValueChanged<String>? onAdd;

  @override
  Widget build(BuildContext context) {
    final key = normalizeOption(typed);
    String? picked;
    for (final v in values) {
      if (normalizeOption(v) == key) picked = v;
    }
    final List<String> shown;
    if (key.isEmpty || picked != null) {
      shown = values;
    } else {
      final starts = <String>[];
      final inside = <String>[];
      for (final v in values) {
        final k = normalizeOption(v);
        if (k.startsWith(key)) {
          starts.add(v);
        } else if (k.contains(key)) {
          inside.add(v);
        }
      }
      shown = [...starts, ...inside];
    }
    final canAdd =
        onAdd != null && addLabel != null && key.isNotEmpty && picked == null;
    if (shown.isEmpty && !canAdd) return const SizedBox(height: 4);
    final prefix = keyPrefix;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final v in shown)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: prefix == null ? null : Key('option-$prefix-$v'),
                  // Built-in values in the phone's language (FM #24).
                  label: Text(shopValue(context, v)),
                  avatar: leadingOf?.call(v),
                  showCheckmark: false,
                  selected: v == picked,
                  // The picked one in navy, as a filled button reads.
                  selectedColor: scheme.primary,
                  side: v == picked ? BorderSide(color: scheme.primary) : null,
                  labelStyle: v == picked
                      ? TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onPicked(v),
                ),
              ),
            if (canAdd)
              ActionChip(
                key: prefix == null ? null : Key('create-$prefix'),
                avatar: const Icon(Icons.add, size: 18),
                label: Text(addLabel!(typed.trim())),
                visualDensity: VisualDensity.compact,
                onPressed: () => onAdd!(typed.trim()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Several picks in one sideways row — a repair's complaints, what was left
/// with the phone. Picked ones turn navy and come first, so what is picked is
/// always in sight; [typed] narrows the rest. The [PickRow] for lists where
/// more than one can be true.
///
/// Keys, for tests: `option-<keyPrefix>-<value>`.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.values,
    required this.picked,
    required this.onToggle,
    this.typed = '',
    this.keyPrefix,
  });

  final List<String> values;
  final Set<String> picked;
  final void Function(String value, bool on) onToggle;
  final String typed;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final key = normalizeOption(typed);
    final starts = <String>[];
    final inside = <String>[];
    for (final v in values) {
      if (picked.contains(v)) continue;
      final k = normalizeOption(v);
      if (key.isEmpty || k.startsWith(key)) {
        starts.add(v);
      } else if (k.contains(key)) {
        inside.add(v);
      }
    }
    final shown = [...values.where(picked.contains), ...starts, ...inside];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (shown.isEmpty) {
      return const SizedBox(height: 4);
    }
    final prefix = keyPrefix;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final v in shown)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  key: prefix == null ? null : Key('option-$prefix-$v'),
                  // Built-in values in the phone's language (FM #24).
                  label: Text(shopValue(context, v)),
                  selected: picked.contains(v),
                  selectedColor: scheme.primary,
                  checkmarkColor: scheme.onPrimary,
                  side: picked.contains(v)
                      ? BorderSide(color: scheme.primary)
                      : null,
                  labelStyle: picked.contains(v)
                      ? TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (on) => onToggle(v, on),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The red * after something that must be filled before saving.
class RequiredMark extends StatelessWidget {
  const RequiredMark({super.key});

  @override
  Widget build(BuildContext context) => Text(
    ' *',
    style: TextStyle(
      color: Theme.of(context).colorScheme.error,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// A field's label, with the red * when it must be filled to save. Use as
/// `InputDecoration(label: FieldLabel('Brand', required: true))`.
///
/// The words stay a Text of their own, so a field is still found by them.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (!required) return Text(text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        const RequiredMark(),
      ],
    );
  }
}

/// A ROW IN A PICKER THAT LOOKS LIKE SOMETHING TO TAP
///
/// A bordered card with an icon, the name, the price in bold and an "Add"
/// button — not a line of text that reads like a list of rules. A row that
/// cannot be picked has no button, is greyed, and [subtitle] says why.
class PickTile extends StatelessWidget {
  const PickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.price,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? price;

  /// Null: shown, but not pickable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    final faded = scheme.onSurface.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: enabled ? scheme.surface : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: enabled ? scheme.outline : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: enabled
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? scheme.onPrimaryContainer : faded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled ? null : faded,
                        ),
                      ),
                      if (price != null)
                        Text(
                          price!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: enabled ? scheme.primary : faded,
                          ),
                        ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: enabled ? scheme.onSurfaceVariant : faded,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.add),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The brands or categories in a list, most common first — for the sideways
/// filter row of a picker. Blank values are left out.
List<String> groupsByCount(Iterable<String> values) {
  final counts = <String, int>{};
  for (final v in values) {
    final t = v.trim();
    if (t.isEmpty) continue;
    counts[t] = (counts[t] ?? 0) + 1;
  }
  final out = counts.keys.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
    });
  return out;
}

/// One of a few fixed choices in one sideways row — a repair's status, what
/// came of an enquiry. Like [PickRow], but for choices that are not typed and
/// whose words are not their values. The chosen one is navy and is scrolled
/// into sight when the page opens, even if it is at the far end.
class ChoiceRow<T> extends StatefulWidget {
  const ChoiceRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onPicked,
    this.keyOf,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onPicked;
  final Key Function(T value)? keyOf;

  @override
  State<ChoiceRow<T>> createState() => _ChoiceRowState<T>();
}

class _ChoiceRowState<T> extends State<ChoiceRow<T>> {
  final _chosen = GlobalKey();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showChosen());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The picked one scrolled into sight — this row only, never the page it
  /// sits on, and only as far as needed: a row whose pick already shows
  /// stays where it starts, so its first options are not pushed off.
  void _showChosen() {
    if (!mounted || !_scroll.hasClients) return;
    final chip = _chosen.currentContext?.findRenderObject();
    final row = context.findRenderObject();
    if (chip is! RenderBox || row is! RenderBox) return;
    if (!chip.hasSize || !row.hasSize) return;
    final left =
        chip.localToGlobal(Offset.zero, ancestor: row).dx + _scroll.offset;
    final right = left + chip.size.width;
    final view = row.size.width;
    final pos = _scroll.position;
    double? to;
    if (right > _scroll.offset + view) to = right - view + 16;
    if (left < _scroll.offset) to = left - 16;
    if (to != null) {
      _scroll.jumpTo(to.clamp(pos.minScrollExtent, pos.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in widget.values)
            Padding(
              key: v == widget.selected ? _chosen : null,
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: widget.keyOf?.call(v),
                label: Text(widget.labelOf(v)),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selected: v == widget.selected,
                selectedColor: scheme.primary,
                side: v == widget.selected
                    ? BorderSide(color: scheme.primary)
                    : null,
                labelStyle: v == widget.selected
                    ? TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
                // The chosen one stays drawn as chosen; tapping it again
                // does nothing.
                onSelected: (_) {
                  if (v != widget.selected) widget.onPicked(v);
                },
              ),
            ),
        ],
      ),
    );
  }
}
