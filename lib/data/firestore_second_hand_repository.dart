/// SECOND-HAND STOCK, OUT OF FIRESTORE
///
/// The same `SecondHandRepository` the screens already talk to, backed by the
/// `second_hand_mobiles` collection instead of a list in memory. Nothing in
/// `lib/ui` or `lib/domain` changes to use this — that was the point of the
/// repository boundary.
///
/// Three things shape this file.
///
/// **It caches, because the interface is synchronous.** `devices` and `byId`
/// return values, not futures, because the lists filter in the hand — see
/// `search.dart`. So this holds snapshot listeners open and keeps the last
/// result. That is also what the shop wants: the stock list is opened dozens
/// of times a day and re-reading it each time is a spinner nobody needs.
///
/// **It listens to a window, not the whole collection** (live_window.dart):
/// every phone still in the shop, plus anything touched in the last 90
/// days. Phones sold before that are fetched when asked for — a record
/// page, a seller's history, an IMEI search, a report over an older range.
///
/// **Writes that have a rule go through a transaction.** `markSold` and
/// `returnToStock` read, check and write as one step, because "sold always
/// wins" is a rule about what the record currently says — and two tills
/// selling the same handset is exactly the race it exists for. An ordinary
/// `set()` would let the second one win by arriving later.
///
/// **A dropped connection is not an error state.** Firestore keeps a local
/// cache and queues writes, so the till keeps working on the shop's own wifi
/// going down. `error` is for a real failure — a permission denial, a missing
/// collection — which the list screen shows rather than rendering an empty
/// shelf. What each failure says is in `firestore_errors.dart`.
///
/// **It is handed a [ShopScope] and cannot name a collection.** The app is
/// sold to many shops, and the way one shop reads another's stock is one line
/// that says `collection('second_hand_mobiles')` instead of going through the
/// shop. There is no such line here because there is no way to write one —
/// see `firestore_paths.dart`.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/phone.dart';
import '../domain/inventory/imei.dart';
import '../domain/inventory/second_hand_device.dart';
import '../domain/inventory/stock_state.dart';
import '../domain/labels/label_entry.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'live_window.dart';
import 'second_hand_repository.dart';
import 'signatures.dart';

