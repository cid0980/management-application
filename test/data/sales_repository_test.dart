import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/reports/shop_report.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/customers/wallet.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/sales/due_payments.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

SecondHandDevice _device(String id, {String status = kAvailable}) =>
    SecondHandDevice(
      id: id,
      brand: 'Samsung',
      model: 'Galaxy A54',
      imei: '354879104523681',
      status: status,
      purchasePrice: 14500,
      askingPrice: 18500,
    );

class _Fixture {
  _Fixture({
    List<SecondHandDevice>? devices,
    List<Customer>? customers,
    List<Product>? products,
  }) : stock = InMemorySecondHandStore(seed: devices ?? [_device('sh-1')]),
       products = InMemoryProductStore(seed: products ?? [_product()]),
       customers = InMemoryCustomerStore(
         seed:
             customers ??
             [const Customer(id: 'c-1', name: 'Ramesh K', phone: '9876543210')],
       ) {
    sales = InMemorySalesStore(
      stock: stock,
      products: this.products,
      customers: this.customers, // the field, not the constructor parameter
      counter: InMemoryCounter(),
      today: DateTime(2026, 3, 4),
    );
  }

  final InMemorySecondHandStore stock;
  final InMemoryProductStore products;
  final InMemoryCustomerStore customers;
  late final InMemorySalesStore sales;

  void dispose() {
    sales.dispose();
    stock.dispose();
    products.dispose();
    customers.dispose();
  }
}

Product _product({String id = 'p-1', int stock = 10, num price = 199}) =>
    Product(
      id: id,
      name: 'Tempered glass',
      brand: 'Spigen',
      category: 'Screen guard',
      costPrice: 45,
      sellingPrice: price,
      stockCount: stock,
      reorderLevel: 4,
    );

Sale _bill({
  String id = 's-1',
  String deviceId = 'sh-1',
  num price = 18500,
  String method = 'Cash',
  num paid = 18500,
  num walletUsed = 0,
  bool manualOnly = false,
}) => Sale(
  id: id,
  customerId: 'c-1',
  customerPhone: '9876543210',
  items: manualOnly
      ? const [SaleItem(description: 'Fitting charge', unitPrice: 200)]
      : [
          SaleItem(
            description: 'Samsung Galaxy A54',
            unitPrice: price,
            source: LineSource.secondHand,
            recordId: deviceId,
          ),
        ],
  paymentMethod: method,
  amountPaid: paid,
  walletUsed: walletUsed,
);

