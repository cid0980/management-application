/// THE LABEL REGISTRY, OUT OF FIRESTORE
///
/// The same `LabelRepository` the screens already talk to, backed by
/// `shops/{shopId}/label_registry`, **keyed by the label number itself**. The
/// document id is the number, so a duplicate is not a race this code has to
/// win — Firestore cannot hold two documents at one id.
///
/// **One registry mints every label.** Second-hand stock, service orders,
/// sales and products all come here. Each area used to keep a counter of its
/// own: four counters over one number space, and label 26042 ended up on two
/// different phones.
///
/// **Minting and attaching are one step.** [assign] takes the number off the
/// counter, writes it onto the record, and files the registry entry. A number
/// handed out and not attached is a sticker nobody can trace; a record
/// carrying a number with no entry is a scan that resolves to nothing.
///
/// **Numbers start at 26001, and never go backwards.** Below that are labels
/// the shop printed by hand years ago, and a scan of one of those must not
/// open a new record. The counter's floor is also lifted past anything already
/// in the registry, so a shop whose registry was imported does not reissue a
/// number that is already stuck to a phone.
///
/// **A reprint keeps its number and its copy.** The snapshot is a record of
/// what was printed; the live record is laid over it on a scan, which is where
/// today's price comes from. Refreshing the copy on a reprint would quietly
/// rewrite history on every sticker.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/counters.dart';
import '../domain/labels/label_entry.dart';
import '../domain/labels/label_target.dart';
import 'firestore_counter.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'label_repository.dart';

class FirestoreLabelStore extends ChangeNotifier implements LabelRepository {
  FirestoreLabelStore({
    required this.scope,
    required this.targets,
    NumberCounter? counter,
  }) : _counter = counter ?? FirestoreCounter(scope: scope);

  /// This shop, and only this shop. A label number is unique within a shop
  /// and nowhere else: two shops both starting at 26001 is correct.
  final ShopScope scope;

  final Map<LabelTargetKind, LabelTargetBinding> targets;
  final NumberCounter _counter;

  List<LabelEntry> _entries = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  List<LabelEntry> get entries => List.unmodifiable(_entries);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  /// A hint for the labels page, not a promise: by the time a sticker is
  /// printed somebody else may have taken that number. Only [assign] decides.
  @override
  int get nextNumber => _floor();

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    _subscription = scope.labelRegistry.snapshots().listen(
      (snapshot) {
        _entries = [
          for (final doc in snapshot.docs)
            // The number comes off the document itself. The id is the same
            // number, which is what makes a duplicate impossible, and a
            // document whose field somehow disagrees is read by its field so
            // the entry still says what was printed.
            LabelEntry.fromMap(doc.data()),
        ]..sort((a, b) => a.number.compareTo(b.number));
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'label registry');
        notifyListeners();
      },
    );
  }

  @override
  LabelEntry? byNumber(int number) {
    for (final entry in _entries) {
      if (entry.number == number) return entry;
    }
    return null;
  }

  @override
  LabelEntry? forRecord(LabelTargetKind kind, String recordId) {
    for (final entry in _entries) {
      if (entry.kind == kind && entry.recordId == recordId) return entry;
    }
    return null;
  }

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

    // Off the counter, never from counting documents. The floor is lifted
    // past anything already in the registry — see the class note.
    final number = await _counter.next('labels', start: _floor());

    final entry = LabelEntry(
      number: number,
      kind: kind,
      recordId: recordId,
      // The copy. See label_entry.dart for why it is here at all.
      snapshot: Map<String, Object?>.unmodifiable(snapshot),
      printedAt: DateTime.now(),
    );

    // Onto the record first, then into the registry — the same order as the
    // in-memory store. Either failing throws rather than reporting a label
    // that was not filed, because a sticker about to come out of a printer
    // with a number nothing knows about is the one outcome worth stopping
    // for.
    await binding.attach(recordId, number);
    await scope.labelRegistry.doc('$number').set(entry.toMap());
    return LabelAssignment.assigned(entry);
  }

  @override
  Future<LabelEntry> markReprinted(int number) async {
    final ref = scope.labelRegistry.doc('$number');
    return scope.firestore.runTransaction<LabelEntry>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchLabel(number);

      final entry = LabelEntry.fromMap(snapshot.data()!);
      // Incremented in the document rather than written from what this device
      // read, so two reprints from two tills both count. The number and the
      // copy are not touched at all: that is the whole rule.
      transaction.update(ref, {'reprints': FieldValue.increment(1)});

      return LabelEntry(
        number: entry.number,
        kind: entry.kind,
        recordId: entry.recordId,
        snapshot: entry.snapshot,
        printedAt: entry.printedAt,
        printedBy: entry.printedBy,
        reprints: entry.reprints + 1,
      );
    });
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

  /// The lowest number [assign] may hand out next.
  ///
  /// Above every number already in the registry, and never below
  /// [kFirstLabelNumber]. A registry imported from the shop's old book has a
  /// floor well above 26001, and a counter that did not know about it would
  /// hand out a number already stuck to a phone.
  int _floor() {
    var highest = kFirstLabelNumber - 1;
    for (final entry in _entries) {
      if (entry.number > highest) highest = entry.number;
    }
    final next = highest + 1;
    return next < kFirstLabelNumber ? kFirstLabelNumber : next;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
