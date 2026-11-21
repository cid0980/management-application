/// THE PRE-DELIVERY CHECKLIST
///
/// The labels come from settings, where anyone can type anything; the ticks
/// are stored on the order as a map, which needs keys. Turning a label into a
/// key throws away case and punctuation, and that is how two labels a person
/// reads as different — "Display OK" and "Display: OK!" — ended up sharing one
/// checkbox. Ticking the second visibly un-ticked the first, and the order
/// could be saved claiming a check nobody had carried out. On a list whose
/// whole job is making sure a device is tested before it goes back, that is
/// the worst thing it could quietly do.
///
/// Keys are made once for the whole list here, so a collision is resolved
/// rather than discovered. The first label to claim a key keeps it, which
/// leaves ticks already stored against that key still readable.
library;

/// A storable key for one label. Never empty: a blank key collides with itself.
String checklistKey(Object? label) {
  final slug = (label ?? '')
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return slug.isEmpty ? 'item' : slug;
}

typedef ChecklistEntry = ({String item, String key});

/// The labels paired with keys that are unique across the list.
/// Order is preserved, and so is every label exactly as it was written.
List<ChecklistEntry> checklistEntries(List<String> items) {
  final taken = <String>{};
  return items.map((item) {
    final base = checklistKey(item);
    var key = base;
    var n = 2;
    while (taken.contains(key)) {
      key = '${base}_${n++}';
    }
    taken.add(key);
    return (item: item, key: key);
  }).toList();
}

Map<String, bool> blankChecklist(List<String> items) => {
  for (final e in checklistEntries(items)) e.key: false,
};

/// The same list, keeping whatever was already ticked.
Map<String, bool> carryOver(List<String> items, Map<String, bool>? previous) =>
    {for (final e in checklistEntries(items)) e.key: previous?[e.key] == true};

/// Whether every item on the list is ticked.
///
/// Asked about the list, not about the stored map. Reading the map's own
/// values meant a leftover tick from a since-removed item could carry the
/// vote, and a key that was never written at all counted as agreement.
///
/// A shop with no checklist configured has nothing to verify, so an empty list
/// passes. Failing it instead would stop every order in the shop being
/// completed until somebody went and built a checklist, which is a rule nobody
/// asked for.
bool allChecked(List<String> items, Map<String, bool>? state) =>
    checklistEntries(items).every((e) => state?[e.key] == true);
