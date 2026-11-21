/// THE LABEL REGISTRY
///
/// **The only thing in the app that mints a label number.**
///
/// That is the point of this file. Before, the second-hand store had its own
/// counter and so would every other area that prints labels — four counters,
/// one number space, and label 26042 on two different phones. A label is
/// physical: a duplicate is not a display bug, it is two handsets the shop
/// cannot tell apart, and a scanner that opens the wrong one.
///
/// So minting and attaching are **one operation**. [assign] takes the number
/// off the counter, writes the registry entry with its snapshot, and puts the
/// number on the record — and the record's own repository is given no way to
/// invent a number of its own. Each area tells this one how to snapshot and
/// how to attach, through a [LabelTargetBinding], which is also why this file
/// imports none of them.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/counters.dart';
import '../domain/labels/label_entry.dart';
import '../domain/labels/label_target.dart';

/// How one area plugs into the registry.
///
/// Two functions rather than a repository interface, because the registry does
/// not want to know what a `SecondHandDevice` is — and because an area that
/// cannot yet be labelled simply has no binding, instead of four methods
/// throwing `UnimplementedError`.
class LabelTargetBinding {
  const LabelTargetBinding({required this.snapshot, required this.attach});

  /// The label fields for this record — `kLabelTitle`, `kLabelSubtitle`,
  /// `kLabelPrice`, `kLabelStatus` — or null when the record is gone.
  ///
  /// Called twice: once at print time for the copy stored on the entry, and
  /// again on every scan for the live values laid over it.
  final Map<String, Object?>? Function(String recordId) snapshot;

  /// Put the number on the record. Called inside [InMemoryLabelStore.assign],
  /// after the number is minted and before the entry is written.
  final Future<void> Function(String recordId, int number) attach;
}

abstract class LabelRepository extends ChangeNotifier {
  List<LabelEntry> get entries;
  bool get loading;
  String? get error;

  Future<void> load();

  /// The entry for a scanned number, or null.
  LabelEntry? byNumber(int number);

  /// The label already on this record, or null.
  LabelEntry? forRecord(LabelTargetKind kind, String recordId);

  /// What the next label printed will be, without consuming it.
  ///
  /// For the registry page, which shows it. Reading it must not take it: a
  /// page that burns a number every time somebody opens it leaves gaps nobody
  /// can account for.
  int get nextNumber;

  /// Mint a number, write the entry, put the number on the record.
  ///
  /// One operation. A record that already has a label keeps it — assigning
  /// again would leave two stickers resolving to different places.
  Future<LabelAssignment> assign(LabelTargetKind kind, String recordId);

  /// Print an existing label again, keeping its number.
  ///
  /// A sticker peels off, or goes on in the wrong place. The number must not
  /// change: the first sticker may still be on something.
  Future<LabelEntry> markReprinted(int number);

  /// The live record for an entry, for laying over the printed copy. Null when
  /// the record is gone or its kind is unreadable.
  Map<String, Object?>? liveRecordFor(LabelEntry entry);

  /// A scanned label, resolved. Convenience over [byNumber] and
  /// [liveRecordFor], so a caller cannot forget the overlay.
  LabelView? resolve(int number);
}

/// What came of an [LabelRepository.assign].
class LabelAssignment {
  const LabelAssignment.assigned(this.entry)
    : alreadyLabelled = false,
      error = null;

  const LabelAssignment.alreadyLabelled(this.entry)
    : alreadyLabelled = true,
      error = null;

  const LabelAssignment.failed(this.error)
    : entry = null,
      alreadyLabelled = false;

  final LabelEntry? entry;

  /// The record already had a label, and kept it.
  final bool alreadyLabelled;

  /// Why no label could be assigned — no binding for this kind, or the record
  /// is gone. Said rather than thrown: the detail page reports it.
  final String? error;

  bool get ok => entry != null;
}

class NoSuchLabel implements Exception {
  const NoSuchLabel(this.number);
  final int number;
  @override
  String toString() => 'No label $number in the registry';
}

