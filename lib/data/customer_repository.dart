/// WHERE CUSTOMERS COME FROM
///
/// The wallet is why this interface is shaped the way it is. A wallet move is
/// not "write a new balance" — it is read, check, write, as one step, because
/// two tills spending the same credit at the same moment is the race the rule
/// exists for. So the repository owns [moveWallet] and no screen is given a
/// way to write `walletBalance` directly.
///
/// [applyMove] decides whether a move is allowed; this runs it.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/phone.dart';
import '../domain/customers/customer.dart';
import '../domain/customers/wallet.dart';

abstract class CustomerRepository extends ChangeNotifier {
  List<Customer> get customers;
  bool get loading;
  String? get error;

  Future<void> load();

  Customer? byId(String id);

  /// The customer with this number, or null. The sale form asks this before
  /// adding anyone, which is how nobody gets added twice.
  Customer? byPhone(String? phone);

  Future<Customer> save(Customer customer);

  /// The wallet's history, newest first.
  List<WalletMove> walletHistory(String id);

  /// Read, check, write, as one step.
  ///
  /// Returns the result rather than throwing on a refusal: a wallet that
  /// cannot cover a bill is an ordinary thing the counter handles, not an
  /// error. A refusal leaves the balance exactly as it was.
  Future<WalletMoveResult> moveWallet(String id, WalletMove move);
}

class NoSuchCustomer implements Exception {
  const NoSuchCustomer(this.id);
  final String id;
  @override
  String toString() => 'No customer $id';
}

class InMemoryCustomerStore extends ChangeNotifier
    implements CustomerRepository {
  InMemoryCustomerStore({List<Customer>? seed}) {
    _customers = [...(seed ?? _seedRecords())];
  }

  late List<Customer> _customers;
  final Map<String, List<WalletMove>> _history = {};
  bool _loading = false;
  String? _error;

  @override
  List<Customer> get customers => List.unmodifiable(_customers);

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
  Customer? byId(String id) => _customers.where((c) => c.id == id).firstOrNull;

  @override
  Customer? byPhone(String? phone) => findByPhone(_customers, phone);

  @override
  Future<Customer> save(Customer customer) async {
    final existing = byId(customer.id);
    final stored = customer.copyWith(
      // Normalized here too, not only on read: a form writes what was typed.
      phone: normalizePhone(customer.phone),
      altPhone: normalizePhone(customer.altPhone),
      // The balance is never taken from a form. Only moveWallet changes it.
      walletBalance: existing?.walletBalance ?? 0,
      // Stamped once, by the store, for whichever form added them: the
      // purchase form's "add new customer" sent none, so a seller added today
      // never counted as New Today and sorted as the oldest customer.
      createdAt: existing?.createdAt ?? customer.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final index = _customers.indexWhere((c) => c.id == stored.id);
    if (index >= 0) {
      _customers[index] = stored;
    } else {
      _customers.add(stored);
    }
    notifyListeners();
    return stored;
  }

  @override
  List<WalletMove> walletHistory(String id) =>
      List.unmodifiable((_history[id] ?? const <WalletMove>[]).reversed);

  @override
  Future<WalletMoveResult> moveWallet(String id, WalletMove move) async {
    final customer = byId(id);
    if (customer == null) throw NoSuchCustomer(id);

    // Read, check, write. In Firestore this is the body of a transaction; the
    // decision itself is the same function either way.
    final result = applyMove(customer.walletBalance, move);
    if (!result.allowed) return result;

    final index = _customers.indexWhere((c) => c.id == id);
    _customers[index] = customer.copyWith(
      walletBalance: result.newBalance,
      // Every move stamps this. It is how the other till learns.
      updatedAt: DateTime.now(),
    );
    (_history[id] ??= []).add(
      WalletMove(
        kind: move.kind,
        amount: move.amount,
        reason: move.reason,
        reference: move.reference,
        at: move.at ?? DateTime.now(),
        by: move.by,
      ),
    );
    notifyListeners();
    return result;
  }
}

List<Customer> _seedRecords() {
  final now = DateTime.now();
  return [
    Customer(
      id: 'c-1',
      name: 'Ramesh K',
      phone: '9876543210',
      address: 'Gandhi Road',
      createdAt: now.subtract(const Duration(days: 120)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
    Customer(
      id: 'c-2',
      name: 'Priya S',
      phone: '9123456780',
      email: 'priya@example.com',
      createdAt: now.subtract(const Duration(days: 60)),
      updatedAt: now.subtract(const Duration(days: 6)),
    ),
    // A walk-in recorded by number alone, and nothing else yet. A real
    // customer: refusing the record would have put the repair in under nobody.
    Customer(
      id: 'c-3',
      name: '',
      phone: '9000022222',
      createdAt: now.subtract(const Duration(days: 9)),
      updatedAt: now.subtract(const Duration(days: 9)),
    ),
    // The seller of second-hand record sh-3. In the book under the same number
    // that record carries, so the detail page's history finds it.
    Customer(
      id: 'c-5',
      name: 'Anand M',
      phone: '9988776655',
      createdAt: now.subtract(const Duration(days: 21)),
      updatedAt: now.subtract(const Duration(days: 4)),
    ),
    // The same number written three ways is one person, which is what
    // normalizing on read is for.
    Customer.fromMap('c-4', {
      'name': 'Kavitha R',
      'phone': '+91 90000 11111',
      'walletBalance': '350',
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
    }),
  ];
}

/// Files the person a repair, bill or enquiry was taken for, when they are not
/// in the book yet. See [newCustomerFor].
///
/// Never throws: it runs after the record it came from has been saved, and
/// nothing waits on it. A customer who failed to file is a list briefly out
/// of date, not a lost repair.
Future<Customer?> fileCustomer(
  CustomerRepository repo, {
  required String name,
  required String phone,
  String address = '',
}) async {
  final now = DateTime.now();
  final fresh = newCustomerFor(
    book: repo.customers,
    name: name,
    phone: phone,
    address: address,
    id: 'cust-${now.millisecondsSinceEpoch}',
    now: now,
  );
  if (fresh == null) return null;
  try {
    return await repo.save(fresh);
  } catch (_) {
    return null;
  }
}
