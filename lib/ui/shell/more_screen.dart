import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../app/nav.dart';
import '../../l10n/l10n.dart';

/// The More tab: every area the bottom bar has no room for, then logout.
///
/// This is what the side menu used to hold, minus the four areas that already
/// have a tab — listing Service twice would only make staff wonder whether
/// they are the same place.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final onBar = kBottomNav.map((d) => d.path).toSet();
    final items = kNavItems
        .where((i) => i.visibleTo(isAdmin: auth.isAdmin))
        .where((i) => !onBar.contains(i.path))
        .toList();

    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(user?.initials ?? '?')),
          title: Text(user?.name ?? user?.email ?? context.l10n.signedOut),
          subtitle: Text(user?.role.name ?? ''),
        ),
        const Divider(height: 1),
        for (final item in items)
          ListTile(
            leading: Icon(item.icon),
            title: Text(item.labelIn(context.l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(item.path),
          ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(context.l10n.navLogout),
          onTap: () => context.read<AuthState>().signOut(),
        ),
      ],
    );
  }
}
