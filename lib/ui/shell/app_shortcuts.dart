import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../l10n/l10n.dart';
import '../screens/sales/sale_form_sheet.dart';
import '../screens/second_hand/second_hand_form_sheet.dart';
import '../screens/service/service_form_sheet.dart';

/// SHORTCUTS ON THE APP ICON
///
/// Press and hold the app's icon on the phone's home screen: New repair, Buy
/// phone, New bill and Scan are right there, and each opens straight into
/// its form (or the scanner) — no Home, no tab, no button. The busiest
/// moments at a counter start with one of these four.
///
/// Draws nothing. Lives in the signed-in frame (AppShell), so a shortcut is
/// only acted on once someone is signed in to a shop.
class AppShortcuts extends StatefulWidget {
  const AppShortcuts({super.key});

  /// The shortcut ids, as Android keeps them.
  static const repair = 'repair';
  static const buy = 'buy';
  static const bill = 'bill';
  static const scan = 'scan';

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  final _actions = const QuickActions();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || kIsWeb) return;
    _started = true;
    final l10n = context.l10n;
    _setUp([
      ShortcutItem(
        type: AppShortcuts.repair,
        localizedTitle: l10n.homeNewRepair,
      ),
      ShortcutItem(type: AppShortcuts.buy, localizedTitle: l10n.homeBuyPhone),
      ShortcutItem(
        type: AppShortcuts.bill,
        localizedTitle: l10n.shortcutNewBill,
      ),
      ShortcutItem(type: AppShortcuts.scan, localizedTitle: l10n.navScanner),
    ]);
  }

  Future<void> _setUp(List<ShortcutItem> items) async {
    try {
      await _actions.initialize(_open);
      await _actions.setShortcutItems(items);
    } catch (_) {
      // A platform without icon shortcuts (or a test): nothing to set up.
    }
  }

  Future<void> _open(String type) async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    switch (type) {
      case AppShortcuts.scan:
        router.go('/scanner');
        return;
      case AppShortcuts.repair:
        router.go('/service');
      case AppShortcuts.buy:
        router.go('/inventory/second-hand');
      case AppShortcuts.bill:
        router.go('/sales');
      default:
        return;
    }
    // The list first, then its form over it, as if its + had been tapped.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    switch (type) {
      case AppShortcuts.repair:
        await openServiceSheet(context);
      case AppShortcuts.buy:
        await openPurchaseSheet(context);
      case AppShortcuts.bill:
        await openSaleSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
