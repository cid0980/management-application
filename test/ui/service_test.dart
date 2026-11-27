import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/labels/intake_prefill.dart';

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
import 'package:fm_shop/ui/screens/service/service_form_sheet.dart';
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
}) => ServiceOrder(
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
  DraftStore? drafts,
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
        ChangeNotifierProvider<SettingsRepository>.value(value: settingsStore),
        ChangeNotifierProvider<ServiceRepository>.value(value: service),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        Provider<DraftStore>.value(value: drafts ?? InMemoryDraftStore()),
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
    testWidgets('a job finished last month is not shown as an alarm', (
      tester,
    ) async {
      await pumpService(
        tester,
        const ServiceListScreen(),
        seed: [
          _o(
            'done',
            status: 'Completed',
            finalPrice: 1800,
            expected: DateTime(2026, 1, 1),
          ),
        ],
      );
      // Closed beats overdue: the Overdue tab is empty and the row reads as
      // finished.
      expect(chipLabelled('Overdue 0'), findsOneWidget);
      await tapTab(tester, 'Completed 1');
      // Its own status, and no "Overdue" alarm pill on the row.
      expect(find.widgetWithText(StatusPill, 'Completed'), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Overdue'), findsNothing);
    });

    testWidgets('an overdue job is in Overdue and reads as an alarm', (
      tester,
    ) async {
      await pumpService(
        tester,
        const ServiceListScreen(),
        seed: [
          _o(
            'late',
            expected: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      );
      expect(chipLabelled('Overdue 1'), findsOneWidget);
      expect(find.widgetWithText(StatusPill, 'Overdue'), findsOneWidget);
    });

    testWidgets('a status this build has never seen shows as itself', (
      tester,
    ) async {
      await pumpService(
        tester,
        const ServiceListScreen(),
        seed: [
          ServiceOrder.fromMap('x', {
            'orderNumber': 'SO-1',
            'brand': 'Vivo',
            'model': 'T2x',
            'status': 'Waiting For Spare',
            'complaints': ['Software / hanging'],
            'receivedAt': '2026-03-01T10:00:00.000Z',
            'expectedCompletionAt': DateTime.now()
                .add(const Duration(days: 2))
                .toIso8601String(),
          }),
        ],
      );
      expect(find.text('Waiting For Spare'), findsOneWidget);
      expect(chipLabelled('Open 1'), findsOneWidget);
    });

    testWidgets('My jobs: only the open jobs given to me', (tester) async {
      await pumpService(
        tester,
        const ServiceListScreen(),
        seed: [
          _o('a').copyWith(
            model: 'Mine Open',
            technicianUid: 'local-staff',
            technician: 'Me',
          ),
          _o('b').copyWith(
            model: 'Somebody Else',
            technicianUid: 'other',
            technician: 'Mani',
          ),
          _o(
            'c',
            status: 'Completed',
          ).copyWith(model: 'Mine Done', technicianUid: 'local-staff'),
        ],
      );
      final tab = find.byKey(const Key('service-tab-Mine'));
      expect(tab, findsOneWidget);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text('Samsung Mine Open'), findsOneWidget);
      expect(find.text('Samsung Somebody Else'), findsNothing);
      expect(find.text('Samsung Mine Done'), findsNothing);
    });

    testWidgets('search covers the order number and the IMEI', (tester) async {
      await pumpService(tester, const ServiceListScreen(), seed: [_o('a')]);
      await tester.enterText(
        find.byKey(const Key('service-search')),
        '354879104523681',
      );
      await tester.pumpAndSettle();
      expect(find.text('Samsung Galaxy M14'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('service-search')), 'iphone');
      await tester.pumpAndSettle();
      expect(find.textContaining('No match'), findsOneWidget);
    });
  });

  group('the status picker', () {
    testWidgets('Completed is not offered to anyone, of any role', (
      tester,
    ) async {
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
        expect(
          find.textContaining('Completed is not here for anyone'),
          findsOneWidget,
        );
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

    testWidgets('the button opens its own page; a missed check is pointed at', (
      tester,
    ) async {
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

    testWidgets('ticks, the price, UPI: handed back and the page closes', (
      tester,
    ) async {
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

    testWidgets(
      'nothing charged yet: the estimate is filled in and can change',
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
      },
    );

    testWidgets('an empty price is pointed at, not handed back', (
      tester,
    ) async {
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

    testWidgets('the card on the repair page opens the same page', (
      tester,
    ) async {
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

    testWidgets('charging from the sheet fills the hand-over price', (
      tester,
    ) async {
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

    testWidgets('a closed order offers no checklist and no status change', (
      tester,
    ) async {
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [
          _o(
            'a',
            status: 'Completed',
            finalPrice: 1800,
            checklist: {
              for (final e in checklistEntries(_checklist)) e.key: true,
            },
          ),
        ],
      );
      expect(find.text('Hand the phone back'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('Nothing more is owed on it'), findsOneWidget);
      // The final bill replaces the job card once it has gone out.
      expect(find.text('Print final bill'), findsOneWidget);
    });

    testWidgets('returned unrepaired closes it with no checklist to pass', (
      tester,
    ) async {
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
        find.byKey(const Key('return-reason')),
        'Beyond repair',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Return it'));
      await tester.pumpAndSettle();

      expect(store.byId('a')!.status, 'Returned');
      expect(store.byId('a')!.complaintNotes, contains('Beyond repair'));
    });
  });

  group('what an intake files', () {
    testWidgets('a complaint the shop has never seen joins the list', (
      tester,
    ) async {
      // The job card and the final bill are both built from these, so a
      // complaint typed once has to be findable the next time.
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('service-customerPhone')),
        '9876543210',
      );
      await tester.enterText(find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(find.byKey(const Key('service-model')), 'X9b');
      await tester.pumpAndSettle();

      // Typed into the find box, as at the counter: the row is one line.
      await tester.enterText(
        find.byKey(const Key('service-complaintFind')),
        'charging',
      );
      await tester.pumpAndSettle();
      final complaint = find.widgetWithText(FilterChip, 'Not charging');
      await tester.ensureVisible(complaint);
      await tester.pumpAndSettle();
      await tester.tap(complaint);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.orders, hasLength(1));
      expect(
        lastSettings.settings.list(OptionKind.brands).contains('Honor'),
        isTrue,
      );
      expect(lastSettings.settings.modelsFor('Honor').values, ['X9b']);
    });

    testWidgets('the promised day in one tap: Tomorrow, 2 days, 1 week', (
      tester,
    ) async {
      await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      bool shows(String text) => find
          .descendant(
            of: find.byKey(const Key('service-expectedAt')),
            matching: find.text(text),
          )
          .evaluate()
          .isNotEmpty;
      String day(int n) {
        final t = DateTime.now();
        final d = DateTime(t.year, t.month, t.day + n);
        return '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // It starts at 3 days, 6 PM, and that choice is shown as picked.
      expect(shows(day(3)), isTrue);
      // The time has its own button, on the 12-hour clock.
      expect(shows('6:00 PM'), isTrue);
      for (final (key, n) in [
        ('promise-1', 1),
        ('promise-2', 2),
        ('promise-7', 7),
      ]) {
        final chip = find.byKey(Key(key));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(shows(day(n)), isTrue, reason: key);
      }
      final time = find.byKey(const Key('service-expectedAt-time'));
      await tester.ensureVisible(time);
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('time-14')));
      await tester.pumpAndSettle();
      expect(shows('2:00 PM'), isTrue);
      // The day stays what was picked; only the time moved.
      expect(shows(day(7)), isTrue);
    });

    testWidgets("only the chosen brand's models are suggested", (tester) async {
      await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('service-brand')), 'Apple');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'iPhone 11'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Galaxy A54'), findsNothing);
    });

    testWidgets('a brand with no saved models offers what its repairs carry', (
      tester,
    ) async {
      // Redmi has no built-in models: the row used to stay empty for it.
      await pumpService(
        tester,
        const ServiceListScreen(),
        seed: [
          ServiceOrder(
            id: 'r1',
            orderNumber: 'SO-1',
            brand: 'Redmi',
            model: 'Note 13',
            status: 'In Progress',
            receivedAt: DateTime.now(),
          ),
        ],
      );
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

    testWidgets('Save with no complaint takes them to the complaints', (
      tester,
    ) async {
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('service-customerPhone')),
        '9876543210',
      );
      await tester.enterText(find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(find.byKey(const Key('service-model')), 'X9b');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.orders, isEmpty);
      final box = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('service-complaintFind')),
          matching: find.byType(EditableText),
        ),
      );
      expect(box.focusNode.hasFocus, isTrue);
      expect(find.textContaining('at least one complaint'), findsOneWidget);
    });

    testWidgets('the IMEI box has a camera button, as on Buy phone', (
      tester,
    ) async {
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

  testWidgets('a phone back under the shop warranty is flagged at intake', (
    tester,
  ) async {
    final now = DateTime.now();
    await pumpService(
      tester,
      const ServiceListScreen(),
      seed: [
        ServiceOrder(
          id: 'old',
          orderNumber: 'SO-OLD',
          imei: '356789012345678',
          status: 'Completed',
          warrantyDays: 30,
          completedAt: now.subtract(const Duration(days: 3)),
        ),
      ],
    );
    await tester.tap(find.text('New repair'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('service-imei')),
      '356789012345678',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hit')), findsOneWidget);
    expect(find.textContaining('SO-OLD'), findsOneWidget);
  });

  testWidgets('marking a job Ready offers to tell the customer', (
    tester,
  ) async {
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
    expect(
      find.widgetWithText(SnackBarAction, 'Tell the customer'),
      findsOneWidget,
    );
  });

  testWidgets('the Mark ready button does the same in one tap', (tester) async {
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

  testWidgets('the track says what it is waiting for, as the status does', (
    tester,
  ) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a', finalPrice: 1800).copyWith(status: 'Parts Awaiting')],
    );
    final track = find.byKey(const Key('track-1'));
    expect(
      find.descendant(of: track, matching: find.text('Parts Awaiting')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: track, matching: find.text('Working')),
      findsNothing,
    );
  });

  group('the technician is a staff member', () {
    Finder personChip() => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          k.value.startsWith('technician-') &&
          !const [
            'technician-none',
            'technician-typed',
            'technician-card',
            'technician-change',
          ].contains(k.value);
    });

    testWidgets('picked on a new repair, the job is linked to their account', (
      tester,
    ) async {
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('service-customerPhone')),
        '9876543210',
      );
      await tester.enterText(find.byKey(const Key('service-brand')), 'Honor');
      await tester.enterText(find.byKey(const Key('service-model')), 'X9b');
      await tester.enterText(
        find.byKey(const Key('service-complaintFind')),
        'charging',
      );
      await tester.pumpAndSettle();
      final complaint = find.widgetWithText(FilterChip, 'Not charging');
      await tester.ensureVisible(complaint);
      await tester.tap(complaint);
      await tester.pumpAndSettle();
      // No free typing: the box is gone, the people are there — the owner
      // or whoever is signed in too, marked as themselves.
      expect(find.byKey(const Key('service-technician')), findsOneWidget);
      expect(find.textContaining('(me)'), findsOneWidget);
      final person = personChip().first;
      await tester.ensureVisible(person);
      await tester.tap(person);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final o = store.orders.single;
      expect(o.technicianUid, isNotEmpty);
      expect(o.technician, isNotEmpty);
      expect(o.assignedAt, isNotNull);
    });

    testWidgets('the owner changes it from the repair page; a typed name '
        'shows as not linked', (tester) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a').copyWith(technician: 'Suresh')],
        isAdmin: true,
      );
      expect(find.text('Suresh (not linked)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('technician-change')));
      await tester.pumpAndSettle();
      await tester.tap(personChip().first);
      await tester.pumpAndSettle();
      final o = store.byId('a')!;
      expect(o.technicianUid, isNotEmpty);
      expect(o.technician, isNot('Suresh'));
      expect(find.byKey(const Key('technician-card')), findsOneWidget);
    });

    testWidgets('staff see who is on it but cannot change it', (tester) async {
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a').copyWith(technician: 'Suresh')],
      );
      expect(find.byKey(const Key('technician-card')), findsOneWidget);
      expect(find.byKey(const Key('technician-change')), findsNothing);
    });
  });

  testWidgets('the lock has its own card: hidden until Show, pattern drawn', (
    tester,
  ) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a').copyWith(lockType: 'Pattern', lockValue: '1-2-3-6-9')],
    );
    expect(find.byKey(const Key('lock-card')), findsOneWidget);
    expect(find.byKey(const Key('lock-pattern')), findsNothing);
    await tester.tap(find.byKey(const Key('lock-show')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-pattern')), findsOneWidget);
  });

  testWidgets('a PIN shows as dots until Show', (tester) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [_o('a').copyWith(lockType: 'PIN', lockValue: '4417')],
    );
    expect(find.text('4417'), findsNothing);
    await tester.tap(find.byKey(const Key('lock-show')));
    await tester.pumpAndSettle();
    expect(find.text('4417'), findsOneWidget);
  });

  testWidgets('photos wait for a tap; empty slots show where they go', (
    tester,
  ) async {
    await pumpService(
      tester,
      const ServiceDetailScreen(id: 'a'),
      seed: [
        _o('a').copyWith(photos: const ['fs://shops/s1/photos/202611/1.jpg']),
      ],
    );
    expect(find.byKey(const Key('repair-photo-strip')), findsOneWidget);
    // Not downloaded yet: the tile says so.
    expect(
      find.descendant(
        of: find.byKey(const Key('repair-photo-0')),
        matching: find.text('Tap to view'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const Key('repair-photo-empty-0')), findsOneWidget);
  });

  testWidgets('an enquiry\'s customer beats a stale repair draft', (
    tester,
  ) async {
    final drafts = InMemoryDraftStore();
    await drafts.write(draftKey('service'), {
      'customerPhone': '9000000000',
      'customerName': 'Yesterday',
      'brand': 'Nokia',
    });
    await pumpService(
      tester,
      const ServiceIntakeForm(
        prefill: IntakePrefill(
          customerPhone: '9876543210',
          customerName: 'Ramesh K',
        ),
      ),
      drafts: drafts,
    );
    String text(String key) => tester
        .widget<TextField>(find.byKey(Key('service-$key')))
        .controller!
        .text;
    expect(text('customerPhone'), '9876543210');
    expect(text('customerName'), 'Ramesh K');
  });

  group('several phones in one visit', () {
    Future<void> fillPhone(
      WidgetTester tester,
      String brand,
      String model, {
      bool phone = true,
    }) async {
      if (phone) {
        await tester.enterText(
          find.byKey(const Key('service-customerPhone')),
          '9876543210',
        );
      }
      await tester.enterText(find.byKey(const Key('service-brand')), brand);
      await tester.enterText(find.byKey(const Key('service-model')), model);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('service-complaintFind')),
        'charging',
      );
      await tester.pumpAndSettle();
      final complaint = find.widgetWithText(FilterChip, 'Not charging');
      await tester.ensureVisible(complaint);
      await tester.pumpAndSettle();
      await tester.tap(complaint);
      await tester.pumpAndSettle();
      // The estimate is required.
      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Save & add another phone: the customer is typed once and '
        'both jobs share the visit', (tester) async {
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await fillPhone(tester, 'Honor', 'X9b');
      await tester.tap(find.byKey(const Key('service-save-another')));
      await tester.pumpAndSettle();

      // A fresh form for the same customer, saying so.
      expect(find.byKey(const Key('service-visit-banner')), findsOneWidget);
      await fillPhone(tester, 'Vivo', 'Y21', phone: false);
      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.orders, hasLength(2));
      final ids = store.orders.map((o) => o.visitId).toSet();
      expect(ids, hasLength(1));
      expect(ids.single, isNotEmpty);
      expect(store.orders.map((o) => o.brand).toSet(), {'Honor', 'Vivo'});
      // The number was typed once, for the first phone only.
      expect(store.orders.map((o) => o.customerPhone).toSet(), {'9876543210'});
    });

    testWidgets("a known number fills the customer's name without tapping the "
        'match (FM #18)', (tester) async {
      final store = await pumpService(tester, const ServiceListScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await fillPhone(tester, 'Honor', 'X9b');
      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(store.orders.single.customerName, isNotEmpty);
      expect(store.orders.single.customerId, isNotNull);
    });

    testWidgets("a job's page lists the other phones in its visit", (
      tester,
    ) async {
      final a = ServiceOrder.fromMap('a', {
        ..._o('a').toMap(),
        'visitId': 'a',
        'createdAt': '2026-03-01T10:00:00',
      });
      final b = ServiceOrder.fromMap('b', {
        ..._o('b').toMap(),
        'orderNumber': 'SO-20260304-002',
        'brand': 'Vivo',
        'model': 'Y21',
        'visitId': 'a',
        'createdAt': '2026-03-01T10:05:00',
      });
      await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [a, b],
      );
      expect(find.byKey(const Key('visit-card')), findsOneWidget);
      expect(find.text('Phones in this visit'), findsOneWidget);
      expect(find.byKey(const Key('visit-b')), findsOneWidget);
      expect(find.text('Vivo Y21'), findsOneWidget);
    });

    testWidgets('adding a phone to a lone job puts both in one visit', (
      tester,
    ) async {
      final store = await pumpService(
        tester,
        const ServiceDetailScreen(id: 'a'),
        seed: [_o('a')],
      );
      await tester.tap(find.byKey(const Key('visit-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('service-visit-banner')), findsOneWidget);
      await fillPhone(tester, 'Vivo', 'Y21', phone: false);
      await tester.enterText(
        find.byKey(const Key('service-estimatedPrice')),
        '1500',
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(store.orders, hasLength(2));
      expect(store.byId('a')!.visitId, 'a');
      expect(store.orders.every((o) => o.visitId == 'a'), isTrue);
    });
  });
}
