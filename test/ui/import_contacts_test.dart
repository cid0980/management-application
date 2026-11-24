import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/screens/customers/import_contacts_screen.dart';

Future<InMemoryCustomerStore> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final customers = InMemoryCustomerStore(
    seed: [const Customer(id: 'c-1', name: 'Ramesh K', phone: '9876543210')],
  );
  addTearDown(customers.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<CustomerRepository>.value(
      value: customers,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ImportContactsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return customers;
}

void main() {
  tearDown(() {
    readPhoneBook = () async => const PhoneBookRead();
    pickContactFile = () async => null;
  });

  testWidgets('from the phone: pick who to add, skip who is already in', (
    tester,
  ) async {
    readPhoneBook = () async => const PhoneBookRead(
      book: [
        ('Ramesh K', ['+91 98765 43210']),
        ('Anand', ['94431 22110']),
        ('Electricity office', ['80123 45678']),
      ],
    );
    final customers = await _pump(tester);
    await tester.tap(find.byKey(const Key('import-from-phone')));
    await tester.pumpAndSettle();

    expect(find.text('2 new · 1 already in your customers'), findsOneWidget);
    // Not a customer: unticked.
    await tester.tap(find.byKey(const Key('import-8012345678')));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 customer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-add')));
    await tester.pumpAndSettle();

    final names = customers.customers.map((c) => c.name).toSet();
    expect(names, containsAll(['Ramesh K', 'Anand']));
    expect(names, isNot(contains('Electricity office')));
  });

  testWidgets('Contacts not allowed: says so, adds nothing', (tester) async {
    readPhoneBook = () async => const PhoneBookRead(blocked: true);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('import-from-phone')));
    await tester.pumpAndSettle();
    expect(
      find.text('Allow Contacts for this app to import from the phone.'),
      findsOneWidget,
    );
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('from a CSV file', (tester) async {
    pickContactFile = () async =>
        'First Name,Last Name,Phone 1 - Value\nBhavani,S,90031 45567\n';
    final customers = await _pump(tester);
    await tester.tap(find.byKey(const Key('import-from-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-add')));
    await tester.pumpAndSettle();
    expect(
      customers.customers.any(
        (c) => c.name == 'Bhavani S' && c.phone == '9003145567',
      ),
      isTrue,
    );
  });

  testWidgets('a file that cannot be read says so', (tester) async {
    pickContactFile = () async => '';
    await _pump(tester);
    await tester.tap(find.byKey(const Key('import-from-file')));
    await tester.pumpAndSettle();
    expect(
      find.text("That file couldn't be read. Use a .csv or .vcf file."),
      findsOneWidget,
    );
  });
}
