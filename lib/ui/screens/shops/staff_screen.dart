import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shops/membership.dart';
import '../../../l10n/l10n.dart';

/// STAFF
///
/// Who works here, what they may do, and who has been invited but has not
/// signed up yet.
///
/// **An invite is sent to an email, not to an account.** The person being
/// invited usually has no account at the moment the owner adds them — so the
/// invite waits under the shop, keyed by their email, and is claimed the first
/// time they sign in. That is why this page has two lists and not one: the
/// second list is people who cannot be given a role yet, because there is no
/// uid to give it to.
///
/// **Every refusal comes from the domain, not from this page.** The owner
/// cannot be demoted, the last admin cannot remove themselves, and only an
/// admin may change anything — `inviteBlockFor`, `roleChangeBlockFor` and
/// `removeBlockFor` decide all three, and the repository asks them. This
/// screen shows the answer. A screen that hid the button instead would be a
/// rule that a modified client could walk straight past.
///
/// **Nothing is changed without a confirmation.** Removing somebody takes
/// their access away mid-shift, and the undo is an invite and a sign-in.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    // Null when the app is running without Firebase — see `main.dart`. There
    // is no local stand-in for a shop's membership, so the page says so.
    final shops = context.watch<ShopRepository?>();
    final shopId = auth.shopId;

    if (shops == null || shopId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l10n.staffOffline, textAlign: TextAlign.center),
        ),
      );
    }

    return StreamBuilder<List<ShopMember>>(
      stream: shops.watchMembers(shopId),
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? const <ShopMember>[];

        if (memberSnapshot.hasError) {
          return _Problem(message: '${memberSnapshot.error}');
        }
        if (!memberSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<ShopInvite>>(
          stream: shops.watchInvites(shopId),
          builder: (context, inviteSnapshot) {
            final invites = inviteSnapshot.data ?? const <ShopInvite>[];
            // Whoever is signed in, as this shop sees them — the actor every
            // rule is checked against.
            final me = members
                .where((m) => m.uid == (auth.user?.uid ?? ''))
                .cast<ShopMember?>()
                .firstWhere((_) => true, orElse: () => null);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  context.l10n.workingHere('${members.length}'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final member in members)
                  _MemberCard(
                    member: member,
                    me: me,
                    members: members,
                    shopId: shopId,
                    shops: shops,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.invited,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.icon(
                      onPressed: () => _invite(
                        context,
                        shops: shops,
                        shopId: shopId,
                        shopName: '',
                        me: me,
                        members: members,
                      ),
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(context.l10n.invite),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (inviteSnapshot.hasError)
                  _Problem(message: '${inviteSnapshot.error}')
                else if (invites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(context.l10n.nobodyWaitingToJoin),
                  )
                else
                  for (final invite in invites)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(invite.email),
                        subtitle: Text(
                          context.l10n.claimedOnFirstSignIn(
                            roleLabel(context, invite.role),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: context.l10n.withdraw,
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final result = await shops.withdrawInvite(
                              shopId: shopId,
                              email: invite.email,
                              actor: me,
                            );
                            if (context.mounted) _say(context, result);
                          },
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _invite(
    BuildContext context, {
    required ShopRepository shops,
    required String shopId,
    required String shopName,
    required ShopMember? me,
    required List<ShopMember> members,
  }) async {
    final controller = TextEditingController();
    var role = ShopRole.staff;

    final send = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.inviteSomebody),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.l10n.email,
                  helperText: context.l10n.claimFirstSignIn,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ShopRole>(
                segments: [
                  for (final r in ShopRole.values)
                    ButtonSegment(value: r, label: Text(roleLabel(context, r))),
                ],
                selected: {role},
                onSelectionChanged: (s) => setState(() => role = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.send),
            ),
          ],
        ),
      ),
    );

    if (send != true || !context.mounted) return;

    final result = await shops.invite(
      shopId: shopId,
      shopName: shopName,
      email: controller.text,
      role: role,
      actor: me,
      existing: members,
    );
    if (context.mounted) {
      _say(
        context,
        result,
        okMessage: context.l10n.inviteSentTo(controller.text),
      );
    }
  }
}

/// What a role is called in the shop's language.
///
/// The stored value is the enum; this is only what it is called on screen.
String roleLabel(BuildContext context, ShopRole role) => switch (role) {
  ShopRole.admin => context.l10n.roleAdmin,
  ShopRole.staff => context.l10n.roleStaff,
};

void _say(BuildContext context, MemberResult result, {String? okMessage}) {
  final message = result.ok ? okMessage : result.message;
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.me,
    required this.members,
    required this.shopId,
    required this.shops,
  });

  final ShopMember member;
  final ShopMember? me;
  final List<ShopMember> members;
  final String shopId;
  final ShopRepository shops;

  @override
  Widget build(BuildContext context) {
    final isMe = member.uid == me?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initials(member))),
        title: Text(member.name.trim().isEmpty ? member.email : member.name),
        subtitle: Text(
          [
            member.email,
            roleLabel(context, member.role),
            if (member.isOwner) context.l10n.owner,
            if (isMe) context.l10n.you,
          ].join(' · '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (choice) => _choose(context, choice),
          itemBuilder: (context) => [
            for (final role in ShopRole.values)
              if (role != member.role)
                PopupMenuItem(
                  value: 'role:${role.name}',
                  child: Text(
                    context.l10n.makeRole(
                      roleLabel(context, role).toLowerCase(),
                    ),
                  ),
                ),
            PopupMenuItem(
              value: 'remove',
              child: Text(context.l10n.removeFromShop),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context, String choice) async {
    if (choice.startsWith('role:')) {
      final role = choice == 'role:${ShopRole.admin.name}'
          ? ShopRole.admin
          : ShopRole.staff;
      final result = await shops.setRole(
        shopId: shopId,
        target: member,
        role: role,
        actor: me,
        allMembers: members,
      );
      if (context.mounted) {
        _say(context, result, okMessage: context.l10n.roleChanged);
      }
      return;
    }

    // Removing somebody takes their access away mid-shift. Asked first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.removeNamed(
            member.name.isEmpty ? member.email : member.name,
          ),
        ),
        content: Text(context.l10n.loseAccessNow),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await shops.removeMember(
      shopId: shopId,
      target: member,
      actor: me,
      allMembers: members,
    );
    if (context.mounted) {
      _say(context, result, okMessage: context.l10n.removed);
    }
  }

  static String _initials(ShopMember member) {
    final source = member.name.trim().isNotEmpty ? member.name : member.email;
    final parts = source
        .split(RegExp(r'[\s@._+-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
