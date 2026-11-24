/// WHERE SALES COME FROM
///
/// This repository owns the one step that matters in this area: **completing a
/// sale**. It is a single operation that does all of it — assign the invoice
/// number, mark every handset on the bill sold, take the wallet payment, and
/// only then record the sale as completed.
///
/// It is one operation because the alternative was several, and the shop lived
/// with the result: stock came down as each line was added, so an abandoned
/// bill left the shelf short of stock it still had, and a handset marked sold
/// that was still in the cabinet.
///
/// It is also ordered the way it is on purpose. The stock writes happen
/// FIRST. If a handset has gone out from under the bill — someone else sold it
/// while this one was being built — the completion is refused and nothing is
/// written: no invoice number burnt, no wallet taken, no sale recorded. The
/// counter is told which handset, and can take it off the bill.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/counters.dart';
import '../domain/common/phone.dart';
import '../domain/customers/wallet.dart';
import '../domain/labels/label_entry.dart';
import '../domain/sales/due_payments.dart';
import '../domain/sales/sale.dart';
import '../domain/sales/sale_item.dart';
import 'customer_repository.dart';
import 'product_repository.dart';
import 'second_hand_repository.dart';

abstract class SalesRepository extends ChangeNotifier {
  List<Sale> get sales;
  bool get loading;
  String? get error;

  Future<void> load();

  Sale? byId(String id);

  /// Where the live list starts: drafts, bills still owed, and everything
  /// touched since this. Null when every bill is loaded (in-memory store).
  DateTime? get liveSince;

  /// [byId], going to the server for a record outside the live list. Kept
  /// for the session once fetched, so [byId] finds it after.
  Future<Sale?> fetchById(String id);

  /// Bills outside the live list, from the server: a customer's (by id or
  /// number), or one invoice number. Loaded bills may come back too.
  Future<List<Sale>> fetchOlder({
    String? customerId,
    String? phone,
    String? number,
  });

  /// Bills completed between [from] and [to], for a report over an older
  /// range.
  Future<List<Sale>> fetchCompletedBetween(DateTime from, DateTime to);

  /// Save a bill as a draft. Moves nothing.
  ///
  /// A status of completed passed in here is ignored: completing is
  /// [completeSale]'s job, because that is where the stock writes are.
  Future<Sale> saveDraft(Sale sale);

  /// Complete the bill. The one step that moves stock.
  ///
  /// Returns the outcome rather than throwing on a refusal: a handset sold out
  /// from under a half-built bill is an ordinary thing at a busy counter, and
  /// the counter needs to know which one.
  Future<SaleCompletion> completeSale(Sale sale);

  /// Collect part or all of an outstanding balance. Admin only — the rule is
  /// `canCollect`'s, and this runs it.
  /// Records [amount] received against a completed bill's balance, by
  /// [method], now. Admin only.
  Future<CollectionCheck> collect(
    String id,
    Object? amount, {
    required bool isAdmin,
    String method = 'Cash',
  });

  /// The label fields for this bill, so a scanned invoice barcode opens it.
  /// Null when the bill is gone.
  Map<String, Object?>? labelSnapshot(String id);

  /// Reverse a completed sale: put the handsets back and keep the record.
  ///
  /// The bill is kept rather than deleted. A bill that was given to a customer
  /// and then cancelled is part of the day's record, and deleting it is how a
  /// till came up short with nothing to explain it.
  Future<Sale> cancelSale(String id, {required String reason});
}

/// A line that cannot be sold, and why.
///
/// The reason is carried rather than derived, because the two cases read very
/// differently at a counter: a used handset is simply gone, while a product is
/// a number — "only two left of three on the bill" tells the person serving
/// what to change, where "not available" does not.
class UnavailableLine {
  const UnavailableLine(this.item, this.reason);

  final SaleItem item;
  final String reason;
}

/// What happened when a bill was completed.
class SaleCompletion {
  const SaleCompletion.done(this.sale)
    : unavailable = const [],
      walletRefusal = null;

  const SaleCompletion.unavailable(this.unavailable)
    : sale = null,
      walletRefusal = null;

  const SaleCompletion.walletRefused(this.walletRefusal)
    : sale = null,
      unavailable = const [];

  /// The completed sale, with its invoice number. Null on a refusal.
  final Sale? sale;

  /// The lines that cannot be sold. Named, so the counter can change that one
  /// line rather than guessing.
  final List<UnavailableLine> unavailable;

  /// Why the wallet payment could not be taken, if that is what stopped it.
  final String? walletRefusal;

  bool get completed => sale != null;

  String? get message {
    if (completed) return null;
    if (walletRefusal != null) return walletRefusal;
    final lines = unavailable
        .map((u) => '${u.item.description} — ${u.reason}')
        .join('; ');
    return 'Cannot complete this bill: $lines.';
  }
}

