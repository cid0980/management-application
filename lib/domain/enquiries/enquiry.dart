/// ONE WALK-IN QUESTION
///
/// Somebody comes in and asks something the shop cannot answer on the spot:
/// whether an A54 will come in second hand, what a display costs, whether a
/// water-damaged phone is worth repairing. Writing it down is worth doing
/// because the shop can ring them when the answer changes.
///
/// The record is thin on purpose. The value is in the number and the one line
/// saying what they asked — a long form at the counter does not get filled in,
/// and an enquiry that was not written down is worth nothing at all.
library;

import '../common/money.dart';
import '../common/dates.dart';
import '../common/phone.dart';
import '../common/search.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import 'enquiry_state.dart';

/// What the enquiry is about. Decides nothing on its own — it is there so the
/// list can be read, and so "we get asked for chargers constantly" is
/// answerable.
const List<String> kEnquiryAbout = [
  'Second-hand handset',
  'New handset',
  'Repair',
  'Accessory',
  'Trade-in value',
  'Price only',
  'Other',
];

class Enquiry {
  const Enquiry({
    required this.id,
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.about = '',
    this.question = '',
    this.brand = '',
    this.model = '',
    this.budget = 0,
    this.quotedPrice = 0,
    this.status = 'Open',
    this.outcomeRef = '',
    this.notes = '',
    this.handledBy = '',
    this.askedAt,
    this.followUpAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// The customer record, when they are already in the book. Null for someone
  /// who gave a number and nothing else — which is most walk-ins, and is why
  /// the number is copied onto the enquiry as well.
  final String? customerId;
  final String customerName;
  final String customerPhone;

  final String about;

  /// What they actually asked, in their words where possible. The one field
  /// that makes the record worth keeping.
  final String question;

  final String brand;
  final String model;

  /// What they said they would spend. Zero when they did not say, which is
  /// not the same as zero budget — see [hasBudget].
  final num budget;

  final num quotedPrice;

  final String status;

  /// The sale, service order, or note saying what this became. Required to
  /// close as Won — see `wonBlockFor`.
  final String outcomeRef;

  final String notes;
  final String handledBy;

  final DateTime? askedAt;

  /// When to ring them back. The only date the list sorts on, because it is
  /// the only one that says what to do today.
  final DateTime? followUpAt;

  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// They said a number. Zero means they did not say, and quoting against a
  /// budget nobody gave is how a shop talks itself out of a sale.
  bool get hasBudget => budget > 0;

  String get device => [brand, model].where((p) => p.isNotEmpty).join(' ');

  /// One line for the list. The question leads, because that is what the
  /// person reading the list is scanning for.
  String get headline {
    final text = question.trim();
    if (text.isNotEmpty) return text;
    if (device.isNotEmpty) return 'Asked about $device';
    return about.isEmpty ? 'Walk-in enquiry' : about;
  }

  EnquiryStateView get asState =>
      EnquiryStateView(status: status, followUpAt: followUpAt);

  bool get closed => isEnquiryClosed(status);
  bool get won => isEnquiryWon(status);
  bool isOverdueAt(DateTime now) => isEnquiryOverdue(asState, now: now);
  bool isDueTodayAt(DateTime now) => isEnquiryDueToday(asState, now: now);
  EnquiryLifecycle lifecycleAt(DateTime now) =>
      enquiryStateOf(asState, now: now);

  /// Quoted above what they said they would spend. Worth seeing on the detail
  /// page — it is usually why the answer was no.
  bool get quotedOverBudget => hasBudget && quotedPrice > budget;

  bool matches(String? query) => matchesQuery(query, [
    customerName,
    customerPhone,
    about,
    question,
    brand,
    model,
    handledBy,
    outcomeRef,
    notes,
  ]);

  Enquiry copyWith({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? about,
    String? question,
    String? brand,
    String? model,
    num? budget,
    num? quotedPrice,
    String? status,
    String? outcomeRef,
    String? notes,
    String? handledBy,
    DateTime? askedAt,
    DateTime? followUpAt,
    DateTime? closedAt,
    DateTime? updatedAt,
  }) => Enquiry(
    id: id,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    about: about ?? this.about,
    question: question ?? this.question,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    budget: budget ?? this.budget,
    quotedPrice: quotedPrice ?? this.quotedPrice,
    status: status ?? this.status,
    outcomeRef: outcomeRef ?? this.outcomeRef,
    notes: notes ?? this.notes,
    handledBy: handledBy ?? this.handledBy,
    askedAt: askedAt ?? this.askedAt,
    followUpAt: followUpAt ?? this.followUpAt,
    closedAt: closedAt ?? this.closedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Enquiry fromMap(String id, Map<String, Object?> map) => Enquiry(
    id: id,
    customerId: map['customerId'] as String?,
    customerName: _str(map['customerName']),
    customerPhone: normalizePhone(_str(map['customerPhone'])),
    about: _str(map['about']),
    question: _str(map['question'] ?? map['enquiry']),
    brand: _str(map['brand']),
    model: _str(map['model']),
    budget: asAmount(map['budget']),
    quotedPrice: asAmount(map['quotedPrice']),
    // An unrecognised status is kept rather than guessed at: the list
    // shows it and `enquiryStatusOptions` offers it back.
    status: _str(map['status']).isEmpty ? 'Open' : _str(map['status']),
    outcomeRef: _str(map['outcomeRef']),
    notes: _str(map['notes']),
    handledBy: _str(map['handledBy']),
    askedAt: normalizeDate(map['askedAt']),
    followUpAt: normalizeDate(map['followUpAt']),
    closedAt: normalizeDate(map['closedAt']),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'about': about,
    'question': question,
    'brand': brand,
    'model': model,
    'budget': budget,
    'quotedPrice': quotedPrice,
    'status': status,
    'outcomeRef': outcomeRef,
    'notes': notes,
    'handledBy': handledBy,
    'askedAt': askedAt?.toIso8601String(),
    'followUpAt': followUpAt?.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static String _str(Object? v) => v == null ? '' : v.toString().trim();
}

/// IS THIS ENQUIRY GOOD TO SAVE
///
/// One validator. The bar is deliberately low: an enquiry nobody could be
/// bothered to record is worth nothing, so the only hard requirements are a
/// number to ring back on and something saying what was asked.
class EnquiryValidation {
  const EnquiryValidation(this.errors, this.warnings);

  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

EnquiryValidation validateEnquiry(Enquiry enquiry) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  // The whole point is being able to ring them back.
  if (enquiry.customerPhone.trim().isEmpty && enquiry.customerId == null) {
    errors['customerPhone'] =
        'A number is needed — the point of recording this is ringing them back';
  } else if (enquiry.customerId == null &&
      !isDiallablePhone(enquiry.customerPhone)) {
    errors['customerPhone'] = 'That is not a ten-digit mobile number';
  }

  if (enquiry.question.trim().isEmpty && enquiry.about.trim().isEmpty) {
    errors['question'] = 'Say what they asked';
  }

  if (enquiry.budget < 0 || enquiry.quotedPrice < 0) {
    errors['budget'] = 'A price cannot be negative';
  }

  // Won needs something to point at. Checked here as well as at the status
  // change, so a form cannot save its way around it.
  if (enquiry.won && wonBlockFor(enquiry.outcomeRef) != null) {
    errors['outcomeRef'] = kWonBlockMessages[WonBlock.noOutcome]!;
  }

  if (enquiry.followUpAt == null && !enquiry.closed) {
    // Not refused: plenty of enquiries are answered on the spot and need no
    // ringing back. But an open one with no follow-up date will never appear
    // in anything time-based, and that is worth knowing.
    warnings['followUpAt'] =
        'No follow-up date, so this will not come up again on its own';
  }

  if (enquiry.quotedOverBudget) {
    warnings['quotedPrice'] =
        'Quoted ₹${formatIndianNumber(enquiry.quotedPrice)} against a ₹${formatIndianNumber(enquiry.budget)} budget';
  }

  if (enquiry.handledBy.trim().isEmpty) {
    warnings['handledBy'] = 'Nobody recorded as having taken this';
  }

  return EnquiryValidation(errors, warnings);
}
