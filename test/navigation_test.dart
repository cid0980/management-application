import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/app/nav.dart';
import 'package:fm_shop/app/router.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/rating_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/data/task_repository.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/dashboard/board.dart';
import 'package:fm_shop/domain/devices/tac_registry.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/ui/screens/sales/sale_form_sheet.dart';
import 'package:fm_shop/ui/screens/second_hand/second_hand_form_sheet.dart';
import 'package:fm_shop/ui/screens/service/service_form_sheet.dart';

Future<GoRouter> pumpApp(WidgetTester tester, AuthState auth) async {
  // A phone, not the 800x600 default: the More page lists every area the
  // bottom bar has no room for, and the last of them has to be on screen.
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = buildRouter(auth);
  final settings = InMemorySettingsStore();
  addTearDown(settings.dispose);
  final secondHand = InMemorySecondHandStore();
  addTearDown(secondHand.dispose);
  final customers = InMemoryCustomerStore();
  addTearDown(customers.dispose);
  final service = InMemoryServiceStore(settings: settings);
  addTearDown(service.dispose);
  final products = InMemoryProductStore();
  addTearDown(products.dispose);
  final enquiries = InMemoryEnquiryStore();
  addTearDown(enquiries.dispose);
  final tasks = InMemoryTaskStore();
  addTearDown(tasks.dispose);
  final sales = InMemorySalesStore(
    stock: secondHand,
    products: products,
    customers: customers,
  );
  addTearDown(sales.dispose);
  final labels = InMemoryLabelStore(
    targets: {
      LabelTargetKind.secondHand: LabelTargetBinding(
        snapshot: secondHand.labelSnapshot,
        attach: (id, number) => secondHand.attachLabel(id, number),
      ),
      LabelTargetKind.service: LabelTargetBinding(
        snapshot: service.labelSnapshot,
        attach: (_, _) async {},
      ),
      LabelTargetKind.product: LabelTargetBinding(
        snapshot: products.labelSnapshot,
        attach: (id, number) => products.attachLabel(id, number),
      ),
    },
  );
  addTearDown(labels.dispose);
  final ratings = InMemoryRatingStore();
  addTearDown(ratings.dispose);

  // The same providers main.dart gives the app. A screen that reaches for a
  // repository the test did not provide fails as a missing provider, not as a
  // routing problem, which is a long way from the real fault.
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        ChangeNotifierProvider<SecondHandRepository>.value(value: secondHand),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<ServiceRepository>.value(value: service),
        ChangeNotifierProvider<ProductRepository>.value(value: products),
        ChangeNotifierProvider<EnquiryRepository>.value(value: enquiries),
        ChangeNotifierProvider<TaskRepository>.value(value: tasks),
        ChangeNotifierProvider<SalesRepository>.value(value: sales),
        ChangeNotifierProvider<LabelRepository>.value(value: labels),
        ChangeNotifierProvider<RatingRepository>.value(value: ratings),
        Provider<PublicRatings>.value(value: ratings.public),
        Provider<TacRegistry>.value(value: SeedTacRegistry()),
        Provider<PrintServer>.value(value: RecordingPrintServer()),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('a signed-out open lands on login', (tester) async {
    final router = await pumpApp(tester, AuthState());
    expect(locationOf(router), '/login');
  });

  testWidgets('the scan page opens without signing in — that is the point of '
      'printing it on a label', (tester) async {
    final router = await pumpApp(tester, AuthState());
    router.go('/scan/26042');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/scan/26042');
    expect(find.text('Label 26042'), findsOneWidget);
  });

  testWidgets('the rating page opens without signing in — the customer has '
      'no account', (tester) async {
    final router = await pumpApp(tester, AuthState());
    router.go('/rate/some-token');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/rate/some-token');
    expect(find.textContaining('not valid'), findsOneWidget);
  });

  testWidgets('an admin reaches ratings; staff are sent home', (tester) async {
    final admin = AuthState();
    await admin.signInLocally(email: 'a@b.c', role: Role.admin);
    var router = await pumpApp(tester, admin);
    router.go('/admin/ratings');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/admin/ratings');

    final staff = AuthState();
    await staff.signInLocally(email: 's@b.c', role: Role.staff);
    router = await pumpApp(tester, staff);
    router.go('/admin/ratings');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/dashboard');
  });

  testWidgets('signing in lands on the dashboard', (tester) async {
    final auth = AuthState();
    final router = await pumpApp(tester, auth);
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    await tester.pumpAndSettle();
    expect(locationOf(router), '/dashboard');
  });

  testWidgets('staff following an admin link are put back on the dashboard', (
    tester,
  ) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.staff);
    final router = await pumpApp(tester, auth);
    router.go('/admin/settings');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/dashboard');
  });

  testWidgets('an admin reaches settings', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    final router = await pumpApp(tester, auth);
    router.go('/admin/settings');
    await tester.pumpAndSettle();
    expect(locationOf(router), '/admin/settings');
  });

  testWidgets('every nav destination resolves to a screen', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    final router = await pumpApp(tester, auth);
    for (final item in kNavItems.where((i) => !i.staffOnly)) {
      router.go(item.path);
      await tester.pumpAndSettle();
      expect(locationOf(router), item.path, reason: item.label);
      expect(
        find.text('No screen for ${item.path}'),
        findsNothing,
        reason: item.label,
      );
    }
  });

  testWidgets('detail routes resolve under every list', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    final router = await pumpApp(tester, auth);
    const details = [
      '/customers/c1',
      '/inventory/second-hand/d1',
      '/products/p1',
      '/service/s1',
      '/sales/x1',
      '/enquiries/e1',
    ];
    for (final path in details) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(locationOf(router), path);
      expect(find.text('No screen for $path'), findsNothing, reason: path);
    }
  });

  group('an account with no shop', () {
    testWidgets('lands on shop setup, not on an empty dashboard', (
      tester,
    ) async {
      // Every screen reads a shop's data, so a dashboard full of zeroes would
      // look like a broken app rather than an unfinished setup.
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin, shopId: '');
      final router = await pumpApp(tester, auth);
      expect(locationOf(router), '/shop/new');
    });

    testWidgets('cannot reach any shop screen by deep link', (tester) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin, shopId: '');
      final router = await pumpApp(tester, auth);

      for (final path in ['/dashboard', '/customers', '/sales', '/service']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(locationOf(router), '/shop/new', reason: path);
      }
    });

    testWidgets('once a shop is attached the setup screen is behind them', (
      tester,
    ) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin, shopId: '');
      final router = await pumpApp(tester, auth);
      expect(locationOf(router), '/shop/new');

      auth.attachShop(shopId: 'sri-balaji-4f2a', shopName: 'Sri Balaji');
      await tester.pumpAndSettle();
      expect(locationOf(router), '/dashboard');
    });

    testWidgets('hasShop is what the gate reads, not signedIn alone', (
      tester,
    ) async {
      final auth = AuthState();
      expect(auth.hasShop, isFalse);
      await auth.signInLocally(email: 'a@b.c', role: Role.admin, shopId: '');
      expect(auth.signedIn, isTrue);
      expect(auth.hasShop, isFalse);
      auth.attachShop(shopId: 's1', shopName: 'S1');
      expect(auth.hasShop, isTrue);
      // Whoever creates a shop is its admin by definition.
      expect(auth.isAdmin, isTrue);
    });
  });

  testWidgets('signing out returns to login', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    final router = await pumpApp(tester, auth);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(locationOf(router), '/login');
  });

  testWidgets('the More page hides admin areas from staff', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.staff);
    final router = await pumpApp(tester, auth);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/more');
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('Staff'), findsNothing);
    // The areas staff do work in are still there.
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('the More page shows admins every area', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    await pumpApp(tester, auth);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
  });

  testWidgets('there is no side menu', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    await pumpApp(tester, auth);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
  });

  group('Back goes one level up, and only Home leaves the app', () {
    test('a record goes back to its list', () {
      expect(backTarget('/customers/c1'), '/customers');
      expect(backTarget('/inventory/second-hand/d1'), '/inventory/second-hand');
      expect(backTarget('/service/s1'), '/service');
    });

    test('an area opened from More goes back to More', () {
      for (final path in [
        '/customers',
        '/products',
        '/sales',
        '/admin/settings',
        '/admin/staff',
        '/reports',
      ]) {
        expect(backTarget(path), kMorePath, reason: path);
      }
    });

    test('a bottom-bar tab goes back to Home', () {
      for (final path in [
        '/inventory/second-hand',
        '/scanner',
        '/service',
        kMorePath,
      ]) {
        expect(backTarget(path), '/dashboard', reason: path);
      }
    });

    test('Home is the only place Back closes the app', () {
      expect(backTarget('/dashboard'), isNull);
      for (final item in kNavItems.where((i) => i.path != '/dashboard')) {
        expect(backTarget(item.path), isNotNull, reason: item.path);
      }
    });

    testWidgets('pressing Back from an area opened via More lands on More', (
      tester,
    ) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      final router = await pumpApp(tester, auth);
      router.go('/customers');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(router), kMorePath);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(router), '/dashboard');
    });

    testWidgets('pressing Back from a record lands on its list', (
      tester,
    ) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      final router = await pumpApp(tester, auth);
      router.go('/service/s1');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(router), '/service');
    });
  });

  testWidgets('logging out from More returns to login', (tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.staff);
    final router = await pumpApp(tester, auth);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/login');
  });

  group('a "New …" button on Home opens the form, not the list', () {
    Future<GoRouter> home(WidgetTester tester) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      final router = await pumpApp(tester, auth);
      expect(locationOf(router), '/dashboard');
      return router;
    }

    testWidgets('New sale', (tester) async {
      final router = await home(tester);
      await tester.tap(find.byKey(const Key('home-new-sale')));
      await tester.pumpAndSettle();
      expect(find.byType(SaleForm), findsOneWidget);
      expect(locationOf(router), '/dashboard');
    });

    testWidgets('New service order', (tester) async {
      final router = await home(tester);
      await tester.tap(find.text('New service order'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceIntakeForm), findsOneWidget);
      expect(locationOf(router), '/dashboard');
    });

    testWidgets('New purchase', (tester) async {
      final router = await home(tester);
      await tester.tap(find.text('New purchase'));
      await tester.pumpAndSettle();
      expect(find.byType(PurchaseForm), findsOneWidget);
      expect(locationOf(router), '/dashboard');
    });
  });

  group('a Home tile opens its list on the tab it counts', () {
    String selectedChip(WidgetTester tester) {
      final chip = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .firstWhere((c) => c.selected);
      return (chip.label as Text).data!;
    }

    for (final (tile, starts) in [
      (BoardTile.overdue, 'Overdue'),
      (BoardTile.dueToday, 'Due Today'),
      (BoardTile.readyForPickup, 'Ready for pickup'),
      (BoardTile.lowStock, 'To order'),
      (BoardTile.pendingBills, 'Drafts'),
    ]) {
      testWidgets('$tile', (tester) async {
        final auth = AuthState();
        await auth.signInLocally(email: 'a@b.c', role: Role.admin);
        final router = await pumpApp(tester, auth);
        router.go(kBoardTileRoutes[tile]!);
        await tester.pumpAndSettle();
        expect(selectedChip(tester), startsWith(starts));
      });
    }

    testWidgets('an unknown tab falls back to the list\'s usual one', (
      tester,
    ) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      final router = await pumpApp(tester, auth);
      router.go('/service?tab=Nonsense');
      await tester.pumpAndSettle();
      expect(selectedChip(tester), startsWith('Open'));
    });
  });
}
