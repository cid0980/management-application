/// SALES, OUT OF FIRESTORE
///
/// The same `SalesRepository` the screens already talk to, backed by
/// `shops/{shopId}/sales`. The order of the work in [completeSale] is the
/// whole file, and it is the same order the in-memory store does it in:
///
///   1. check every stock line, writing nothing,
///   2. take the wallet part, which can also refuse,
///   3. move the stock,
///   4. and only then does the bill become a sale and get its number.
///
/// **Stock moves only when a sale is completed.** A bill being built moves
/// nothing: the shop's old app took the handset off the shelf as soon as it
/// was added to a bill, so an abandoned bill hid a phone that was sitting in
/// the cabinet.
///
/// **An invoice number is minted last, off the counter.** An abandoned bill
/// must not burn a number out of the day's sequence, and a number handed out
/// twice is two bills the shop cannot tell apart.
///
/// **The writes to stock, products and the wallet go through those
/// repositories**, which is why this one holds them rather than a screen
/// wiring the four together. Each of those writes is a transaction of its own
/// — "sold always wins", "never below zero", "a wallet move below zero is
/// refused" — so a race on any one of them is settled where that rule lives.
///
/// Firestore has no transaction across all four, and this does not pretend to:
/// the checks in step 1 are what keep the ordinary case honest, and a line
/// that becomes unavailable in the half-second after it was checked is
/// refused by the stock repository itself rather than quietly oversold.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/money.dart';
import '../domain/common/counters.dart';
import '../domain/common/phone.dart';
import '../domain/customers/wallet.dart';
import '../domain/labels/label_entry.dart';
import '../domain/sales/due_payments.dart';
import '../domain/sales/sale.dart';
import '../domain/sales/sale_item.dart';
import 'customer_repository.dart';
import 'firestore_counter.dart';
import 'firestore_errors.dart';
import 'live_window.dart';
import 'firestore_paths.dart';
import 'product_repository.dart';
import 'sales_repository.dart';
import 'second_hand_repository.dart';

class FirestoreSalesStore extends ChangeNotifier implements SalesRepository {
  FirestoreSalesStore({
    required this.scope,
    required this.stock,
    required this.products,
    required this.customers,
    NumberCounter? counter,
    this.today,
  }) : _counter = counter ?? FirestoreCounter(scope: scope);

  /// This shop, and only this shop.
  final ShopScope scope;

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

  List<Sale> _sales = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;

  DateTime get _now => today ?? DateTime.now();