void main() {
  group('a draft moves nothing', () {
    test('saving a bill with a handset on it leaves the shelf alone', () async {
      final f = _Fixture();
      addTearDown(f.dispose);

      await f.sales.saveDraft(_bill());
      // The whole reason this is one step: an abandoned bill used to leave the
      // shop short of stock it still had.
      expect(f.stock.byId('sh-1')!.isSellable, isTrue);
      expect(f.stock.byId('sh-1')!.isSold, isFalse);
    });

    test('a draft gets no invoice number', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      // An abandoned bill must not burn a number out of the day's sequence.
      expect((await f.sales.saveDraft(_bill())).invoiceNumber, '');
    });

    test('a draft cannot be saved as completed', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final saved = await f.sales.saveDraft(
        _bill().copyWith(status: SaleStatus.completed),
      );
      expect(saved.status, SaleStatus.draft);
      expect(f.stock.byId('sh-1')!.isSold, isFalse);
    });
  });

  group('completing is the one step that moves stock', () {
    test('the handset is sold, at what it went out at', () async {
      final f = _Fixture();
      addTearDown(f.dispose);

      final outcome = await f.sales.completeSale(_bill(price: 17500));
      expect(outcome.completed, isTrue);
      final device = f.stock.byId('sh-1')!;
      expect(device.isSold, isTrue);
      // Realised against what it actually went for, not the asking price.
      expect(device.soldPrice, 17500);
      expect(device.costing.realisedProfit, 3000);
      expect(device.soldAt, isNotNull);
    });

    test('and the invoice number is assigned then, not before', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill());
      expect(outcome.sale!.invoiceNumber, 'INV-20260304-001');
      expect(outcome.sale!.status, SaleStatus.completed);
      expect(outcome.sale!.completedAt, isNotNull);
    });

    test('numbers never repeat', () async {
      final f = _Fixture(devices: [_device('sh-1'), _device('sh-2')]);
      addTearDown(f.dispose);
      final a = await f.sales.completeSale(_bill(id: 'a', deviceId: 'sh-1'));
      final b = await f.sales.completeSale(_bill(id: 'b', deviceId: 'sh-2'));
      expect(a.sale!.invoiceNumber, 'INV-20260304-001');
      expect(b.sale!.invoiceNumber, 'INV-20260304-002');
    });

    test(
      'a bill of only typed lines touches no stock and still completes',
      () async {
        final f = _Fixture();
        addTearDown(f.dispose);
        final outcome = await f.sales.completeSale(
          _bill(manualOnly: true, paid: 200),
        );
        expect(outcome.completed, isTrue);
        expect(f.stock.byId('sh-1')!.isSellable, isTrue);
      },
    );

    test('completing twice does not take the stock down twice', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final first = await f.sales.completeSale(_bill());
      final again = await f.sales.completeSale(first.sale!);
      expect(again.sale!.invoiceNumber, first.sale!.invoiceNumber);
      // And the counter was not consumed a second time.
      expect(f.stock.byId('sh-1')!.soldAt, isNotNull);
    });
  });

  group('a handset sold out from under the bill refuses the lot', () {
    test('nothing is written: no number, no sale, no wallet', () async {
      final f = _Fixture(
        devices: [_device('sh-1', status: kSold)],
        customers: [
          const Customer(id: 'c-1', name: 'Ramesh K', phone: '9876543210'),
        ],
      );
      addTearDown(f.dispose);
      await f.customers.moveWallet(
        'c-1',
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 500,
          reason: 'Deposit',
        ),
      );

      final outcome = await f.sales.completeSale(
        _bill(paid: 18500, walletUsed: 500),
      );
      expect(outcome.completed, isFalse);
      expect(outcome.unavailable, hasLength(1));
      // Named, with the reason, so the counter can change that one line
      // rather than guessing.
      expect(outcome.message, contains('Samsung Galaxy A54'));
      expect(outcome.message, contains('already sold'));
      // And the wallet was not touched.
      expect(f.customers.byId('c-1')!.walletBalance, 500);
      expect(f.sales.sales, isEmpty);
    });

    test('a handset on the bench is refused too', () async {
      final f = _Fixture(devices: [_device('sh-1', status: kRepairing)]);
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill());
      expect(outcome.completed, isFalse);
    });

    test('a handset whose record has gone is refused', () async {
      final f = _Fixture(devices: []);
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill());
      expect(outcome.completed, isFalse);
    });
  });

  group('the wallet part of the payment', () {
    test('is taken, as a debit against this bill', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      await f.customers.moveWallet(
        'c-1',
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 2000,
          reason: 'Part-exchange difference',
        ),
      );

      final outcome = await f.sales.completeSale(
        _bill(paid: 18500, walletUsed: 2000),
      );
      expect(outcome.completed, isTrue);
      expect(f.customers.byId('c-1')!.walletBalance, 0);
      final history = f.customers.walletHistory('c-1');
      expect(history.first.kind, WalletMoveKind.debit);
      expect(history.first.reference, 's-1');
    });

    test(
      'a wallet that cannot cover it refuses the sale, stock untouched',
      () async {
        final f = _Fixture();
        addTearDown(f.dispose);
        await f.customers.moveWallet(
          'c-1',
          const WalletMove(
            kind: WalletMoveKind.credit,
            amount: 300,
            reason: 'Deposit',
          ),
        );

        final outcome = await f.sales.completeSale(
          _bill(paid: 18500, walletUsed: 1000),
        );
        expect(outcome.completed, isFalse);
        expect(outcome.walletRefusal, contains('take the rest another way'));
        expect(f.customers.byId('c-1')!.walletBalance, 300);
        expect(f.stock.byId('sh-1')!.isSellable, isTrue);
      },
    );

    test('a wallet payment with nobody to take it from is refused', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      // Built rather than copied: copyWith cannot set customerId back to
      // null, and nothing in the app needs to — a bill does not have its
      // customer removed.
      final outcome = await f.sales.completeSale(
        Sale(
          id: 's-1',
          customerPhone: '9876543210',
          items: const [SaleItem(description: 'Fitting', unitPrice: 200)],
          amountPaid: 200,
          walletUsed: 100,
        ),
      );
      expect(outcome.completed, isFalse);
      expect(outcome.walletRefusal, contains('needs a customer record'));
    });
  });

  group('collecting a balance', () {
    test('an admin collects, and the balance comes down', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill(paid: 10000));
      final id = outcome.sale!.id;
      expect(f.sales.byId(id)!.balanceDue, 8500);

      final check = await f.sales.collect(id, 3000, isAdmin: true);
      expect(check.isAllowed, isTrue);
      expect(f.sales.byId(id)!.balanceDue, 5500);
    });

    test('staff cannot, and nothing moves', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill(paid: 10000));
      final check = await f.sales.collect(
        outcome.sale!.id,
        3000,
        isAdmin: false,
      );
      expect(check.refusal, CollectionRefusal.notAdmin);
      expect(f.sales.byId(outcome.sale!.id)!.balanceDue, 8500);
    });

    test('more than is owed is refused', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill(paid: 10000));
      final check = await f.sales.collect(
        outcome.sale!.id,
        99999,
        isAdmin: true,
      );
      expect(check.refusal, CollectionRefusal.overpayment);
      expect(f.sales.byId(outcome.sale!.id)!.amountPaid, 10000);
    });

    test('a financed bill has nothing to collect', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(
        _bill(method: 'Bajaj Finance', paid: 2000),
      );
      final check = await f.sales.collect(outcome.sale!.id, 100, isAdmin: true);
      expect(check.refusal, CollectionRefusal.nothingOwed);
      // And it is not in Due Payments.
      expect(dueAccounts(f.sales.sales), isEmpty);
    });

    test('a missing sale is said so', () {
      final f = _Fixture();
      addTearDown(f.dispose);
      expect(
        () => f.sales.collect('nope', 1, isAdmin: true),
        throwsA(isA<NoSuchSale>()),
      );
    });
  });

  group('cancelling', () {
    test(
      'a completed bill puts the handset back, and keeps the record',
      () async {
        final f = _Fixture();
        addTearDown(f.dispose);
        final outcome = await f.sales.completeSale(_bill());
        expect(f.stock.byId('sh-1')!.isSold, isTrue);

        final cancelled = await f.sales.cancelSale(
          outcome.sale!.id,
          reason: 'Customer changed their mind',
        );

        // Back on the shelf, through the one door that can do it.
        final device = f.stock.byId('sh-1')!;
        expect(device.isSellable, isTrue);
        expect(device.soldPrice, isNull);
        expect(device.soldAt, isNull);
        expect(device.notes, contains('Back in stock'));

        // The bill is kept: deleting it is how a till comes up short with
        // nothing to explain it.
        expect(cancelled.status, SaleStatus.cancelled);
        expect(f.sales.byId(outcome.sale!.id), isNotNull);
        expect(cancelled.notes, contains('Customer changed their mind'));
        // And it is no longer a debt.
        expect(unpaidSales(f.sales.sales), isEmpty);
      },
    );

    test('a returned phone: the shop gives back part, and keeps the rest '
        'in its takings', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(_bill());
      final paid = outcome.sale!.counterPaid;
      expect(paid, greaterThan(500));
      await expectLater(
        f.sales.cancelSale(
          outcome.sale!.id,
          reason: 'Returned',
          refundAmount: paid + 1,
        ),
        throwsA(anything),
      );
      final cancelled = await f.sales.cancelSale(
        outcome.sale!.id,
        reason: 'Returned',
        refundAmount: paid - 500,
      );
      expect(f.stock.byId('sh-1')!.isSellable, isTrue);
      expect(cancelled.refund!.amount, paid - 500);
      expect(cancelled.notes, contains('Kept on return: 500'));
      final report = buildReport(
        range: DateRange(
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 1)),
        ),
        sales: f.sales.sales,
        orders: const [],
        stock: const [],
        customers: const [],
      );
      expect(report.keptOnReturns, 500);
    });

    test('a draft has nothing to put back', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final draft = await f.sales.saveDraft(_bill());
      final cancelled = await f.sales.cancelSale(draft.id, reason: 'Changed');
      expect(cancelled.status, SaleStatus.cancelled);
      expect(f.stock.byId('sh-1')!.isSellable, isTrue);
    });

    test('a cancelled handset can be sold again', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final first = await f.sales.completeSale(_bill(id: 'a'));
      await f.sales.cancelSale(first.sale!.id, reason: 'Payment failed');

      // Without the one door back from sold, the only way to sell it again
      // was to re-enter it as a new purchase, double-counting stock and
      // margin.
      final second = await f.sales.completeSale(_bill(id: 'b'));
      expect(second.completed, isTrue);
      expect(f.stock.byId('sh-1')!.isSold, isTrue);
    });
  });

  group('product lines move the count, and only on completion', () {
    Sale productBill({int quantity = 3, String id = 's-1'}) => Sale(
      id: id,
      customerId: 'c-1',
      customerPhone: '9876543210',
      items: [
        SaleItem(
          description: 'Tempered glass',
          unitPrice: 199,
          quantity: quantity,
          source: LineSource.product,
          recordId: 'p-1',
        ),
      ],
      amountPaid: 199 * quantity,
    );

    test('a draft leaves the shelf alone', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      await f.sales.saveDraft(productBill());
      expect(f.products.byId('p-1')!.stockCount, 10);
    });

    test('completing takes the quantity off the shelf', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(productBill(quantity: 3));
      expect(outcome.completed, isTrue);
      expect(f.products.byId('p-1')!.stockCount, 7);
      // And the movement names the bill it came off.
      final move = f.products.history('p-1').first;
      expect(move.reference, 's-1');
      expect(move.quantity, 3);
    });

    test('more on the bill than on the shelf refuses the lot, and says how '
        'many are left', () async {
      final f = _Fixture(products: [_product(stock: 2)]);
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(productBill(quantity: 3));

      expect(outcome.completed, isFalse);
      // A product is a number, and the useful answer names it.
      expect(outcome.message, contains('only 2 left'));
      expect(outcome.message, contains('3 on the bill'));
      // Nothing was written: not the count, not the sale, not a number.
      expect(f.products.byId('p-1')!.stockCount, 2);
      expect(f.sales.sales, isEmpty);
    });

    test('a product whose record has gone refuses the bill', () async {
      final f = _Fixture(products: []);
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(productBill());
      expect(outcome.completed, isFalse);
      expect(outcome.message, contains('the product is gone'));
    });

    test('a bill mixing a handset, a product and a typed line', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(
        Sale(
          id: 's-1',
          customerId: 'c-1',
          customerPhone: '9876543210',
          items: const [
            SaleItem(
              description: 'Samsung Galaxy A54',
              unitPrice: 18500,
              source: LineSource.secondHand,
              recordId: 'sh-1',
            ),
            SaleItem(
              description: 'Tempered glass',
              unitPrice: 199,
              quantity: 2,
              source: LineSource.product,
              recordId: 'p-1',
            ),
            SaleItem(description: 'Fitting', unitPrice: 100),
          ],
          amountPaid: 18998,
        ),
      );

      expect(outcome.completed, isTrue);
      expect(f.stock.byId('sh-1')!.isSold, isTrue);
      expect(f.products.byId('p-1')!.stockCount, 8);
      expect(outcome.sale!.total, 18998);
    });

    test(
      'one bad line refuses the whole bill, including the good lines',
      () async {
        // Otherwise half a bill would be written and nobody would know which
        // half.
        final f = _Fixture(products: [_product(stock: 0)]);
        addTearDown(f.dispose);
        final outcome = await f.sales.completeSale(
          Sale(
            id: 's-1',
            customerId: 'c-1',
            customerPhone: '9876543210',
            items: const [
              SaleItem(
                description: 'Samsung Galaxy A54',
                unitPrice: 18500,
                source: LineSource.secondHand,
                recordId: 'sh-1',
              ),
              SaleItem(
                description: 'Tempered glass',
                unitPrice: 199,
                source: LineSource.product,
                recordId: 'p-1',
              ),
            ],
            amountPaid: 18699,
          ),
        );

        expect(outcome.completed, isFalse);
        expect(f.stock.byId('sh-1')!.isSellable, isTrue);
        expect(f.products.byId('p-1')!.stockCount, 0);
      },
    );

    test('cancelling puts the quantity back as a returned movement', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final outcome = await f.sales.completeSale(productBill(quantity: 3));
      expect(f.products.byId('p-1')!.stockCount, 7);

      await f.sales.cancelSale(outcome.sale!.id, reason: 'Changed their mind');
      expect(f.products.byId('p-1')!.stockCount, 10);
      final move = f.products.history('p-1').first;
      expect(move.kind.name, 'returned');
      expect(move.reason, contains('cancelled'));
    });

    test('a cancelled product line can be sold again', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final first = await f.sales.completeSale(productBill(id: 'a'));
      await f.sales.cancelSale(first.sale!.id, reason: 'Payment failed');
      final second = await f.sales.completeSale(productBill(id: 'b'));
      expect(second.completed, isTrue);
      expect(f.products.byId('p-1')!.stockCount, 7);
    });
  });

  group('bugs from the 23 Nov phone test', () {
    test('cancelling gives the wallet part back and records the refund '
        '(FM #10, #11)', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      await f.customers.moveWallet(
        'c-1',
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 2000,
          reason: 'Part-exchange difference',
        ),
      );
      final done = await f.sales.completeSale(
        _bill(paid: 18500, walletUsed: 2000),
      );
      expect(f.customers.byId('c-1')!.walletBalance, 0);
      final cancelled = await f.sales.cancelSale(
        done.sale!.id,
        reason: 'Changed their mind',
        refundMethod: 'UPI',
      );
      // The wallet money is back on the wallet...
      expect(f.customers.byId('c-1')!.walletBalance, 2000);
      // ...and the counter money is recorded as given back by UPI.
      expect(cancelled.refund!.amount, 16500);
      expect(cancelled.refund!.method, 'UPI');
    });

    test('a cancel needs a reason', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final done = await f.sales.completeSale(_bill());
      expect(
        () => f.sales.cancelSale(done.sale!.id, reason: '  '),
        throwsA(isA<String>()),
      );
      expect(f.sales.byId(done.sale!.id)!.completed, isTrue);
    });

    test('the same handset twice on one bill is refused (FM #3)', () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      final line = SaleItem(
        description: 'Samsung Galaxy A54',
        unitPrice: 10000,
        source: LineSource.secondHand,
        recordId: 'sh-1',
      );
      final result = await f.sales.completeSale(
        Sale(
          id: 's-dup',
          customerId: 'c-1',
          customerPhone: '9876543210',
          items: [line, line],
          amountPaid: 20000,
        ),
      );
      expect(result.completed, isFalse);
      expect(result.message, contains('on this bill twice'));
      expect(f.stock.byId('sh-1')!.isSold, isFalse);
    });

    test('5 + 5 of a product with 5 on the shelf is refused (FM #4)', () async {
      final f = _Fixture(products: [_product(stock: 5)]);
      addTearDown(f.dispose);
      const five = SaleItem(
        description: 'Tempered glass',
        unitPrice: 90,
        quantity: 5,
        source: LineSource.product,
        recordId: 'p-1',
      );
      final result = await f.sales.completeSale(
        const Sale(
          id: 's-over',
          customerId: 'c-1',
          customerPhone: '9876543210',
          items: [five, five],
          amountPaid: 900,
        ),
      );
      expect(result.completed, isFalse);
      expect(result.message, contains('only 5 left, 10 on the bill'));
      expect(f.products.byId('p-1')!.stockCount, 5);
    });
  });

  test('a change notifies, so the list redraws without being told', () async {
    final f = _Fixture();
    addTearDown(f.dispose);
    var notified = 0;
    f.sales.addListener(() => notified++);
    await f.sales.saveDraft(_bill());
    await f.sales.completeSale(_bill());
    expect(notified, 2);
  });
}
