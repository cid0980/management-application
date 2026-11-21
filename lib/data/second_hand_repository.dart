/// WHERE SECOND-HAND RECORDS COME FROM
///
/// The screens talk to this and never to Firestore. Two reasons, and the
/// second is the one that matters: the rules about stock can be driven from a
/// test with no emulator, and the shop can walk the whole flow on a machine
/// that has no Firebase config yet — which is every machine today, since
/// `firebase_options.dart` is not in the project.
///
/// [InMemorySecondHandStore] is that walkable implementation, seeded with a
/// few records of the shapes that caused trouble: one on the bench, one sold,
/// one with a status nobody recognises.
///
/// The state transitions live HERE rather than in the screens, so the detail
/// page, the sale and a scan cannot each have their own idea of what selling a
/// handset does.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/inventory/purchase_costing.dart';
import '../domain/inventory/second_hand_device.dart';
import '../domain/inventory/stock_state.dart';
import '../domain/labels/label_entry.dart';

abstract class SecondHandRepository extends ChangeNotifier {
  /// Everything loaded, sellable or not. The list filters in the hand.
  List<SecondHandDevice> get devices;

  bool get loading;

  /// The error from the last load, or null. Shown as itself — a failed load
  /// must say so rather than render an empty shelf, which reads as "no stock".
  String? get error;

  Future<void> load();

  SecondHandDevice? byId(String id);

  /// Save a new record or an existing one. Returns what was stored, which is
  /// not always what was passed: [statusForSave] may hold a sold device sold.
  Future<SecondHandDevice> save(SecondHandDevice device);

  /// Put a handset on the bench, or take it off.
  ///
  /// Refused on a sold device: it is not in the shop to repair.
  Future<SecondHandDevice> setRepairing(String id, {required bool repairing});

  /// Record the handset going out. [soldPrice] is what it actually went for,
  /// which is the only figure Reports may use.
  Future<SecondHandDevice> markSold(String id, {required num soldPrice});

  /// Put a label number that the registry has already minted onto a record.
  ///
  /// This store does NOT choose the number, and that is deliberate. It used to:
  /// it kept a counter of its own, and so would every other area that prints
  /// labels — four counters over one number space, and label 26042 ending up
  /// on two different phones. `LabelRepository` is the only thing that mints,
  /// and it calls this to attach what it minted.
  ///
  /// A record that already has a label keeps it: a second number for one
  /// handset is a second sticker that resolves somewhere the first did not.
  Future<SecondHandDevice> attachLabel(String id, int number);

  /// The label fields for this record, for the registry's snapshot and for the
  /// live values laid over it on a scan. Null when the record is gone.
  Map<String, Object?>? labelSnapshot(String id);

  /// Put a sold handset back on the shelf. **The only way back from sold.**
  ///
  /// `statusForSave` exists so that nothing ordinary can do this: an edit, a
  /// form, a scan and the bench switch all leave a sold device sold, because
  /// the shop's problem was records being quietly un-sold by someone editing
  /// them.
  ///
  /// But a cancelled bill is real. A customer changes their mind at the
  /// counter, a payment fails, the wrong handset was scanned onto the bill —
  /// and the phone is still in the cabinet. Without this, the only way to sell
  /// it again was to re-enter it as a new purchase, which double-counted the
  /// stock and the margin.
  ///
  /// So there is exactly one door, it is named after what it is for, and it is
  /// called by the sales repository when a completed bill is cancelled. It
  /// clears the sold price and date along with the status: a handset back on
  /// the shelf has not been sold for anything.
  Future<SecondHandDevice> returnToStock(String id, {required String reason});
}

/// A device already out of the shop cannot be changed back into stock.
class SoldDeviceLocked implements Exception {
  const SoldDeviceLocked(this.id);
  final String id;
  @override
  String toString() =>
      'Device $id is sold. A sold handset cannot be put back into stock.';
}

class NoSuchDevice implements Exception {
  const NoSuchDevice(this.id);
  final String id;
  @override
  String toString() => 'No second-hand device $id';
}

