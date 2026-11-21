/// ONE OF THE SHOP'S OWN LISTS
///
/// Brands, suppliers, colours, categories, complaint types. Each is a list
/// that **grows by itself**: a value typed into a form that is not on the list
/// joins it, so the next person finds it in the dropdown instead of typing it
/// again slightly differently.
///
/// Which makes the dedupe rule the whole of this file.
///
/// **Case and surrounding space do not make a new value.** `samsung`,
/// `Samsung` and ` Samsung ` are one brand. Without that, a list that learns
/// by itself fills up with the same word five ways within a month, and the
/// dropdown becomes useless for exactly the job it exists for.
///
/// **The first spelling to arrive keeps the list's casing.** Not the newest,
/// and not a normalised form of its own: records already written carry the
/// first spelling, and rewriting the list entry would make the dropdown
/// disagree with the records. It is the same rule as the pre-delivery
/// checklist keys — first to claim it keeps it.
///
/// **Order is the order values arrived**, because that is what an append gives
/// you and because a shop that has put its categories in a sensible order
/// should see that order. Sorting is a display choice, offered separately.
library;

class OptionSet {
  OptionSet(Iterable<String> values) : _values = [] {
    for (final value in values) {
      add(value);
    }
  }

  OptionSet.empty() : _values = [];

  final List<String> _values;

  /// In the order they arrived.
  List<String> get values => List.unmodifiable(_values);

  /// For a dropdown that would rather be alphabetical. Case-insensitive, so
  /// `iPhone` does not sort away from `Infinix`.
  List<String> get sorted => [..._values]..sort(compareOptions);

  int get length => _values.length;
  bool get isEmpty => _values.isEmpty;
  bool get isNotEmpty => _values.isNotEmpty;

  /// Whether this value is already on the list, ignoring case and space.
  bool contains(String? value) => indexOf(value) >= 0;

  int indexOf(String? value) {
    final key = normalizeOption(value);
    if (key.isEmpty) return -1;
    for (var i = 0; i < _values.length; i++) {
      if (normalizeOption(_values[i]) == key) return i;
    }
    return -1;
  }

  /// The value as the list spells it, or null when it is not on the list.
  ///
  /// This is how a form writes the list's spelling onto a record rather than
  /// whatever was typed, so the two cannot drift.
  String? canonical(String? value) {
    final i = indexOf(value);
    return i < 0 ? null : _values[i];
  }

  /// Add a value if it is new. Returns true when the list actually grew.
  ///
  /// Blank values are never added: an empty entry in a dropdown is a trap, and
  /// a form left untouched must not file anything.
  bool add(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return false;
    if (contains(trimmed)) return false;
    _values.add(trimmed);
    return true;
  }

  /// Remove a value, ignoring case. Returns true when it was there.
  ///
  /// Removing from the list does NOT touch the records that already use it —
  /// a brand taken off the list is still the brand on two hundred handsets,
  /// and rewriting those is not a settings change.
  bool remove(String? value) {
    final i = indexOf(value);
    if (i < 0) return false;
    _values.removeAt(i);
    return true;
  }

  /// Move a value to a new position, for a list whose order people work
  /// through — the pre-delivery checklist, most of all.
  bool moveTo(String? value, int index) {
    final from = indexOf(value);
    if (from < 0) return false;
    final to = index < 0
        ? 0
        : index >= _values.length
        ? _values.length - 1
        : index;
    if (from == to) return false;
    final moved = _values.removeAt(from);
    _values.insert(to, moved);
    return true;
  }

  OptionSet copy() => OptionSet(_values);

  /// Everything in [candidates] that is not already on this list, deduped
  /// against itself as well.
  ///
  /// This is the "what is new" half of the rule, and it is deliberately
  /// separate from writing anything — see `option_learning.dart`.
  List<String> additionsFrom(Iterable<String?> candidates) {
    final seen = <String>{for (final v in _values) normalizeOption(v)};
    final additions = <String>[];
    for (final candidate in candidates) {
      final trimmed = (candidate ?? '').trim();
      if (trimmed.isEmpty) continue;
      final key = normalizeOption(trimmed);
      if (seen.contains(key)) continue;
      seen.add(key);
      additions.add(trimmed);
    }
    return additions;
  }

  /// What to offer under a field while someone is typing into it.
  ///
  /// Names that **start with** what was typed come first, then names that
  /// merely contain it — "a5" finds "Galaxy A54" too, because staff type the
  /// part of the model they can read off the back. Case and spacing do not
  /// matter, the same as everywhere else in this list.
  ///
  /// Once the field already holds a value from the list there is nothing left
  /// to offer, so it returns nothing: the chips get out of the way instead of
  /// sitting under a finished field.
  ///
  /// **In the shop's own order** unless [sortByName] is asked for. The list
  /// is kept most-used first (and the settings page can reorder it), so with
  /// only a few chips on screen, A–Z would hide Samsung behind Apple, Infinix
  /// and iQOO. Storage sizes are the exception — those read best in order.
  List<String> suggestionsFor(
    String? typed, {
    int limit = 12,
    bool sortByName = false,
  }) {
    final key = normalizeOption(typed);
    final all = sortByName ? sorted : values;
    if (key.isEmpty) return all.take(limit).toList();
    if (contains(key)) return const [];
    final starts = <String>[];
    final inside = <String>[];
    for (final value in all) {
      final k = normalizeOption(value);
      if (k.startsWith(key)) {
        starts.add(value);
      } else if (k.contains(key)) {
        inside.add(value);
      }
    }
    return [...starts, ...inside].take(limit).toList();
  }

  /// True when [typed] is something the shop has never had in this list —
  /// what the form flags as "new, will be added when you save".
  bool isNew(String? typed) =>
      normalizeOption(typed).isNotEmpty && !contains(typed);

  @override
  String toString() => 'OptionSet($_values)';
}

/// The comparison key for a value: trimmed, lower-cased, and with runs of
/// whitespace collapsed.
///
/// `Screen  Guard` and `screen guard` are one category. A person typing into a
/// phone keyboard produces both.
String normalizeOption(String? value) =>
    (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Alphabetical, but numbers inside a name compare as numbers: "2/32" before
/// "12/256", "iPhone 8" before "iPhone 11". Plain text order puts them the
/// wrong way round, and a list of storage sizes in that order looks broken.
int compareOptions(String a, String b) {
  final digits = RegExp(r'\d+|\D+');
  final pa = digits.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final pb = digits.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]);
    final nb = int.tryParse(pb[i]);
    final c = (na != null && nb != null)
        ? na.compareTo(nb)
        : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}
