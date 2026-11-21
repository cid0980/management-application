/// ONE SECOND-HAND PURCHASE RECORD
///
/// Written by the purchase form, read by the stock list, the sale picker, the
/// scanner and the seller's declaration. It is a plain Dart object with no
/// Firestore in it, so the rules about it can be stated in a test.
///
/// Every read normalizes. Dates arrive as a Firestore `Timestamp` on documents
/// the web app wrote and as an ISO string on documents this one wrote; amounts
/// arrive as numbers or as the strings a text field held. [fromMap] is the one
/// place that has to know, and nothing downstream carries a `dynamic`.
library;

import '../common/dates.dart';
import '../common/phone.dart';
import '../common/search.dart';
import 'condition_grade.dart';
import 'imei.dart';
import 'purchase_costing.dart';
import 'stock_state.dart' as stock;

/// How the device was locked when it came in — the same vocabulary the service
/// intake uses, because it is the same question.
const List<String> kLockTypes = [
  'None',
  'PIN',
  'Password',
  'Pattern',
  'Fingerprint',
  'Face Unlock',
  'Other',
];

/// The photo slots, in the order they are taken and stored. Only the front is
/// required.
const List<String> kPhotoSlots = [
  'front',
  'back',
  'left',
  'right',
  'topBottom',
  'extra',
];

/// What [SecondHandDevice.gradeDetails] holds.
const String kWarrantyExpiry = 'warrantyExpiry';
const String kAccessories = 'accessories';
const String kConditionDescription = 'description';