class NoSuchSale implements Exception {
  const NoSuchSale(this.id);
  final String id;
  @override
  String toString() => 'No sale $id';
}

class InMemorySalesStore extends ChangeNotifier implements SalesRepository {
  InMemorySalesStore({
    required this.stock,
    required this.products,
    required this.customers,
    List<Sale>? seed,
    NumberCounter? counter,
    this.today,
  }) : _counter = counter ?? InMemoryCounter() {
    _sales = [...(seed ?? const [])];
  }

  /// Completing a bill writes to stock, so the sales store holds the stock
  /// store rather than a screen wiring the two together — a screen that forgot
  /// one of the writes is exactly the bug this shape prevents.
  final SecondHandRepository stock;

  /// And to new-goods stock, for the product lines on the bill.
  final ProductRepository products;

  /// And to the wallet, for the part of the payment that came out of it.
  final CustomerRepository customers;

  final NumberCounter _counter;

  /// Fixed in tests so an invoice number is predictable.
  final DateTime? today;

  late List<Sale> _sales;
  bool _loading = false;
  String? _error;

  DateTime get _now => today ?? DateTime.now();

  @override
  List<Sale> get sales => List.unmodifiable(_sales);

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
  Future<Sale?> fetchById(String id) async => byId(id);

  /// Everything is in memory: there is no window.
  @override
  DateTime? get liveSince => null;

  @override
  Future<List<Sale>> fetchOlder({
    String? customerId,
    String? phone,
    String? number,
  }) async => [
    for (final s in _sales)
      if ((customerId != null &&
              customerId.isNotEmpty &&
              s.customerId == customerId) ||
          (phone != null &&
              phone.isNotEmpty &&
              normalizePhone(s.customerPhone) == normalizePhone(phone)) ||
          (number != null && number.isNotEmpty && s.invoiceNumber == number))
        s,
  ];

  @override
  Future<List<Sale>> fetchCompletedBetween(DateTime from, DateTime to) async =>
      [
        for (final s in _sales)
          if (s.completedAt != null &&
              !s.completedAt!.isBefore(from) &&
              !s.completedAt!.isAfter(to))
            s,
      ];

  @override
  Sale? byId(String id) => _sales.where((s) => s.id == id).firstOrNull;

  @override
  Future<Sale> saveDraft(Sale sale) async {
    final existing = byId(sale.id);
    final stored = sale.copyWith(
      customerPhone: normalizePhone(sale.customerPhone),
      // A draft moves nothing, so it cannot be saved as completed.
      status: existing?.status == SaleStatus.completed
          ? SaleStatus.completed
          : SaleStatus.draft,
      // And it has no invoice number: an abandoned bill must not burn one out
      // of the day's sequence.
      invoiceNumber: existing?.invoiceNumber ?? '',
      updatedAt: DateTime.now(),
    );
    _put(stored);
    return stored;
  }

