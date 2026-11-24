import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/ui/screens/customers/customer_form_sheet.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/customers/wallet.dart';
import 'package:fm_shop/ui/screens/customers/customer_detail_screen.dart';
import 'package:fm_shop/ui/screens/customers/customer_list_screen.dart';

class Stores {
  Stores(this.customers, this.secondHand);
  final InMemoryCustomerStore customers;
  final InMemorySecondHandStore secondHand;
}

Future<Stores> pumpCustomers(
  WidgetTester tester,
  Widget screen, {
  List<Customer>? seed,
  DraftStore? drafts,
}) async {
  tester.view.physicalSize = const Size(500, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final customers = InMemoryCustomerStore(seed: seed);
  final secondHand = InMemorySecondHandStore();
  addTearDown(customers.dispose);
  addTearDown(secondHand.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<SecondHandRepository>.value(value: secondHand),
        Provider<DraftStore>.value(value: drafts ?? InMemoryDraftStore()),
      ],
      child: MaterialApp(
        home: screen,
        // The detail page links out to a stock record, so the router has to
        // exist for those taps to have somewhere to go.
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return Stores(customers, secondHand);
}

void main() {
  group('the list', () {
    testWidgets('a walk-in with no name shows by number, not as a blank row', (
      tester,
    ) async {
      await pumpCustomers(tester, const CustomerListScreen());
      expect(find.text('90000 22222'), findsOneWidget);
      expect(find.text('No name given'), findsOneWidget);
    });

    testWidgets('searching by a number typed with spaces finds them', (
      tester,
    ) async {
      await pumpCustomers(tester, const CustomerListScreen());
      await tester.enterText(
        find.byKey(const Key('customer-search')),
        '+91 91234 56780',
      );
      await tester.pumpAndSettle();
      expect(find.text('Priya S'), findsOneWidget);
      expect(find.text('Ramesh K'), findsNothing);
    });

    testWidgets(
      'a full number with no hit offers to add them with it filled in',
      (tester) async {
        await pumpCustomers(tester, const CustomerListScreen());
        await tester.enterText(
          find.byKey(const Key('customer-search')),
          '9000000001',
        );
        await tester.pumpAndSettle();

        expect(find.text('Add 90000 00001'), findsOneWidget);
        await tester.tap(find.text('Add 90000 00001'));
        await tester.pumpAndSettle();

        // The sheet opens with the number already in, so nobody reads it out
        // twice.
        final field = tester.widget<TextField>(
          find.byKey(const Key('customer-phone')),
        );
        expect(field.controller!.text, '9000000001');
      },
    );

    testWidgets('a half-typed number offers nothing to add', (tester) async {
      await pumpCustomers(tester, const CustomerListScreen());
      await tester.enterText(find.byKey(const Key('customer-search')), '90000');
      await tester.pumpAndSettle();
      expect(find.textContaining('Add '), findsNothing);
    });
  });

  group('the form', () {
    testWidgets('a number alone is enough to save', (tester) async {
      final stores = await pumpCustomers(
        tester,
        const CustomerListScreen(),
        seed: [],
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer-phone')),
        '9000000002',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stores.customers.customers, hasLength(1));
      expect(stores.customers.byPhone('9000000002'), isNotNull);
    });

    testWidgets('a number already in the book is refused, with who has it', (
      tester,
    ) async {
      final stores = await pumpCustomers(tester, const CustomerListScreen());

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer-phone')),
        '9876543210',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Already in the book'), findsWidgets);
      expect(find.textContaining('Ramesh K'), findsWidgets);
      // Nobody was added.
      expect(stores.customers.customers, hasLength(5));
    });
  });

  group('the wallet', () {
    testWidgets('credit goes in through the repository', (tester) async {
      final stores = await pumpCustomers(
        tester,
        const CustomerDetailScreen(id: 'c-1'),
      );

      await tester.tap(find.text('Add credit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('wallet-amount')), '350');
      await tester.enterText(
        find.byKey(const Key('wallet-reason')),
        'Refund left on account',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(stores.customers.byId('c-1')!.walletBalance, 350);
      expect(find.text('Wallet ₹350'), findsOneWidget);
      expect(find.text('Refund left on account'), findsOneWidget);
    });

    testWidgets('spending more than it holds is refused, balance untouched', (
      tester,
    ) async {
      final stores = await pumpCustomers(
        tester,
        const CustomerDetailScreen(id: 'c-1'),
      );
      await stores.customers.moveWallet(
        'c-1',
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 300,
          reason: 'Deposit',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spend'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('wallet-amount')), '500');
      await tester.enterText(
        find.byKey(const Key('wallet-reason')),
        'Against a bill',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(stores.customers.byId('c-1')!.walletBalance, 300);
      expect(find.textContaining('take the rest another way'), findsOneWidget);
    });

    testWidgets('an unexplained move is refused', (tester) async {
      final stores = await pumpCustomers(
        tester,
        const CustomerDetailScreen(id: 'c-1'),
      );

      await tester.tap(find.text('Add credit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('wallet-amount')), '100');
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(stores.customers.byId('c-1')!.walletBalance, 0);
      expect(
        find.textContaining('Say what this wallet move is for'),
        findsOneWidget,
      );
    });
  });

  group('the history is assembled by number', () {
    testWidgets('a handset this person sold the shop shows up', (tester) async {
      // Seed customer c-1 is Ramesh K on 9876543210, which is also the seller
      // on second-hand record sh-1.
      await pumpCustomers(tester, const CustomerDetailScreen(id: 'c-1'));
      expect(find.text('Samsung Galaxy A54 8/128'), findsOneWidget);
    });

    testWidgets('somebody who has sold nothing says so', (tester) async {
      // c-3 is the walk-in recorded by number alone, with nothing against it.
      await pumpCustomers(tester, const CustomerDetailScreen(id: 'c-3'));
      expect(find.text('Nothing yet.'), findsOneWidget);
    });

    testWidgets('a number written with +91 on the stock record still matches', (
      tester,
    ) async {
      // Second-hand sh-4 stores the seller as '+91 90000 11111'; customer c-4
      // is stored as ten digits. Normalizing on read is what joins them.
      await pumpCustomers(tester, const CustomerDetailScreen(id: 'c-4'));
      expect(find.text('Vivo Y21'), findsOneWidget);
    });
  });

  testWidgets('a missing customer is said so, not shown blank', (tester) async {
    await pumpCustomers(tester, const CustomerDetailScreen(id: 'nope'));
    expect(find.text('No customer nope'), findsOneWidget);
  });

  testWidgets("the customer's repairs show on their page, matched by number", (
    tester,
  ) async {
    final customers = InMemoryCustomerStore();
    final secondHand = InMemorySecondHandStore();
    final service = InMemoryServiceStore(
      seed: const [
        ServiceOrder(
          id: 'o-ramesh',
          orderNumber: 'SO-7',
          customerPhone: '98765 43210',
          brand: 'Apple',
          model: 'iPhone 11',
          status: 'In Progress',
        ),
        ServiceOrder(id: 'o-other', customerPhone: '9000000000'),
      ],
    );
    for (final d in [customers, secondHand, service]) {
      addTearDown(d.dispose);
    }
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CustomerRepository>.value(value: customers),
          ChangeNotifierProvider<SecondHandRepository>.value(value: secondHand),
          ChangeNotifierProvider<ServiceRepository>.value(value: service),
          Provider<DraftStore>.value(value: InMemoryDraftStore()),
        ],
        child: const MaterialApp(home: CustomerDetailScreen(id: 'c-1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-order-o-ramesh')), findsOneWidget);
    expect(find.byKey(const Key('history-order-o-other')), findsNothing);
    expect(find.textContaining('wired up'), findsNothing);
  });

  group('a draft about someone else', () {
    Future<String> openFor(WidgetTester tester, String draftPhone) async {
      final drafts = InMemoryDraftStore();
      await drafts.write(draftKey('customer'), {
        'phone': draftPhone,
        'name': 'Yesterday',
        'address': 'Old Street',
      });
      await pumpCustomers(
        tester,
        const Scaffold(body: CustomerForm(initialPhone: '9876543210')),
        drafts: drafts,
      );
      return tester
          .widget<TextField>(find.byKey(const Key('customer-name')))
          .controller!
          .text;
    }

    testWidgets('opened for another number: the draft is not used', (
      tester,
    ) async {
      expect(await openFor(tester, '9000000000'), '');
    });
  });
}
