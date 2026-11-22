import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// THE LIVE WINDOW
///
/// Repairs and bills grow with every day the shop is open. Listening to the
/// whole collection made every morning's start re-read years of records
/// (docs/SCALING.md). So a store listens to a few queries instead — what is
/// still open, and what changed recently — and this merges them into one list
/// by document id. Older records are fetched on demand by the store.
///
/// The first list is delivered once every query has answered, so a screen
/// does not flash a half-loaded list.
class MergedListener {
  MergedListener({
    required this.queries,
    required this.onData,
    required this.onError,
  });

  final List<Query<Map<String, dynamic>>> queries;
  final void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)
  onData;
  final void Function(Object error) onError;

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs =
      [];
  late final List<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> _latest =
      List.filled(queries.length, null);

  void start() {
    for (var i = 0; i < queries.length; i++) {
      _subs.add(
        queries[i].snapshots().listen((snapshot) {
          _latest[i] = snapshot.docs;
          if (_latest.every((l) => l != null)) onData(merged(_latest));
        }, onError: onError),
      );
    }
  }

  Future<void> cancel() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}

/// The union of several query results, one entry per document id — the
/// later list's copy wins, which is the same document either way.
List<T> mergedById<T>(Iterable<Iterable<T>?> lists, String Function(T) idOf) {
  final byId = <String, T>{};
  for (final list in lists) {
    for (final item in list ?? <T>[]) {
      byId[idOf(item)] = item;
    }
  }
  return byId.values.toList();
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> merged(
  Iterable<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>?> lists,
) => mergedById(lists, (d) => d.id);

/// How far back the live window reaches.
const Duration kLiveWindow = Duration(days: 90);

/// The window's start, as both shapes a date is stored in: this build
/// writes ISO strings; older builds wrote Firestore timestamps. A range
/// query only matches values of its own type, so each gets a query.
({String iso, Timestamp ts}) liveWindowStart(DateTime now) {
  final since = now.subtract(kLiveWindow);
  return (iso: since.toIso8601String(), ts: Timestamp.fromDate(since));
}
