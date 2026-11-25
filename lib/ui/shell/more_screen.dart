import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

import '../../app/auth_state.dart';
import '../../app/nav.dart';
import '../../l10n/l10n.dart';
import '../widgets/input_sheet.dart';

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

    Widget group(List<Widget> rows) => Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            r,
          ],
        ],
      ),
    );
    Widget row(NavItem item) => ListTile(
      key: Key('more-${item.path}'),
      leading: Icon(item.icon, color: AppTheme.primary),
      title: Text(item.labelIn(context.l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openPage(context, item.path),
    );
    // Under a few headings rather than one long list, so a page is found
    // by what it is about. An area not named here still shows, under Other.
    final l10n = context.l10n;
    final sections = <(String?, List<String>)>[
      (l10n.moreGroupMoney, ['/due-payments', '/expenses', '/reports']),
      (l10n.moreGroupStock, ['/products', '/admin/labels', '/scanner']),
      (
        l10n.moreGroupPeople,
        ['/customers', '/admin/staff', '/admin/import-contacts'],
      ),
      (
        l10n.moreGroupWork,
        ['/enquiries', '/admin/tasks', '/tasks', '/admin/ratings'],
      ),
      (null, ['/admin/settings']),
    ];
    final named = {for (final (_, paths) in sections) ...paths};
    final others = items.where((i) => !named.contains(i.path)).toList();
    final heading = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: AppTheme.textSecondary);
    List<Widget> section(String? title, List<NavItem> rows) => rows.isEmpty
        ? const []
        : [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Text(title, style: heading),
              ),
            group([for (final r in rows) row(r)]),
            const SizedBox(height: 12),
          ];
    final error = Theme.of(context).colorScheme.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Who is signed in, and as what.
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              user?.name ?? user?.email ?? context.l10n.signedOut,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                if (auth.shopName != null) auth.shopName!,
                user?.role.name ?? '',
              ].where((p) => p.isNotEmpty).join(' · '),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final (title, paths) in sections)
          ...section(title, [
            for (final p in paths) ...items.where((i) => i.path == p),
          ]),
        ...section(l10n.moreGroupOther, others),
        group([
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primary),
            title: Text(context.l10n.navLogout),
            onTap: () => context.read<AuthState>().signOut(),
          ),
          // A Google Play requirement for any app with sign-up. Last, and
          // red, so it is findable without being tapped by accident.
          ListTile(
            key: const Key('delete-account'),
            leading: Icon(Icons.person_remove_outlined, color: error),
            title: Text(
              context.l10n.deleteMyAccount,
              style: TextStyle(color: error),
            ),
            onTap: () => _confirmDelete(context),
          ),
        ]),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final password = await showInputSheet<String>(
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
  bool _show = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return InputSheet(
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
            obscureText: !_show,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.passwordToConfirm,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _show ? l10n.hidePassword : l10n.showPassword,
                icon: Icon(
                  _show
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _show = !_show),
              ),
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
