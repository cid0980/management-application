import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/ui/screens/sales/due_payments_screen.dart';
import 'package:fm_shop/ui/screens/sales/sale_detail_screen.dart';
import 'package:fm_shop/ui/screens/sales/sale_form_sheet.dart';

SecondHandDevice _device(String id, {String status = kAvailable}) =>
    SecondHandDevice(
      id: id,
      brand: 'Samsung',
      model: 'Galaxy A54',
      imei: '354879104523681',
      status: status,
      purchasePrice: 14500,
      askingPrice: 18500,
      grade: 'A',
    );

class Harness {
  Harness(this.stock, this.customers, this.sales, this.products);
  final InMemorySecondHandStore stock;
  final InMemoryCustomerStore customers;
  final InMemorySalesStore sales;
  final InMemoryProductStore products;
}

Future<Harness> pumpSales(
  WidgetTester tester,
  Widget screen, {
  List<SecondHandDevice>? devices,
  List<Sale>? seed,
  List<Product>? productSeed,
  bool isAdmin = false,
}) async {
  tester.view.physicalSize = const Size(520, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final stock = InMemorySecondHandStore(
    seed: devices ?? [_device('sh-1'), _device('sh-2', status: kRepairing)],
  );
  final customers = InMemoryCustomerStore(
    seed: [const Customer(id: 'c-1', name: 'Ramesh K', phone: '9876543210')],
  );
  final products = InMemoryProductStore(seed: productSeed);
  final sales = InMemorySalesStore(
    stock: stock,
    products: products,
    customers: customers,
    seed: seed,
    counter: InMemoryCounter(),
    today: DateTime(2026, 3, 4),
  );
  final auth = AuthState();
  await auth.signInLocally(
    email: 'a@b.c',
    role: isAdmin ? Role.admin : Role.staff,
  );

  addTearDown(stock.dispose);
  addTearDown(products.dispose);
  addTearDown(customers.dispose);
  addTearDown(sales.dispose);
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<SecondHandRepository>.value(value: stock),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<ProductRepository>.value(value: products),
        ChangeNotifierProvider<SalesRepository>.value(value: sales),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return Harness(stock, customers, sales, products);
}

Sale _completed({
  String id = 's-1',
  num total = 1000,
  num paid = 0,
  String method = 'Cash',
}) => Sale(
  id: id,
  invoiceNumber: 'INV-20260304-001',
  customerId: 'c-1',
  customerName: 'Ramesh K',
  customerPhone: '9876543210',
  items: [SaleItem(description: 'Screen guard', unitPrice: total)],
  paymentMethod: method,
  amountPaid: paid,
  status: SaleStatus.completed,
  completedAt: DateTime(2026, 3, 1),
);

void main() {
  group('the stock picker', () {
    testWidgets(
      'offers only sellable handsets, and says why the rest are not',
      (tester) async {
        await pumpSales(tester, const SaleForm());
        await tester.tap(find.byKey(const Key('sale-add-stock')));
        await tester.pumpAndSettle();

        // Pickable.
        expect(find.byKey(const Key('pick-sh-1')), findsOneWidget);
        // Shown, not absent: a device that simply does not appear is one staff
        // re-enter as a new purchase.
        expect(find.byKey(const Key('pick-sh-2')), findsNothing);
        expect(find.text('On the bench — not ready to sell'), findsOneWidget);
      },
    );

    testWidgets('an already sold handset explains itself', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        devices: [_device('sh-1', status: kSold)],
      );
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      expect(find.text('Already sold'), findsOneWidget);
      expect(
        find.text('Nothing sellable in second-hand stock.'),
        findsOneWidget,
      );
    });

    testWidgets('sits below the status bar, not under the clock', (
      tester,
    ) async {
      await pumpSales(tester, const SaleForm());
      tester.view.padding = const FakeViewPadding(top: 48);
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('In stock')).dy, greaterThan(48));
    });

    testWidgets('rows look tappable: an Add button on what can be picked, '
        'none on what cannot', (tester) async {
      await pumpSales(tester, const SaleForm());
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('pick-sh-1')),
          matching: find.text('Add'),
        ),
        findsOneWidget,
      );
      // sh-2 is on the bench: shown greyed, with no button.
      expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('pick-sh-1')),
          matching: find.text('Add'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Galaxy A54'), findsWidgets);
    });

    testWidgets('a brand row narrows the stock to one brand', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        devices: [
          _device('sh-1'),
          _device('sh-3').copyWith(brand: 'Oppo', model: 'A17'),
          _device('sh-4').copyWith(brand: 'Oppo', model: 'A78'),
        ],
      );
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-brand-all')), findsOneWidget);
      await tester.tap(find.byKey(const Key('pick-brand-Oppo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-sh-1')), findsNothing);
      expect(find.byKey(const Key('pick-sh-3')), findsOneWidget);
      expect(find.byKey(const Key('pick-sh-4')), findsOneWidget);
      await tester.tap(find.byKey(const Key('pick-brand-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-sh-1')), findsOneWidget);
    });

    testWidgets('a search box narrows a long list', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        devices: [
          _device('sh-1'),
          _device('sh-3').copyWith(brand: 'Oppo', model: 'A17'),
        ],
      );
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-sh-1')), findsOneWidget);
      expect(find.byKey(const Key('pick-sh-3')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('pick-stock-search')),
        'oppo',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-sh-1')), findsNothing);
      expect(find.byKey(const Key('pick-sh-3')), findsOneWidget);
    });
  });

  group('nothing moves until Complete', () {
    testWidgets('adding a handset to the bill does not sell it', (
      tester,
    ) async {
      final h = await pumpSales(tester, const SaleForm());
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-sh-1')));
      await tester.pumpAndSettle();

      expect(find.text('Samsung Galaxy A54'), findsWidgets);
      expect(h.stock.byId('sh-1')!.isSellable, isTrue);
    });

    testWidgets('keeping it as a draft leaves the shelf alone', (tester) async {
      final h = await pumpSales(tester, const SaleForm());
      await tester.enterText(find.byKey(const Key('sale-phone')), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-sh-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep as draft'));
      await tester.pumpAndSettle();

      expect(h.sales.sales.single.status, SaleStatus.draft);
      expect(h.sales.sales.single.invoiceNumber, '');
      expect(h.stock.byId('sh-1')!.isSellable, isTrue);
    });

    testWidgets('completing sells it and numbers the invoice', (tester) async {
      final h = await pumpSales(tester, const SaleForm());
      await tester.enterText(find.byKey(const Key('sale-phone')), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ramesh K · 98765 43210'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sale-add-stock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-sh-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sale-paid')), '18500');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();

      expect(h.stock.byId('sh-1')!.isSold, isTrue);
      expect(h.stock.byId('sh-1')!.soldPrice, 18500);
      expect(h.sales.sales.single.invoiceNumber, 'INV-20260304-001');
    });

    testWidgets('an empty bill cannot be completed', (tester) async {
      final h = await pumpSales(tester, const SaleForm());
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();
      expect(h.sales.sales, isEmpty);
      expect(find.text('Nothing on the bill yet'), findsWidgets);
    });
  });

  group('a typed line', () {
    testWidgets('goes on the bill and touches no stock', (tester) async {
      final h = await pumpSales(tester, const SaleForm());
      await tester.enterText(find.byKey(const Key('sale-phone')), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sale-add-line')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('line-description')),
        'Fitting charge',
      );
      await tester.enterText(find.byKey(const Key('line-price')), '200');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sale-paid')), '200');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();

      expect(h.sales.sales.single.completed, isTrue);
      expect(h.stock.byId('sh-1')!.isSellable, isTrue);
    });
  });

  group('the product picker', () {
    Product prod({
      String id = 'p-1',
      String name = 'Tempered glass',
      int count = 10,
    }) => Product(
      id: id,
      name: name,
      brand: 'Spigen',
      category: 'Screen guard',
      costPrice: 45,
      sellingPrice: 199,
      stockCount: count,
      reorderLevel: 4,
    );

    testWidgets('offers only what is on the shelf, and says why the rest is '
        'not', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [
          prod(),
          prod(id: 'p-2', name: 'Cable', count: 0),
        ],
      );
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pick-product-p-1')), findsOneWidget);
      // Shown, not absent: a product that does not appear is one somebody
      // adds a second record for.
      expect(find.byKey(const Key('pick-product-p-2')), findsNothing);
      expect(find.text('None on the shelf'), findsOneWidget);
    });

    testWidgets('a category row narrows the products', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [
          prod(),
          prod(id: 'p-3', name: 'Probe Cable').copyWith(category: 'Cable'),
        ],
      );
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-category-Cable')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-product-p-1')), findsNothing);
      expect(find.byKey(const Key('pick-product-p-3')), findsOneWidget);
    });

    testWidgets('the product picker searches too', (tester) async {
      await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [
          prod(),
          prod(id: 'p-3', name: 'Probe Cable'),
        ],
      );
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('pick-product-search')),
        'probe',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-product-p-1')), findsNothing);
      expect(find.byKey(const Key('pick-product-p-3')), findsOneWidget);
    });

    testWidgets('a product line goes on the bill and moves nothing yet', (
      tester,
    ) async {
      final h = await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [prod()],
      );
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-product-p-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sale-product-quantity')),
        '3',
      );
      await tester.tap(find.byKey(const Key('sale-quantity-add')));
      await tester.pumpAndSettle();

      expect(find.textContaining('₹199 × 3'), findsOneWidget);
      // Nothing moves until Complete.
      expect(h.products.byId('p-1')!.stockCount, 10);
    });

    testWidgets('more than the shelf holds is said, not quietly cut down', (
      tester,
    ) async {
      // Finding out after the customer has been told a total is the wrong
      // moment.
      final h = await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [prod(count: 2)],
      );
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-product-p-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sale-product-quantity')),
        '99',
      );
      await tester.tap(find.byKey(const Key('sale-quantity-add')));
      await tester.pumpAndSettle();
      expect(find.text('Only 2 left — that is all there is'), findsOneWidget);
      expect(find.textContaining('₹199 ×'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('sale-product-quantity')),
        '2',
      );
      await tester.tap(find.byKey(const Key('sale-quantity-add')));
      await tester.pumpAndSettle();
      expect(find.textContaining('₹199 × 2'), findsOneWidget);
      expect(h.products.byId('p-1')!.stockCount, 2);

      // Added again, the picker counts what the bill already takes.
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-product-p-1')), findsNothing);
      expect(find.text('All of it is already on this bill'), findsOneWidget);
    });

    testWidgets('completing takes the quantity off the shelf', (tester) async {
      final h = await pumpSales(
        tester,
        const SaleForm(),
        productSeed: [prod()],
      );
      await tester.enterText(find.byKey(const Key('sale-phone')), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sale-add-product')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-product-p-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sale-product-quantity')),
        '3',
      );
      await tester.tap(find.byKey(const Key('sale-quantity-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sale-paid')), '597');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();

      expect(h.products.byId('p-1')!.stockCount, 7);
      expect(h.sales.sales.single.completed, isTrue);
      expect(h.products.history('p-1').first.kind.name, 'sold');
    });
  });

  group('the bill detail', () {
    testWidgets(
      'a financed bill shows no balance — the customer owes nothing',
      (tester) async {
        await pumpSales(
          tester,
          const SaleDetailScreen(id: 's-1'),
          seed: [_completed(total: 18500, paid: 2000, method: 'Bajaj Finance')],
        );
        expect(
          find.text('nothing — financed through Bajaj Finance'),
          findsOneWidget,
        );
        expect(find.textContaining('Collect'), findsNothing);
      },
    );

    testWidgets('staff see what is owed and are told they may not collect', (
      tester,
    ) async {
      final h = await pumpSales(
        tester,
        const SaleDetailScreen(id: 's-1'),
        seed: [_completed(total: 1000, paid: 400)],
      );
      // Shown, then refused with a reason: "no way to do this" and "you may
      // not do this" are different answers to give at a counter.
      await tester.tap(find.text('Collect ₹600'));
      await tester.pumpAndSettle();
      expect(find.text('Only an admin may collect a balance'), findsOneWidget);
      expect(h.sales.byId('s-1')!.amountPaid, 400);
    });

    testWidgets('an admin collects, and part payments are fine', (
      tester,
    ) async {
      final h = await pumpSales(
        tester,
        const SaleDetailScreen(id: 's-1'),
        seed: [_completed(total: 1000, paid: 400)],
        isAdmin: true,
      );
      await tester.tap(find.text('Collect ₹600'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('collect-amount')), '200');
      await tester.tap(find.widgetWithText(FilledButton, 'Collect'));
      await tester.pumpAndSettle();

      expect(h.sales.byId('s-1')!.balanceDue, 400);
      expect(find.textContaining('₹400 still owed'), findsOneWidget);
    });

    testWidgets('collecting more than is owed is refused', (tester) async {
      final h = await pumpSales(
        tester,
        const SaleDetailScreen(id: 's-1'),
        seed: [_completed(total: 1000, paid: 400)],
        isAdmin: true,
      );
      await tester.tap(find.text('Collect ₹600'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('collect-amount')), '5000');
      await tester.tap(find.widgetWithText(FilledButton, 'Collect'));
      await tester.pumpAndSettle();

      expect(find.textContaining('more than is owed'), findsOneWidget);
      expect(h.sales.byId('s-1')!.amountPaid, 400);
    });

    testWidgets('a missing sale is said so', (tester) async {
      await pumpSales(tester, const SaleDetailScreen(id: 'nope'));
      expect(find.text('No sale nope'), findsOneWidget);
    });
  });

  group('due payments', () {
    testWidgets('a financed sale is never on the list', (tester) async {
      await pumpSales(
        tester,
        const DuePaymentsScreen(),
        seed: [_completed(total: 18500, paid: 0, method: 'Bajaj Finance')],
      );
      expect(find.text('Nothing outstanding'), findsOneWidget);
      expect(find.textContaining('owe the shop nothing'), findsOneWidget);
    });

    testWidgets('one customer with two bills is one row', (tester) async {
      await pumpSales(
        tester,
        const DuePaymentsScreen(),
        seed: [
          _completed(id: 'a', total: 1000, paid: 0),
          _completed(id: 'b', total: 500, paid: 100),
        ],
      );
      expect(find.text('₹1,400 owed by 1 customer'), findsOneWidget);
      expect(find.text('Ramesh K'), findsOneWidget);
      expect(find.textContaining('2 bills'), findsOneWidget);
    });

    testWidgets('a draft is not a debt', (tester) async {
      await pumpSales(
        tester,
        const DuePaymentsScreen(),
        seed: [
          Sale(
            id: 'd',
            customerId: 'c-1',
            customerPhone: '9876543210',
            items: const [SaleItem(description: 'Guard', unitPrice: 1000)],
          ),
        ],
      );
      expect(find.text('Nothing outstanding'), findsOneWidget);
    });
  });
}