class InMemorySecondHandStore extends ChangeNotifier
    implements SecondHandRepository {
  InMemorySecondHandStore({List<SecondHandDevice>? seed}) {
    _devices = [...(seed ?? _seedRecords())];
  }

  late List<SecondHandDevice> _devices;
  bool _loading = false;
  String? _error;

  @override
  List<SecondHandDevice> get devices => List.unmodifiable(_devices);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }

  @override
  SecondHandDevice? byId(String id) =>
      _devices.where((d) => d.id == id).firstOrNull;

  @override
  Future<SecondHandDevice> save(SecondHandDevice device) async {
    final existing = byId(device.id);
    // The form's answer to "is this ready to sell" goes through the one
    // function that knows sold wins.
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

    final index = _devices.indexWhere((d) => d.id == stored.id);
    if (index >= 0) {
      _devices[index] = stored;
    } else {
      _devices.add(stored);
    }
    notifyListeners();
    return stored;
  }

  @override
  Future<SecondHandDevice> setRepairing(
    String id, {
    required bool repairing,
  }) async {
    final device = byId(id);
    if (device == null) throw NoSuchDevice(id);
    if (device.isSold) throw SoldDeviceLocked(id);
    return _replace(
      device.copyWith(
        status: repairing ? kRepairing : kAvailable,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<SecondHandDevice> markSold(String id, {required num soldPrice}) async {
    final device = byId(id);
    if (device == null) throw NoSuchDevice(id);
    final now = DateTime.now();
    return _replace(
      device.copyWith(
        status: kSold,
        soldPrice: asAmount(soldPrice),
        // Kept, so a handset sold twice by mistake shows the first date rather
        // than quietly moving.
        soldAt: device.soldAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<SecondHandDevice> attachLabel(String id, int number) async {
    final device = byId(id);
    if (device == null) throw NoSuchDevice(id);
    if (device.labelNumber != null) return device;
    return _replace(
      device.copyWith(labelNumber: number, updatedAt: DateTime.now()),
    );
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
      // The asking price, because that is what a sticker on a shelf is for.
      kLabelPrice: device.askingPrice,
      kLabelStatus: kStockLabels[device.stockState] ?? device.stockState,
    };
  }

  @override
  Future<SecondHandDevice> returnToStock(
    String id, {
    required String reason,
  }) async {
    final device = byId(id);
    if (device == null) throw NoSuchDevice(id);
    if (!device.isSold) return device;

    // Rebuilt rather than copied, because copyWith cannot set soldPrice and
    // soldAt back to null — and leaving them would show a handset on the shelf
    // with a sale price and a sale date against it.
    final restored = SecondHandDevice(
      id: device.id,
      brand: device.brand,
      model: device.model,
      variant: device.variant,
      colour: device.colour,
      imei: device.imei,
      imei2: device.imei2,
      serial: device.serial,
      status: kAvailable,
      grade: device.grade,
      gradeOverridden: device.gradeOverridden,
      conditionAnswers: device.conditionAnswers,
      repairs: device.repairs,
      purchasePrice: device.purchasePrice,
      otherCost: device.otherCost,
      askingPrice: device.askingPrice,
      soldPrice: null,
      photos: device.photos,
      sellerName: device.sellerName,
      sellerPhone: device.sellerPhone,
      sellerIdProof: device.sellerIdProof,
      sellerSignature: device.sellerSignature,
      labelNumber: device.labelNumber,
      // Why it came back goes on the record. A handset that has been sold and
      // returned is worth knowing about when it is sold again.
      notes: [
        device.notes,
        if (reason.trim().isNotEmpty) 'Back in stock: ${reason.trim()}',
      ].where((p) => p.isNotEmpty).join('\n'),
      purchasedAt: device.purchasedAt,
      soldAt: null,
      createdAt: device.createdAt,
      updatedAt: DateTime.now(),
    );
    return _replace(restored);
  }

  SecondHandDevice _replace(SecondHandDevice device) {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index < 0) throw NoSuchDevice(device.id);
    _devices[index] = device;
    notifyListeners();
    return device;
  }
}

/// Seed records, each one a shape that has gone wrong before.
List<SecondHandDevice> _seedRecords() {
  final now = DateTime.now();
  return [
    SecondHandDevice(
      id: 'sh-1',
      brand: 'Samsung',
      model: 'Galaxy A54',
      variant: '8/128',
      colour: 'Awesome Violet',
      imei: '354879104523681',
      status: kAvailable,
      grade: 'A',
      // Nothing marked: every check passed.
      conditionAnswers: const {},
      purchasePrice: 14500,
      askingPrice: 18500,
      photos: const ['seed://a54-front', 'seed://a54-back'],
      sellerName: 'Ramesh K',
      sellerPhone: '9876543210',
      sellerIdProof: 'Aadhaar ••• 4412',
      labelNumber: 26001,
      purchasedAt: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    // On the bench: bought with a broken display, repair costed here so the
    // margin is honest, and kept out of the sale picker meanwhile.
    SecondHandDevice(
      id: 'sh-2',
      brand: 'Xiaomi',
      model: 'Redmi Note 12',
      variant: '6/128',
      colour: 'Ice Blue',
      imei: '861234509876543',
      status: kRepairing,
      grade: 'C',
      // Bought with a bad, already-replaced display: a C, whatever else works.
      conditionAnswers: const {
        'display_clarity': false,
        'display_replaced': false,
      },
      repairs: const [
        RepairCost(description: 'Display assembly', amount: 2400),
        RepairCost(description: 'Battery', amount: 650),
      ],
      purchasePrice: 6200,
      otherCost: 150,
      askingPrice: 11500,
      photos: const ['seed://note12-front'],
      sellerName: 'Priya S',
      sellerPhone: '9123456780',
      purchasedAt: now.subtract(const Duration(days: 6)),
      createdAt: now.subtract(const Duration(days: 6)),
    ),
    SecondHandDevice(
      id: 'sh-3',
      brand: 'Apple',
      model: 'iPhone 11',
      variant: '64GB',
      colour: 'Black',
      imei: '353012104567894',
      status: kSold,
      grade: 'B',
      purchasePrice: 19000,
      askingPrice: 25000,
      soldPrice: 24000,
      photos: const ['seed://iphone11-front'],
      sellerName: 'Anand M',
      sellerPhone: '9988776655',
      labelNumber: 26002,
      purchasedAt: now.subtract(const Duration(days: 21)),
      soldAt: now.subtract(const Duration(days: 4)),
      createdAt: now.subtract(const Duration(days: 21)),
    ),
    // Written by an older build with a status this one has never heard of. It
    // reads as plain stock and still shows up, rather than vanishing.
    SecondHandDevice.fromMap('sh-4', {
      'brand': 'Vivo',
      'model': 'Y21',
      'status': 'in_stock_old',
      'purchasePrice': '7,500',
      'askingPrice': 9500,
      'photos': ['seed://y21-front'],
      'sellerName': 'Kavitha R',
      'sellerPhone': '+91 90000 11111',
      'purchasedAt': now.subtract(const Duration(days: 11)).toIso8601String(),
    }),
  ];
}
