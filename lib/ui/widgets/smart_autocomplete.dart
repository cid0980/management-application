import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// SEARCH FIRST, SELECT IF IT IS THERE, CREATE IF IT IS NOT
///
/// One search box used for every "pick from the shop's records" field —
/// customers, brands, models, RAM, storage, colours, suppliers — so they all
/// behave the same way and staff learn it once:
///
/// - Nothing is listed until something is typed.
/// - While typing, the matching records appear right under the box, best
///   first, in tall rows a thumb can hit.
/// - Tapping one selects it and closes the list.
/// - When nothing is an exact match, the last row offers to add what was
///   typed — `+ Add "Apple" as a new brand` — so there is never a separate
///   "Add new" button to hunt for.
///
/// The list is drawn in the page, under the box, rather than floating over
/// it: on a phone with the keyboard up a floating list is half hidden, and
/// this one scrolls with the form.
///
/// **This widget decides nothing about duplicates.** "Is this already there"
/// is [isExisting]'s answer, so each caller applies its own rule — a phone
/// number matched exactly, a brand matched case-insensitively — and the rule
/// lives next to the data it is about.
class SmartAutocomplete<T> extends StatefulWidget {
  const SmartAutocomplete({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.search,
    required this.titleOf,
    required this.optionKey,
    required this.onSelected,
    this.subtitleOf,
    this.leadingOf,
    this.isExisting,
    this.createLabel,
    this.onCreate,
    this.createKey,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.loading = false,
    this.enabled = true,
    this.emptyText,
    this.helperWhenClosed,
    this.maxResults = 5,
  });

  /// The key on the text box, so a test or a draft can find it by name.
  final Key fieldKey;

  final TextEditingController controller;

  /// What matches [query], best first. Called on every keystroke; it should
  /// be cheap (the lists are small and already in memory).
  final List<T> Function(String query) search;

  final String Function(T item) titleOf;
  final String? Function(T item)? subtitleOf;
  final Widget? Function(T item)? leadingOf;

  /// The key on a result row.
  final Key Function(T item) optionKey;

  final ValueChanged<T> onSelected;

  /// Whether [query] already names a record exactly. When it does, no
  /// "Add" row is offered — that is what stops a second "Samsung" being
  /// made. Defaults to a case-insensitive match on a result's title.
  final bool Function(String query)? isExisting;

  /// The words on the "Add" row, given what was typed.
  final String Function(String query)? createLabel;

  /// Adds what was typed. Without it there is no "Add" row.
  final FutureOr<void> Function(String query)? onCreate;

  /// The key on the "Add" row. Defaults to `create-<fieldKey>`.
  final Key? createKey;

  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  /// The records are still arriving: a spinner row instead of an empty list
  /// that would read as "there are none".
  final bool loading;

  /// Off when the field depends on an earlier one (a model before a brand).
  final bool enabled;

  /// Shown when nothing matches and nothing can be added.
  final String? emptyText;

  /// A note under the box once the list has closed — "New — it will be
  /// added when you save" — hidden while the list is open, where the "Add"
  /// row already says it.
  final String? helperWhenClosed;

  final int maxResults;

  @override
  State<SmartAutocomplete<T>> createState() => _SmartAutocompleteState<T>();
}

class _SmartAutocompleteState<T> extends State<SmartAutocomplete<T>> {
  final _focus = FocusNode();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // The list belongs to the box being typed in, so it comes and goes with
    // the focus and follows every keystroke.
    _focus.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(SmartAutocomplete<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _select(T item) {
    widget.onSelected(item);
    _focus.unfocus();
  }

  Future<void> _create(String query) async {
    final create = widget.onCreate;
    if (create == null || _creating) return;
    setState(() => _creating = true);
    try {
      await create(query);
    } finally {
      if (mounted) {
        setState(() => _creating = false);
        _focus.unfocus();
      }
    }
  }

  bool _exists(String query, List<T> results) {
    final check = widget.isExisting;
    if (check != null) return check(query);
    final wanted = query.trim().toLowerCase();
    return results.any((r) => widget.titleOf(r).trim().toLowerCase() == wanted);
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.text.trim();
    final open = widget.enabled && _focus.hasFocus && query.isNotEmpty;
    final results = open
        ? widget.search(query).take(widget.maxResults).toList()
        : <T>[];
    final canCreate =
        open &&
        widget.onCreate != null &&
        widget.createLabel != null &&
        !_exists(query, results);

    return TextFieldTapRegion(
      // One tap region for the box and its list, so tapping a result does
      // not count as tapping away from the box.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            textInputAction: TextInputAction.next,
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            decoration: widget.helperWhenClosed == null
                ? widget.decoration
                : widget.decoration.copyWith(
                    helperText: open ? null : widget.helperWhenClosed,
                  ),
          ),
          if (open &&
              (widget.loading ||
                  results.isNotEmpty ||
                  canCreate ||
                  widget.emptyText != null))
            _Dropdown(
              children: [
                if (widget.loading) const _SpinnerRow(),
                for (final item in results)
                  _ResultRow(
                    key: widget.optionKey(item),
                    title: widget.titleOf(item),
                    subtitle: widget.subtitleOf?.call(item),
                    leading: widget.leadingOf?.call(item),
                    onTap: () => _select(item),
                  ),
                if (canCreate)
                  _CreateRow(
                    key: widget.createKey ?? Key('create-${widget.fieldKey}'),
                    label: widget.createLabel!(query),
                    busy: _creating,
                    onTap: () => _create(query),
                  ),
                if (!widget.loading &&
                    results.isEmpty &&
                    !canCreate &&
                    widget.emptyText != null)
                  _EmptyRow(text: widget.emptyText!),
              ],
            ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      // A Material of its own, so a row's tap ripple shows.
      child: Material(
        color: AppTheme.surface,
        elevation: 4,
        shadowColor: AppTheme.secondary.withValues(alpha: 0.25),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // Tall rows: a thumb, not a mouse pointer.
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.north_west,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow({
    super.key,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = theme.colorScheme.primary;
    return InkWell(
      onTap: busy ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colour,
                    ),
                  )
                : Icon(Icons.add_circle, color: colour),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpinnerRow extends StatelessWidget {
  const _SpinnerRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
