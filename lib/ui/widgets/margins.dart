import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../data/settings_repository.dart';

/// Whether the person holding this phone may see cost prices and profit.
///
/// Admins always; staff only when the owner has turned on "Staff can see cost
/// and profit" in Settings (see `ShopSettings.staffSeeCosts`). A screen pumped
/// without either store above it — a test — shows everything, as before.
///
/// This hides the figures on the screen; it is not a security boundary. The
/// records themselves are still the shop's, readable by its members.
bool canSeeMargins(BuildContext context) {
  try {
    if (context.watch<AuthState>().isAdmin) return true;
  } on ProviderNotFoundException {
    return true;
  }
  try {
    return context.watch<SettingsRepository>().settings.staffSeeCosts;
  } on ProviderNotFoundException {
    return true;
  }
}
