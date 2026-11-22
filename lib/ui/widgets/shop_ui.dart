import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
            padding: EdgeInsets.fromLTRB(12, 7, count == null ? 14 : 7, 7),
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
                    fontSize: 15,
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
                        fontSize: 14,
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 128,
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
  const FormSection(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Row(
      children: [
        Flexible(
          child: Text(
            title,
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