class FirestoreSecondHandStore extends ChangeNotifier
    implements SecondHandRepository {
  FirestoreSecondHandStore({required this.scope, this.saveSignature});

  /// This shop, and only this shop.
  final ShopScope scope;

  /// Moves a signature off its record into the shop's storage
  /// (signatures.dart). Null: signatures stay on the record.
  final SignatureSaver? saveSignature;

  /// Records whose signature this run has already tried to move — once is
  /// enough; a failure (offline, say) is tried again on the next start.
  final Set<String> _signatureTried = {};

  List<SecondHandDevice> _devices = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;

  CollectionReference<Map<String, dynamic>> get _collection => scope.secondHand;

  @override
  List<SecondHandDevice> get devices => List.unmodifiable(_devices);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    // Idempotent: the list screen calls this on its retry button, and opening
    // a second listener would double every change notification.
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // Phones not sold, of any age, and anything touched in the last 90
    // days: the live window. Older sold phones come on demand.
    final since = liveWindowStart(DateTime.now());
    _since = DateTime.now().subtract(kLiveWindow);
    _window = MergedListener(
      queries: [
        _collection.where('status', isNotEqualTo: kSold),
        _collection.where('updatedAt', isGreaterThanOrEqualTo: since.iso),
        _collection.where('updatedAt', isGreaterThanOrEqualTo: since.ts),
      ],
      onData: (docs) {
        // Every read normalizes — `fromMap` handles a Timestamp or an ISO
        // string, an amount stored as text, and a status this build has never
        // seen. That work was done for exactly this moment.
        _devices = [
          for (final doc in docs) SecondHandDevice.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
        _moveSignatures();
      },
      onError: (Object e) {
        _loading = false;
        // Said as itself. "Could not load" with no reason is how somebody
        // spends an afternoon on a rules problem they could have read.
        _error = describeFirestoreError(e, 'stock');
        notifyListeners();
      },
    )..start();
  }

  MergedListener? _window;
  DateTime? _since;

  /// Records outside the live list, fetched one at a time by [fetchById].
  final Map<String, SecondHandDevice> _fetched = {};

  @override
  DateTime? get liveSince => _since;

  @override
  Future<SecondHandDevice?> fetchById(String id) async {
    final known = byId(id);
    if (known != null) return known;
    final doc = await _collection.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    final record = SecondHandDevice.fromMap(id, data);
    _fetched[id] = record;
    notifyListeners();
    return record;
  }

  @override
  Future<List<SecondHandDevice>> fetchOlder({
    String? sellerCustomerId,
    String? sellerPhone,
    String? imei,
  }) async {
    final phone = normalizePhone(sellerPhone);
    final number = normalizeImei(imei);
    final queries = [
      if (sellerCustomerId != null && sellerCustomerId.isNotEmpty)
        _collection.where('sellerCustomerId', isEqualTo: sellerCustomerId),
      // Saved as typed before this build normalized it, so the shapes a
      // number was usually typed in are asked for too.
      if (phone.isNotEmpty)
        _collection.where(
          'sellerPhone',
          whereIn: {
            phone,
            formatPhone(phone),
            if (sellerPhone != null && sellerPhone.trim().isNotEmpty)
              sellerPhone.trim(),
          }.toList(),
        ),
      if (number.isNotEmpty) _collection.where('imei', isEqualTo: number),
    ];
    final results = [for (final q in queries) (await q.get()).docs];
    return [
      for (final doc in merged(results))
        SecondHandDevice.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<List<SecondHandDevice>> fetchActiveBetween(
    DateTime from,
    DateTime to,
  ) async {
    final f = from.toIso8601String();
    final t = to.toIso8601String();
    final results = [
      for (final field in ['purchasedAt', 'soldAt'])
        (await _collection
                .where(field, isGreaterThanOrEqualTo: f)
                .where(field, isLessThanOrEqualTo: t)
                .get())
            .docs,
    ];
    return [
      for (final doc in merged(results))
        SecondHandDevice.fromMap(doc.id, doc.data()),
    ];
  }

  /// Every signature still kept on its record goes to storage, and the
  /// record keeps the address instead.
  void _moveSignatures() {
    final save = saveSignature;
    if (save == null) return;
    for (final device in _devices) {
      final inline = device.sellerSignature;
      if (!isSignatureDataUrl(inline) || !_signatureTried.add(device.id)) {
        continue;
      }
      _moveSignature(save, device.id, inline!);
    }
  }

  Future<void> _moveSignature(
    SignatureSaver save,
    String id,
    String inline,
  ) async {
    final png = signatureFromDataUrl(inline);
    if (png == null || png.length > kMaxSignatureBytes) return;
    try {
      final stored = await save(id, png);
      // Only if the record still has this signature: a seller who signed
      // again meanwhile keeps the new one. updatedAt is left alone — the
      // purchase did not change, and an old record must not look recent.
      await _transact(
        id,
        (current) => current.sellerSignature == inline
            ? {'sellerSignature': stored}
            : const {},
      );
    } catch (e) {
      // Kept on the record, where it still shows and prints; tried again
      // on the next start.
      debugPrint('Signature for $id not moved: $e');
    }
  }

  @override
  SecondHandDevice? byId(String id) {
    for (final device in _devices) {
      if (device.id == id) return device;
    }
    return _fetched[id];
  }

  @override
  Future<SecondHandDevice> save(SecondHandDevice device) async {
    final existing = byId(device.id);
    // The one function that knows sold wins. A form cannot talk its way past
    // it by writing a status directly.
    final status = statusForSave(
      current: existing?.status,
      stillBeingRepaired: device.isBeingRepaired,
    );
    final stored = device.copyWith(
      status: status,
      // Stored clean, so a seller's older phones and an IMEI can be found
      // by query (fetchOlder).
      sellerPhone: normalizePhone(device.sellerPhone),
      imei: normalizeImei(device.imei),
      updatedAt: DateTime.now(),
      purchasedAt:
          device.purchasedAt ?? existing?.purchasedAt ?? DateTime.now(),
    );

    await localWrite(_collection.doc(stored.id).set(stored.toMap()));
    // The snapshot listener will deliver this back; returning the local value
    // means the caller does not have to wait a round trip to show it.
    return stored;
  }

  @override
  Future<SecondHandDevice> setRepairing(
    String id, {
    required bool repairing,
  }) async {
    return _transact(id, (device) {
      if (device.isSold) throw SoldDeviceLocked(id);
      return {
        'status': repairing ? kRepairing : kAvailable,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    });
  }

  @override
  Future<SecondHandDevice> markSold(String id, {required num soldPrice}) async {
    return _transact(id, (device) {
      final now = DateTime.now();
      return {
        'status': kSold,
        'soldPrice': soldPrice,
        // Kept, so a handset sold twice by mistake shows the first date
        // rather than quietly moving.
        'soldAt': (device.soldAt ?? now).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
    });
  }

  @override
  Future<SecondHandDevice> attachLabel(String id, int number) async {
    return _transact(id, (device) {
      // A record that already has a label keeps it: a second number for one
      // handset is a second sticker resolving somewhere the first did not.
      if (device.labelNumber != null) return const {};
      return {
        'labelNumber': number,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    });
  }

  @override
  Future<SecondHandDevice> returnToStock(
    String id, {
    required String reason,
  }) async {
    return _transact(id, (device) {
      if (!device.isSold) return const {};
      return {
        'status': kAvailable,
        // Deleted rather than set to null, so a handset back on the shelf
        // does not read as "sold for nothing" — and so `fromMap` sees no key
        // at all, which is what it treats as not sold.
        'soldPrice': FieldValue.delete(),
        'soldAt': FieldValue.delete(),
        'notes': [
          device.notes,
          if (reason.trim().isNotEmpty) 'Back in stock: ${reason.trim()}',
        ].where((p) => p.isNotEmpty).join('\n'),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    });
  }

  @override
  Map<String, Object?>? labelSnapshot(String id) {
    final device = byId(id);
    if (device == null) return null;
    return {
      kLabelTitle: device.title,
      kLabelSubtitle: [
        if (device.grade != null) 'Grade ${device.grade}',
        if (device.imei.isNotEmpty) 'IMEI ${device.imei}',
      ].join(' · '),
      kLabelPrice: device.askingPrice,
      kLabelStatus: kStockLabels[device.stockState] ?? device.stockState,
    };
  }

  /// Read, decide, write — as one step.
  ///
  /// [change] is given the record as it currently stands in Firestore, not as
  /// this device last saw it, and returns the fields to write. An empty map
  /// means the rule decided nothing should change, which is different from
  /// an error and must not write anything.
  Future<SecondHandDevice> _transact(
    String id,
    Map<String, Object?> Function(SecondHandDevice current) change,
  ) async {
    final ref = _collection.doc(id);
    return scope.firestore.runTransaction<SecondHandDevice>((
      transaction,
    ) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchDevice(id);

      final current = SecondHandDevice.fromMap(id, snapshot.data()!);
      final updates = change(current);
      if (updates.isEmpty) return current;

      transaction.update(ref, updates);
      // Read back from the same data the transaction just wrote, so the
      // caller gets what landed rather than what it hoped for.
      return SecondHandDevice.fromMap(
        id,
        {
          ...snapshot.data()!,
          ...Map<String, Object?>.fromEntries(
            updates.entries.where((e) => e.value is! FieldValue),
          ),
        }..removeWhere((key, _) => updates[key] is FieldValue),
      );
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }
}
