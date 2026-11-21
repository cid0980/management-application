import 'package:flutter/material.dart';

import '../../domain/settings/languages.dart';
import '../../l10n/l10n.dart';

/// THE LANGUAGE PICKER
///
/// One widget, used when a shop is created and again on the settings page, so
/// the two cannot drift into offering different languages or describing the
/// choice differently.
///
/// **Each language names itself in its own script**, with the English name
/// underneath. Somebody changing the language is usually somebody who cannot
/// read the language the app is in at that moment — a list of English names
/// would be no help, and a list of only native scripts would strand an owner
/// setting the app up for staff.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.showHint = true,
  });

  final ShopLanguage selected;
  final ValueChanged<ShopLanguage> onChanged;
  final bool enabled;

  /// False where the surrounding section already carries the same sentence —
  /// saying it twice on one screen reads as a mistake, because it is one.
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RadioGroup<ShopLanguage>(
      groupValue: selected,
      // Gated here rather than by passing null: RadioGroup takes a
      // non-nullable callback, and a picker that is busy saving should ignore
      // taps rather than disappear.
      onChanged: (ShopLanguage? v) {
        if (!enabled || v == null) return;
        onChanged(v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final language in ShopLanguage.values)
            RadioListTile<ShopLanguage>(
              key: Key('language-${codeOf(language)}'),
              value: language,
              contentPadding: EdgeInsets.zero,
              title: Text(
                kLanguageNames[language]!,
                style: theme.textTheme.titleMedium,
              ),
              subtitle:
                  kLanguageNames[language] == kLanguageEnglishNames[language]
                  ? null
                  : Text(kLanguageEnglishNames[language]!),
            ),
          if (showHint) ...[
            const SizedBox(height: 4),
            Text(context.l10n.languageHint, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
