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
