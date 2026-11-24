import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
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
/// What reading the phone's contacts came back with.
class PhoneBookRead {
  const PhoneBookRead({this.book, this.blocked = false});

  /// Null when Contacts was not allowed.
  final List<(String, List<String>)>? book;

  /// Refused for good ("Don't ask again"): only Settings can allow it now.
  final bool blocked;
}

/// Reads the phone's contacts, asking for Contacts first. Swapped in tests.
@visibleForTesting
Future<PhoneBookRead> Function() readPhoneBook = _readPhoneBook;

/// Lets the person pick a .csv or .vcf file; its text, or null if none was
/// picked. Swapped in tests.
@visibleForTesting
Future<String?> Function() pickContactFile = _pickContactFile;

Future<PhoneBookRead> _readPhoneBook() async {
  final status = await fc.FlutterContacts.permissions.request(
    fc.PermissionType.read,
  );
  if (status != fc.PermissionStatus.granted &&
      status != fc.PermissionStatus.limited) {
    return PhoneBookRead(
      blocked: status == fc.PermissionStatus.permanentlyDenied,
    );
  }
  final all = await fc.FlutterContacts.getAll(
    properties: {fc.ContactProperty.phone},
  );
  return PhoneBookRead(
    book: [
      for (final c in all)
        (c.displayName ?? '', [for (final p in c.phones) p.number]),
    ],
  );
}

Future<String?> _pickContactFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'vcf', 'txt'],
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  // A phone book of thousands of people is well under this.
  if (bytes.length > 10 * 1024 * 1024) return '';
  return utf8.decode(bytes, allowMalformed: true);
}

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

  /// Numbers the person unticked: a plumber in the phone book is not a
  /// customer.
  final Set<String> _unticked = {};

  void _show(List<ImportedContact> found) {
    setState(() {
      _found = found;
      _unticked.clear();
      _read = true;
    });
  }

  Future<void> _fromPhone() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    PhoneBookRead result;
    try {
      result = await readPhoneBook();
    } catch (_) {
      result = const PhoneBookRead();
    }
    if (!mounted) return;
    final book = result.book;
    if (book == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.importContactsDenied),
          action: result.blocked
              ? SnackBarAction(
                  label: l10n.importOpenSettings,
                  onPressed: () =>
                      fc.FlutterContacts.permissions.openSettings(),
                )
              : null,
        ),
      );
      return;
    }
    _show(contactsFromPhoneBook(book));
  }

  Future<void> _fromFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    String? text;
    try {
      text = await pickContactFile();
    } catch (_) {
      text = '';
    }
    if (!mounted || text == null) return;
    final found = text.isEmpty
        ? const <ImportedContact>[]
        : parseContactFile(text);
    if (text.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFileUnreadable)),
      );
      return;
    }
    _show(found);
  }

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

  void _readIt() => _show(parseContacts(_paste.text));

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
      _unticked.clear();
      _paste.clear();
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.importAdded(added))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final existing = context.watch<CustomerRepository>().customers;
    final fresh = newContacts(_found, existing);
    final skipped = _found.length - fresh.length;
    final ticked = [
      for (final c in fresh)
        if (!_unticked.contains(c.phone)) c,
    ];

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
        // The two easy ways: the phone's own contacts, or an exported file.
        FilledButton.icon(
          key: const Key('import-from-phone'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _fromPhone,
          icon: const Icon(Icons.contact_phone_outlined),
          label: Text(l10n.importFromPhone),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('import-from-file'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _fromFile,
          icon: const Icon(Icons.upload_file),
          label: Text(l10n.importFromFile),
        ),
        const SizedBox(height: 16),
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
          if (fresh.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('import-tick-all'),
                onPressed: () => setState(() {
                  if (_unticked.isEmpty) {
                    _unticked.addAll(fresh.map((c) => c.phone));
                  } else {
                    _unticked.clear();
                  }
                }),
                child: Text(
                  _unticked.isEmpty ? l10n.importUntickAll : l10n.importTickAll,
                ),
              ),
            ),
          for (final c in fresh)
            CheckboxListTile(
              key: Key('import-${c.phone}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: !_unticked.contains(c.phone),
              onChanged: (on) => setState(() {
                if (on == true) {
                  _unticked.remove(c.phone);
                } else {
                  _unticked.add(c.phone);
                }
              }),
              title: Text(c.name.isEmpty ? l10n.noNameGiven : c.name),
              subtitle: Text(formatPhone(c.phone)),
            ),
          if (ticked.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('import-add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _adding ? null : () => _add(ticked),
              icon: const Icon(Icons.check),
              label: Text(l10n.importAddAll(ticked.length)),
            ),
          ],
        ],
      ],
    );
  }
}
