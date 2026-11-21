/// THE SHOP'S WORDS, FROM ANY WIDGET
///
/// `context.l10n.navSales` instead of `AppLocalizations.of(context).navSales`,
/// with one difference that matters: **a widget built without the delegate
/// above it falls back to English rather than throwing.**
///
/// That is not laziness about test setup. The app always installs the
/// delegate, so in the shop this is never the fallback path. But a widget test
/// pumping one sheet, a thumbnail, an error screen rendered before
/// `MaterialApp` is ready — none of those should crash because a language was
/// not wired up. A till that shows English for a moment is a till; a till that
/// shows a red screen is not.
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}
