/// SERVICE ORDERS, OUT OF FIRESTORE
///
/// The same `ServiceRepository` the screens already talk to, backed by
/// `shops/{shopId}/service_orders`.
///
/// **An order number is minted once, off the counter.** On first save only,
/// and from `counters/service-YYYYMMDD` rather than from counting documents. A
/// reissued number is two job cards the shop cannot tell apart. An order that
/// already has one keeps it, whatever a form sends.
///
/// **Completion is not a write.** `setStatus` refuses `Completed` and an edit
/// carrying it keeps whatever the order actually is — the only way an order is
/// completed is [complete], which asks `canComplete` first. That is the
/// checklist gate, and it is the rule the shop's old app did not have: a phone
/// went back to a customer with the lock pattern still on it because somebody
/// picked a dropdown value.
///
/// **The checklist comes from the shop's settings.** Editing it there changes
/// what has to be ticked before the next phone goes back. The labels may have
/// changed since an order was taken in, so a save carries over the ticks that
/// still have an item and drops the ones that do not.
///
/// **Status and completion go through a transaction**, because both are rules
/// about what the record currently says — what a status may move to depends on
/// the status it is on now, and a second till moving the same order is exactly
/// the race an ordinary `set()` would lose.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/counters.dart';
import '../domain/common/phone.dart';
import '../domain/labels/label_entry.dart';
import '../domain/service/checklist.dart';
import '../domain/service/order_state.dart';
import '../domain/service/order_validation.dart';
import '../domain/service/service_order.dart';
import 'firestore_counter.dart';
import 'firestore_errors.dart';
import 'live_window.dart';
import 'firestore_paths.dart';
import 'service_repository.dart';
import 'settings_repository.dart';
import '../domain/sales/sale.dart' show Collection;

