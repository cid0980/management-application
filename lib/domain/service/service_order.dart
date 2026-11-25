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

import 'repair_history.dart';
import '../common/dates.dart';
import '../common/money.dart';
import '../common/phone.dart';
import '../common/search.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import '../sales/sale.dart' show Collection;
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
    this.photos = const [],
    this.complaints = const [],
    this.complaintNotes = '',
    this.estimatedPrice = 0,
    this.rawMaterialCost = 0,
    this.outsideLabourCost = 0,
    this.finalPrice,
    this.advancePaid = 0,
    this.advanceMethod = 'Cash',
    this.pickupPayment,
    this.partsUsed = const [],
    this.warrantyDays = 0,
    this.status = 'Received',
    this.technician = '',
    this.technicianUid = '',
    this.assignedAt,
    this.assignedBy = '',
    this.history = const [],
    this.checklist = const {},
    this.receivedAt,
    this.expectedCompletionAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.visitId = '',
    this.payments = const [],
  });

  /// MONEY TAKEN OR GIVEN BACK ON THIS JOB, EACH ON ITS OWN DAY
  ///
  /// The advance when it was taken, any change to it later (an edit from
  /// ₹120 to ₹20 is a ₹100 refund, not ₹100 vanishing), the change given
  /// back when the advance was more than the charge, the advance refunded on
  /// a phone returned unrepaired. Negative amounts went back to the
  /// customer. The pickup payment is [pickupPayment]. Empty on jobs written
  /// before this existed, which Reports read the old way.
  final List<Collection> payments;

  final String id;

  /// SEVERAL PHONES, ONE VISIT
  ///
  /// A customer who brings two phones gets one job per phone — each keeps its
  /// own status, checklist, price and warranty — and the jobs share this id
  /// (the first job's id). The job card and the final bill print every phone
  /// in the visit together. Empty for a phone that came in alone, which is
  /// every record written before this existed.
  final String visitId;

  bool get inVisit => visitId.isNotEmpty;

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

  /// Photos of the phone as it came in — cracks, dents, a missing back —
  /// uploaded addresses. What it looked like settles "it wasn't like that".
  final List<String> photos;

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

  /// Paid at the counter when the phone was taken in. Indian repair shops
  /// commonly take one for parts; without a place for it the advance lived in
  /// somebody's memory and the customer was asked for the full amount again.
  final num advancePaid;

  /// How the advance was paid — counted on the day the phone came in.
  final String advanceMethod;

  /// What was paid when the phone was handed back, how, and when. Null until
  /// then, or when nothing was left to pay.
  final Collection? pickupPayment;

  /// Parts taken from the shop's stock for this job. Their cost is part of
  /// [costs], so the job's profit counts the battery that went into it.
  final List<PartUse> partsUsed;

  num get partsCost =>
      partsUsed.fold<num>(0, (s, p) => s + p.unitCost * p.quantity);

  /// The shop's repair warranty on this job, in days, copied from settings
  /// when it was handed back. 0 is none.
  final int warrantyDays;

  final String status;
  final String technician;

  /// The staff member [technician] names, by account: their phone gets the
  /// job's reminders and alarms. Empty on a name typed before technicians
  /// were linked to staff, or when nobody is on it.
  final String technicianUid;

  /// When the job was last given to [technicianUid].
  final DateTime? assignedAt;

  /// Who gave it to them (account id): their own phone does not announce a
  /// job somebody gave to themselves.
  final String assignedBy;

  /// Who did what to this job, and when (repair_history.dart).
  final List<RepairEvent> history;

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
  num get costs => rawMaterialCost + outsideLabourCost + partsCost;

  /// Profit at the estimate, which is what the counter quotes against. Shown
  /// live on the intake form so a quote below cost is visible before it is
  /// given, not after.
  num get estimatedProfit => estimatedPrice - costs;

  /// What the customer still pays at pickup: the charge (or, until it is set,
  /// the estimate) less the advance. Never below zero — an advance larger
  /// than the bill is change to give back, which [advanceExceedsCharge] says.
  num get toCollect {
    final due = (finalPrice ?? estimatedPrice) - advancePaid;
    return due < 0 ? 0 : due;
  }

  /// More was taken in advance than the job is charged at.
  bool get advanceExceedsCharge =>
      advancePaid > 0 && advancePaid > (finalPrice ?? estimatedPrice);

  /// The last day of the shop's repair warranty, or null when there is none:
  /// no warranty given, or the job was not completed (a phone returned
  /// unrepaired has no repair to guarantee).
  DateTime? get warrantyUntil {
    final done = completedAt;
    if (warrantyDays <= 0 || done == null || status != 'Completed') return null;
    return DateTime(done.year, done.month, done.day + warrantyDays);
  }

  /// Still covered on [now] — through the end of the last day.
  bool underWarrantyAt(DateTime now) {
    final until = warrantyUntil;
    return until != null && now.isBefore(until.add(const Duration(days: 1)));
  }

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
    List<String>? photos,
    List<String>? complaints,
    String? complaintNotes,
    num? estimatedPrice,
    num? rawMaterialCost,
    num? outsideLabourCost,
    num? finalPrice,
    num? advancePaid,
    String? advanceMethod,
    Collection? pickupPayment,
    List<PartUse>? partsUsed,
    int? warrantyDays,
    String? status,
    String? technician,
    String? technicianUid,
    DateTime? assignedAt,
    String? assignedBy,
    List<RepairEvent>? history,
    Map<String, bool>? checklist,
    DateTime? receivedAt,
    DateTime? expectedCompletionAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? visitId,
    List<Collection>? payments,
  }) => ServiceOrder(
    id: id,
    visitId: visitId ?? this.visitId,
    payments: payments ?? this.payments,
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
    photos: photos ?? this.photos,
    complaints: complaints ?? this.complaints,
    complaintNotes: complaintNotes ?? this.complaintNotes,
    estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    rawMaterialCost: rawMaterialCost ?? this.rawMaterialCost,
    outsideLabourCost: outsideLabourCost ?? this.outsideLabourCost,
    finalPrice: finalPrice ?? this.finalPrice,
    advancePaid: advancePaid ?? this.advancePaid,
    advanceMethod: advanceMethod ?? this.advanceMethod,
    pickupPayment: pickupPayment ?? this.pickupPayment,
    partsUsed: partsUsed ?? this.partsUsed,
    warrantyDays: warrantyDays ?? this.warrantyDays,
    status: status ?? this.status,
    technician: technician ?? this.technician,
    technicianUid: technicianUid ?? this.technicianUid,
    assignedAt: assignedAt ?? this.assignedAt,
    assignedBy: assignedBy ?? this.assignedBy,
    history: history ?? this.history,
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
    photos: _strings(map['photos']),
    complaints: _strings(map['complaints']),
    complaintNotes: _str(map['complaintNotes']),
    estimatedPrice: asAmount(map['estimatedPrice']),
    rawMaterialCost: asAmount(map['rawMaterialCost']),
    outsideLabourCost: asAmount(map['outsideLabourCost']),
    finalPrice: map['finalPrice'] == null ? null : asAmount(map['finalPrice']),
    advancePaid: asAmount(map['advancePaid']),
    advanceMethod: _str(map['advanceMethod']).isEmpty
        ? 'Cash'
        : _str(map['advanceMethod']),
    pickupPayment: map['pickupPayment'] is Map
        ? Collection.fromMap(
            Map<String, Object?>.from(map['pickupPayment'] as Map),
          )
        : null,
    partsUsed: map['partsUsed'] is Iterable
        ? [
            for (final e in map['partsUsed'] as Iterable)
              if (e is Map) PartUse.fromMap(Map<String, Object?>.from(e)),
          ]
        : const [],
    warrantyDays: map['warrantyDays'] is num
        ? (map['warrantyDays'] as num).toInt()
        : 0,
    // An order carrying a status this build has never seen keeps it: the
    // list shows it rather than dropping the row.
    status: _str(map['status']).isEmpty ? 'Received' : _str(map['status']),
    technician: _str(map['technician']),
    technicianUid: _str(map['technicianUid']),
    assignedAt: normalizeDate(map['assignedAt']),
    assignedBy: _str(map['assignedBy']),
    history: map['history'] is Iterable
        ? [
            for (final e in map['history'] as Iterable)
              if (e is Map) ?RepairEvent.fromMap(Map<String, Object?>.from(e)),
          ]
        : const [],
    checklist: _ticks(map['checklist']),
    receivedAt: normalizeDate(map['receivedAt']),
    expectedCompletionAt: normalizeDate(map['expectedCompletionAt']),
    completedAt: normalizeDate(map['completedAt']),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
    visitId: _str(map['visitId']),
    payments: map['payments'] is Iterable
        ? [
            for (final e in map['payments'] as Iterable)
              if (e is Map) Collection.fromMap(Map<String, Object?>.from(e)),
          ]
        : const [],
  );

  Map<String, Object?> toMap() => {
    'orderNumber': orderNumber,
    if (visitId.isNotEmpty) 'visitId': visitId,
    if (payments.isNotEmpty) 'payments': [for (final p in payments) p.toMap()],
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'brand': brand,
    'model': model,
    'imei': imei,
    'lockType': lockType,
    'lockValue': lockValue,
    'accessories': accessories,
    'photos': photos,
    'complaints': complaints,
    'complaintNotes': complaintNotes,
    'estimatedPrice': estimatedPrice,
    'rawMaterialCost': rawMaterialCost,
    'outsideLabourCost': outsideLabourCost,
    'finalPrice': finalPrice,
    'advancePaid': advancePaid,
    'advanceMethod': advanceMethod,
    'pickupPayment': pickupPayment?.toMap(),
    'partsUsed': [for (final p in partsUsed) p.toMap()],
    'warrantyDays': warrantyDays,
    'status': status,
    'technician': technician,
    'technicianUid': technicianUid,
    'assignedAt': assignedAt?.toIso8601String(),
    'assignedBy': assignedBy,
    if (history.isNotEmpty) 'history': [for (final e in history) e.toMap()],
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

/// A phone being taken in that this shop repaired before and that is still
/// under the shop's warranty — matched by IMEI, newest job first. Null when
/// there is none. The intake form shows it, so a warranty claim is noticed
/// at the counter instead of being charged again.
ServiceOrder? warrantyMatch(
  Iterable<ServiceOrder> orders,
  String imei, {
  required DateTime now,
  String? excludeId,
}) {
  final digits = imei.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 14) return null;
  final hits =
      orders
          .where(
            (o) =>
                o.id != excludeId && o.imei == digits && o.underWarrantyAt(now),
          )
          .toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  return hits.isEmpty ? null : hits.first;
}

