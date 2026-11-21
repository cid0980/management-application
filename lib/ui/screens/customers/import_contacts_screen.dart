import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/customers/contact_import.dart';
import '../../../domain/customers/customer.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/field_help.dart';

/// IMPORT CONTACTS — `/admin/import-contacts`
///
/// Ported from the French Mobiles Flutter port. For a shop starting out with
/// a phone book full of customers: paste it in, see who would be added, add
/// them. Nothing is written until the list is confirmed, and anyone already
/// on the books is skipped by number. The reading rules are in
/// `contact_import.dart`.
class ImportContactsScreen extends StatefulWidget {
  const ImportContactsScreen({super.key});

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  final _paste = TextEditingController();
  List<ImportedContact> _found = const [];
  bool _read = false;
  bool _adding = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _paste.text = data!.text!;
    _readIt();
  }

  void _readIt() {
    setState(() {
      _found = parseContacts(_paste.text);
      _read = true;
    });
  }

  Future<void> _add(List<ImportedContact> fresh) async {
    final repo = context.read<CustomerRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _adding = true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    var added = 0;
    for (final (i, c) in fresh.indexed) {
      await repo.save(
        Customer(
          id: 'c-$stamp-$i',
          name: c.name,
          phone: c.phone,
          createdAt: DateTime.now(),
        ),
      );
      added++;
    }
    if (!mounted) return;
    setState(() {
      _adding = false;
      _found = const [];
      _read = false;
      _paste.clear();
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.importAdded('$added'))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final existing = context.watch<CustomerRepository>().customers;
    final fresh = newContacts(_found, existing);
    final skipped = _found.length - fresh.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HelpTitle(
          icon: Icons.contacts_outlined,
          text: l10n.importTitle,
          help: l10n.helpImport,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(l10n.importHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(
          key: const Key('import-paste'),
          controller: _paste,
          minLines: 6,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: 'Ramesh Kumar, 98765 43210\nPriya S  9123456780',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _read = false),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('import-from-clipboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _pasteClipboard,
                icon: const Icon(Icons.content_paste),
                label: Text(l10n.importPaste),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('import-read'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _readIt,
                icon: const Icon(Icons.manage_search),
                label: Text(l10n.importRead),
              ),
            ),
          ],
        ),
        if (_read) ...[
          const SizedBox(height: 20),
          Text(
            _found.isEmpty
                ? l10n.importNoneFound
                : l10n.importSummary('${fresh.length}', '$skipped'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final c in fresh)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_add_alt),
              title: Text(c.name.isEmpty ? l10n.noNameGiven : c.name),
              subtitle: Text(formatPhone(c.phone)),
            ),
          if (fresh.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('import-add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _adding ? null : () => _add(fresh),
              icon: const Icon(Icons.check),
              label: Text(l10n.importAddAll('${fresh.length}')),
            ),
          ],
        ],
      ],
    );
  }
}
