/// WHERE SERVICE ORDERS COME FROM
///
/// The transitions live here, not in the screens, because there are three
/// places an order's status can be moved from — the detail page, a scan, and
/// the checklist — and they have to agree.
///
/// Two of those transitions are not ordinary writes:
///
/// - **completing an order** goes through `canComplete`, never a status
///   write. A screen is given no way to write 'Completed' directly.
/// - **the order number** comes off an atomic counter, assigned once on first
///   save. Deriving it by counting gave two staff the same number.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/counters.dart';
import '../domain/common/phone.dart';
import '../domain/labels/label_entry.dart';
import 'settings_repository.dart';
import '../domain/service/checklist.dart';
import '../domain/service/order_state.dart';
import '../domain/service/order_validation.dart';
import '../domain/service/service_order.dart';

abstract class ServiceRepository extends ChangeNotifier {
  List<ServiceOrder> get orders;
  bool get loading;
  String? get error;

  /// The pre-delivery labels, from settings. The checklist's keys are derived
  /// from these, once, for the whole list.
  List<String> get checklistItems;

  Future<void> load();

  ServiceOrder? byId(String id);

  /// Save a new order or an existing one.
  ///
  /// A new order gets its number here. A status of 'Completed' passed in is
  /// ignored: completion is [complete]'s job and nothing else's.
  Future<ServiceOrder> save(ServiceOrder order);

  /// Move the status, within what `statusOptionsFor` allows for this role.
  ///
  /// Refused for anything not on that list, 'Completed' included — the gate is
  /// the checklist, and a dropdown must not be a way round it.
  Future<ServiceOrder> setStatus(
    String id,
    String status, {
    required bool isAdmin,
  });

  /// Tick or untick one pre-delivery check.
  Future<ServiceOrder> setCheck(String id, String key, {required bool ticked});

  /// Record what is being charged. Asked for before completion, because a
  /// completed order with no price is a phone handed back for free.
  Future<ServiceOrder> setFinalPrice(String id, num price);

  /// Hand the phone back. The only way to 'Completed'.
  ///
  /// Returns the check rather than throwing when it is blocked: a half-ticked
  /// list is an ordinary state, and the page names what is left.
  Future<CompletionCheck> complete(String id);

  /// Returned without being repaired — the customer took it away, or the job
  /// could not be done. Closed, like completed, but no checklist: there is
  /// nothing to verify on a phone nobody worked on.
  Future<ServiceOrder> markReturned(String id, {String? reason});

  /// The label fields for this order, for the registry's snapshot and for the
  /// live values laid over it on a scan. Null when the order is gone.
  ///
  /// There is no `attachLabel` here, unlike second-hand: the registry is the
  /// record of which order a sticker belongs to, and nothing on an order needs
  /// to be searched by its label number. Second-hand carries a copy of the
  /// number only because the stock list searches on it.
  Map<String, Object?>? labelSnapshot(String id);
}

class NoSuchOrder implements Exception {
  const NoSuchOrder(this.id);
  final String id;
  @override
  String toString() => 'No service order $id';
}

/// A status a screen is not allowed to set.
class StatusNotAllowed implements Exception {
  const StatusNotAllowed(this.status, {this.becauseCompletion = false});

  final String status;

  /// True for 'Completed', which has its own door.
  final bool becauseCompletion;

  @override
  String toString() => becauseCompletion
      ? 'An order is completed by passing the pre-delivery checklist, '
            'not by setting its status.'
      : 'Not an allowed status change: $status';
}

class InMemoryServiceStore extends ChangeNotifier implements ServiceRepository {
  InMemoryServiceStore({
    List<ServiceOrder>? seed,
    List<String>? checklist,
    this.settings,
    NumberCounter? counter,
    this.today,
  }) : _fixedChecklist = checklist,
       _counter = counter ?? InMemoryCounter() {
    _orders = [...(seed ?? _seedRecords())];
  }

  late List<ServiceOrder> _orders;

