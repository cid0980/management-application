/// WHERE PRODUCTS COME FROM
///
/// The shape of this interface is one decision: **a form cannot write a stock
/// count.** [save] takes a whole product and ignores its count; every change
/// goes through [move], which does read-check-write around `applyStockMove`.
///
/// That is the same shape as the customer wallet, for the same reason. Two
/// tills selling the last screen guard both read "two in stock" and both wrote
/// "one", and the shop was a guard short with nothing to show where it went.
/// A count is read, checked and written in one step, and the movement that
/// caused it is appended in the same step.
///
/// Refusals come back as results rather than exceptions. "There are only two
/// left" is an ordinary thing at a counter, not an error — the till shows it
/// and the person serving decides what to do.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/labels/label_entry.dart';
import '../domain/products/product.dart';
import '../domain/products/stock_level.dart';
import '../domain/products/stock_movement.dart';

abstract class ProductRepository extends ChangeNotifier {
  List<Product> get products;
  bool get loading;
  String? get error;

  Future<void> load();

  Product? byId(String id);

  /// Save a new product or an existing one.
  ///
  /// The stock count on [product] is ignored — see the library note. A new
  /// product starts at zero and its first delivery is a `received` movement,
  /// so the first line of its history says where the stock came from.
  Future<Product> save(Product product);

  /// This product's stock history, newest first.
  List<StockMovement> history(String id);

  /// Read, check, write, in one step.
  Future<StockMoveResult> move(String id, StockMovement movement);

  /// Take [quantity] off the shelf for a completed bill.
  ///
  /// Separate from [move] only so the sales repository cannot get the kind or
  /// the sign wrong, and so every sold line carries the bill as its reference.
  Future<StockMoveResult> sell(
    String id, {
    required int quantity,
    required String saleId,
  });

  /// Put [quantity] back, because a bill was cancelled or a customer returned
  /// something.
  Future<StockMoveResult> returnStock(
    String id, {
    required int quantity,
    required String reason,
    String? reference,
  });

  /// Correct the count to what was actually counted on the shelf.
  ///
  /// The honest version of "the system says three and I have five". Records the
  /// difference as an adjustment with a reason, rather than overwriting the
  /// count and losing the fact that it was ever wrong.
  Future<StockMoveResult> stockTake(
    String id, {
    required int counted,
    required String reason,
  });

  /// Put a label number the registry has minted onto a product.
  ///
  /// As with second-hand, this store does not choose the number:
  /// `LabelRepository` is the only thing that mints one.
  Future<Product> attachLabel(String id, int number);

  /// The label fields for this product, for the registry's snapshot and the
  /// live values laid over it on a scan. Null when the product is gone.
  Map<String, Object?>? labelSnapshot(String id);
}

class NoSuchProduct implements Exception {
  const NoSuchProduct(this.id);
  final String id;
  @override
  String toString() => 'No product $id';
}

class InMemoryProductStore extends ChangeNotifier implements ProductRepository {
  InMemoryProductStore({List<Product>? seed}) {
    _products = [...(seed ?? _seedRecords())];
    // A seeded product arrives with a count but no history, which would read
    // as a broken record on its detail page. Each one gets an opening line
    // saying exactly that: this is what was on the shelf when the app started
    // keeping count.
    for (final p in _products) {
      if (p.stockCount > 0) {
        _history[p.id] = [
          StockMovement(
            kind: StockMoveKind.received,
            quantity: p.stockCount,
            reason: 'Opening stock',
            at: p.createdAt ?? DateTime.now(),
          ),
        ];
      }
    }
  }

  late List<Product> _products;
  final Map<String, List<StockMovement>> _history = {};
  bool _loading = false;
  String? _error;

  @override
  List<Product> get products => List.unmodifiable(_products);

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
  Product? byId(String id) => _products.where((p) => p.id == id).firstOrNull;

  @override
  Future<Product> save(Product product) async {
    final existing = byId(product.id);
    final stored = product.copyWith(
      // The count is never taken from a form. Only `move` changes it.
      stockCount: existing?.stockCount ?? 0,
      updatedAt: DateTime.now(),
    );
    final index = _products.indexWhere((p) => p.id == stored.id);
    if (index >= 0) {
      _products[index] = stored;
    } else {
      _products.add(stored);
    }
    notifyListeners();
    return stored;
  }

  @override
  List<StockMovement> history(String id) =>
      List.unmodifiable((_history[id] ?? const <StockMovement>[]).reversed);

  @override
  Future<StockMoveResult> move(String id, StockMovement movement) async {
    final product = byId(id);
    if (product == null) throw NoSuchProduct(id);

    // Read, check, write. In Firestore this is the body of a transaction; the
    // decision itself is the same function either way.
    final result = applyStockMove(product.stockCount, movement);
    if (!result.allowed) return result;

    final index = _products.indexWhere((p) => p.id == id);
    _products[index] = product.copyWith(
      stockCount: result.newCount,
      // Stamped by every movement, which is how another till learns the count
      // changed.
      updatedAt: DateTime.now(),
    );
    (_history[id] ??= []).add(
      StockMovement(
        kind: movement.kind,
        quantity: movement.quantity,
        reason: movement.reason,
        reference: movement.reference,
        at: movement.at ?? DateTime.now(),
        by: movement.by,
      ),
    );
    notifyListeners();
    return result;
  }

