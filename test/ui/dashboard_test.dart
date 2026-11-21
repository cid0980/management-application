import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/ui/screens/dashboard/dashboard_screen.dart';

/// THE BOARD, ON SCREEN
///
/// `board_test.dart` holds the counting rules down. This holds down the one
/// thing only a widget can be wrong about: that a count which could not be
/// read is drawn as a failure rather than as a zero.
///
/// A repository that is refusing reads is simulated by a store that reports an
/// error — the same shape a `Firestore…Store` is in after a permission denial.
class _RefusingCustomers extends InMemoryCustomerStore {
  _RefusingCustomers() : super(seed: const []);

  @override
  String? get error => "You do not have access to this shop's customers.";
}

Future<void> _pump(
  WidgetTester tester, {
  CustomerRepository? customers,
  List<ServiceOrder> orders = const [],
  bool isAdmin = true,
}) async {
  tester.view.physicalSize = const Size(600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthState();
  await auth.signInLocally(
    email: 'ramesh@shop.com',
    role: isAdmin ? Role.admin : Role.staff,
  );

  final customerStore = customers ?? InMemoryCustomerStore(seed: const []);
  final serviceStore = InMemoryServiceStore(seed: orders);
  final productStore = InMemoryProductStore(seed: const []);
  final stock = InMemorySecondHandStore(seed: const []);
  final salesStore = InMemorySalesStore(
    seed: const [],
    stock: stock,
    products: productStore,
    customers: customerStore,
  );
  final enquiryStore = InMemoryEnquiryStore(seed: const []);

  for (final d in [
    auth,
    customerStore,
    serviceStore,
    productStore,
    stock,
    salesStore,
    enquiryStore,
  ]) {
    addTearDown(d.dispose);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<CustomerRepository>.value(value: customerStore),
        ChangeNotifierProvider<ServiceRepository>.value(value: serviceStore),
        ChangeNotifierProvider<ProductRepository>.value(value: productStore),
        ChangeNotifierProvider<SalesRepository>.value(value: salesStore),
        ChangeNotifierProvider<EnquiryRepository>.value(value: enquiryStore),
      ],
      child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a count that could not be read is not drawn as a zero',
      (tester) async {
    await _pump(tester, customers: _RefusingCustomers());

    // The customers tile is on the board…
    expect(find.text('Customers'), findsOneWidget);
    // …and says it could not be read, rather than "0".
    expect(find.text('Could not be read'), findsWidgets);
    expect(find.byIcon(Icons.error_outline), findsWidgets);
  });

  testWidgets('a real zero is still a number', (tester) async {
    await _pump(tester);

    expect(find.text('Could not be read'), findsNothing);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('staff do not see the money tiles', (tester) async {
    await _pump(tester, isAdmin: false);

    expect(find.text('Due Payments'), findsNothing);
    expect(find.text('Pending Bills'), findsNothing);
    expect(find.text('Pending Orders'), findsOneWidget);
  });

  testWidgets('an admin sees them', (tester) async {
    await _pump(tester);

    expect(find.text('Due Payments'), findsOneWidget);
    expect(find.text('Pending Bills'), findsOneWidget);
  });

  testWidgets('recent orders are listed, newest first', (tester) async {
    final today = DateTime.now();
    await _pump(tester, orders: [
      ServiceOrder(
        id: 'so-old',
        customerName: 'Ramesh K',
        brand: 'Samsung',
        model: 'Galaxy M14',
        status: 'In Progress',
        receivedAt: today.subtract(const Duration(days: 4)),
      ),
      ServiceOrder(
        id: 'so-new',
        customerName: 'Priya S',
        brand: 'Xiaomi',
        model: 'Redmi 13C',
        status: 'In Progress',
        receivedAt: today,
      ),
    ]);

    final newest = tester.getTopLeft(find.text('Xiaomi Redmi 13C')).dy;
    final oldest = tester.getTopLeft(find.text('Samsung Galaxy M14')).dy;
    expect(newest, lessThan(oldest));
  });

  testWidgets('nothing taken in yet says so', (tester) async {
    await _pump(tester);

    expect(find.text('Nothing taken in yet'), findsOneWidget);
  });

  testWidgets('a customer added today is counted as new today',
      (tester) async {
    final store = InMemoryCustomerStore(seed: [
      Customer(
        id: 'c-1',
        name: 'Ramesh K',
        phone: '9876543210',
        createdAt: DateTime.now(),
      ),
    ]);
    await _pump(tester, customers: store);

    expect(find.text('New Today'), findsOneWidget);
    // One customer, and one of them new today.
    expect(find.text('1'), findsNWidgets(2));
  });
}