/// The money a repair brought in, each with its day and method: the advance
/// on the day the phone came in, and what was paid at pickup on the day it
/// went back. What Reports adds to the drawer.
List<Collection> repairPayments(ServiceOrder o) => [
  ...advanceLedger(o),
  if (o.pickupPayment != null && o.pickupPayment!.amount > 0) o.pickupPayment!,
];

/// The job's advance payments as dated entries: [ServiceOrder.payments], or
/// for a job written before them, its advance on the day it came in.
List<Collection> advanceLedger(ServiceOrder o) => o.payments.isNotEmpty
    ? o.payments
    : [
        if (o.advancePaid > 0)
          Collection(
            amount: o.advancePaid,
            method: o.advanceMethod,
            at: o.receivedAt ?? o.createdAt,
          ),
      ];

/// [o]'s ledger with one more entry — a correction, a refund, change.
List<Collection> withPayment(ServiceOrder o, Collection entry) => [
  ...advanceLedger(o),
  if (entry.amount != 0) entry,
];

/// The ledger for a job saved from the form with [advance] by [method]:
/// the first advance taken now, or an edit recorded as the difference, on
/// the day it was made — never by rewriting the earlier entry.
List<Collection> advanceAfterEdit(
  ServiceOrder? before,
  num advance,
  String method,
  DateTime now,
) {
  if (before == null) {
    return [
      if (advance > 0) Collection(amount: advance, method: method, at: now),
    ];
  }
  final delta = roundMoney(advance - before.advancePaid);
  return withPayment(
    before,
    Collection(amount: delta, method: method, at: now),
  );
}

