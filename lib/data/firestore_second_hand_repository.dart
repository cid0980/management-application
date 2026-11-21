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
/// `search.dart`. So this holds a snapshot listener open and keeps the last
/// result. That is also what the shop wants: the stock list is opened dozens
/// of times a day and re-reading it each time is a spinner nobody needs.
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

import '../domain/inventory/second_hand_device.dart';
import '../domain/inventory/stock_state.dart';
import '../domain/labels/label_entry.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'second_hand_repository.dart';

class FirestoreSecondHandStore extends ChangeNotifier
    implements SecondHandRepository {
  FirestoreSecondHandStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

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

    _collection.snapshots().listen(
      (snapshot) {
        // Every read normalizes — `fromMap` handles a Timestamp or an ISO
        // string, an amount stored as text, and a status this build has never
        // seen. That work was done for exactly this moment.
        _devices = [
          for (final doc in snapshot.docs)
            SecondHandDevice.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        // Said as itself. "Could not load" with no reason is how somebody
        // spends an afternoon on a rules problem they could have read.
        _error = describeFirestoreError(e, 'stock');
        notifyListeners();
      },
    );
  }

  @override
  SecondHandDevice? byId(String id) {
    for (final device in _devices) {
      if (device.id == id) return device;
    }
    return null;
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
      updatedAt: DateTime.now(),
      purchasedAt:
          device.purchasedAt ?? existing?.purchasedAt ?? DateTime.now(),
    );

    await _collection.doc(stored.id).set(stored.toMap());
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
}
