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
import '../common/money.dart';
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
    this.paidBy,
    this.collections = const [],
    this.status = SaleStatus.draft,
    this.notes = '',
    this.interState = false,
    this.pendingCompletion = false,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// The customer is in another state: the bill's GST is IGST, not CGST
  /// plus SGST. Only printed when the shop charges GST.
  final bool interState;

  /// "Complete sale" was pressed with no internet: the bill is kept as a
  /// draft on the phone and completed automatically once the server can be
  /// reached (pending_bills.dart). Stock has not moved yet.
  final bool pendingCompletion;

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

  /// HOW THE MONEY AT THE COUNTER CAME IN, BY METHOD
  ///
  /// {Cash: 500, UPI: 166} — the counter money only (not the wallet, not
  /// the financier), after any change was given back. Reports read this,
  /// so a split payment lands in each method's row and a financed sale's
  /// down payment is in the drawer. Null on bills written before it
  /// existed, which Reports read the old way.
  final Map<String, num>? paidBy;

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

  /// Money taken against this bill AFTER it was completed — a balance
  /// collected days later — each with its own day and method. Included in
  /// [amountPaid]; kept apart so Reports counts it on the day it came in, by
  /// how it came in, instead of on the day of the bill.
  final List<Collection> collections;

  /// Part of [amountPaid] that came in later, through [collections].
  num get collectedLater => collections.fold<num>(0, (s, c) => s + c.amount);

  Sale copyWith({
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<SaleItem>? items,
    String? paymentMethod,
    num? amountPaid,
    num? walletUsed,
    Map<String, num>? paidBy,
    List<Collection>? collections,
    SaleStatus? status,
    String? notes,
    bool? interState,
    bool? pendingCompletion,
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
    paidBy: paidBy ?? this.paidBy,
    collections: collections ?? this.collections,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    interState: interState ?? this.interState,
    pendingCompletion: pendingCompletion ?? this.pendingCompletion,
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
    paidBy: map['paidBy'] is Map
        ? {
            for (final e in (map['paidBy'] as Map).entries)
              if (asAmount(e.value) > 0) '${e.key}': asAmount(e.value),
          }
        : null,
    collections: map['collections'] is Iterable
        ? [
            for (final e in map['collections'] as Iterable)
              if (e is Map) Collection.fromMap(Map<String, Object?>.from(e)),
          ]
        : const [],
    // An unrecognised status reads as a draft, which is the state that
    // moves nothing. Guessing "completed" would take stock down twice.
    status: switch ((map['status'] ?? '').toString()) {
      'completed' => SaleStatus.completed,
      'cancelled' => SaleStatus.cancelled,
      _ => SaleStatus.draft,
    },
    notes: (map['notes'] ?? '').toString().trim(),
    interState: map['interState'] == true,
    pendingCompletion: map['pendingCompletion'] == true,
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
    if (paidBy != null) 'paidBy': paidBy,
    'collections': [for (final c in collections) c.toMap()],
    'status': status.name,
    'notes': notes,
    'interState': interState,
    'pendingCompletion': pendingCompletion,
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
  if (sale.walletUsed > sale.total) {
    errors['walletUsed'] = 'More from the wallet than the whole bill';
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

/// WHAT A BILL RECORDS AS PAID
///
/// From what was typed at the counter. The rules:
///
/// - **The wallet is on top of the counter money**, never inside it: ₹100
///   from the wallet and the rest at the counter pays a ₹300 bill in full.
/// - **Nothing typed means paid in full** — except on a financed sale, where
///   the box is the down payment and nothing typed means none.
/// - **More than is owed is change, not takings.** ₹9,999 handed over for a
///   ₹750 bill records ₹750; the ₹9,249 goes back to the customer.
/// - **Split** is the amounts by each method, added up.
/// - A **financed** sale's down payment is counter money (by
///   [downPaymentMethod]); the financier pays the rest of the bill.
class BillPayment {
  const BillPayment({
    required this.amountPaid,
    required this.paidBy,
    required this.change,
  });

  /// Counter money kept + wallet: what goes on the bill as paid.
  final num amountPaid;

  /// The counter money kept, by method.
  final Map<String, num> paidBy;

  /// Handed back to the customer.
  final num change;
}

BillPayment settleBill({
  required num total,
  required String method,
  required String typed,
  num wallet = 0,
  Map<String, String> splitTyped = const {},
  String downPaymentMethod = 'Cash',
}) {
  final owedAtCounter = total - wallet < 0 ? 0 : total - wallet;
  final finance = isFinanceMethod(method);
  // What came in at the counter, by method, before any change.
  final Map<String, num> given;
  if (method == 'Split') {
    given = {
      for (final e in splitTyped.entries)
        if (asAmount(e.value) > 0) e.key: asAmount(e.value),
    };
  } else if (finance) {
    final down = typed.trim().isEmpty ? 0 : asAmount(typed);
    given = {if (down > 0) downPaymentMethod: down};
  } else {
    final paid = typed.trim().isEmpty ? owedAtCounter : asAmount(typed);
    given = {if (paid > 0) method: paid};
  }
  final handed = given.values.fold<num>(0, (a, b) => a + b);
  final change = roundMoney(
    handed > owedAtCounter ? handed - owedAtCounter : 0,
  );
  // The change comes out of cash first, then the rest in order.
  final kept = <String, num>{...given};
  var left = change;
  for (final m in ['Cash', ...kept.keys.where((k) => k != 'Cash')]) {
    if (left <= 0) break;
    final have = kept[m] ?? 0;
    final take = have < left ? have : left;
    if (take > 0) {
      kept[m] = roundMoney(have - take);
      left = roundMoney(left - take);
    }
  }
  kept.removeWhere((_, v) => v <= 0);
  final counter = kept.values.fold<num>(0, (a, b) => a + b);
  return BillPayment(
    amountPaid: roundMoney(counter + wallet),
    paidBy: kept,
    change: change,
  );
}

/// One later payment against a bill.
class Collection {
  const Collection({required this.amount, required this.method, this.at});

  final num amount;
  final String method;
  final DateTime? at;

  factory Collection.fromMap(Map<String, Object?> m) => Collection(
    amount: asAmount(m['amount']),
    method: (m['method'] ?? 'Cash').toString(),
    at: normalizeDate(m['at']),
  );

  Map<String, Object?> toMap() => {
    'amount': amount,
    'method': method,
    'at': at?.toIso8601String(),
  };
}

/// HOW MUCH OF EACH PRODUCT THE WHOLE BILL TAKES
///
/// A product added on two lines (5 cables, then 5 more) is checked against
/// the shelf as 10, not as 5 twice — checked line by line, a shelf of 5
/// let 10 go out.
Map<String, int> productQuantities(Sale sale) {
  final out = <String, int>{};
  for (final line in sale.stockLines) {
    if (line.source != LineSource.product) continue;
    final id = line.recordId ?? '';
    out[id] = (out[id] ?? 0) + line.effectiveQuantity;
  }
  return out;
}

/// Handset lines that repeat an earlier line's handset: one phone cannot be
/// sold twice on the same bill.
List<SaleItem> repeatedHandsets(Sale sale) {
  final seen = <String>{};
  return [
    for (final line in sale.stockLines)
      if (line.source == LineSource.secondHand &&
          !seen.add(line.recordId ?? line.imei ?? line.description))
        line,
  ];
}
