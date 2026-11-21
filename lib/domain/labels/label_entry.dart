/// ONE ENTRY IN THE LABEL REGISTRY
///
/// A label entry carries a **copy of the record it was printed for**. That is
/// the whole design, and it buys two things:
///
/// 1. **A scan resolves in one read.** The scanner reads the registry and has
///    a title, a price and a status immediately — it does not have to work out
///    which collection to look in and then fetch it. On the shop's connection
///    that was the difference between instant and a spinner at the counter.
///
/// 2. **A deleted record still scans.** The label is stuck to a phone. If the
///    record behind it is gone, the entry still says what was printed, which
///    is more use at the counter than "not found".
///
/// But a copy goes stale, and a stale price on a scan is worse than no price:
/// someone reads it out to a customer. So on display **the live record is laid
/// over the copy** — live values win where there is a live record, the copy
/// fills in the rest, and anything that has changed since printing is flagged
/// so the counter knows the sticker is out of date.
library;

import '../common/dates.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import 'label_target.dart';

class LabelEntry {
  const LabelEntry({
    required this.number,
    required this.kind,
    required this.recordId,
    this.snapshot = const {},
    this.printedAt,
    this.printedBy,
    this.reprints = 0,
  });

  final int number;

  /// Null when the stored kind is one this build does not recognise. The entry
  /// is still listed — the number is real and stuck to something.
  final LabelTargetKind? kind;

  final String recordId;

  /// The copy, taken at print time. Deliberately a plain map: the registry
  /// holds labels for four different kinds of record and has no business
  /// knowing any of their shapes.
  final Map<String, Object?> snapshot;

  final DateTime? printedAt;
  final String? printedBy;

  /// How many times it has been printed again. A reprint keeps the number —
  /// a new number for the same record is a second sticker that resolves
  /// somewhere the first one did not.
  final int reprints;

  /// Where a scan of this label lands, or null when the kind is unreadable.
  String? get route => kind == null ? null : routeForTarget(kind!, recordId);

  static LabelEntry fromMap(Map<String, Object?> map) => LabelEntry(
    number: _int(map['number']) ?? 0,
    kind: targetKindFrom(map['kind']),
    recordId: (map['recordId'] ?? '').toString(),
    snapshot: map['snapshot'] is Map
        ? Map<String, Object?>.from(map['snapshot'] as Map)
        : const {},
    printedAt: normalizeDate(map['printedAt']),
    printedBy: map['printedBy'] as String?,
    reprints: _int(map['reprints']) ?? 0,
  );

  Map<String, Object?> toMap() => {
    'number': number,
    'kind': kind?.name,
    'recordId': recordId,
    'snapshot': snapshot,
    'printedAt': printedAt?.toIso8601String(),
    'printedBy': printedBy,
    'reprints': reprints,
  };

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// The fields a label shows, whatever kind of record it was printed for.
///
/// Four kinds of record have four different shapes, and the scan result has to
/// read the same for all of them. Each repository builds this map when it
/// hands over a snapshot, so the registry never learns what a `SecondHandDevice`
/// is.
const String kLabelTitle = 'title';
const String kLabelSubtitle = 'subtitle';
const String kLabelPrice = 'price';
const String kLabelStatus = 'status';

/// What to show for a scanned label.
class LabelView {
  const LabelView({
    required this.entry,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.staleFields,
    required this.recordExists,
  });

  final LabelEntry entry;

  final String title;
  final String subtitle;

  /// Null when neither the live record nor the copy carries one.
  final num? price;

  final String status;

  /// Field names whose live value differs from what was printed. The counter
  /// needs this: the sticker on the phone says one thing and the screen says
  /// another, and which one is right is not a guess.
  final List<String> staleFields;

  /// Whether the record behind the label is still there. A label for a deleted
  /// record still resolves off the copy, and says so.
  final bool recordExists;

  bool get isStale => staleFields.isNotEmpty;

  /// Whether a scan can open the record. Needs both a readable kind and a
  /// record to open.
  bool get canOpen => recordExists && entry.route != null;

  String? get route => entry.route;
}

/// Lay the live record over the copy.
///
/// [live] is the record as it is now, in the same shape the snapshot was
/// written in, or null when the record is gone. Live wins field by field; the
/// copy fills in anything live does not carry, so a repository that has
/// stopped writing one of these fields does not blank it on old labels.
LabelView resolveLabel(LabelEntry entry, Map<String, Object?>? live) {
  String pick(String field) {
    final liveValue = live?[field];
    if (liveValue != null && liveValue.toString().trim().isNotEmpty) {
      return liveValue.toString().trim();
    }
    final copied = entry.snapshot[field];
    return copied == null ? '' : copied.toString().trim();
  }

  num? pickPrice() {
    final liveValue = live?[kLabelPrice];
    if (liveValue != null) return asAmount(liveValue);
    final copied = entry.snapshot[kLabelPrice];
    return copied == null ? null : asAmount(copied);
  }

  final stale = <String>[];
  if (live != null) {
    for (final field in [
      kLabelTitle,
      kLabelSubtitle,
      kLabelPrice,
      kLabelStatus,
    ]) {
      final liveValue = live[field];
      final copied = entry.snapshot[field];
      if (liveValue == null || copied == null) continue;
      // Compared as numbers where both are numbers, so 18500 and '18500' on a
      // label written by an older build do not read as a change.
      final changed = field == kLabelPrice
          ? asAmount(liveValue) != asAmount(copied)
          : liveValue.toString().trim() != copied.toString().trim();
      if (changed) stale.add(field);
    }
  }

  return LabelView(
    entry: entry,
    title: pick(kLabelTitle),
    subtitle: pick(kLabelSubtitle),
    price: pickPrice(),
    status: pick(kLabelStatus),
    staleFields: stale,
    recordExists: live != null,
  );
}
