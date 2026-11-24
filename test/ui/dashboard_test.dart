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
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/ui/screens/dashboard/dashboard_screen.dart';
import 'package:fm_shop/ui/theme/app_theme.dart';

/// HOME, ON SCREEN
///
/// `board_test.dart` holds the counting rules down. This holds down what only
/// a widget can get wrong: a count that could not be read is drawn as a
/// failure rather than a zero, staff do not see money rows, and the repairs
/// that need somebody are drawn as job cards in the queue that was picked.
///
/// A repository that is refusing reads is simulated by a store that reports an
/// error — the same shape a `Firestore…Store` is in after a permission denial.
class _RefusingEnquiries extends InMemoryEnquiryStore {
  _RefusingEnquiries() : super(seed: const []);

  @override
  String? get error => "You do not have access to this shop's enquiries.";
}

class _RefusingSales extends InMemorySalesStore {
  _RefusingSales({
    required super.stock,
    required super.products,
    required super.customers,
  }) : super(seed: const []);

  @override
  String? get error => "You do not have access to this shop's sales.";
}

Future<void> _pump(
  WidgetTester tester, {
  EnquiryRepository? enquiries,
  bool refuseSales = false,
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

  final customerStore = InMemoryCustomerStore(seed: const []);
  final serviceStore = InMemoryServiceStore(seed: orders);
  final productStore = InMemoryProductStore(seed: const []);
  final stock = InMemorySecondHandStore(seed: const []);
  final salesStore = refuseSales
      ? _RefusingSales(
          stock: stock,
          products: productStore,
          customers: customerStore,
        )
      : InMemorySalesStore(
          seed: const [],
          stock: stock,
          products: productStore,
          customers: customerStore,
        );
  final enquiryStore = enquiries ?? InMemoryEnquiryStore(seed: const []);

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
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a count that could not be read is not drawn as a zero', (
    tester,
  ) async {
    await _pump(tester, enquiries: _RefusingEnquiries());

    // The enquiries row is on Home even though it has no number…
    expect(find.text('Open Enquiries'), findsOneWidget);
    // …and says it could not be read, rather than "0".
    expect(find.text('Could not be read'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsWidgets);
  });

  testWidgets('a real zero is still a number, and quiet rows stay hidden', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Could not be read'), findsNothing);
    // Today's ₹0, UPI ₹0, Cash ₹0 and dues ₹0: real zeros, drawn as numbers.
    expect(find.text('₹0'), findsWidgets);
    // Nothing owed: the dues card says so (Forest & Lime design, 2026-11-25)
    // rather than vanishing; no unfinished bills: that card is not drawn.
    expect(find.text('No pending credit'), findsOneWidget);
    expect(find.text('Pending Bills'), findsNothing);
  });

  testWidgets('staff do not see the money rows', (tester) async {
    await _pump(tester, refuseSales: true, isAdmin: false);

    expect(find.text('Due Payments'), findsNothing);
    expect(find.text('Pending Bills'), findsNothing);
  });

  testWidgets('an admin sees them', (tester) async {
    await _pump(tester, refuseSales: true);

    expect(find.text('Due Payments'), findsOneWidget);
    expect(find.text('Pending Bills'), findsOneWidget);
  });

  testWidgets('a late repair is a job card; Ready shows the ready ones', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      orders: [
        ServiceOrder(
          id: 'so-late',
          orderNumber: 'J-1039',
          customerName: 'Ramesh K',
          customerPhone: '9876543210',
          brand: 'Samsung',
          model: 'Galaxy M14',
          status: 'In Progress',
          receivedAt: now.subtract(const Duration(days: 5)),
          expectedCompletionAt: now.subtract(const Duration(days: 2)),
        ),
        ServiceOrder(
          id: 'so-ready',
          orderNumber: 'J-1037',
          customerName: 'Priya S',
          customerPhone: '9876500000',
          brand: 'Vivo',
          model: 'Y21',
          status: 'Ready',
          receivedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );

    // Late is picked first, because something is late.
    expect(find.byKey(const Key('home-job-so-late')), findsOneWidget);
    expect(find.text('2 days late'), findsOneWidget);
    expect(find.text('Samsung Galaxy M14'), findsOneWidget);
    expect(find.byKey(const Key('home-job-so-ready')), findsNothing);

    await tester.tap(find.byKey(const Key('home-queue-ready')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-job-so-ready')), findsOneWidget);
    expect(find.byKey(const Key('home-job-so-late')), findsNothing);
  });

  testWidgets('nothing needing action says so', (tester) async {
    await _pump(tester);

    expect(find.text('Nothing here right now'), findsOneWidget);
  });
}
