import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../app/nav.dart';
import '../../data/settings_repository.dart';

/// The frame every signed-in screen sits in: a title bar, and a bottom bar of
/// five. Scan is the button inside the search boxes, not a tab.
///
/// No side menu — a hamburger drawer is a website habit and makes the app feel
/// like one. The bottom bar is the destinations staff move between all day,
/// and its last tab, More, lists everything else, so any area is still at most
/// two taps from anywhere.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// The nav item whose area the current location is in. A detail page
  /// (`/service/abc123`) belongs to its list (`/service`), so the bar does not
  /// go blank the moment someone opens a record.
  static bool _isActive(String location, String path) =>
      location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isAdmin = auth.isAdmin;
    final location = GoRouterState.of(context).uri.path;
    final items = kNavItems
        .where((i) => i.visibleTo(isAdmin: isAdmin))
        .toList();
    final current = items.where((i) => _isActive(location, i.path)).toList();
    final title = location == kMorePath
        ? context.l10n.tabMore
        : current.isEmpty
        ? context.l10n.appTitle
        : current.first.labelIn(context.l10n);

    // Back goes up a level rather than out of the app — see [backTarget].
    final up = backTarget(location);
    return PopScope(
      canPop: up == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && up != null) context.go(up);
      },
      child: Scaffold(
        // Home draws its own navy top block, with the search inside it.
        appBar: location == '/dashboard' ? null : AppBar(title: Text(title)),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: _BottomBar(location: location),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    // An area with no tab of its own (Customers, Settings…) was reached
    // through More, so More stays lit there — the bar never goes blank.
    final own = kBottomNav.indexWhere(
      (d) => d.path != kMorePath && AppShell._isActive(location, d.path),
    );
    final selected = own >= 0
        ? own
        : kBottomNav.indexWhere((d) => d.path == kMorePath);
    // Material's own bottom bar, as every Android app has it: the active tab
    // sits on a pale-navy pill, so "where am I" is a shape as well as a
    // colour.
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => context.go(kBottomNav[i].path),
      destinations: [
        for (final dest in kBottomNav)
          NavigationDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
            label: dest.labelIn(context.l10n),
          ),
      ],
    );
  }
}

/// "Offline — saved on this phone". Shown only while the server cannot be
/// reached; nothing is lost meanwhile, and saying so stops a bill being
/// entered twice because the first one "didn't go through".
///
/// Only after [delay] of being offline: every app start serves the cache
/// for a moment before the server answers, and a banner that flashes each
/// morning is one people learn to ignore.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, this.delay = const Duration(seconds: 4)});

  final Duration delay;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _timer;
  bool _show = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool offline;
    try {
      offline = context.watch<SettingsRepository>().offline;
    } on ProviderNotFoundException {
      offline = false;
    }
    if (!offline) {
      _timer?.cancel();
      _timer = null;
      _show = false;
    } else if (!_show && _timer == null) {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _show = true);
      });
    }
    if (!_show) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      key: const Key('offline-banner'),
      color: theme.colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.offlineBanner,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
