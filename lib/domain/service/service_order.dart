/// ONE SERVICE ORDER
///
/// A phone on the bench, from the moment it is handed over to the moment it is
/// handed back. The record is what the job card and the final bill are both
/// built from — one record, two documents, so a job taken in as "charging
/// port" cannot go out billed as something else.
///
/// The rules about it live next door and are already tested: `order_state.dart`
/// owns what status may follow what and what overdue means, and
/// `checklist.dart` owns the pre-delivery keys. This is the record they read.
library;

import '../common/dates.dart';
import '../common/phone.dart';
import '../common/search.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import 'order_state.dart';

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    this.orderNumber = '',
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.brand = '',
    this.model = '',
    this.imei = '',
    this.lockType = 'None',
    this.lockValue = '',
    this.accessories = const [],
    this.complaints = const [],
    this.complaintNotes = '',
    this.estimatedPrice = 0,
    this.rawMaterialCost = 0,
    this.outsideLabourCost = 0,
    this.finalPrice,
    this.status = 'Received',
    this.technician = '',
    this.checklist = const {},
    this.receivedAt,
    this.expectedCompletionAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// `SO-20260304-007`, from the atomic counter. Empty until the order is
  /// saved for the first time.
  final String orderNumber;

  /// The customer record this belongs to. The name and number are copied onto
  /// the order as well, because the job card is printed from the order and has
  /// to be printable without a second read.
  final String? customerId;
  final String customerName;
  final String customerPhone;

  final String brand;
  final String model;

  /// Taken off the phone, not the box. A warranty claim against the wrong IMEI
  /// is the shop's problem, not the customer's.
  final String imei;

  final String lockType;

  /// The PIN, password, or the pattern as `1-2-3-6-9`. A phone that cannot be
  /// unlocked cannot be tested, and a job handed back untested comes straight
  /// back.
  final String lockValue;

  /// What the customer left with it. On the job card, because what came in is
  /// the only answer to "where is my charger".
  final List<String> accessories;

  /// From the shop's shared vocabulary. The job card and the final bill are
  /// both built from these.
  final List<String> complaints;

  final String complaintNotes;

  final num estimatedPrice;
  final num rawMaterialCost;
  final num outsideLabourCost;

  /// What was actually charged, once the job is done. Null while it is open —
  /// not zero, the same reason a handset still in stock has no realised
  /// profit.
  final num? finalPrice;

  final String status;
  final String technician;

  /// Pre-delivery ticks, keyed by `checklistKey`. An order is completed by
  /// passing this list, never by a dropdown.
  final Map<String, bool> checklist;

  final DateTime? receivedAt;

  /// What the customer was promised. Both dates are mandatory and validated in
  /// one place — see `requireOrderDates`.
  final DateTime? expectedCompletionAt;

  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get device => [brand, model].where((p) => p.isNotEmpty).join(' ');

  String get title => orderNumber.isEmpty ? device : '$orderNumber · $device';

  /// The slice the state rules read.
  ServiceOrderState get asState => ServiceOrderState(
    status: status,
    expectedCompletionAt: expectedCompletionAt,
  );

  bool get closed => isClosed(status);
  bool isOverdueAt(DateTime now) => isOverdue(asState, now: now);
  bool isDueTodayAt(DateTime now) => isDueToday(asState, now: now);
  OrderLifecycle lifecycleAt(DateTime now) => stateOf(asState, now: now);

  /// What the shop spends on the job.
  num get costs => rawMaterialCost + outsideLabourCost;

  /// Profit at the estimate, which is what the counter quotes against. Shown
  /// live on the intake form so a quote below cost is visible before it is
  /// given, not after.
  num get estimatedProfit => estimatedPrice - costs;

  /// What the job actually made. Null until it is charged.
  num? get realisedProfit => finalPrice == null ? null : finalPrice! - costs;

  /// Quoted at or below what the job costs. A warning, not a refusal: a
  /// goodwill repair is a decision.
  bool get quotedAtALoss => estimatedPrice > 0 && estimatedProfit <= 0;

  bool matches(String? query) => matchesQuery(query, [
    orderNumber,
    customerName,
    customerPhone,
    brand,
    model,
    imei,
    technician,
    ...complaints,
  ]);

  ServiceOrder copyWith({
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? brand,
    String? model,
    String? imei,
    String? lockType,
    String? lockValue,
    List<String>? accessories,
    List<String>? complaints,
    String? complaintNotes,
    num? estimatedPrice,
    num? rawMaterialCost,
    num? outsideLabourCost,
    num? finalPrice,
    String? status,
    String? technician,
    Map<String, bool>? checklist,
    DateTime? receivedAt,
    DateTime? expectedCompletionAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) => ServiceOrder(
    id: id,
    orderNumber: orderNumber ?? this.orderNumber,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    imei: imei ?? this.imei,
    lockType: lockType ?? this.lockType,
    lockValue: lockValue ?? this.lockValue,
    accessories: accessories ?? this.accessories,
    complaints: complaints ?? this.complaints,
    complaintNotes: complaintNotes ?? this.complaintNotes,
    estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    rawMaterialCost: rawMaterialCost ?? this.rawMaterialCost,
    outsideLabourCost: outsideLabourCost ?? this.outsideLabourCost,
    finalPrice: finalPrice ?? this.finalPrice,
    status: status ?? this.status,
    technician: technician ?? this.technician,
    checklist: checklist ?? this.checklist,
    receivedAt: receivedAt ?? this.receivedAt,
    expectedCompletionAt: expectedCompletionAt ?? this.expectedCompletionAt,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static ServiceOrder fromMap(
    String id,
    Map<String, Object?> map,
  ) => ServiceOrder(
    id: id,
    orderNumber: _str(map['orderNumber']),
    customerId: map['customerId'] as String?,
    customerName: _str(map['customerName']),
    customerPhone: normalizePhone(_str(map['customerPhone'])),
    brand: _str(map['brand']),
    model: _str(map['model']),
    imei: _str(map['imei']).replaceAll(RegExp(r'\D'), ''),
    lockType: _str(map['lockType']).isEmpty ? 'None' : _str(map['lockType']),
    lockValue: _str(map['lockValue']),
    accessories: _strings(map['accessories']),
    complaints: _strings(map['complaints']),
    complaintNotes: _str(map['complaintNotes']),
    estimatedPrice: asAmount(map['estimatedPrice']),
    rawMaterialCost: asAmount(map['rawMaterialCost']),
    outsideLabourCost: asAmount(map['outsideLabourCost']),
    finalPrice: map['finalPrice'] == null ? null : asAmount(map['finalPrice']),
    // An order carrying a status this build has never seen keeps it: the
    // list shows it rather than dropping the row.
    status: _str(map['status']).isEmpty ? 'Received' : _str(map['status']),
    technician: _str(map['technician']),
    checklist: _ticks(map['checklist']),
    receivedAt: normalizeDate(map['receivedAt']),
    expectedCompletionAt: normalizeDate(map['expectedCompletionAt']),
    completedAt: normalizeDate(map['completedAt']),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'orderNumber': orderNumber,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'brand': brand,
    'model': model,
    'imei': imei,
    'lockType': lockType,
    'lockValue': lockValue,
    'accessories': accessories,
    'complaints': complaints,
    'complaintNotes': complaintNotes,
    'estimatedPrice': estimatedPrice,
    'rawMaterialCost': rawMaterialCost,
    'outsideLabourCost': outsideLabourCost,
    'finalPrice': finalPrice,
    'status': status,
    'technician': technician,
    'checklist': checklist,
    'receivedAt': receivedAt?.toIso8601String(),
    'expectedCompletionAt': expectedCompletionAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

String _str(Object? v) => v == null ? '' : v.toString().trim();

List<String> _strings(Object? v) => v is Iterable
    ? [
        for (final e in v)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ]
    : const [];

Map<String, bool> _ticks(Object? v) {
  if (v is! Map) return const {};
  final out = <String, bool>{};
  v.forEach((key, value) {
    final k = key?.toString();
    if (k != null && k.isNotEmpty) out[k] = value == true;
  });
  return out;
}
