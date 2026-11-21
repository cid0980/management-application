import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// NAV ITEMS
///
/// One list, read by both the More page and the bottom bar, so the two can
/// never disagree about where something lives. `adminOnly` / `staffOnly` is the only
/// visibility rule there is.
class NavItem {
  const NavItem(
    this.label,
    this.path,
    this.icon, {
    this.adminOnly = false,
    this.staffOnly = false,
  });

  /// The English label, and the key this item is translated by.
  ///
  /// Kept on the item rather than looked up by path, so adding a destination
  /// without a translation shows English rather than a blank drawer row.
  final String label;

  final String path;
  final IconData icon;
  final bool adminOnly;
  final bool staffOnly;

  /// What this item is called in the shop's language.
  ///
  /// The drawer and the bottom bar both go through here, so they cannot drift
  /// into calling the same destination two things.
  String labelIn(AppLocalizations l10n) => switch (path) {
    '/dashboard' => l10n.navDashboard,
    '/customers' => l10n.navCustomers,
    '/inventory/second-hand' => l10n.navSecondHand,
    '/products' => l10n.navProducts,
    '/service' => l10n.navService,
    '/sales' => l10n.navSales,
    '/due-payments' => l10n.navDuePayments,
    '/enquiries' => l10n.navEnquiries,
    '/scanner' => l10n.navScanner,
    '/admin/labels' => l10n.navLabels,
    '/admin/settings' => l10n.navSettings,
    '/reports' => l10n.navReports,
    '/admin/staff' => l10n.navStaff,
    '/admin/tasks' => l10n.navTasks,
    '/tasks' => l10n.navMyTasks,
    // A destination added without a translation is not a blank row.
    _ => label,
  };

  bool visibleTo({required bool isAdmin}) {
    if (adminOnly) return isAdmin;
    if (staffOnly) return !isAdmin;
    return true;
  }
}

const List<NavItem> kNavItems = [
  NavItem('Dashboard', '/dashboard', Icons.home_outlined),
  NavItem('Customers', '/customers', Icons.people_outline),
  NavItem('Second-Hand', '/inventory/second-hand', Icons.smartphone_outlined),
  NavItem('Products', '/products', Icons.inventory_2_outlined),
  NavItem('Service', '/service', Icons.build_outlined),
  NavItem('Sales', '/sales', Icons.point_of_sale_outlined),
  NavItem('Due Payments', '/due-payments', Icons.currency_rupee),
  NavItem('Enquiries', '/enquiries', Icons.chat_bubble_outline),
  NavItem('Scanner', '/scanner', Icons.qr_code_scanner),
  NavItem('Labels', '/admin/labels', Icons.sell_outlined),
  NavItem(
    'Settings',
    '/admin/settings',
    Icons.settings_outlined,
    adminOnly: true,
  ),
  NavItem('Reports', '/reports', Icons.bar_chart_outlined, adminOnly: true),
  NavItem('Staff', '/admin/staff', Icons.badge_outlined, adminOnly: true),
  // One area, two doors: the owner writes and hands out the tasks, a staff
  // member sees only their own. Each role is shown exactly one of them.
  NavItem('Tasks', '/admin/tasks', Icons.checklist, adminOnly: true),
  NavItem('My Tasks', '/tasks', Icons.checklist, staffOnly: true),
  NavItem(
    'Import contacts',
    '/admin/import-contacts',
    Icons.contacts_outlined,
    adminOnly: true,
  ),
];

/// BOTTOM TAB BAR
///
/// Four destinations plus a raised Scan action in the middle, the arrangement
/// people already expect from a native app. Scan is the middle one because it
/// is the thing staff do standing at the counter with a phone in one hand.
///
/// There is no side menu. The last tab, More, is a page listing every other
/// area and logout — what WhatsApp, Paytm and the banking apps staff already
/// use have taught them to look for.
class BottomDestination {
  const BottomDestination(
    this.label,
    this.path,
    this.icon, {
    this.raised = false,
  });

  /// The English label, and the key this item is translated by.
  ///
  /// Kept on the item rather than looked up by path, so adding a destination
  /// without a translation shows English rather than a blank drawer row.
  final String label;

  final String path;
  final IconData icon;
  final bool raised;

  /// What the tab is called in the shop's language. The bottom bar has room
  /// for two or three words at most, so these are the short forms.
  String labelIn(AppLocalizations l10n) => switch (path) {
    '/dashboard' => l10n.tabHome,
    '/inventory/second-hand' => l10n.tabMobiles,
    '/scanner' => l10n.tabScan,
    '/service' => l10n.navService,
    '/sales' => l10n.navSales,
    kMorePath => l10n.tabMore,
    _ => label,
  };
}

/// The More page. Not a [NavItem]: it is the list of areas, not one of them.
const String kMorePath = '/more';

const List<BottomDestination> kBottomNav = [
  BottomDestination('Home', '/dashboard', Icons.home_outlined),
  BottomDestination(
    'Mobiles',
    '/inventory/second-hand',
    Icons.smartphone_outlined,
  ),
  BottomDestination('Scan', '/scanner', Icons.qr_code_scanner, raised: true),
  BottomDestination('Service', '/service', Icons.build_outlined),
  BottomDestination('More', kMorePath, Icons.menu),
];

/// Where Android Back goes from [location]: **one level up, and only Home
/// leaves the app.** Returns null on Home, meaning let the system close it.
///
/// Every move in this app is a `go`, never a `push` — the bottom bar and the
/// More list jump between areas, they do not stack them — so there is no
/// history for Back to pop. Left alone, Back closed the app from every page:
/// staff opened Customers from More, pressed Back to choose another area, and
/// were on the phone's home screen. So Back is not "previous page", which
/// would depend on how somebody happened to arrive; it is "up", which is the
/// same answer every time:
///
///     /customers/c1           → /customers   a record goes back to its list
///     /customers              → /more        an area opened from More
///     /service, /scanner, …   → /dashboard   a bottom-bar tab
///     /dashboard              → (exit)
///
/// A record opened from a list is stacked by its nested route, so the
/// navigator pops it before this is ever asked; the detail rule is here for a
/// record reached by a link or a scan, which has no list underneath it.
String? backTarget(String location) {
  if (location == '/dashboard') return null;
  for (final item in kNavItems) {
    if (location.startsWith('${item.path}/')) return item.path;
  }
  if (kBottomNav.any((d) => d.path == location)) return '/dashboard';
  if (kNavItems.any((i) => i.path == location)) return kMorePath;
  return '/dashboard';
}
