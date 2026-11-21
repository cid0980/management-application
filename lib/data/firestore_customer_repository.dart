/// CUSTOMERS, OUT OF FIRESTORE
///
/// The same `CustomerRepository` the screens already talk to, backed by
/// `shops/{shopId}/customers` instead of a list in memory.
///
/// Three things shape this file, and they are the same three as every other
/// Firestore store here.
///
/// **It caches, because the interface is synchronous.** `customers` and
/// `byPhone` return values, not futures, because the list and the sale form's
/// autocomplete filter in the hand. So a snapshot listener is held open and
/// the last result kept.
///
/// **A wallet move is a transaction.** Read the balance, ask [applyMove],
/// write the new balance and the history line together. Two tills spending
/// the same credit at the same moment is the race the rule exists for, and an
/// ordinary `set()` would let the second one win by arriving later. The
/// history line is written inside the same transaction as the balance: a
/// balance that moved with no line against it is a wallet nobody can explain.
///
/// **Wallet history is loaded per customer, on demand.** A shop with a
/// thousand customers has a thousand little ledgers, and the list screen needs
/// none of them. The first call to [walletHistory] for a customer opens that
/// one sub-collection's listener and returns what it has — empty on the first
/// frame, filled on the next, which is why it notifies.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/phone.dart';
import '../domain/customers/customer.dart';
import '../domain/customers/wallet.dart';
import 'customer_repository.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';

class FirestoreCustomerStore extends ChangeNotifier
    implements CustomerRepository {
  FirestoreCustomerStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

  List<Customer> _customers = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;

  final Map<String, List<WalletMove>> _history = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _historyListeners = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  List<Customer> get customers => List.unmodifiable(_customers);

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    // Idempotent: the list screen calls this on its retry button, and a second
    // listener would double every change notification.
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    _subscription = scope.customers.snapshots().listen(
      (snapshot) {
        _customers = [
          for (final doc in snapshot.docs) Customer.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'customers');
        notifyListeners();
      },
    );
  }

  @override
  Customer? byId(String id) {
    for (final customer in _customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  @override
  Customer? byPhone(String? phone) => findByPhone(_customers, phone);

  @override
  Future<Customer> save(Customer customer) async {
    final existing = byId(customer.id);
    final stored = customer.copyWith(
      // Normalized on the way in as well as on the way out: a form writes
      // whatever was typed, and the same number written three ways is one
      // person.
      phone: normalizePhone(customer.phone),
      altPhone: normalizePhone(customer.altPhone),
      // The balance is never taken from a form. Only moveWallet changes it,
      // and a form that has been open while a sale completed would otherwise
      // write back the balance as it was when it opened.
      walletBalance: existing?.walletBalance ?? 0,
      // Stamped once, by the store, for whichever form added them: the
      // purchase form's "add new customer" sent none, so a seller added today
      // never counted as New Today and sorted as the oldest customer.
      createdAt: existing?.createdAt ?? customer.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final map = stored.toMap();
    if (existing == null) {
      await scope.customers.doc(stored.id).set(map);
    } else {
      // Merged rather than replaced, so a field this build does not know
      // about — written by a newer one, or by the import tool — is not wiped
      // by somebody editing an address.
      await scope.customers.doc(stored.id).set(map, SetOptions(merge: true));
    }
    // The listener will deliver this back; returning the local value means the
    // caller does not wait a round trip to show it.
    return stored;
  }

  @override
  List<WalletMove> walletHistory(String id) {
    _watchHistory(id);
    return List.unmodifiable((_history[id] ?? const <WalletMove>[]));
  }

  @override
  Future<WalletMoveResult> moveWallet(String id, WalletMove move) async {
    final ref = scope.customers.doc(id);
    final moveRef = scope.walletMoves(id).doc();

    return scope.firestore.runTransaction<WalletMoveResult>((
      transaction,
    ) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchCustomer(id);

      final customer = Customer.fromMap(id, snapshot.data()!);
      // The decision is the same function the in-memory store runs. Only the
      // read and the write around it differ.
      final result = applyMove(customer.walletBalance, move);
      // A refusal leaves the balance exactly as it was — and writes no history
      // line, because nothing happened.
      if (!result.allowed) return result;

      final stamped = WalletMove(
        kind: move.kind,
        amount: move.amount,
        reason: move.reason,
        reference: move.reference,
        at: move.at ?? DateTime.now(),
        by: move.by,
      );

      transaction.update(ref, {
        'walletBalance': result.newBalance,
        // Every move stamps this. It is how the other till learns.
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.set(moveRef, stamped.toMap());
      return result;
    });
  }

  /// Opens the listener on one customer's wallet history, once.
  void _watchHistory(String id) {
    if (_historyListeners.containsKey(id)) return;
    _historyListeners[id] = scope
        .walletMoves(id)
        // Newest first, which is the order the detail page shows. Ordered by
        // the field rather than sorted here so a long history can be limited
        // later without changing what "newest" means.
        .orderBy('at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _history[id] = [
              for (final doc in snapshot.docs) WalletMove.fromMap(doc.data()),
            ];
            notifyListeners();
          },
          // A history that cannot be read does not break the customer's page: the
          // balance is on the customer record itself. The error is reported
          // through the same field the list uses.
          onError: (Object e) {
            _error = describeFirestoreError(e, 'wallet history');
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final listener in _historyListeners.values) {
      listener.cancel();
    }
    super.dispose();
  }
}
