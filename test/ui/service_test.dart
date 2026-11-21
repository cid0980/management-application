import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/service/checklist.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';
import 'package:fm_shop/ui/screens/service/service_detail_screen.dart';
import 'package:fm_shop/ui/screens/service/service_list_screen.dart';

const _checklist = ['Display OK', 'Charging tested'];

/// The settings store the last pumped screen was given, so a test can read
/// what a form filed.
late InMemorySettingsStore lastSettings;

ServiceOrder _o(
  String id, {
  String status = 'In Progress',
  Map<String, bool>? checklist,
  num? finalPrice,
  DateTime? expected,
}) =>
    ServiceOrder(
      id: id,
      orderNumber: 'SO-20260304-001',
      customerId: 'c-1',
      customerName: 'Ramesh K',
      customerPhone: '9876543210',
      brand: 'Samsung',
      model: 'Galaxy M14',
      imei: '354879104523681',
      complaints: const ['Not charging'],
      estimatedPrice: 1400,
      rawMaterialCost: 650,
      technician: 'Suresh',
      status: status,
      finalPrice: finalPrice,
      checklist: checklist ?? const {},
      receivedAt: DateTime(2026, 3, 1),
      expectedCompletionAt: expected ?? DateTime.now().add(const Duration(days: 2)),
    );