  @override
  Future<StockMoveResult> sell(
    String id, {
    required int quantity,
    required String saleId,
  }) => move(
    id,
    StockMovement(
      kind: StockMoveKind.sold,
      quantity: quantity,
      reason: 'Sold on $saleId',
      reference: saleId,
    ),
  );

  @override
  Future<StockMoveResult> returnStock(
    String id, {
    required int quantity,
    required String reason,
    String? reference,
  }) => move(
    id,
    StockMovement(
      kind: StockMoveKind.returned,
      quantity: quantity,
      reason: reason,
      reference: reference,
    ),
  );

  @override
  Future<StockMoveResult> stockTake(
    String id, {
    required int counted,
    required String reason,
  }) async {
    final product = byId(id);
    if (product == null) throw NoSuchProduct(id);
    if (counted < 0) {
      return StockMoveResult.refused(
        StockRefusal.notAQuantity,
        product.stockCount,
      );
    }

    final movement = stockTakeMovement(
      recorded: product.stockCount,
      counted: counted,
      reason: reason,
    );
    // Nothing moved. A zero-quantity line in the history would look as though
    // something had.
    if (movement == null) {
      return StockMoveResult.allowed(product.stockCount);
    }
    return move(id, movement);
  }

  @override
  Future<Product> attachLabel(String id, int number) async {
    final product = byId(id);
    if (product == null) throw NoSuchProduct(id);
    if (product.labelNumber != null) return product;
    final index = _products.indexWhere((p) => p.id == id);
    _products[index] = product.copyWith(
      labelNumber: number,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return _products[index];
  }

  @override
  Map<String, Object?>? labelSnapshot(String id) {
    final product = byId(id);
    if (product == null) return null;
    return {
      kLabelTitle: product.title,
      kLabelSubtitle: [
        if (product.category.isNotEmpty) product.category,
        if (product.sku.isNotEmpty) product.sku,
      ].join(' · '),
      // The selling price. The cost price is never printed on a label and
      // never reaches the public scan page.
      kLabelPrice: product.sellingPrice,
      kLabelStatus: kStockLevelLabels[product.level]!,
    };
  }
}

/// Seed products, each one a state the list has to get right.
List<Product> _seedRecords() {
  final now = DateTime.now();
  return [
    // Plenty, with a threshold set.
    Product(
      id: 'p-1',
      name: 'Tempered glass',
      brand: 'Spigen',
      category: 'Screen guard',
      variant: 'Galaxy A54',
      sku: 'SG-A54-TG',
      supplier: 'Chennai Mobile Traders',
      costPrice: 45,
      sellingPrice: 199,
      mrp: 299,
      stockCount: 48,
      reorderLevel: 10,
      photos: const ['seed://glass-front'],
      createdAt: now.subtract(const Duration(days: 40)),
    ),
    // Low: at its reorder level exactly, which has to read as low rather than
    // as fine.
    Product(
      id: 'p-2',
      name: 'Fast charger 33W',
      brand: 'Xiaomi',
      category: 'Charger',
      sku: 'CH-MI-33',
      supplier: 'Chennai Mobile Traders',
      costPrice: 420,
      sellingPrice: 749,
      mrp: 999,
      stockCount: 4,
      reorderLevel: 4,
      photos: const ['seed://charger-front'],
      createdAt: now.subtract(const Duration(days: 25)),
    ),
    // Out of stock. Not folded into low: it is a sale the shop cannot make
    // today.
    Product(
      id: 'p-3',
      name: 'Type-C cable 1m',
      brand: 'Boat',
      category: 'Cable',
      sku: 'CB-BT-C1',
      costPrice: 85,
      sellingPrice: 249,
      mrp: 349,
      stockCount: 0,
      reorderLevel: 12,
      createdAt: now.subtract(const Duration(days: 18)),
    ),
    // No reorder level, so it can only ever be in stock or out — never low,
    // and the form says so rather than inventing a threshold.
    Product(
      id: 'p-4',
      name: 'Car phone holder',
      category: 'Car accessory',
      costPrice: 130,
      sellingPrice: 399,
      stockCount: 3,
      createdAt: now.subtract(const Duration(days: 9)),
    ),
    // Written by an older build: a count as a string, a price under the key
    // this one does not use, and a threshold under its old name.
    Product.fromMap('p-5', {
      'name': 'Bluetooth earbuds',
      'brand': 'Realme',
      'category': 'Bluetooth earbuds',
      'price': 1899,
      'purchasePrice': 1150,
      'stock': '7',
      'lowStockThreshold': 3,
      'createdAt': now.subtract(const Duration(days: 60)).toIso8601String(),
    }),
  ];
}
