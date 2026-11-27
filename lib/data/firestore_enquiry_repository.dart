/// ENQUIRIES, OUT OF FIRESTORE
///
/// The same `EnquiryRepository` the screens already talk to, backed by
/// `shops/{shopId}/enquiries`.
///
/// **A Won enquiry needs something to point at.** `setStatus` asks
/// `wonBlockFor` before it writes, and a refusal writes nothing — "we sold
/// them one" with no sale against it is a conversion figure nobody can check,
/// and that is what the shop's old sheet was full of. The check runs inside
/// the transaction, against the reference the record currently carries, so a
/// reference cleared on the other till cannot be talked past.
///
/// **`closedAt` is stamped once.** An enquiry closed twice shows the first
/// time it was dealt with, and an enquiry reopened loses the stamp — which is
/// why it is written as a delete rather than as a null.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/phone.dart';
import '../domain/enquiries/enquiry.dart';
import '../domain/enquiries/enquiry_state.dart';
import 'enquiry_repository.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'live_window.dart';

class FirestoreEnquiryStore extends ChangeNotifier
    implements EnquiryRepository {
  FirestoreEnquiryStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

  List<Enquiry> _enquiries = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;
  MergedListener? _window;
  DateTime? _since;

  /// Enquiries outside the live list, fetched one at a time by [fetchById].
  final Map<String, Enquiry> _fetched = {};

  @override
  List<Enquiry> get enquiries => List.unmodifiable(_enquiries);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // Open enquiries of any age, and anything touched in the last 90 days:
    // the live window (live_window.dart). Older closed ones come on demand.
    final since = liveWindowStart(DateTime.now());
    _since = DateTime.now().subtract(kLiveWindow);
    _window = MergedListener(
      queries: [
        scope.enquiries.where(
          'status',
          whereNotIn: const ['Won', 'Lost', 'Closed'],
        ),
        scope.enquiries.where('updatedAt', isGreaterThanOrEqualTo: since.iso),
        scope.enquiries.where('updatedAt', isGreaterThanOrEqualTo: since.ts),
      ],
      onData: (docs) {
        _enquiries = [
          for (final doc in docs) Enquiry.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'enquiries');
        notifyListeners();
      },
    )..start();
  }

  @override
  DateTime? get liveSince => _since;

  @override
  Enquiry? byId(String id) {
    for (final enquiry in _enquiries) {
      if (enquiry.id == id) return enquiry;
    }
    return _fetched[id];
  }

  @override
  Future<Enquiry?> fetchById(String id) async {
    final known = byId(id);
    if (known != null) return known;
    final doc = await scope.enquiries.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    final record = Enquiry.fromMap(id, data);
    _fetched[id] = record;
    notifyListeners();
    return record;
  }

  @override
  Future<List<Enquiry>> fetchOlder({String? customerId, String? phone}) async {
    final number = normalizePhone(phone);
    final queries = [
      if (customerId != null && customerId.isNotEmpty)
        scope.enquiries.where('customerId', isEqualTo: customerId),
      if (number.isNotEmpty)
        scope.enquiries.where('customerPhone', isEqualTo: number),
    ];
    final results = [for (final q in queries) (await q.get()).docs];
    return [
      for (final doc in merged(results)) Enquiry.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<Enquiry> save(Enquiry enquiry) async {
    final ref = scope.enquiries.doc(enquiry.id);
    final snapshot = await ref.get();
    final existing = snapshot.exists
        ? Enquiry.fromMap(enquiry.id, snapshot.data()!)
        : null;

    final now = DateTime.now();
    final stored = enquiry.copyWith(
      customerPhone: normalizePhone(enquiry.customerPhone),
      askedAt: enquiry.askedAt ?? existing?.askedAt ?? now,
      closedAt: enquiry.closed ? (existing?.closedAt ?? now) : null,
      updatedAt: now,
    );

    final map = stored.toMap();
    // An enquiry that is open again has no closing date. Deleted rather than
    // written as null, so `fromMap` sees no key at all — and so a merge does
    // not leave the old stamp sitting under it.
    if (!stored.closed) map['closedAt'] = FieldValue.delete();

    if (existing == null) {
      map.remove('closedAt');
      await localWrite(ref.set(map));
    } else {
      await localWrite(ref.set(map, SetOptions(merge: true)));
    }
    return stored;
  }

  @override
  Future<EnquiryStatusResult> setStatus(
    String id,
    String status, {
    String? outcomeRef,
  }) async {
    final ref = scope.enquiries.doc(id);
    return scope.firestore.runTransaction<EnquiryStatusResult>((
      transaction,
    ) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchEnquiry(id);

      final enquiry = Enquiry.fromMap(id, snapshot.data()!);
      // What it became belongs to Won only (FM #23).
      final reference = isEnquiryWon(status)
          ? (outcomeRef ?? enquiry.outcomeRef).trim()
          : '';
      if (isEnquiryWon(status)) {
        final block = wonBlockFor(reference);
        // Refused, and nothing is written. See the class note.
        if (block != null) return EnquiryStatusResult.refused(block);
      }

      final now = DateTime.now();
      final closing = isEnquiryClosed(status);
      final closedAt = closing ? (enquiry.closedAt ?? now) : null;

      transaction.update(ref, {
        'status': status,
        'outcomeRef': reference,
        'closedAt': closedAt == null
            ? FieldValue.delete()
            : closedAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      return EnquiryStatusResult.changed(
        enquiry.copyWith(
          status: status,
          outcomeRef: reference,
          closedAt: closedAt,
          updatedAt: now,
        ),
      );
    });
  }

  @override
  Future<Enquiry> setFollowUp(String id, DateTime? followUpAt) async {
    final ref = scope.enquiries.doc(id);
    final snapshot = await ref.get();
    if (!snapshot.exists) throw NoSuchEnquiry(id);

    final now = DateTime.now();
    await localWrite(
      ref.update({
        // Clearing a follow-up is a real thing to want, and a null here would
        // read back as a date nobody set. Deleted instead.
        'followUpAt': followUpAt == null
            ? FieldValue.delete()
            : followUpAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }),
    );

    final data = {...snapshot.data()!};
    if (followUpAt == null) {
      data.remove('followUpAt');
    } else {
      data['followUpAt'] = followUpAt.toIso8601String();
    }
    data['updatedAt'] = now.toIso8601String();
    return Enquiry.fromMap(id, data);
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }
}