class InMemoryLabelStore extends ChangeNotifier implements LabelRepository {
  InMemoryLabelStore({
    required this.targets,
    List<LabelEntry>? seed,
    NumberCounter? counter,
  }) : _counter = counter ?? InMemoryCounter() {
    _entries = [...(seed ?? const [])];
    // A registry seeded with labels already printed has to leave the counter
    // above them, or the next assign hands out a number that is already stuck
    // to a phone.
    final highest = _entries.fold<int>(
      kFirstLabelNumber - 1,
      (max, e) => e.number > max ? e.number : max,
    );
    _next = highest + 1 < kFirstLabelNumber ? kFirstLabelNumber : highest + 1;
  }

  final Map<LabelTargetKind, LabelTargetBinding> targets;
  final NumberCounter _counter;

  late List<LabelEntry> _entries;
  late int _next;
  bool _loading = false;
  String? _error;

  @override
  List<LabelEntry> get entries => List.unmodifiable(_entries);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  int get nextNumber => _next;

  @override
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }

  @override
  LabelEntry? byNumber(int number) =>
      _entries.where((e) => e.number == number).firstOrNull;

  @override
  LabelEntry? forRecord(LabelTargetKind kind, String recordId) => _entries
      .where((e) => e.kind == kind && e.recordId == recordId)
      .firstOrNull;

  @override
  Future<LabelAssignment> assign(LabelTargetKind kind, String recordId) async {
    final existing = forRecord(kind, recordId);
    // Two stickers for one record resolve to the same place today and to
    // different places the moment one of them is reprinted.
    if (existing != null) return LabelAssignment.alreadyLabelled(existing);

    final binding = targets[kind];
    if (binding == null) {
      return LabelAssignment.failed(
        '${kLabelTargetLabels[kind]} records cannot carry a label yet',
      );
    }

    final snapshot = binding.snapshot(recordId);
    if (snapshot == null) {
      return const LabelAssignment.failed(
        'That record is gone — nothing to print a label for',
      );
    }

    // Off the counter, in one step with the write. In Firestore this whole
    // method is the body of a transaction.
    //
    // The floor is `_next`, not `kFirstLabelNumber`: a registry seeded with
    // labels already printed has a floor above 26001, and a counter that does
    // not know about them would hand out a number already stuck to a phone.
    // `nextCounterValue` never goes below the floor it is given.
    final number = await _counter.next('labels', start: _next);
    _next = number + 1;

    await binding.attach(recordId, number);

    final entry = LabelEntry(
      number: number,
      kind: kind,
      recordId: recordId,
      // The copy. See label_entry.dart for why it is here at all.
      snapshot: Map<String, Object?>.unmodifiable(snapshot),
      printedAt: DateTime.now(),
    );
    _entries.add(entry);
    notifyListeners();
    return LabelAssignment.assigned(entry);
  }

  @override
  Future<LabelEntry> markReprinted(int number) async {
    final index = _entries.indexWhere((e) => e.number == number);
    if (index < 0) throw NoSuchLabel(number);
    final entry = _entries[index];
    final updated = LabelEntry(
      // The number is kept. That is the whole rule.
      number: entry.number,
      kind: entry.kind,
      recordId: entry.recordId,
      // The copy is NOT refreshed. It is a record of what was printed, and a
      // reprint of an old sticker is still that sticker — the overlay is what
      // shows the current price.
      snapshot: entry.snapshot,
      printedAt: entry.printedAt,
      printedBy: entry.printedBy,
      reprints: entry.reprints + 1,
    );
    _entries[index] = updated;
    notifyListeners();
    return updated;
  }

  @override
  Map<String, Object?>? liveRecordFor(LabelEntry entry) {
    final kind = entry.kind;
    if (kind == null) return null;
    return targets[kind]?.snapshot(entry.recordId);
  }

  @override
  LabelView? resolve(int number) {
    final entry = byNumber(number);
    if (entry == null) return null;
    return resolveLabel(entry, liveRecordFor(entry));
  }
}