/// Handed back at pickup when the advance was more than the charge.
num changeOnHandover(ServiceOrder o) {
  final c = o.advancePaid - (o.finalPrice ?? o.estimatedPrice);
  return c > 0 ? roundMoney(c) : 0;
}

/// One part taken from stock for a job.
class PartUse {
  const PartUse({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitCost,
    this.at,
  });

  final String productId;
  final String name;
  final int quantity;

  /// The product's cost price when it was used, kept so a later price change
  /// does not rewrite what this job cost.
  final num unitCost;
  final DateTime? at;

  factory PartUse.fromMap(Map<String, Object?> m) => PartUse(
    productId: (m['productId'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    quantity: m['quantity'] is num ? (m['quantity'] as num).toInt() : 1,
    unitCost: asAmount(m['unitCost']),
    at: normalizeDate(m['at']),
  );

  Map<String, Object?> toMap() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'unitCost': unitCost,
    'at': at?.toIso8601String(),
  };
}

/// What repairs brought in on [day] — advances taken that day and balances
/// paid at pickup that day. Home shows it beside the bills, which do not
/// include repair money.
num repairTakingsOn(Iterable<ServiceOrder> orders, DateTime day) {
  num sum = 0;
  for (final o in orders) {
    for (final p in repairPayments(o)) {
      final at = p.at;
      if (at != null &&
          at.year == day.year &&
          at.month == day.month &&
          at.day == day.day) {
        sum += p.amount;
      }
    }
  }
  return sum;
}

/// Every job in [order]'s visit, [order] included, oldest first; just
/// [order] when it came in alone.
List<ServiceOrder> visitOf(ServiceOrder order, Iterable<ServiceOrder> all) {
  if (!order.inVisit) return [order];
  final jobs = [
    for (final o in all)
      if (o.visitId == order.visitId || o.id == order.visitId) o,
  ];
  if (!jobs.any((o) => o.id == order.id)) jobs.add(order);
  jobs.sort(
    (a, b) => (a.createdAt ?? a.receivedAt ?? DateTime(0)).compareTo(
      b.createdAt ?? b.receivedAt ?? DateTime(0),
    ),
  );
  return jobs;
}