Future<InMemoryServiceStore> pumpService(
  WidgetTester tester,
  Widget screen, {
  List<ServiceOrder>? seed,
  bool isAdmin = false,
}) async {
  tester.view.physicalSize = const Size(520, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final service = InMemoryServiceStore(
    seed: seed ?? [],
    checklist: _checklist,
    counter: InMemoryCounter(),
    today: DateTime(2026, 3, 4),
  );
  final customers = InMemoryCustomerStore();
  final auth = AuthState();
  await auth.signInLocally(
    email: 'a@b.c',
    role: isAdmin ? Role.admin : Role.staff,
  );
  addTearDown(service.dispose);
  addTearDown(customers.dispose);
  addTearDown(auth.dispose);

  final settingsStore = InMemorySettingsStore();

  addTearDown(settingsStore.dispose);
  lastSettings = settingsStore;


  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<SettingsRepository>.value(
          value: settingsStore,
        ),
        ChangeNotifierProvider<ServiceRepository>.value(value: service),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

Future<void> tapTab(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('the list', () {
    testWidgets('a job finished last month is not shown as an alarm',
        (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [
        _o('done',
            status: 'Completed',
            finalPrice: 1800,
            expected: DateTime(2026, 1, 1)),
      ]);
      // Closed beats overdue: the Overdue tab is empty and the row reads as
      // finished.
      expect(find.text('Overdue 0'), findsOneWidget);
      await tapTab(tester, 'Completed 1');
      expect(find.text('Finished'), findsOneWidget);
    });

    testWidgets('an overdue job is in Overdue and reads as an alarm',
        (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [
        _o('late', expected: DateTime.now().subtract(const Duration(days: 2))),
      ]);
      expect(find.text('Overdue 1'), findsOneWidget);
      expect(find.text('Overdue'), findsWidgets);
    });

    testWidgets('a status this build has never seen shows as itself',
        (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [
        ServiceOrder.fromMap('x', {
          'orderNumber': 'SO-1',
          'brand': 'Vivo',
          'model': 'T2x',
          'status': 'Waiting For Spare',
          'complaints': ['Software / hanging'],
          'receivedAt': '2026-03-01T10:00:00.000Z',
          'expectedCompletionAt':
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        }),
      ]);
      expect(find.text('Waiting For Spare'), findsOneWidget);
      expect(find.text('Open 1'), findsOneWidget);
    });

    testWidgets('search covers the order number and the IMEI', (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [_o('a')]);
      await tester.enterText(
          find.byKey(const Key('service-search')), '354879104523681');
      await tester.pumpAndSettle();
      expect(find.text('Samsung Galaxy M14'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('service-search')), 'iphone');
      await tester.pumpAndSettle();
      expect(find.textContaining('No match'), findsOneWidget);
    });
  });

  group('the status picker', () {
    testWidgets('Completed is not offered to anyone, of any role',
        (tester) async {
      for (final isAdmin in [false, true]) {
        await pumpService(
          tester,
          const ServiceDetailScreen(id: 'a'),
          seed: [_o('a')],
          isAdmin: isAdmin,
        );
        expect(
          find.widgetWithText(ChoiceChip, 'Completed'),
          findsNothing,
          reason: 'isAdmin: $isAdmin',
        );
        expect(find.textContaining('Completed is not here for anyone'),
            findsOneWidget);
      }
    });

    testWidgets('staff are not offered Received; an admin is', (tester) async {
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      expect(find.widgetWithText(ChoiceChip, 'Received'), findsNothing);

      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
        isAdmin: true,
      );
      expect(find.widgetWithText(ChoiceChip, 'Received'), findsOneWidget);
    });

    testWidgets('an ordinary step goes through', (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Parts Awaiting'));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.status, 'Parts Awaiting');
    });
  });

  group('handing the phone back', () {
    testWidgets('a half-ticked list is refused, and names what is left',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a', finalPrice: 1800)],
      );
      await tester.tap(find.text('Hand the phone back'));
      await tester.pumpAndSettle();

      // Named, not "the checklist is incomplete" — that sends someone
      // scrolling a list looking for the one they missed.
      expect(find.textContaining('Still to check: Display OK'),
          findsOneWidget);
      expect(store.byId('a')!.closed, isFalse);
    });

    testWidgets('ticking the list and charging opens the door', (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a', finalPrice: 1800)],
      );
      for (final e in checklistEntries(_checklist)) {
        await tester.tap(find.byKey(Key('check-${e.key}')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Hand the phone back'));
      await tester.pumpAndSettle();

      expect(store.byId('a')!.status, 'Completed');
      expect(find.textContaining('Handed back'), findsWidgets);
    });

    testWidgets('nothing charged is refused even with a full list',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      for (final e in checklistEntries(_checklist)) {
        await tester.tap(find.byKey(Key('check-${e.key}')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Hand the phone back'));
      await tester.pumpAndSettle();

      expect(store.byId('a')!.closed, isFalse);
      expect(find.textContaining('Say what is being charged'), findsOneWidget);
    });

    testWidgets('charging through the dialog, then completing', (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await tester.tap(find.text('Set what is charged'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('charge-amount')), '1800');
      await tester.tap(find.widgetWithText(FilledButton, 'Set'));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.finalPrice, 1800);

      for (final e in checklistEntries(_checklist)) {
        await tester.tap(find.byKey(Key('check-${e.key}')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Hand the phone back'));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.closed, isTrue);
    });

    testWidgets('a closed order offers no checklist and no status change',
        (tester) async {
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [
          _o('a',
              status: 'Completed',
              finalPrice: 1800,
              checklist: {
                for (final e in checklistEntries(_checklist)) e.key: true
              }),
        ],
      );
      expect(find.text('Hand the phone back'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('Nothing more is owed on it'), findsOneWidget);
      // The final bill replaces the job card once it has gone out.
      expect(find.text('Print final bill'), findsOneWidget);
    });

    testWidgets('returned unrepaired closes it with no checklist to pass',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await tester.tap(find.text('Returned unrepaired'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('return-reason')), 'Beyond repair');
      await tester.tap(find.widgetWithText(FilledButton, 'Return it'));
      await tester.pumpAndSettle();

      expect(store.byId('a')!.status, 'Returned');
      expect(store.byId('a')!.complaintNotes, contains('Beyond repair'));
    });
  });

  group('what an intake files', () {
    testWidgets('a complaint the shop has never seen joins the list',
        (tester) async {
      // The job card and the final bill are both built from these, so a
      // complaint typed once has to be findable the next time.
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('Take in'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('service-customerPhone')), '9876543210');
      await tester.enterText(
          find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(
          find.byKey(const Key('service-model')), 'X9b');
      await tester.pumpAndSettle();

      final complaint = find.widgetWithText(FilterChip, 'Not charging');
      await tester.ensureVisible(complaint);
      await tester.pumpAndSettle();
      await tester.tap(complaint);
      await tester.pumpAndSettle();

      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.orders, hasLength(1));
      expect(lastSettings.settings.list(OptionKind.brands).contains('Honor'),
          isTrue);
      expect(lastSettings.settings.modelsFor('Honor').values, ['X9b']);
    });

    testWidgets("only the chosen brand's models are suggested",
        (tester) async {
      await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('Take in'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('service-brand')), 'Apple');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ActionChip, 'iPhone 11'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Galaxy A54'), findsNothing);
    });
  });

  testWidgets('a missing order is said so, not shown blank', (tester) async {
    await pumpService(tester, const ServiceDetailScreen(id: 'nope'));
    expect(find.textContaining('No service order nope'), findsOneWidget);
  });

  testWidgets('a phone back under the shop warranty is flagged at intake',
      (tester) async {
    final now = DateTime.now();
    await pumpService(tester, const ServiceListScreen(), seed: [
      ServiceOrder(
        id: 'old',
        orderNumber: 'SO-OLD',
        imei: '356789012345678',
        status: 'Completed',
        warrantyDays: 30,
        completedAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
    await tester.tap(find.text('Take in'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsNothing);
    await tester.enterText(
        find.byKey(const Key('service-imei')), '356789012345678');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsOneWidget);
    expect(find.textContaining('SO-OLD'), findsOneWidget);
  });
}