class SecondHandDevice {
  const SecondHandDevice({
    required this.id,
    required this.brand,
    required this.model,
    this.variant = '',
    this.ram = '',
    this.rom = '',
    this.colour = '',
    this.imei = '',
    this.imei2 = '',
    this.serial = '',
    this.status = stock.kAvailable,
    this.grade,
    this.gradeOverridden = false,
    this.conditionAnswers = const {},
    this.repairs = const [],
    this.purchasePrice = 0,
    this.otherCost = 0,
    this.askingPrice = 0,
    this.soldPrice,
    this.photos = const [],
    this.idCardPhotos = const [],
    this.gradeDetails = const {},
    this.supplier = '',
    this.sellerCustomerId,
    this.sellerName = '',
    this.sellerPhone = '',
    this.sellerAltPhone = '',
    this.sellerIdProof = '',
    this.sellerSignature,
    this.sellerIdVerified = false,
    this.agreementAcceptedAt,
    this.labelNumber,
    this.notes = '',
    this.purchasedAt,
    this.soldAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String brand;
  final String model;

  /// Kept for records written before RAM and storage were asked for apart.
  /// New records leave it empty and carry [ram] and [rom].
  final String variant;

  /// "6GB", "128GB" — two answers, the way the box prints them and the way
  /// the shop's counter app asks for them.
  final String ram;
  final String rom;

  final String colour;
  final String imei;
  final String imei2;
  final String serial;

  /// `available` / `repairing` / `sold` — see `stock_state.dart`, which owns
  /// what each one means and which one wins.
  final String status;

  final String? grade;

  /// A human set the grade rather than the checklist computing it. Kept so the
  /// record shows which, and so reopening the form does not silently
  /// recompute over somebody's judgement.
  final bool gradeOverridden;

  final Map<String, bool?> conditionAnswers;
  final List<RepairCost> repairs;

  final num purchasePrice;
  final num otherCost;
  final num askingPrice;
  final num? soldPrice;

  /// One per slot, in [kPhotoSlots] order, empty where none was taken. The
  /// first is the front view, which the form requires — a stock row with no
  /// picture of the front is not a listing.
  final List<String> photos;

  /// The seller's ID card, front then back. Proof of who sold it, for when
  /// the police ask about a phone months later.
  final List<String> idCardPhotos;

  /// What the grade needs said: for an A, the warranty expiry and the
  /// accessories; for anything less, a description of the wear or damage.
  /// Keyed by [kGradeDetailKeys].
  final Map<String, String> gradeDetails;

  /// Who it was bought from when it is not a walk-in: a dealer, another shop.
  final String supplier;

  /// The customer record of the seller, when one was picked or created.
  final String? sellerCustomerId;

  final String sellerName;
  final String sellerPhone;
  final String sellerAltPhone;
  final String sellerIdProof;

  /// The seller's signature on the declaration, as a data URL or a stored URL.
  final String? sellerSignature;

  /// Somebody at the counter looked at the seller's government photo ID.
  final bool sellerIdVerified;

  /// When the seller agreed to the purchase declaration (it was read to
  /// them, and they accepted every line). Null when they have not.
  final DateTime? agreementAcceptedAt;

  /// The shop label assigned to this handset, once one has been printed.
  final int? labelNumber;

  final String notes;
  final DateTime? purchasedAt;
  final DateTime? soldAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// "6GB/128GB" — or the old one-box variant on records from before.
  String get memory => ram.isEmpty && rom.isEmpty
      ? variant
      : [ram, rom].where((p) => p.isNotEmpty).join('/');

  String get title =>
      [brand, model, memory].where((p) => p.isNotEmpty).join(' ');

  String get stockState => stock.stockStateOf(status);
  bool get isSellable => stock.isSellable(status);
  bool get isBeingRepaired => stock.isBeingRepaired(status);
  bool get isSold => stockState == stock.kSold;

  Costing get costing => costingOf(
    purchasePrice: purchasePrice,
    repairs: repairs,
    otherCost: otherCost,
    askingPrice: askingPrice,
    soldPrice: soldPrice,
  );

  /// The grade the checklist computes right now, override ignored. The detail
  /// page shows both when they disagree.
  GradeResult get computedGrade =>
      gradeFrom(conditionAnswers, checklist: checklistFor(brand));

  String? get frontPhoto =>
      photos.isEmpty || photos.first.isEmpty ? null : photos.first;

  /// Whether this row matches what is typed in the list's search box.
  bool matches(String? query) => matchesQuery(query, [
    brand,
    model,
    variant,
    ram,
    rom,
    colour,
    imei,
    imei2,
    serial,
    sellerName,
    sellerPhone,
    sellerAltPhone,
    supplier,
    labelNumber?.toString(),
  ]);

  SecondHandDevice copyWith({
    String? brand,
    String? model,
    String? variant,
    String? ram,
    String? rom,
    String? colour,
    String? imei,
    String? imei2,
    String? serial,
    String? status,
    String? grade,
    bool? gradeOverridden,
    Map<String, bool?>? conditionAnswers,
    List<RepairCost>? repairs,
    num? purchasePrice,
    num? otherCost,
    num? askingPrice,
    num? soldPrice,
    List<String>? photos,
    List<String>? idCardPhotos,
    Map<String, String>? gradeDetails,
    String? supplier,
    String? sellerCustomerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerAltPhone,
    String? sellerIdProof,
    String? sellerSignature,
    bool? sellerIdVerified,
    DateTime? agreementAcceptedAt,
    int? labelNumber,
    String? notes,
    DateTime? purchasedAt,
    DateTime? soldAt,
    DateTime? updatedAt,
  }) {
    return SecondHandDevice(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      ram: ram ?? this.ram,
      rom: rom ?? this.rom,
      colour: colour ?? this.colour,
      imei: imei ?? this.imei,
      imei2: imei2 ?? this.imei2,
      serial: serial ?? this.serial,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      gradeOverridden: gradeOverridden ?? this.gradeOverridden,
      conditionAnswers: conditionAnswers ?? this.conditionAnswers,
      repairs: repairs ?? this.repairs,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      otherCost: otherCost ?? this.otherCost,
      askingPrice: askingPrice ?? this.askingPrice,
      soldPrice: soldPrice ?? this.soldPrice,
      photos: photos ?? this.photos,
      idCardPhotos: idCardPhotos ?? this.idCardPhotos,
      gradeDetails: gradeDetails ?? this.gradeDetails,
      supplier: supplier ?? this.supplier,
      sellerCustomerId: sellerCustomerId ?? this.sellerCustomerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAltPhone: sellerAltPhone ?? this.sellerAltPhone,
      sellerIdProof: sellerIdProof ?? this.sellerIdProof,
      sellerSignature: sellerSignature ?? this.sellerSignature,
      sellerIdVerified: sellerIdVerified ?? this.sellerIdVerified,
      agreementAcceptedAt: agreementAcceptedAt ?? this.agreementAcceptedAt,
      labelNumber: labelNumber ?? this.labelNumber,
      notes: notes ?? this.notes,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      soldAt: soldAt ?? this.soldAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Read a document, whichever build wrote it.
  static SecondHandDevice fromMap(String id, Map<String, Object?> map) {
    return SecondHandDevice(
      id: id,
      brand: _str(map['brand']),
      model: _str(map['model']),
      variant: _str(map['variant']),
      ram: _str(map['ram']),
      rom: _str(map['rom']),
      colour: _str(map['colour'] ?? map['color']),
      imei: normalizeImei(_str(map['imei'])),
      imei2: normalizeImei(_str(map['imei2'])),
      serial: _str(map['serial']),
      // An unknown status reads as plain stock rather than throwing; the web
      // app has written values this build has never heard of before.
      status: stock.stockStateOf(_str(map['status'])),
      grade: map['grade'] as String?,
      gradeOverridden: map['gradeOverridden'] == true,
      conditionAnswers: _answers(map['conditionAnswers'] ?? map['condition']),
      repairs: _repairs(map['repairs']),
      purchasePrice: asAmount(map['purchasePrice']),
      otherCost: asAmount(map['otherCost']),
      askingPrice: asAmount(map['askingPrice'] ?? map['sellingPrice']),
      soldPrice: map['soldPrice'] == null ? null : asAmount(map['soldPrice']),
      photos: _strings(map['photos']),
      idCardPhotos: _strings(map['idCardPhotos']),
      gradeDetails: _stringMap(map['gradeDetails']),
      supplier: _str(map['supplier']),
      sellerCustomerId: map['sellerCustomerId'] as String?,
      sellerName: _str(map['sellerName']),
      sellerPhone: normalizePhone(_str(map['sellerPhone'])),
      sellerAltPhone: normalizePhone(_str(map['sellerAltPhone'])),
      sellerIdProof: _str(map['sellerIdProof']),
      sellerSignature: map['sellerSignature'] as String?,
      // The older app wrote `sellerIdVerified` too, so a record from it reads.
      sellerIdVerified: map['sellerIdVerified'] == true,
      agreementAcceptedAt: normalizeDate(map['agreementAcceptedAt']),
      labelNumber: _int(map['labelNumber']),
      notes: _str(map['notes']),
      purchasedAt: normalizeDate(map['purchasedAt']),
      soldAt: normalizeDate(map['soldAt']),
      createdAt: normalizeDate(map['createdAt']),
      updatedAt: normalizeDate(map['updatedAt']),
    );
  }

  /// Write a document. Dates go out as ISO strings so a record written here is
  /// readable by anything that can parse one, the web app included.
  Map<String, Object?> toMap() => {
    'brand': brand,
    'model': model,
    'variant': variant,
    'ram': ram,
    'rom': rom,
    'colour': colour,
    'imei': imei,
    'imei2': imei2,
    'serial': serial,
    'status': status,
    'grade': grade,
    'gradeOverridden': gradeOverridden,
    'conditionAnswers': conditionAnswers,
    'repairs': [for (final r in repairs) r.toMap()],
    'purchasePrice': purchasePrice,
    'otherCost': otherCost,
    'askingPrice': askingPrice,
    'soldPrice': soldPrice,
    'photos': photos,
    'idCardPhotos': idCardPhotos,
    'gradeDetails': gradeDetails,
    'supplier': supplier,
    'sellerCustomerId': sellerCustomerId,
    'sellerName': sellerName,
    'sellerPhone': sellerPhone,
    'sellerAltPhone': sellerAltPhone,
    'sellerIdProof': sellerIdProof,
    'sellerSignature': sellerSignature,
    'sellerIdVerified': sellerIdVerified,
    'agreementAcceptedAt': agreementAcceptedAt?.toIso8601String(),
    'labelNumber': labelNumber,
    'notes': notes,
    'purchasedAt': purchasedAt?.toIso8601String(),
    'soldAt': soldAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

String _str(Object? v) => v == null ? '' : v.toString().trim();

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

List<String> _strings(Object? v) => v is Iterable
    ? [for (final e in v) e == null ? '' : e.toString()]
    : const [];

Map<String, String> _stringMap(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key != null && e.value != null) '${e.key}': '${e.value}',
      }
    : const {};

/// The checklist as stored: a map of key to yes/no. A key present with a null
/// value is "not answered yet", which the grade treats differently from "no".
Map<String, bool?> _answers(Object? v) {
  if (v is! Map) return const {};
  final out = <String, bool?>{};
  v.forEach((key, value) {
    final k = key?.toString();
    if (k == null || k.isEmpty) return;
    out[k] = value is bool ? value : (value == null ? null : value == true);
  });
  return out;
}

List<RepairCost> _repairs(Object? v) => v is Iterable
    ? [
        for (final e in v)
          if (e is Map) RepairCost.fromMap(Map<String, Object?>.from(e)),
      ]
    : const [];