  @override
  Future<SaleCompletion> completeSale(Sale sale) async {
    final existing = byId(sale.id);
    if (existing != null && existing.completed) {
      // Already done. Completing twice would take the stock down twice.
      return SaleCompletion.done(existing);
    }

    // 1. Check every stock line BEFORE writing anything.
    final unavailable = <UnavailableLine>[];
    final wanted = productQuantities(sale);
    for (final line in repeatedHandsets(sale)) {
      unavailable.add(UnavailableLine(line, 'on this bill twice'));
    }
    for (final line in sale.stockLines) {
      switch (line.source) {
        case LineSource.secondHand:
          final device = stock.byId(line.recordId ?? '');
          if (device == null) {
            unavailable.add(
              const UnavailableLine(
                SaleItem(description: 'A handset on this bill', unitPrice: 0),
                'the record is gone',
              ),
            );
          } else if (!device.isSellable) {
            unavailable.add(
              UnavailableLine(
                line,
                device.isSold
                    ? 'already sold'
                    : 'on the bench, not ready to sell',
              ),
            );
          }

        case LineSource.product:
          // Checked against the count, not a status: a product is a number,
          // and the useful answer names it.
          final product = products.byId(line.recordId ?? '');
          if (product == null) {
            unavailable.add(UnavailableLine(line, 'the product is gone'));
          } else if (product.stockCount <
              (wanted[line.recordId ?? ''] ?? line.effectiveQuantity)) {
            // The whole bill's quantity of it, every line together.
            unavailable.add(
              UnavailableLine(
                line,
                'only ${product.stockCount} left, '
                '${wanted[line.recordId ?? '']} on the bill',
              ),
            );
          }

        case LineSource.manual:
          break;
      }
    }
    if (unavailable.isNotEmpty) {
      return SaleCompletion.unavailable(unavailable);
    }

    // 2. The wallet, which can also refuse. Still nothing written to the sale.
    if (sale.walletUsed > 0) {
      final customerId = sale.customerId;
      if (customerId == null) {
        return const SaleCompletion.walletRefused(
          'A wallet payment needs a customer record to take it from',
        );
      }
      final result = await customers.moveWallet(
        customerId,
        WalletMove(
          kind: WalletMoveKind.debit,
          amount: sale.walletUsed,
          reason: 'Against this bill',
          reference: sale.id,
        ),
      );
      if (!result.allowed) {
        return SaleCompletion.walletRefused(result.refusalMessage!);
      }
    }

    // 3. Mark the handsets sold at the price they went out at, and take the
    //    product quantities off the shelf. Both only now, and both for the
    //    same reason: a bill being built must move nothing.
    for (final line in sale.stockLines) {
      switch (line.source) {
        case LineSource.secondHand:
          await stock.markSold(line.recordId!, soldPrice: line.total);
        case LineSource.product:
          await products.sell(
            line.recordId!,
            quantity: line.effectiveQuantity,
            saleId: sale.id,
          );
        case LineSource.manual:
          break;
      }
    }

    // 4. Only now does the sale become a sale, and only now does it get a
    //    number.
    final day = _now;
    final sequence = await _counter.next(dailyCounterKey('invoice', day));
    final now = DateTime.now();
    final completed = sale.copyWith(
      invoiceNumber: invoiceNumber(day, sequence),
      customerPhone: normalizePhone(sale.customerPhone),
      status: SaleStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    _put(completed);
    return SaleCompletion.done(completed);
  }

  @override
  Future<CollectionCheck> collect(
    String id,
    Object? amount, {
    required bool isAdmin,
    String method = 'Cash',
  }) async {
    final sale = byId(id);
    if (sale == null) throw NoSuchSale(id);

    final check = canCollect(sale, amount, isAdmin: isAdmin);
    if (!check.isAllowed) return check;

    final now = DateTime.now();
    _put(
      sale.copyWith(
        amountPaid: sale.total - check.remaining,
        collections: [
          ...sale.collections,
          Collection(
            amount: sale.balanceDue - check.remaining,
            method: method,
            at: now,
          ),
        ],
        updatedAt: now,
      ),
    );
    return check;
  }

  @override
  Future<Sale> cancelSale(String id, {required String reason}) async {
    final sale = byId(id);
    if (sale == null) throw NoSuchSale(id);
    if (!sale.completed) {
      // A draft never moved anything, so there is nothing to put back.
      final cancelled = sale.copyWith(
        status: SaleStatus.cancelled,
        notes: _withReason(sale.notes, reason),
        updatedAt: DateTime.now(),
      );
      _put(cancelled);
      return cancelled;
    }

    // Put the stock back. Handsets go through the one door that can un-sell
    // them — an ordinary save cannot, because `statusForSave` leaves a sold
    // device sold, which is the whole point of it. Product quantities go back
    // as a `returned` movement, so the history says why the count moved.
    for (final line in sale.stockLines) {
      switch (line.source) {
        case LineSource.secondHand:
          if (stock.byId(line.recordId ?? '') == null) continue;
          await stock.returnToStock(
            line.recordId!,
            reason: 'bill ${sale.invoiceNumber} cancelled',
          );
        case LineSource.product:
          if (products.byId(line.recordId ?? '') == null) continue;
          await products.returnStock(
            line.recordId!,
            quantity: line.effectiveQuantity,
            reason: 'Bill ${sale.invoiceNumber} cancelled',
            reference: sale.id,
          );
        case LineSource.manual:
          break;
      }
    }

    final cancelled = sale.copyWith(
      status: SaleStatus.cancelled,
      notes: _withReason(sale.notes, reason),
      updatedAt: DateTime.now(),
    );
    _put(cancelled);
    return cancelled;
  }

  static String _withReason(String notes, String reason) => [
    notes,
    if (reason.trim().isNotEmpty) 'Cancelled: ${reason.trim()}',
  ].where((p) => p.isNotEmpty).join('\n');

  @override
  Map<String, Object?>? labelSnapshot(String id) {
    final sale = byId(id);
    if (sale == null) return null;
    return {
      kLabelTitle: sale.title,
      kLabelSubtitle: [
        if (sale.customerName.isNotEmpty) sale.customerName,
        '${sale.totals.lineCount} item(s)',
      ].join(' · '),
      kLabelPrice: sale.total,
      kLabelStatus: switch (sale.status) {
        SaleStatus.draft => 'Draft',
        SaleStatus.completed => 'Completed',
        SaleStatus.cancelled => 'Cancelled',
      },
    };
  }

  void _put(Sale sale) {
    final index = _sales.indexWhere((s) => s.id == sale.id);
    if (index >= 0) {
      _sales[index] = sale;
    } else {
      _sales.add(sale);
    }
    notifyListeners();
  }
}
