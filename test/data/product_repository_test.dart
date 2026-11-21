import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/products/stock_movement.dart';

Product _p(String id, {int count = 10, int reorder = 4, int? label}) => Product(
      id: id,
      name: 'Tempered glass',
      brand: 'Spigen',
      category: 'Screen guard',
      sku: 'SG-A54',
      costPrice: 45,
      sellingPrice: 199,
      stockCount: count,
      reorderLevel: reorder,
      labelNumber: label,
    );

StockMovement _received(int quantity) => StockMovement(
      kind: StockMoveKind.received,
      quantity: quantity,
      reason: 'Delivery',
    );

void main() {
  group('a form cannot write a stock count', () {
    test('a save keeps whatever the shelf actually holds', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 10)]);
      addTearDown(store.dispose);
      final saved = await store.save(_p('a', count: 999).copyWith(
        sellingPrice: 249,
      ));
      expect(saved.stockCount, 10);
      expect(saved.sellingPrice, 249);
    });

    test('a new product starts at zero whatever the form says', () async {
      final store = InMemoryProductStore(seed: []);
      addTearDown(store.dispose);
      expect((await store.save(_p('a', count: 50))).stockCount, 0);
      // So the first delivery is a movement, and the history says where the
      // stock came from.
      expect(store.history('a'), isEmpty);
    });

    test('every save stamps updatedAt', () async {
      final store = InMemoryProductStore(seed: []);
      addTearDown(store.dispose);
      expect((await store.save(_p('a'))).updatedAt, isNotNull);
    });
  });

  group('stock moves through movements, read-check-write', () {
    test('a delivery goes on the shelf and into the history', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 10)]);
      addTearDown(store.dispose);
      final result = await store.move('a', _received(20));
      expect(result.allowed, isTrue);
      expect(store.byId('a')!.stockCount, 30);
      expect(store.history('a').first.kind, StockMoveKind.received);
    });

    test('taking more off than is there is refused, count untouched',
        () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 2)]);
      addTearDown(store.dispose);
      final result = await store.sell('a', quantity: 3, saleId: 's-1');
      expect(result.allowed, isFalse);
      expect(result.refusal, StockRefusal.insufficientStock);
      expect(store.byId('a')!.stockCount, 2);
      // And leaves no line in the history: nothing happened.
      expect(store.history('a').where((m) => m.kind == StockMoveKind.sold),
          isEmpty);
    });

    test('a sale carries the bill as its reference', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 10)]);
      addTearDown(store.dispose);
      await store.sell('a', quantity: 3, saleId: 's-1');
      final move = store.history('a').first;
      expect(move.kind, StockMoveKind.sold);
      expect(move.quantity, 3);
      expect(move.reference, 's-1');
      expect(store.byId('a')!.stockCount, 7);
    });

    test('a return puts it back, saying why', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 7)]);
      addTearDown(store.dispose);
      await store.returnStock('a',
          quantity: 3, reason: 'Bill INV-1 cancelled', reference: 's-1');
      expect(store.byId('a')!.stockCount, 10);
      expect(store.history('a').first.reason, 'Bill INV-1 cancelled');
    });

    test('an unexplained movement is refused', () async {
      final store = InMemoryProductStore(seed: [_p('a')]);
      addTearDown(store.dispose);
      final result = await store.move(
        'a',
        const StockMovement(
          kind: StockMoveKind.damaged,
          quantity: 2,
          reason: '  ',
        ),
      );
      expect(result.refusal, StockRefusal.noReason);
      expect(store.byId('a')!.stockCount, 10);
    });

    test('every movement stamps updatedAt and a time on the line', () async {
      final store = InMemoryProductStore(seed: [_p('a')]);
      addTearDown(store.dispose);
      await store.move('a', _received(5));
      expect(store.byId('a')!.updatedAt, isNotNull);
      expect(store.history('a').first.at, isNotNull);
    });

    test('the history is newest first and adds up to the count', () async {
      final store = InMemoryProductStore(seed: []);
      addTearDown(store.dispose);
      await store.save(_p('a'));
      await store.move('a', _received(50));
      await store.sell('a', quantity: 12, saleId: 's-1');
      await store.move('a', const StockMovement(
        kind: StockMoveKind.damaged,
        quantity: 2,
        reason: 'Dropped',
      ));

      expect(store.byId('a')!.stockCount, 36);
      expect(countFromMovements(store.history('a')), 36);
      expect(store.history('a').first.kind, StockMoveKind.damaged);
    });
  });

  group('a stock-take', () {
    test('records the difference, not the new count', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 3)]);
      addTearDown(store.dispose);
      final result =
          await store.stockTake('a', counted: 5, reason: 'Counted 5');
      expect(result.allowed, isTrue);
      expect(store.byId('a')!.stockCount, 5);
      final move = store.history('a').first;
      expect(move.kind, StockMoveKind.adjustedUp);
      expect(move.quantity, 2);
    });

    test('fewer on the shelf than recorded adjusts down', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 5)]);
      addTearDown(store.dispose);
      await store.stockTake('a', counted: 3, reason: 'Counted 3');
      expect(store.byId('a')!.stockCount, 3);
      expect(store.history('a').first.kind, StockMoveKind.adjustedDown);
    });

    test('a count that already matched writes nothing', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 5)]);
      addTearDown(store.dispose);
      final before = store.history('a').length;
      final result =
          await store.stockTake('a', counted: 5, reason: 'Counted 5');
      expect(result.allowed, isTrue);
      expect(result.newCount, 5);
      expect(store.history('a'), hasLength(before));
    });

    test('counting to zero is allowed', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 5)]);
      addTearDown(store.dispose);
      expect(
        (await store.stockTake('a', counted: 0, reason: 'None left')).allowed,
        isTrue,
      );
      expect(store.byId('a')!.stockCount, 0);
    });

    test('a negative count is refused', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 5)]);
      addTearDown(store.dispose);
      final result =
          await store.stockTake('a', counted: -1, reason: 'Nonsense');
      expect(result.refusal, StockRefusal.notAQuantity);
      expect(store.byId('a')!.stockCount, 5);
    });
  });

  group('labels', () {
    test('this store attaches a number, it does not choose one', () async {
      final store = InMemoryProductStore(seed: [_p('a')]);
      addTearDown(store.dispose);
      expect((await store.attachLabel('a', 26042)).labelNumber, 26042);
    });

    test('a product that already has a label keeps it', () async {
      final store = InMemoryProductStore(seed: [_p('a', label: 26005)]);
      addTearDown(store.dispose);
      expect((await store.attachLabel('a', 26099)).labelNumber, 26005);
    });

    test('the snapshot carries the selling price, never the cost', () async {
      final store = InMemoryProductStore(seed: [_p('a')]);
      addTearDown(store.dispose);
      final snapshot = store.labelSnapshot('a')!;
      expect(snapshot[kLabelTitle], 'Spigen Tempered glass');
      expect(snapshot[kLabelPrice], 199);
      expect(snapshot[kLabelStatus], 'In stock');
      // The cost price is never printed on a label.
      expect(snapshot.values, isNot(contains(45)));
    });

    test('the snapshot status follows the count', () async {
      final store = InMemoryProductStore(seed: [_p('a', count: 0)]);
      addTearDown(store.dispose);
      expect(store.labelSnapshot('a')![kLabelStatus], 'Out of stock');
    });

    test('no snapshot for a product that is gone', () {
      final store = InMemoryProductStore(seed: []);
      addTearDown(store.dispose);
      expect(store.labelSnapshot('nope'), isNull);
    });
  });

  test('a missing product is said so, not silently ignored', () {
    final store = InMemoryProductStore(seed: []);
    addTearDown(store.dispose);
    expect(() => store.move('nope', _received(1)),
        throwsA(isA<NoSuchProduct>()));
    expect(() => store.sell('nope', quantity: 1, saleId: 's'),
        throwsA(isA<NoSuchProduct>()));
    expect(() => store.stockTake('nope', counted: 1, reason: 'x'),
        throwsA(isA<NoSuchProduct>()));
    expect(() => store.attachLabel('nope', 1),
        throwsA(isA<NoSuchProduct>()));
  });

  test('a change notifies, so the list redraws without being told', () async {
    final store = InMemoryProductStore(seed: [_p('a', count: 2)]);
    addTearDown(store.dispose);
    var notified = 0;
    store.addListener(() => notified++);
    await store.move('a', _received(5));
    await store.save(_p('a'));
    // A refused movement changed nothing, so it notifies nobody.
    await store.sell('a', quantity: 9999, saleId: 's-1');
    expect(notified, 2);
  });

  group('the seed', () {
    test('holds the states the list has to get right', () {
      final store = InMemoryProductStore();
      addTearDown(store.dispose);
      expect(store.byId('p-1')!.level.name, 'inStock');
      // At its reorder level exactly, which has to read as low.
      expect(store.byId('p-2')!.level.name, 'low');
      expect(store.byId('p-3')!.level.name, 'outOfStock');
      // No reorder level: in stock or out, never low.
      expect(store.byId('p-4')!.reorderLevel, 0);
      expect(store.byId('p-4')!.level.name, 'inStock');
      // Written by an older build, under keys this one does not use.
      expect(store.byId('p-5')!.stockCount, 7);
      expect(store.byId('p-5')!.sellingPrice, 1899);
    });

    test('each seeded product has an opening line in its history', () {
      // A count with no history would read as a broken record on the detail
      // page.
      final store = InMemoryProductStore();
      addTearDown(store.dispose);
      final opening = store.history('p-1').single;
      expect(opening.kind, StockMoveKind.received);
      expect(opening.reason, 'Opening stock');
      expect(countFromMovements(store.history('p-1')),
          store.byId('p-1')!.stockCount);
    });

    test('a product seeded empty has no opening line to write', () {
      final store = InMemoryProductStore();
      addTearDown(store.dispose);
      expect(store.history('p-3'), isEmpty);
    });
  });
}
