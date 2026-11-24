/// IMPORTING A PHONE BOOK
///
/// Ported from the French Mobiles Flutter port's Import Contacts screen, with
/// the gap it wrote down fixed: it kept only the numbers from a phone-book
/// (.vcf) file and dropped the names. Here a card's `FN:` name goes with the
/// number on its `TEL` line.
///
/// Anything that ends up as lines of text works: a .vcf opened as text, a
/// column pasted out of a spreadsheet, a WhatsApp list. Every line with an
/// Indian mobile number in it is a contact; the words beside the number are
/// the name.
///
/// **Nothing already on the books is added again**, matched by number rather
/// than spelling — `98765 43210` and `+91 98765-43210` are one person — and a
/// number pasted twice is one contact.
library;

import 'customer.dart';
import '../common/phone.dart';

class ImportedContact {
  const ImportedContact({required this.name, required this.phone});

  final String name;

  /// Ten digits, clean.
  final String phone;
}

final _mobile = RegExp(r'(?:\+?91[\s-]?|0)?[6-9]\d{4}[\s-]?\d{5}');

/// Every contact in [text], in the order found, each number once.
List<ImportedContact> parseContacts(String text) {
  final found = <ImportedContact>[];
  final seen = <String>{};
  String pendingName = '';

  for (final raw in text.split(RegExp(r'[\r\n]+'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final upper = line.toUpperCase();

    // A vCard: the name comes on its own line, before the number.
    if (upper.startsWith('BEGIN:VCARD')) {
      pendingName = '';
      continue;
    }
    if (upper.startsWith('FN:') || upper.startsWith('FN;')) {
      pendingName = line.substring(line.indexOf(':') + 1).trim();
      continue;
    }
    if (upper.startsWith('N:') || upper.startsWith('N;')) {
      // `N:Kumar;Ramesh;;;` — used only when there is no FN line.
      if (pendingName.isEmpty) {
        final parts = line.substring(line.indexOf(':') + 1).split(';');
        pendingName = [
          if (parts.length > 1) parts[1],
          parts.first,
        ].where((p) => p.trim().isNotEmpty).join(' ').trim();
      }
      continue;
    }
    if (upper.startsWith('END:VCARD')) {
      pendingName = '';
      continue;
    }

    final match = _mobile.firstMatch(line.replaceAll(RegExp(r'[()]'), ''));
    if (match == null) continue;
    final phone = normalizePhone(match.group(0));
    if (!isDiallablePhone(phone) || !seen.add(phone)) continue;

    var name = upper.startsWith('TEL')
        ? pendingName
        : line
              .replaceAll(RegExp(r'[()]'), '')
              .replaceFirst(match.group(0)!, ' ');
    name = name
        .replaceAll(RegExp(r'[\t,;|:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.length > 60) name = name.substring(0, 60).trim();
    found.add(ImportedContact(name: name, phone: phone));
  }
  return found;
}

/// The contacts not already in [existing], by number.
List<ImportedContact> newContacts(
  Iterable<ImportedContact> found,
  Iterable<Customer> existing,
) {
  final known = {for (final c in existing) normalizePhone(c.phone)};
  return [
    for (final c in found)
      if (!known.contains(c.phone)) c,
  ];
}

/// A contact file picked on the phone: a .vcf (every phone's contacts app
/// exports one), or a .csv — a Google Contacts export, or any sheet saved as
/// CSV with a name column and a phone column.
///
/// A CSV with a header row is read by its columns, so a Google export's
/// labels, e-mails and groups do not end up in the name. A CSV without one
/// is read like a pasted list: each line's mobile number, the words beside
/// it the name.
List<ImportedContact> parseContactFile(String text) {
  final clean = text.startsWith('﻿') ? text.substring(1) : text;
  if (clean.toUpperCase().contains('BEGIN:VCARD')) return parseContacts(clean);

  final rows = _csvRows(clean);
  if (rows.isEmpty) return const [];
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  bool isPhone(String h) =>
      (h.contains('phone') ||
          h.contains('mobile') ||
          h.contains('number') ||
          h.contains('tel')) &&
      !h.contains('type') &&
      !h.contains('label');
  final phoneCols = [
    for (var i = 0; i < header.length; i++)
      if (isPhone(header[i])) i,
  ];
  final nameCol = header.indexWhere(
    (h) => h == 'name' || h == 'full name' || h == 'display name',
  );
  final firstCol = header.indexWhere(
    (h) => h == 'first name' || h == 'given name',
  );
  final middleCol = header.indexWhere(
    (h) => h == 'middle name' || h == 'additional name',
  );
  final lastCol = header.indexWhere(
    (h) => h == 'last name' || h == 'family name',
  );
  final hasHeader =
      phoneCols.isNotEmpty && (nameCol >= 0 || firstCol >= 0 || lastCol >= 0);
  if (!hasHeader) {
    return parseContacts([for (final r in rows) r.join(' , ')].join('\n'));
  }

  String cell(List<String> row, int i) =>
      i >= 0 && i < row.length ? row[i].trim() : '';
  final found = <ImportedContact>[];
  final seen = <String>{};
  for (final row in rows.skip(1)) {
    var name = cell(row, nameCol);
    if (name.isEmpty) {
      name = [
        cell(row, firstCol),
        cell(row, middleCol),
        cell(row, lastCol),
      ].where((p) => p.isNotEmpty).join(' ');
    }
    // A Google export keeps several numbers in one cell: "a ::: b".
    for (final col in phoneCols) {
      String? phone;
      for (final part in cell(row, col).split(':::')) {
        final n = normalizePhone(part);
        if (isDiallablePhone(n)) {
          phone = n;
          break;
        }
      }
      if (phone == null) continue;
      if (seen.add(phone)) {
        found.add(ImportedContact(name: _tidyName(name), phone: phone));
      }
      break; // One number per person: their first mobile.
    }
  }
  return found;
}

/// The phone's own contacts, as (name, numbers) pairs: each person once, on
/// their first mobile number; a number shared by two entries only once.
List<ImportedContact> contactsFromPhoneBook(
  Iterable<(String name, List<String> numbers)> book,
) {
  final found = <ImportedContact>[];
  final seen = <String>{};
  for (final (name, numbers) in book) {
    for (final raw in numbers) {
      final n = normalizePhone(raw);
      if (!isDiallablePhone(n)) continue;
      if (seen.add(n)) {
        found.add(ImportedContact(name: _tidyName(name), phone: n));
      }
      break;
    }
  }
  return found;
}

String _tidyName(String name) {
  var t = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length > 60) t = t.substring(0, 60).trim();
  return t;
}

/// CSV rows: commas (or semicolons, as Excel saves in some regions),
/// "quoted, fields" and "" for a quote inside one.
List<List<String>> _csvRows(String text) {
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  final sep =
      ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
      ? ';'
      : ',';
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == sep) {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  row.add(field.toString());
  if (row.any((f) => f.trim().isNotEmpty)) rows.add(row);
  return rows;
}