  @override
  List<Sale> get sales => List.unmodifiable(_sales);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // Drafts and bills still owed, of any age, and anything touched in the
    // last 90 days: the live window (live_window.dart). Due Payments reads
    // every bill with a balance, so those are always in.
    final since = liveWindowStart(DateTime.now());
    _since = DateTime.now().subtract(kLiveWindow);
    _window = MergedListener(
      queries: [
        scope.sales.where('status', isEqualTo: SaleStatus.draft.name),
        scope.sales.where('balanceDue', isGreaterThan: 0),
        scope.sales.where('updatedAt', isGreaterThanOrEqualTo: since.iso),
        scope.sales.where('updatedAt', isGreaterThanOrEqualTo: since.ts),
      ],
      onData: (docs) {
        _sales = [for (final doc in docs) Sale.fromMap(doc.id, doc.data())];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'sales');
        notifyListeners();
      },
    )..start();
  }

  MergedListener? _window;
  DateTime? _since;

  @override
  DateTime? get liveSince => _since;

  @override
  Future<List<Sale>> fetchOlder({
    String? customerId,
    String? phone,
    String? number,
  }) async {
    final queries = [
      if (customerId != null && customerId.isNotEmpty)
        scope.sales.where('customerId', isEqualTo: customerId),
      if (phone != null && phone.isNotEmpty)
        scope.sales.where('customerPhone', isEqualTo: normalizePhone(phone)),
      if (number != null && number.isNotEmpty)
        scope.sales.where('invoiceNumber', isEqualTo: number.trim()),
    ];
    final results = [for (final q in queries) (await q.get()).docs];
    return [
      for (final doc in merged(results)) Sale.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<List<Sale>> fetchCompletedBetween(DateTime from, DateTime to) async {
    final snap = await scope.sales
        .where('completedAt', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('completedAt', isLessThanOrEqualTo: to.toIso8601String())
        .get();
    return [for (final doc in snap.docs) Sale.fromMap(doc.id, doc.data())];
  }

  @override
  Sale? byId(String id) {
    for (final sale in _sales) {
      if (sale.id == id) return sale;
    }
    return _fetched[id];
  }

  /// Records outside the live list, fetched one at a time by [fetchById].
  final Map<String, Sale> _fetched = {};

  @override
  Future<Sale?> fetchById(String id) async {
    final known = byId(id);
    if (known != null) return known;
    final doc = await scope.sales.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    final record = Sale.fromMap(id, data);
    _fetched[id] = record;
    notifyListeners();
    return record;
  }

  @override
  Future<Sale> saveDraft(Sale sale) async {
    final existing = await _stored(sale.id);
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
    await _write(stored, isNew: existing == null);
    return stored;
  }

  @override
  Future<SaleCompletion> completeSale(Sale sale) async {
    // Read from Firestore rather than from the cache: completing twice would
    // take the stock down twice, and the other till may have completed this
    // bill a moment ago.
    final existing = await _stored(sale.id);
    if (existing != null && existing.completed) {
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
    await _write(completed, isNew: existing == null);
    return SaleCompletion.done(completed);
  }

  @override
  Future<CollectionCheck> collect(
    String id,
    Object? amount, {
    required bool isAdmin,
    String method = 'Cash',
  }) async {
    final ref = scope.sales.doc(id);
    return scope.firestore.runTransaction<CollectionCheck>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchSale(id);

      final sale = Sale.fromMap(id, snapshot.data()!);
      // Asked of the bill as it stands in Firestore: what is still owed
      // depends on what has already been collected, and the other till may
      // have taken part of it.
      final check = canCollect(sale, amount, isAdmin: isAdmin);
      if (!check.isAllowed) return check;

      final now = DateTime.now();
      transaction.update(ref, {
        'amountPaid': sale.total - check.remaining,
        // Appended, never rewritten: each collection keeps its own day and
        // method so the day it came in can be counted.
        'collections': FieldValue.arrayUnion([
          Collection(
            amount: sale.balanceDue - check.remaining,
            method: method,
            at: now,
          ).toMap(),
        ]),
        'updatedAt': now.toIso8601String(),
      });
      return check;
    });
  }

  @override
  Future<Sale> cancelSale(
    String id, {
    required String reason,
    String refundMethod = 'Cash',
    num? refundAmount,
  }) async {
    if (reason.trim().isEmpty) throw 'Say why the bill is cancelled';
    if (refundAmount != null && refundAmount < 0) {
      throw 'The refund cannot be less than zero';
    }
    final sale = await _stored(id);
    if (sale == null) throw NoSuchSale(id);

    if (!sale.completed) {
      // A draft never moved anything, so there is nothing to put back.
      final cancelled = sale.copyWith(
        status: SaleStatus.cancelled,
        notes: _withReason(sale.notes, reason),
        updatedAt: DateTime.now(),
      );
      await _write(cancelled, isNew: false);
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

    // The wallet part goes back on the wallet, always; the counter part
    // goes back the way the counter says (or onto the wallet).
    final now = DateTime.now();
    final customerId = sale.customerId;
    // A sold phone brought back: the shop may keep some of what was paid
    // (a deduction for wear or a missing box). Never more than was paid.
    if (refundAmount != null && refundAmount > sale.counterPaid) {
      throw 'The refund cannot be more than was paid (${sale.counterPaid})';
    }
    final paidBack = roundMoney(refundAmount ?? sale.counterPaid);
    final kept = roundMoney(sale.counterPaid - paidBack);
    if (customerId != null) {
      final toWallet =
          sale.walletUsed + (refundMethod == 'Wallet' ? paidBack : 0);
      if (toWallet > 0) {
        await customers.moveWallet(
          customerId,
          WalletMove(
            kind: WalletMoveKind.credit,
            amount: toWallet,
            reason: 'Bill ${sale.invoiceNumber} cancelled',
            reference: sale.id,
            at: now,
          ),
        );
      }
    }
    // Points this bill earned come off the wallet again (if they are still
    // there to take).
    if (customerId != null) {
      num earned = 0;
      try {
        earned = await customers.pointsEarnedOn(customerId, sale.id);
      } catch (_) {
        // Offline: the points stay; the bill is still cancelled.
      }
      if (earned > 0) {
        await customers.moveWallet(
          customerId,
          WalletMove(
            kind: WalletMoveKind.debit,
            amount: earned,
            reason: 'Points taken back: bill ${sale.invoiceNumber} cancelled',
            reference: sale.id,
            at: now,
          ),
        );
      }
    }
    final cancelled = sale.copyWith(
      status: SaleStatus.cancelled,
      notes: [
        _withReason(sale.notes, reason),
        if (kept > 0) 'Kept on return: $kept',
      ].join('\n'),
      refund: sale.counterPaid > 0
          ? Collection(
              amount: paidBack,
              method: customerId == null && refundMethod == 'Wallet'
                  ? 'Cash'
                  : refundMethod,
              at: now,
            )
          : null,
      updatedAt: now,
    );
    await _write(cancelled, isNew: false);
    return cancelled;
  }

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

  static String _withReason(String notes, String reason) => [
    notes,
    if (reason.trim().isNotEmpty) 'Cancelled: ${reason.trim()}',
  ].where((p) => p.isNotEmpty).join('\n');

  /// The bill as Firestore holds it, not as this device last saw it.
  Future<Sale?> _stored(String id) async {
    final snapshot = await scope.sales.doc(id).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Sale.fromMap(id, data);
  }

  Future<void> _write(Sale sale, {required bool isNew}) async {
    final ref = scope.sales.doc(sale.id);
    if (isNew) {
      await localWrite(ref.set(sale.toMap()));
    } else {
      // Merged, so a field this build does not know about is not wiped by a
      // collection or a cancellation.
      await localWrite(ref.set(sale.toMap(), SetOptions(merge: true)));
    }
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }
}
