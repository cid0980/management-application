/// PRODUCTS, OUT OF FIRESTORE
///
/// The same `ProductRepository` the screens already talk to, backed by
/// `shops/{shopId}/products`, with each product's movements under it.
///
/// **A count is never written by a form.** `save` writes the product's details
/// and leaves `stockCount` exactly as it is in Firestore — a form that was
/// opened before a sale completed would otherwise write back the count as it
/// was when it opened, and the shelf would quietly gain back what it sold.
/// Only a movement changes the count.
///
/// **Every movement is a transaction.** Read the count, ask [applyStockMove],
/// write the new count and the history line as one step. Two tills selling the
/// last charger at the same moment is the race the "never below zero" rule
/// exists for, and an ordinary `set()` would let the second one win by
/// arriving later.
///
/// **A stock take is decided against the stored count, not the cached one.**
/// `stockTake` is given what was physically counted on the shelf, and the
/// adjustment is the difference from whatever Firestore holds at that moment —
/// so a sale that landed while somebody was counting is not undone by the
/// count being filed.
///
/// **Movements are loaded per product, on demand.** The list screen needs
/// none of them, and a shop with five hundred products has five hundred little
/// ledgers. The first call to [history] for a product opens that one
/// sub-collection's listener: empty on the first frame, filled on the next,
/// which is why it notifies.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/labels/label_entry.dart';
import '../domain/products/product.dart';
import '../domain/products/stock_level.dart';
import '../domain/products/stock_movement.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'product_repository.dart';

class FirestoreProductStore extends ChangeNotifier
    implements ProductRepository {
  FirestoreProductStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

  List<Product> _products = const [];
  bool _loading = true;
  String? _error;
  bool _listening = false;

  final Map<String, List<StockMovement>> _history = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _historyListeners = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  List<Product> get products => List.unmodifiable(_products);

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

    _subscription = scope.products.snapshots().listen(
      (snapshot) {
        // `fromMap` normalizes: a count stored as text, a price under the key
        // an older build used, a threshold under its old name.
        _products = [
          for (final doc in snapshot.docs) Product.fromMap(doc.id, doc.data()),
        ];
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = describeFirestoreError(e, 'products');
        notifyListeners();
      },
    );
  }

  @override
  Product? byId(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<Product> save(Product product) async {
    final existing = byId(product.id);
    final stored = product.copyWith(
      // See the class note: only a movement changes the count.
      stockCount: existing?.stockCount ?? 0,
      updatedAt: DateTime.now(),
    );

    final map = stored.toMap();
    if (existing == null) {
      await scope.products.doc(stored.id).set(map);
    } else {
      // Merged, so a field this build does not know about is not wiped by
      // somebody editing a price. The count is in the map as it currently
      // stands, so merging cannot stale it either.
      await scope.products.doc(stored.id).set(map, SetOptions(merge: true));
    }
    return stored;
  }

  @override
  List<StockMovement> history(String id) {
    _watchHistory(id);
    return List.unmodifiable(_history[id] ?? const <StockMovement>[]);
  }

  @override
  Future<StockMoveResult> move(String id, StockMovement movement) =>
      _transactMove(id, (_) => movement);

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
  }) =>
      // Built inside the transaction, from the count Firestore holds now —
      // see the class note on why not the cached one.
      _transactMove(id, (recorded) {
        if (counted < 0) return null;
        return stockTakeMovement(
          recorded: recorded,
          counted: counted,
          reason: reason,
        );
      }, refusalWhenNoMovement: counted < 0 ? StockRefusal.notAQuantity : null);

  @override
  Future<Product> attachLabel(String id, int number) async {
    final ref = scope.products.doc(id);
    return scope.firestore.runTransaction<Product>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchProduct(id);

      final product = Product.fromMap(id, snapshot.data()!);
      // A record that already has a label keeps it: a second number for one
      // product is a second sticker resolving somewhere the first did not.
      if (product.labelNumber != null) return product;

      final updatedAt = DateTime.now();
      transaction.update(ref, {
        'labelNumber': number,
        'updatedAt': updatedAt.toIso8601String(),
      });
      return product.copyWith(labelNumber: number, updatedAt: updatedAt);
    });
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

  /// Read the count, decide, write the count and the history line together.
  ///
  /// [build] is given the count as it currently stands in Firestore and
  /// returns the movement to apply. Null means nothing moved — which is an
  /// allowed outcome, not an error: a stock take that agrees with the shelf
  /// must not leave a zero-quantity line in the history looking as though
  /// something happened. [refusalWhenNoMovement] is for the one case where
  /// null means refused instead.
  Future<StockMoveResult> _transactMove(
    String id,
    StockMovement? Function(int count) build, {
    StockRefusal? refusalWhenNoMovement,
  }) {
    final ref = scope.products.doc(id);
    return scope.firestore.runTransaction<StockMoveResult>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw NoSuchProduct(id);

      final product = Product.fromMap(id, snapshot.data()!);
      final movement = build(product.stockCount);
      if (movement == null) {
        return refusalWhenNoMovement == null
            ? StockMoveResult.allowed(product.stockCount)
            : StockMoveResult.refused(
                refusalWhenNoMovement,
                product.stockCount,
              );
      }

      // The decision is the same function the in-memory store runs. Only
      // the read and the write around it differ.
      final result = applyStockMove(product.stockCount, movement);
      // A refusal writes nothing at all — no count, no history line.
      if (!result.allowed) return result;

      final stamped = StockMovement(
        kind: movement.kind,
        quantity: movement.quantity,
        reason: movement.reason,
        reference: movement.reference,
        at: movement.at ?? DateTime.now(),
        by: movement.by,
      );

      transaction.update(ref, {
        'stockCount': result.newCount,
        // Stamped by every movement, which is how another till learns the
        // count changed.
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.set(scope.stockMovements(id).doc(), stamped.toMap());
      return result;
    });
  }

  /// Opens the listener on one product's movements, once.
  void _watchHistory(String id) {
    if (_historyListeners.containsKey(id)) return;
    _historyListeners[id] = scope
        .stockMovements(id)
        // Newest first, which is the order the detail page shows.
        .orderBy('at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _history[id] = [
              for (final doc in snapshot.docs)
                StockMovement.fromMap(doc.data()),
            ];
            notifyListeners();
          },
          // A history that cannot be read does not break the product's page: the
          // count is on the product record itself.
          onError: (Object e) {
            _error = describeFirestoreError(e, 'stock movements');
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