class FirestoreServiceStore extends ChangeNotifier
    implements ServiceRepository {
  FirestoreServiceStore({
    required this.scope,
    this.settings,
    NumberCounter? counter,
    this.today,
  }) : _counter = counter ?? FirestoreCounter(scope: scope);

  /// This shop, and only this shop.
  final ShopScope scope;

  /// The checklist labels come from the shop's settings, so editing them there
  /// changes what has to be ticked before the next phone goes back.
  final SettingsRepository? settings;

  final NumberCounter _counter;

  /// Fixed in tests so an order number is predictable.
  final DateTime? today;

  List<ServiceOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;

  DateTime get _now => today ?? DateTime.now();

  @override
  List<ServiceOrder> get orders => List.unmodifiable(_orders);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  List<String> get checklistItems => List.unmodifiable(_checklist);

  @override
  List<String> get preDeliveryChecklist => _checklist;

  List<String> get _checklist =>
      settings?.settings.preDeliveryChecklist.values ??
      kDefaultPreDeliveryChecklist;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // Open jobs of any age, and anything touched in the last 90 days: the
    // live window (live_window.dart). Older closed jobs come on demand.
    final since = liveWindowStart(DateTime.now());
    _since = DateTime.now().subtract(kLiveWindow);
    _window = MergedListener(
      queries: [
        scope.serviceOrders.where(
          'status',
          whereNotIn: const ['Completed', 'Returned'],
        ),
        scope.serviceOrders.where(
          'updatedAt',
          isGreaterThanOrEqualTo: since.iso,
        ),
        scope.serviceOrders.where(
          'updatedAt',
          isGreaterThanOrEqualTo: since.ts,
        ),
      ],
      onData: (docs) {
        // `fromMap` normalizes, which is what keeps an order written by an
        // older build — with a status this one has never heard of — showing
        // in the list rather than vanishing from every tab.
        _orders = [
          for (final doc in docs) ServiceOrder.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'service orders');
        notifyListeners();
      },
    )..start();
  }

  MergedListener? _window;
  DateTime? _since;

  @override
  DateTime? get liveSince => _since;

  @override
  Future<List<ServiceOrder>> fetchOlder({
    String? customerId,
    String? phone,
    String? number,
  }) async {
    final queries = [
      if (customerId != null && customerId.isNotEmpty)
        scope.serviceOrders.where('customerId', isEqualTo: customerId),
      if (phone != null && phone.isNotEmpty)
        scope.serviceOrders.where(
          'customerPhone',
          isEqualTo: normalizePhone(phone),
        ),
      if (number != null && number.isNotEmpty)
        scope.serviceOrders.where('orderNumber', isEqualTo: number.trim()),
    ];
    final results = [for (final q in queries) (await q.get()).docs];
    return [
      for (final doc in merged(results))
        ServiceOrder.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<List<ServiceOrder>> fetchClosedBetween(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await scope.serviceOrders
        .where('completedAt', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('completedAt', isLessThanOrEqualTo: to.toIso8601String())
        .get();
    return [
      for (final doc in snap.docs) ServiceOrder.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  ServiceOrder? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return _fetched[id];
  }

  /// Records outside the live list, fetched one at a time by [fetchById].
  final Map<String, ServiceOrder> _fetched = {};

  @override
  Future<ServiceOrder?> fetchById(String id) async {
    final known = byId(id);
    if (known != null) return known;
    final doc = await scope.serviceOrders.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    final record = ServiceOrder.fromMap(id, data);
    _fetched[id] = record;
    notifyListeners();
    return record;
  }

  @override
  Future<ServiceOrder> save(ServiceOrder order) async {
    final ref = scope.serviceOrders.doc(order.id);
    ServiceOrder? existing;
    try {
      final snapshot = await ref.get();
      existing = snapshot.exists
          ? ServiceOrder.fromMap(order.id, snapshot.data()!)
          : null;
    } on FirebaseException catch (e) {
      // Offline, a job this phone has never seen cannot be read from the
      // server or the local copy — which is exactly a new job. Anything
      // other than "offline" is a real failure.
      if (e.code != 'unavailable') rethrow;
      existing = byId(order.id);
    }

    // Minted once, before the write, because a counter is a transaction of
    // its own and an order number has to be the same on every later save.
    var number = existing?.orderNumber ?? order.orderNumber;
    if (number.isEmpty) {
      final day = _now;
      try {
        final sequence = await _counter.next(dailyCounterKey('service', day));
        number = serviceOrderNumber(day, sequence);
      } on FirebaseException catch (e) {
        // The counter is a transaction and cannot run offline. Take the job
        // in anyway, with a number that cannot clash with a counted one.
        if (e.code != 'unavailable') rethrow;
        number = offlineServiceOrderNumber(DateTime.now());
      }
    }

    final stored = order.copyWith(
      orderNumber: number,
      customerPhone: normalizePhone(order.customerPhone),
      // Completion is not a write. See the class note.
      status: order.status == 'Completed'
          ? (existing?.status ?? 'Received')
          : order.status,
      // The list from settings may have changed since this order was taken
      // in: carry the ticks that still have an item.
      checklist: carryOver(_checklist, order.checklist),
      updatedAt: DateTime.now(),
    );

    if (existing == null) {
      await localWrite(ref.set(stored.toMap()));
    } else {
      // Merged, so a field this build does not know about is not wiped by an
      // edit to the complaint list.
      await localWrite(ref.set(stored.toMap(), SetOptions(merge: true)));
    }
    return stored;
  }

  @override
  Future<ServiceOrder> setStatus(
    String id,
    String status, {
    required bool isAdmin,
  }) {
    // Refused before the transaction opens: this one does not depend on what
    // the record says.
    if (status == 'Completed') {
      throw const StatusNotAllowed('Completed', becauseCompletion: true);
    }
    return _transact(id, (order) {
      // What a status may move to depends on the status it is on NOW, which
      // is why this is read inside the transaction.
      if (!statusOptionsFor(order.status, isAdmin: isAdmin).contains(status)) {
        throw StatusNotAllowed(status);
      }
      return {'status': status, 'updatedAt': DateTime.now().toIso8601String()};
    });
  }

  @override
  Future<ServiceOrder> setCheck(String id, String key, {required bool ticked}) {
    return _transact(
      id,
      (order) => {
        // One key at a time, so two staff ticking two different items do
        // not overwrite each other's tick.
        'checklist.$key': ticked,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<ServiceOrder> setFinalPrice(String id, num price) {
    checkChargeable(price);
    return _transact(
      id,
      (order) => {
        'finalPrice': price,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<ServiceOrder> addPart(String id, PartUse part) {
    return _transact(
      id,
      (order) => {
        // The whole list, read inside the transaction: an arrayUnion would
        // merge two identical batteries fitted the same second into one.
        'partsUsed': [for (final p in order.partsUsed) p.toMap(), part.toMap()],
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<CompletionCheck> complete(String id, {String method = 'Cash'}) async {
    final ref = scope.serviceOrders.doc(id);
    return scope.firestore.runTransaction<CompletionCheck>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchOrder(id);

      final order = ServiceOrder.fromMap(id, snapshot.data()!);
      // The gate. Asked of the record as it stands in Firestore, not as this
      // device last saw it — a tick cleared on the other till has to count.
      final check = canComplete(order, checklistItems: _checklist);
      if (!check.allowed) return check;

      final now = DateTime.now();
      transaction.update(ref, {
        'status': 'Completed',
        // Kept, so an order completed twice shows the first time it went out.
        'completedAt': (order.completedAt ?? now).toIso8601String(),
        // The policy as it stands when the phone goes out, once.
        if (order.completedAt == null)
          'warrantyDays': settings?.settings.repairWarrantyDays ?? 0,
        // What was paid at pickup, how and when — once.
        if (order.completedAt == null && order.toCollect > 0)
          'pickupPayment': Collection(
            amount: order.toCollect,
            method: method,
            at: now,
          ).toMap(),
        // An advance more than the charge: the difference went back.
        if (order.completedAt == null && changeOnHandover(order) > 0)
          'payments': [
            for (final p in withPayment(
              order,
              Collection(
                amount: -changeOnHandover(order),
                method: order.advanceMethod,
                at: now,
              ),
            ))
              p.toMap(),
          ],
        'updatedAt': now.toIso8601String(),
      });
      return check;
    });
  }

  @override
  Future<ServiceOrder> markReturned(
    String id, {
    required String reason,
    bool refundAdvance = true,
  }) {
    if (reason.trim().isEmpty) {
      throw 'Say why it is going back unrepaired';
    }
    return _transact(id, (order) {
      final now = DateTime.now();
      final advance = order.advancePaid;
      return {
        'status': 'Returned',
        'complaintNotes': [
          order.complaintNotes,
          'Returned: ${reason.trim()}',
        ].where((p) => p.isNotEmpty).join('\n'),
        'completedAt': (order.completedAt ?? now).toIso8601String(),
        // The advance: given back today, or kept as what was charged.
        if (advance > 0 && refundAdvance)
          'payments': [
            for (final p in withPayment(
              order,
              Collection(
                amount: -advance,
                method: order.advanceMethod,
                at: now,
              ),
            ))
              p.toMap(),
          ],
        if (advance > 0 && !refundAdvance) 'finalPrice': advance,
        'updatedAt': now.toIso8601String(),
      };
    });
  }

  @override
  Map<String, Object?>? labelSnapshot(String id) {
    final order = byId(id);
    if (order == null) return null;
    return {
      kLabelTitle: order.device,
      kLabelSubtitle: [
        order.orderNumber,
        if (order.customerName.isNotEmpty) order.customerName,
      ].where((p) => p.isNotEmpty).join(' · '),
      // What the customer was quoted — a sticker on a phone on the bench is
      // read by whoever picks it up next.
      kLabelPrice: order.finalPrice ?? order.estimatedPrice,
      kLabelStatus: order.status,
    };
  }

  /// Read, decide, write — as one step.
  ///
  /// [change] is given the order as it currently stands in Firestore and
  /// returns the fields to write. Dotted keys are field paths, so one tick is
  /// written without sending the whole checklist back.
  Future<ServiceOrder> _transact(
    String id,
    Map<String, Object?> Function(ServiceOrder current) change,
  ) {
    final ref = scope.serviceOrders.doc(id);
    return scope.firestore.runTransaction<ServiceOrder>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchOrder(id);

      final current = ServiceOrder.fromMap(id, snapshot.data()!);
      final updates = change(current);
      if (updates.isEmpty) return current;

      transaction.update(ref, updates);
      // Read back from what the transaction just wrote, so the caller gets
      // what landed rather than what it hoped for. Dotted keys are applied by
      // hand, since the stored map is nested.
      final merged = {...snapshot.data()!};
      for (final entry in updates.entries) {
        final dot = entry.key.indexOf('.');
        if (dot < 0) {
          merged[entry.key] = entry.value;
          continue;
        }
        final parent = entry.key.substring(0, dot);
        final child = entry.key.substring(dot + 1);
        merged[parent] = {
          ...?(merged[parent] as Map?)?.cast<String, Object?>(),
          child: entry.value,
        };
      }
      return ServiceOrder.fromMap(id, merged);
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }
}