  /// The checklist labels come from the shop's settings, so editing them there
  /// changes what has to be ticked before the next phone goes back.
  ///
  /// A fixed list can be passed instead, which is what a test does when the
  /// labels are the thing under test rather than where they came from.
  final SettingsRepository? settings;

  final List<String>? _fixedChecklist;
  final NumberCounter _counter;

  /// Fixed in tests so an order number is predictable.
  final DateTime? today;

  bool _loading = false;
  String? _error;

  DateTime get _now => today ?? DateTime.now();

  @override
  List<ServiceOrder> get orders => List.unmodifiable(_orders);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  List<String> get checklistItems => List.unmodifiable(_checklist);

  List<String> get _checklist =>
      _fixedChecklist ??
      settings?.settings.preDeliveryChecklist.values ??
      kDefaultPreDeliveryChecklist;

  @override
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }

  @override
  ServiceOrder? byId(String id) => _orders.where((o) => o.id == id).firstOrNull;

  @override
  Future<ServiceOrder> save(ServiceOrder order) async {
    final existing = byId(order.id);
    final now = DateTime.now();

    // Assigned once, off the counter, on first save only. A reissued number is
    // two job cards the shop cannot tell apart.
    var number = existing?.orderNumber ?? order.orderNumber;
    if (number.isEmpty) {
      final day = _now;
      final sequence = await _counter.next(dailyCounterKey('service', day));
      number = serviceOrderNumber(day, sequence);
    }

    final stored = order.copyWith(
      orderNumber: number,
      customerPhone: normalizePhone(order.customerPhone),
      // Completion is not a write. An edit carrying 'Completed' keeps whatever
      // the order actually is.
      status: order.status == 'Completed'
          ? (existing?.status ?? 'Received')
          : order.status,
      // The list from settings may have changed since this order was taken in.
      // Carry the ticks that still have an item, and drop the ones that do not.
      checklist: carryOver(_checklist, order.checklist),
      updatedAt: now,
    );

    final index = _orders.indexWhere((o) => o.id == stored.id);
    if (index >= 0) {
      _orders[index] = stored;
    } else {
      _orders.add(stored);
    }
    notifyListeners();
    return stored;
  }

  @override
  Future<ServiceOrder> setStatus(
    String id,
    String status, {
    required bool isAdmin,
  }) async {
    final order = byId(id);
    if (order == null) throw NoSuchOrder(id);
    if (status == 'Completed') {
      throw const StatusNotAllowed('Completed', becauseCompletion: true);
    }
    if (!statusOptionsFor(order.status, isAdmin: isAdmin).contains(status)) {
      throw StatusNotAllowed(status);
    }
    return _replace(order.copyWith(status: status, updatedAt: DateTime.now()));
  }

  @override
  Future<ServiceOrder> setCheck(
    String id,
    String key, {
    required bool ticked,
  }) async {
    final order = byId(id);
    if (order == null) throw NoSuchOrder(id);
    return _replace(
      order.copyWith(
        checklist: {...order.checklist, key: ticked},
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ServiceOrder> setFinalPrice(String id, num price) async {
    final order = byId(id);
    if (order == null) throw NoSuchOrder(id);
    return _replace(
      order.copyWith(finalPrice: price, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<CompletionCheck> complete(String id) async {
    final order = byId(id);
    if (order == null) throw NoSuchOrder(id);

    final check = canComplete(order, checklistItems: _checklist);
    if (!check.allowed) return check;

    final now = DateTime.now();
    _replace(
      order.copyWith(
        status: 'Completed',
        // Kept, so an order completed twice shows the first time it went out.
        completedAt: order.completedAt ?? now,
        updatedAt: now,
      ),
    );
    return check;
  }

  @override
  Future<ServiceOrder> markReturned(String id, {String? reason}) async {
    final order = byId(id);
    if (order == null) throw NoSuchOrder(id);
    final now = DateTime.now();
    return _replace(
      order.copyWith(
        status: 'Returned',
        complaintNotes: reason == null || reason.trim().isEmpty
            ? order.complaintNotes
            : [
                order.complaintNotes,
                'Returned: ${reason.trim()}',
              ].where((p) => p.isNotEmpty).join('\n'),
        completedAt: order.completedAt ?? now,
        updatedAt: now,
      ),
    );
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
      // The estimate, which is what the customer was quoted — a sticker on a
      // phone on the bench is read by whoever picks it up next.
      kLabelPrice: order.finalPrice ?? order.estimatedPrice,
      kLabelStatus: order.status,
    };
  }

  ServiceOrder _replace(ServiceOrder order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index < 0) throw NoSuchOrder(order.id);
    _orders[index] = order;
    notifyListeners();
    return order;
  }
}

/// Seed orders, each one a state the list has to get right.
List<ServiceOrder> _seedRecords() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    // Overdue: promised two days ago and still in the shop.
    ServiceOrder(
      id: 'so-1',
      orderNumber: 'SO-20261018-001',
      customerId: 'c-1',
      customerName: 'Ramesh K',
      customerPhone: '9876543210',
      brand: 'Samsung',
      model: 'Galaxy M14',
      imei: '354879104523682',
      lockType: 'Pattern',
      lockValue: '1-2-3-6-9',
      accessories: const ['Charger'],
      complaints: const ['Not charging'],
      estimatedPrice: 1400,
      rawMaterialCost: 650,
      status: 'Parts Awaiting',
      technician: 'Suresh',
      receivedAt: today.subtract(const Duration(days: 6)),
      expectedCompletionAt: today.subtract(const Duration(days: 2)),
      createdAt: today.subtract(const Duration(days: 6)),
    ),
    // Due today.
    ServiceOrder(
      id: 'so-2',
      orderNumber: 'SO-20261022-002',
      customerId: 'c-2',
      customerName: 'Priya S',
      customerPhone: '9123456780',
      brand: 'Xiaomi',
      model: 'Redmi 13C',
      imei: '861234509876544',
      lockType: 'PIN',
      lockValue: '4417',
      complaints: const ['Display broken'],
      estimatedPrice: 2600,
      rawMaterialCost: 1750,
      status: 'In Progress',
      technician: 'Suresh',
      receivedAt: today.subtract(const Duration(days: 2)),
      expectedCompletionAt: today.add(const Duration(hours: 17)),
      createdAt: today.subtract(const Duration(days: 2)),
    ),
    // Closed last month, and promised before that. Closed beats overdue: this
    // is history, not an alarm, which is the rule the list got wrong.
    ServiceOrder(
      id: 'so-3',
      orderNumber: 'SO-20260915-004',
      customerId: 'c-5',
      customerName: 'Anand M',
      customerPhone: '9988776655',
      brand: 'Apple',
      model: 'iPhone 12',
      imei: '353012104567895',
      complaints: const ['Battery draining'],
      estimatedPrice: 3200,
      rawMaterialCost: 2100,
      finalPrice: 3200,
      status: 'Completed',
      technician: 'Mani',
      checklist: {
        for (final e in checklistEntries(kDefaultPreDeliveryChecklist))
          e.key: true,
      },
      receivedAt: today.subtract(const Duration(days: 40)),
      expectedCompletionAt: today.subtract(const Duration(days: 37)),
      completedAt: today.subtract(const Duration(days: 36)),
      createdAt: today.subtract(const Duration(days: 40)),
    ),
    // Written by an older build with a status this one has never heard of. It
    // keeps that status and still shows, rather than vanishing from every tab.
    ServiceOrder.fromMap('so-4', {
      'orderNumber': 'SO-20261020-003',
      'customerName': 'Kavitha R',
      'customerPhone': '+91 90000 11111',
      'brand': 'Vivo',
      'model': 'T2x',
      'complaints': ['Software / hanging'],
      'status': 'Waiting For Spare',
      'estimatedPrice': '900',
      'receivedAt': today.subtract(const Duration(days: 4)).toIso8601String(),
      'expectedCompletionAt': today
          .add(const Duration(days: 1))
          .toIso8601String(),
    }),
  ];
}
