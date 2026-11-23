import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chips.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';
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
import 'package:fm_shop/ui/screens/service/hand_over_page.dart';
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

Future<void> tapTab(WidgetTester tester, String label) =>
    tapChip(tester, label);

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
      expect(chipLabelled('Overdue 0'), findsOneWidget);
      await tapTab(tester, 'Completed 1');
      // Its own status, and no "Overdue" alarm pill on the row.
      expect(find.widgetWithText(StatusPill, 'Completed'), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Overdue'), findsNothing);
    });

    testWidgets('an overdue job is in Overdue and reads as an alarm',
        (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [
        _o('late', expected: DateTime.now().subtract(const Duration(days: 2))),
      ]);
      expect(chipLabelled('Overdue 1'), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Overdue'), findsOneWidget);
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
      expect(chipLabelled('Open 1'), findsOneWidget);
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
    Future<void> openHandOver(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('hand-back')));
      await tester.pumpAndSettle();
      expect(find.byType(HandOverPage), findsOneWidget);
    }

    Future<void> tickAll(WidgetTester tester) async {
      for (final e in checklistEntries(_checklist)) {
        final row = find.byKey(Key('handover-${e.key}'));
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('the button opens its own page; a missed check is pointed at',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a', finalPrice: 1800)],
      );
      await openHandOver(tester);
      expect(find.text('Display OK'), findsOneWidget);
      expect(find.text('0 of 2 ticked'), findsOneWidget);
      // Never greyed out: pressed early, it says what is left, in red.
      await tester.tap(find.byKey(const Key('handover-confirm')));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.closed, isFalse);
      expect(find.text('2 checks left'), findsWidgets);
    });

    testWidgets('ticks, the price, UPI: handed back and the page closes',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a', finalPrice: 1800)],
      );
      await openHandOver(tester);
      await tickAll(tester);
      expect(find.text('Hand over · collect ₹1,800'), findsOneWidget);
      await tester.tap(find.byKey(const Key('handover-pay-UPI')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('handover-confirm')));
      await tester.pumpAndSettle();

      expect(store.byId('a')!.status, 'Completed');
      expect(store.byId('a')!.pickupPayment!.method, 'UPI');
      expect(store.byId('a')!.pickupPayment!.amount, 1800);
      expect(find.byType(HandOverPage), findsNothing);
      expect(find.textContaining('Handed back'), findsWidgets);
    });

    testWidgets('nothing charged yet: the estimate is filled in and can change',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await openHandOver(tester);
      expect(find.text('1400'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('handover-price')), '1600');
      await tester.pumpAndSettle();
      await tickAll(tester);
      await tester.tap(find.byKey(const Key('handover-confirm')));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.finalPrice, 1600);
      expect(store.byId('a')!.pickupPayment!.method, 'Cash');
      expect(store.byId('a')!.closed, isTrue);
    });

    testWidgets('an empty price is pointed at, not handed back',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await openHandOver(tester);
      await tickAll(tester);
      await tester.enterText(find.byKey(const Key('handover-price')), '');
      await tester.tap(find.byKey(const Key('handover-confirm')));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.closed, isFalse);
      expect(find.textContaining('Type what is charged'), findsOneWidget);
    });

    testWidgets('the card on the repair page opens the same page',
        (tester) async {
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      expect(find.text('Before hand-over'), findsOneWidget);
      await tester.tap(find.byKey(const Key('handover-card')));
      await tester.pumpAndSettle();
      expect(find.byType(HandOverPage), findsOneWidget);
      // Back returns to the repair, nothing changed.
      await tester.tap(find.byKey(const Key('form-close')));
      await tester.pumpAndSettle();
      expect(find.byType(HandOverPage), findsNothing);
      expect(find.byType(ServiceDetailScreen), findsOneWidget);
    });

    testWidgets('charging from the sheet fills the hand-over price',
        (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await tester.tap(find.text('Set what is charged'));
      await tester.pumpAndSettle();
      // From the bottom, not a box in the middle.
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.enterText(find.byKey(const Key('charge-amount')), '1800');
      await tester.tap(find.widgetWithText(FilledButton, 'Set'));
      await tester.pumpAndSettle();
      expect(store.byId('a')!.finalPrice, 1800);

      await openHandOver(tester);
      expect(find.text('1800'), findsOneWidget);
      await tickAll(tester);
      await tester.tap(find.byKey(const Key('handover-confirm')));
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
      await tester.ensureVisible(find.text('Returned unrepaired'));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('service-customerPhone')), '9876543210');
      await tester.enterText(
          find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(
          find.byKey(const Key('service-model')), 'X9b');
      await tester.pumpAndSettle();

      // Typed into the find box, as at the counter: the row is one line.
      await tester.enterText(
          find.byKey(const Key('service-complaintFind')), 'charging');
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
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('service-brand')), 'Apple');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'iPhone 11'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Galaxy A54'), findsNothing);
    });

    testWidgets('a brand with no saved models offers what its repairs carry',
        (tester) async {
      // Redmi has no built-in models: the row used to stay empty for it.
      await pumpService(tester, const ServiceListScreen(), seed: [
        ServiceOrder(
          id: 'r1',
          orderNumber: 'SO-1',
          brand: 'Redmi',
          model: 'Note 13',
          status: 'In Progress',
          receivedAt: DateTime.now(),
        ),
      ]);
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('service-brand')), 'Redmi');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Note 13'), findsOneWidget);

      // A brand with nothing at all says how the row fills.
      await tester.enterText(find.byKey(const Key('service-brand')), 'Lava');
      await tester.pumpAndSettle();
      expect(find.textContaining('No Lava models saved yet'), findsOneWidget);
    });

    testWidgets('Save with no complaint takes them to the complaints',
        (tester) async {
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('service-customerPhone')), '9876543210');
      await tester.enterText(find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(find.byKey(const Key('service-model')), 'X9b');
      await tester.pumpAndSettle();

      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.orders, isEmpty);
      final box = tester.widget<EditableText>(find.descendant(
        of: find.byKey(const Key('service-complaintFind')),
        matching: find.byType(EditableText),
      ));
      expect(box.focusNode.hasFocus, isTrue);
      expect(find.textContaining('at least one complaint'), findsOneWidget);
    });

    testWidgets('the IMEI box has a camera button, as on Buy phone',
        (tester) async {
      // A repair's phone is in the hand: if it switches on, *#06# shows the
      // IMEI barcode on its screen.
      await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('service-imei')),
          matching: find.byKey(const Key('imei-scan')),
        ),
        findsOneWidget,
      );
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
    await tester.tap(find.text('New repair'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsNothing);
    await tester.enterText(
        find.byKey(const Key('service-imei')), '356789012345678');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsOneWidget);
    expect(find.textContaining('SO-OLD'), findsOneWidget);
  });

  testWidgets('marking a job Ready offers to tell the customer', (tester) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a', finalPrice: 1800)],
    );
    // The status row is one sideways line: scrolled to, as a thumb would.
    final ready = find.widgetWithText(ChoiceChip, 'Ready for pickup');
    await tester.ensureVisible(ready);
    await tester.pumpAndSettle();
    await tester.tap(ready);
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(SnackBarAction, 'Tell the customer'),
        findsOneWidget);
  });

  testWidgets('the Mark ready button does the same in one tap',
      (tester) async {
    final store = await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a', finalPrice: 1800)],
    );
    await tester.tap(find.byKey(const Key('mark-ready')));
    await tester.pumpAndSettle();
    expect(store.byId('a')!.status, 'Ready');
    // Once Ready, the button has done its job and goes.
    expect(find.byKey(const Key('mark-ready')), findsNothing);
  });

  test('the track has four steps the customer understands', () {
    expect(trackStepOf('Received'), 0);
    expect(trackStepOf('In Progress'), 1);
    expect(trackStepOf('Parts Awaiting'), 1);
    expect(trackStepOf('Awaiting Customer Approval'), 1);
    expect(trackStepOf('Ready'), 2);
    expect(trackStepOf('Completed'), 3);
    expect(trackStepOf('Returned'), 3);
    // A status this build has never seen is still "being worked on".
    expect(trackStepOf('Waiting For Spare'), 1);
  });

  testWidgets('the job page shows where it is on the track', (tester) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a', finalPrice: 1800)],
    );
    expect(find.text('Where is it now?'), findsOneWidget);
    expect(find.byKey(const Key('track-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mark-ready')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('track-2')), findsOneWidget);
  });
}
