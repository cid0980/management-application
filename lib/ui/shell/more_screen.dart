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
        // A Google Play requirement for any app with sign-up. Last, and red,
        // so it is findable without being tapped by accident.
        ListTile(
          key: const Key('delete-account'),
          leading: Icon(
            Icons.person_remove_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            context.l10n.deleteMyAccount,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null) return;
    final problem = await auth.deleteAccount(password: password);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l10n.deleteMyAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountExplain),
          const SizedBox(height: 16),
          TextField(
            key: const Key('delete-account-password'),
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.passwordToConfirm,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('delete-account-confirm'),
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: () => Navigator.of(context).pop(_password.text),
          child: Text(l10n.deleteForever),
        ),
      ],
    );
  }
}
