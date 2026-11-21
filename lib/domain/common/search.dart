/// SEARCHING A LIST THAT IS ALREADY IN MEMORY
///
/// Every list in the app is loaded and then filtered in the hand, not
/// re-queried: Firestore cannot do a substring match, and the lists are small
/// enough that the shop would rather have an instant answer than a correct
/// index. One matcher, so searching stock behaves the way searching customers
/// does.
///
/// A query is split on whitespace and EVERY word has to land somewhere in the
/// row. Typing `samsung 128` should find the 128 GB Samsung, not every Samsung
/// and everything with a 128 in it.
library;

import 'phone.dart';

String _fold(String s) => s.toLowerCase().trim();

/// Whether [fields] — any of the row's searchable text — matches [query].
///
/// An empty query matches everything: a list with nothing typed into the box
/// is the whole list, not an empty one.
bool matchesQuery(String? query, Iterable<String?> fields) {
  final raw = query ?? '';
  final words = _fold(raw).split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return true;

  final haystack = fields
      .whereType<String>()
      .map(_fold)
      .where((f) => f.isNotEmpty)
      .join(' ');
  if (haystack.isEmpty) return false;

  // A number typed into the box is matched against the digits of the row too,
  // so `9876543210` finds a seller stored as `+91 98765 43210`.
  final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length >= 4) {
    final rowDigits = fields
        .whereType<String>()
        .map((f) => f.replaceAll(RegExp(r'\D'), ''))
        .where((f) => f.isNotEmpty)
        .join(' ');
    if (rowDigits.contains(digitsOnly)) return true;
    if (fields.any((f) => samePhone(f, digitsOnly))) return true;
  }

  return words.every(haystack.contains);
}
