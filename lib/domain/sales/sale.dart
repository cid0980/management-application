/// ONE SALE
///
/// A bill at the counter. It has two lives, and the difference between them is
/// the most important rule in this area:
///
/// **A sale being built moves nothing. A completed sale moves stock.**
///
/// Stock used to come down as each line was added, which meant abandoning a
/// half-built bill — a customer changing their mind, a staff member closing
/// the sheet — left the shop short of stock it still had on the shelf, and a
/// second-hand handset marked sold that was still in the cabinet. Nothing
/// moves until the sale is completed, and completing it is one step that does
/// all of it.
library;

import '../common/dates.dart';
import '../common/phone.dart';
import '../common/search.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import 'payment_methods.dart';
import 'sale_item.dart';

/// Where a bill is up to.
enum SaleStatus {
  /// Being built. Nothing has moved.
  draft,

  /// Done. Stock has come down and any handset is marked sold.
  completed,

  /// Reversed after completion. Kept rather than deleted — a bill that was
  /// given to a customer and then cancelled is part of the day's record, and
  /// deleting it is how a till came up short with nothing to explain it.
  cancelled,
}

class Sale {
  const Sale({
    required this.id,
    this.invoiceNumber = '',
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.items = const [],
    this.paymentMethod = 'Cash',
    this.amountPaid = 0,
    this.walletUsed = 0,
    this.status = SaleStatus.draft,
    this.notes = '',
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// `INV-20260304-007`, off the atomic counter. Assigned when the sale is
  /// COMPLETED, not when the bill is started: a half-built bill that was
  /// abandoned must not burn an invoice number out of the day's sequence.
  final String invoiceNumber;

  final String? customerId;
  final String customerName;
  final String customerPhone;

  final List<SaleItem> items;

  final String paymentMethod;

  /// What the customer handed over at the counter, wallet included.
  final num amountPaid;

  /// How much of [amountPaid] came out of the customer's wallet. Recorded
  /// separately because the wallet move is its own ledger entry.
  final num walletUsed;

  final SaleStatus status;
  final String notes;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BillTotals get totals => billTotals(items);

  num get total => totals.total;

  bool get isFinanced => isFinanceMethod(paymentMethod);

  bool get completed => status == SaleStatus.completed;
  bool get cancelled => status == SaleStatus.cancelled;

  /// What the CUSTOMER still owes the shop.
  ///
  /// A financed sale is zero: the customer pays the financier, and what the
  /// financier owes the shop is a different ledger. This is why a financed
  /// sale must never appear in Due Payments, which chases customers.
  num get balanceDue =>
      balanceDueFor(total: total, paid: amountPaid, method: paymentMethod);

  /// Paid in full as far as the customer is concerned.
  bool get settled => balanceDue <= 0;

  /// The handset records this bill will mark sold on completion.
  List<SaleItem> get stockLines => [
    for (final i in items)
      if (i.movesStock) i,
  ];

  String get title => invoiceNumber.isEmpty ? 'Draft bill' : invoiceNumber;

  bool matches(String? query) => matchesQuery(query, [
    invoiceNumber,
    customerName,
    customerPhone,
    paymentMethod,
    for (final i in items) i.description,
    for (final i in items) i.imei,
  ]);

  Sale copyWith({
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<SaleItem>? items,
    String? paymentMethod,
    num? amountPaid,
    num? walletUsed,
    SaleStatus? status,
    String? notes,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) => Sale(
    id: id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    items: items ?? this.items,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    amountPaid: amountPaid ?? this.amountPaid,
    walletUsed: walletUsed ?? this.walletUsed,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Sale fromMap(String id, Map<String, Object?> map) => Sale(
    id: id,
    invoiceNumber: (map['invoiceNumber'] ?? '').toString().trim(),
    customerId: map['customerId'] as String?,
    customerName: (map['customerName'] ?? '').toString().trim(),
    customerPhone: normalizePhone((map['customerPhone'] ?? '').toString()),
    items: map['items'] is Iterable
        ? [
            for (final e in map['items'] as Iterable)
              if (e is Map) SaleItem.fromMap(Map<String, Object?>.from(e)),
          ]
        : const [],
    paymentMethod: (map['paymentMethod'] ?? 'Cash').toString().trim(),
    amountPaid: asAmount(map['amountPaid']),
    walletUsed: asAmount(map['walletUsed']),
    // An unrecognised status reads as a draft, which is the state that
    // moves nothing. Guessing "completed" would take stock down twice.
    status: switch ((map['status'] ?? '').toString()) {
      'completed' => SaleStatus.completed,
      'cancelled' => SaleStatus.cancelled,
      _ => SaleStatus.draft,
    },
    notes: (map['notes'] ?? '').toString().trim(),
    completedAt: normalizeDate(map['completedAt']),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'invoiceNumber': invoiceNumber,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'items': [for (final i in items) i.toMap()],
    'paymentMethod': paymentMethod,
    'amountPaid': amountPaid,
    'walletUsed': walletUsed,
    'status': status.name,
    'notes': notes,
    'total': total,
    'balanceDue': balanceDue,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

/// IS THIS BILL GOOD TO COMPLETE
///
/// One validator, as everywhere. Completing a sale is the step that moves
/// stock, so this is the gate in front of that write.
class SaleValidation {
  const SaleValidation(this.errors, this.warnings);

  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

SaleValidation validateSale(Sale sale) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  if (sale.items.isEmpty) {
    errors['items'] = 'Nothing on the bill yet';
  }

  // A customer, because a balance left on a bill belongs to somebody, and a
  // warranty claim has to find who bought the handset.
  if (sale.customerPhone.trim().isEmpty && sale.customerId == null) {
    errors['customer'] = 'A customer is needed — pick one or add them';
  }

  for (final item in sale.items) {
    if (item.description.trim().isEmpty) {
      errors['items'] = 'A line needs saying what it is';
      break;
    }
    if (item.unitPrice < 0) {
      errors['items'] = 'A line cannot have a negative price';
      break;
    }
    if (item.discountExceedsLine) {
      warnings['items'] =
          'A discount is larger than its line — it has been capped at the '
          'line total';
    }
  }

  if (!kPaymentMethods.contains(sale.paymentMethod)) {
    // Not refused: the shop may have added a financier this build has never
    // heard of. But a method nobody recognises cannot be known to be finance,
    // so it is treated as a direct payment and the counter is told.
    warnings['paymentMethod'] =
        '${sale.paymentMethod} is not one of the shop\'s payment methods — '
        'treated as a direct payment';
  }

  if (sale.amountPaid < 0) {
    errors['amountPaid'] = 'An amount paid cannot be negative';
  }
  if (sale.walletUsed > sale.amountPaid) {
    errors['walletUsed'] =
        'More taken from the wallet than the customer has paid in total';
  }

  if (sale.amountPaid > sale.total && !sale.isFinanced) {
    warnings['amountPaid'] =
        'Paid ₹${sale.amountPaid} against a ₹${sale.total} bill — '
        '₹${sale.amountPaid - sale.total} to give back';
  }

  if (sale.isFinanced) {
    // Recorded as fully paid whatever was handed over at the counter. The
    // customer owes nothing; the financier's settlement is a different ledger.
    warnings['paymentMethod'] =
        'Financed through ${sale.paymentMethod}: recorded as fully paid, and '
        'it will not appear in Due Payments';
  } else if (sale.balanceDue > 0) {
    warnings['amountPaid'] =
        '₹${sale.balanceDue} left on this bill — only an admin may collect it';
  }

  return SaleValidation(errors, warnings);
}

/// WHAT "PAID AT THE COUNTER" MEANS WHEN NOTHING IS TYPED
///
/// Most bills are paid in full on the spot. With the box starting empty and
/// read as zero, a cash sale where nobody typed the amount was recorded as
/// the customer owing all of it — it showed up in Due Payments, and the owner
/// chased a customer who had paid. So an empty box means **paid in full**
/// (less anything taken from the wallet). A credit sale is still one tap
/// away: type 0, or what was actually paid.
num amountPaidFrom(String typed, {required num total, num walletUsed = 0}) {
  if (typed.trim().isEmpty) {
    final rest = total - walletUsed;
    return rest < 0 ? 0 : rest;
  }
  return asAmount(typed);
}
