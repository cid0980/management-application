import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../app/nav.dart';
import '../../data/settings_repository.dart';

/// The frame every signed-in screen sits in: a title bar, and a bottom bar of
/// five with Scan raised in the middle.
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
        // Home has no title bar: its greeting is the header.
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
    final theme = Theme.of(context);
    // An area with no tab of its own (Customers, Sales, Settings…) was reached
    // through More, so More stays lit there — the bar never goes blank.
    final hasOwnTab = kBottomNav.any(
      (d) => d.path != kMorePath && AppShell._isActive(location, d.path),
    );
    bool lit(BottomDestination d) =>
        d.path == kMorePath ? !hasOwnTab : AppShell._isActive(location, d.path);
    // A rounded bar that floats above the page rather than a strip glued to
    // the bottom edge.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 10,
        shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final dest in kBottomNav)
                if (dest.raised)
                  // Raised, because scanning is the one thing done standing at the
                  // counter with a phone already in the other hand.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FloatingActionButton.small(
                      heroTag: 'scan',
                      // Rose, like the rest of the bar: it is navigation, and
                      // green is kept for the one action a screen asks for.
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      onPressed: () => context.go(dest.path),
                      child: Icon(dest.icon),
                    ),
                  )
                else
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () => context.go(dest.path),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // The active tab sits on a soft-pink pill, so "where am
                          // I" is a shape as well as a colour.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: lit(dest)
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              dest.icon,
                              size: 22,
                              color: lit(dest)
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest.labelIn(context.l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: lit(dest)
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Offline — saved on this phone". Shown only while the server cannot be
/// reached; nothing is lost meanwhile, and saying so stops a bill being
/// entered twice because the first one "didn't go through".
class OfflineBanner extends StatelessWidget {
  const OfflineBanner();

  @override
  Widget build(BuildContext context) {
    bool offline;
    try {
      offline = context.watch<SettingsRepository>().offline;
    } on ProviderNotFoundException {
      offline = false;
    }
    if (!offline) return const SizedBox.shrink();
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
