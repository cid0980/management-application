import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';
import 'package:fm_shop/ui/screens/second_hand/second_hand_form_sheet.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';

/// The form, driven the way staff drive it. These assert the rules the screen
/// is responsible for, not its looks: that Next and Save ask the same
/// validator, that the grade follows the checklist, that a returning seller
/// fills in with one tap, and that what is typed joins the shop's lists.

/// The stores the last pumped form was given, so a test can read what the
/// form did.
late InMemorySettingsStore lastSettings;
late InMemoryCustomerStore lastCustomers;
late RecordingPrintServer lastPrinter;

Future<InMemorySecondHandStore> pumpForm(
  WidgetTester tester, {
  DraftStore? drafts,
  Widget home = const PurchaseForm(),
  List<SecondHandDevice> seed = const [],
}) async {
  // Tall enough that a whole step is laid out at once. The ListView builds
  // lazily, so scrolling between fields would only test the scroll.
  tester.view.physicalSize = const Size(500, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final store = InMemorySecondHandStore(seed: seed);
  addTearDown(store.dispose);
  final settingsStore = InMemorySettingsStore();
  addTearDown(settingsStore.dispose);
  lastSettings = settingsStore;
  final customers = InMemoryCustomerStore(
    seed: const [
      Customer(
        id: 'c-ramesh',
        name: 'Ramesh Kumar',
        phone: '9876543210',
        altPhone: '9123456780',
        idType: 'Aadhaar',
        idNumber: '4412',
      ),
    ],
  );
  addTearDown(customers.dispose);
  lastCustomers = customers;
  final labels = InMemoryLabelStore(
    targets: {
      LabelTargetKind.secondHand: LabelTargetBinding(
        snapshot: store.labelSnapshot,
        attach: (id, number) => store.attachLabel(id, number),
      ),
    },
  );
  addTearDown(labels.dispose);
  lastPrinter = RecordingPrintServer();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsRepository>.value(value: settingsStore),
        ChangeNotifierProvider<SecondHandRepository>.value(value: store),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<LabelRepository>.value(value: labels),
        Provider<PrintServer>.value(value: lastPrinter),
        Provider<DraftStore>.value(value: drafts ?? InMemoryDraftStore()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

/// The form is five steps, with optional fields folded away. Finds [finder]
/// the way a worker would: tap through the steps, opening each step's fold,
/// until it is on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  for (var step = 0; step < 5; step++) {
    await tester.tap(find.byKey(Key('step-$step')));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
    final more = find.byKey(Key('more-$step'));
    if (more.evaluate().isNotEmpty) {
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      if (finder.evaluate().isNotEmpty) return;
    }
  }
}

Future<void> fill(WidgetTester tester, String field, String value) async {
  final finder = find.byKey(Key('purchase-$field'));
  await reveal(tester, finder);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, find.byKey(Key(key)));
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// The seller, the way staff choose one: search, then tap the match.
Future<void> pickSeller(WidgetTester tester, String query, String id) async {
  await fill(tester, 'sellerSearch', query);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('customer-$id')));
  await tester.pumpAndSettle();
}

/// A seller who is not on the books: type them, tap "+ Add", fill the rest.
Future<void> addSeller(
  WidgetTester tester, {
  required String typed,
  String name = '',
  String phone = '',
}) async {
  await fill(tester, 'sellerSearch', typed);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-customer')));
  await tester.pumpAndSettle();
  if (name.isNotEmpty) {
    await tester.enterText(find.byKey(const Key('new-customer-name')), name);
  }
  if (phone.isNotEmpty) {
    await tester.enterText(find.byKey(const Key('new-customer-phone')), phone);
  }
  await tester.tap(find.byKey(const Key('new-customer-save')));
  await tester.pumpAndSettle();
}

Future<void> step(WidgetTester tester, int n) async {
  await tester.tap(find.byKey(Key('step-$n')));
  await tester.pumpAndSettle();
}

/// Everything the counter requires, filled.
Future<void> fillValid(
  WidgetTester tester, {
  String brand = 'Honor',
  String model = 'Hot 30',
  String ram = '8GB',
  String rom = '128GB',
  String colour = '',
  String serial = '',
}) async {
  await pickSeller(tester, 'rames', 'c-ramesh');
  await fill(tester, 'brand', brand);
  await fill(tester, 'model', model);
  await fill(tester, 'ram', ram);
  await fill(tester, 'rom', rom);
  if (colour.isNotEmpty) await fill(tester, 'colour', colour);
  if (serial.isNotEmpty) await fill(tester, 'serial', serial);
  await fill(tester, 'imei', '490154203237518');
  await fill(tester, 'purchasePrice', '6000');
  await fill(tester, 'askingPrice', '9000');
  await tapKey(tester, 'photo-front');
}

void main() {
  group('the steps', () {
    testWidgets('the steps are the counter app order', (tester) async {
      await pumpForm(tester);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Who sold it to you?'), findsOneWidget);
    });

    testWidgets('an empty form saves nothing and goes back to the seller', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await tapText(tester, 'Save');
      expect(store.devices, isEmpty);
      expect(find.text('Who sold it to you?'), findsOneWidget);
      expect(find.textContaining("seller's name is needed"), findsWidgets);
    });

    testWidgets('Next checks only the step on screen', (tester) async {
      await pumpForm(tester);
      // Nothing red before anyone has tried.
      expect(find.textContaining("seller's name is needed"), findsNothing);
      await tester.tap(find.byKey(const Key('wizard-next')));
      await tester.pumpAndSettle();
      expect(find.textContaining("seller's name is needed"), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);

      await addSeller(tester, typed: 'Priya S', phone: '9123456780');
      await tester.tap(find.byKey(const Key('wizard-next')));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 5'), findsOneWidget);
      // The phone step has not been tried yet, so no "Brand is needed".
      expect(find.text('Brand is needed'), findsNothing);
    });

    testWidgets('optional fields stay folded until asked for', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      expect(find.byKey(const Key('purchase-imei')), findsOneWidget);
      expect(find.byKey(const Key('purchase-colour')), findsNothing);
      await tester.tap(find.byKey(const Key('more-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('purchase-colour')), findsOneWidget);
    });

    testWidgets('models wait for a brand', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      expect(
        find.text('Choose the brand first to see its models'),
        findsOneWidget,
      );
      await fill(tester, 'brand', 'Apple');
      await fill(tester, 'model', 'iph');
      await tester.pumpAndSettle();
      expect(
        find.text('Choose the brand first to see its models'),
        findsNothing,
      );
      expect(find.byKey(const Key('option-model-iPhone 11')), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('a complete purchase saves, A-grade with nothing marked', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(tester, brand: 'Samsung', model: 'Galaxy A54');
      await tapText(tester, 'Save');

      final saved = store.devices.single;
      expect(saved.brand, 'Samsung');
      expect(saved.ram, '8GB');
      expect(saved.rom, '128GB');
      expect(saved.title, 'Samsung Galaxy A54 8GB/128GB');
      expect(saved.imei, '490154203237518');
      expect(saved.costing.expectedProfit, 3000);
      expect(saved.grade, 'A');
      // Today, without anyone having to say so.
      expect(saved.purchasedAt, isNotNull);
      expect(saved.isSellable, isTrue);
    });

    testWidgets('a front photo is required — a listing without one is not a '
        'listing', (tester) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapKey(tester, 'photo-front'); // tapped again: still there
      // Remove it.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('photo-front')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Save');

      expect(store.devices, isEmpty);
      expect(find.text('A front view of the device is needed'), findsWidgets);
    });

    testWidgets('an iPhone is not saved without its serial', (tester) async {
      final store = await pumpForm(tester);
      await fillValid(tester, brand: 'Apple', model: 'iPhone 12');
      await tapText(tester, 'Save');
      expect(store.devices, isEmpty);
      expect(
        find.text('The serial number is needed for an iPhone'),
        findsWidgets,
      );

      await fill(tester, 'serial', 'F2LX1234');
      await tapText(tester, 'Save');
      expect(store.devices, hasLength(1));
    });

    testWidgets('Save & print label saves, then assigns and prints a label', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapText(tester, 'Save & print label');

      expect(store.devices.single.labelNumber, isNotNull);
      expect(lastPrinter.jobs, hasLength(1));
      expect(lastPrinter.jobs.single.number, store.devices.single.labelNumber);
    });

    testWidgets('the bench switch holds a handset off the shelf', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapText(tester, 'Still on the bench');
      await tapText(tester, 'Save');

      expect(store.devices.single.isBeingRepaired, isTrue);
      expect(store.devices.single.isSellable, isFalse);
    });
  });

  group('condition', () {
    testWidgets('the grade follows the faults tapped', (tester) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Samsung');
      await step(tester, 2);
      expect(find.text('No faults found'), findsOneWidget);

      await tapKey(tester, 'check-wifi-no');
      expect(find.textContaining('Wi-Fi'), findsWidgets);
      expect(find.text('Faults: Wi-Fi'), findsOneWidget);

      await tapKey(tester, 'check-display_replaced-no');
      await tapKey(tester, 'check-physical_damage-no');
      expect(find.textContaining('Physical Damage'), findsWidgets);
    });

    testWidgets('a grade picked by hand is saved as such', (tester) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapKey(tester, 'grade-C');
      expect(find.text('Chosen by hand'), findsOneWidget);
      await fill(tester, 'description', 'Scratches on the back');
      await tapText(tester, 'Save');

      final saved = store.devices.single;
      expect(saved.grade, 'C');
      expect(saved.gradeOverridden, isTrue);
      expect(saved.gradeDetails['description'], 'Scratches on the back');
    });

    testWidgets('an iPhone gets the iCloud check', (tester) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Apple');
      await step(tester, 2);
      expect(find.text('iPhone checks'), findsOneWidget);
      expect(find.byKey(const Key('check-icloud_lock-no')), findsOneWidget);
      expect(find.byKey(const Key('check-sd_card_slot-no')), findsNothing);
    });
  });

  group('the seller', () {
    testWidgets('a returning seller fills in with one tap', (tester) async {
      final store = await pumpForm(tester);
      await pickSeller(tester, 'rames', 'c-ramesh');

      final card = find.byKey(const Key('seller-card'));
      expect(
        find.descendant(of: card, matching: find.text('9876543210')),
        findsOneWidget,
      );
      expect(find.text('From your customers'), findsOneWidget);

      await fill(tester, 'brand', 'Vivo');
      await fill(tester, 'model', 'Y21');
      await fill(tester, 'ram', '4GB');
      await fill(tester, 'rom', '64GB');
      await fill(tester, 'imei', '490154203237518');
      await fill(tester, 'purchasePrice', '4000');
      await fill(tester, 'askingPrice', '6000');
      await tapKey(tester, 'photo-front');
      await tapText(tester, 'Save');

      final saved = store.devices.single;
      expect(saved.sellerCustomerId, 'c-ramesh');
      expect(saved.sellerAltPhone, '9123456780');
      expect(saved.sellerIdProof, 'Aadhaar 4412');
    });

    testWidgets('a new seller is added to the customers and picked', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'sellerSearch', 'Anbu');
      await tester.pumpAndSettle();
      expect(find.text('Add "Anbu" as a new customer'), findsOneWidget);
      await tapKey(tester, 'add-customer');
      // What was typed comes along into the new customer form.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('new-customer-name')))
            .controller!
            .text,
        'Anbu',
      );
      await tester.enterText(
        find.byKey(const Key('new-customer-phone')),
        '9000011111',
      );
      await tester.tap(find.text('PAN'));
      await tester.enterText(find.byKey(const Key('new-customer-id')), 'ABCDE');
      await tester.tap(find.byKey(const Key('new-customer-save')));
      await tester.pumpAndSettle();

      final added = lastCustomers.customers.firstWhere((c) => c.name == 'Anbu');
      expect(added.idType, 'PAN');
      expect(added.idNumber, 'ABCDE');
      expect(find.text('From your customers'), findsOneWidget);
    });

    testWidgets('search finds a seller by phone number as well as by name', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'sellerSearch', '98765');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-c-ramesh')), findsOneWidget);
      // Only a partial number, so adding someone new is still offered.
      expect(find.byKey(const Key('add-customer')), findsOneWidget);
    });

    testWidgets('a whole number already on the books offers no second record', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'sellerSearch', '9876543210');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-c-ramesh')), findsOneWidget);
      expect(find.byKey(const Key('add-customer')), findsNothing);
    });

    testWidgets('a number typed goes into the phone box of the new customer', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'sellerSearch', '9000022222');
      await tester.pumpAndSettle();
      await tapKey(tester, 'add-customer');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('new-customer-phone')))
            .controller!
            .text,
        '9000022222',
      );
    });

    testWidgets('Change goes back to an empty search', (tester) async {
      await pumpForm(tester);
      await pickSeller(tester, 'rames', 'c-ramesh');
      await tapKey(tester, 'change-seller');
      expect(find.byKey(const Key('seller-card')), findsNothing);
      expect(find.byKey(const Key('purchase-sellerSearch')), findsOneWidget);
    });
  });

  testWidgets('every step has a "?" and the bubble explains in place', (
    tester,
  ) async {
    await pumpForm(tester);
    for (var s = 0; s < 5; s++) {
      await step(tester, s);
      expect(find.byTooltip('What is this?'), findsWidgets, reason: 'step $s');
    }

    await step(tester, 1);
    final imeiHelp = find.descendant(
      of: find.byKey(const Key('purchase-imei')),
      matching: find.byTooltip('What is this?'),
    );
    await tester.tap(imeiHelp);
    await tester.pumpAndSettle();
    // A small bubble beside the "?", over the form — not a page of its own.
    expect(find.textContaining('*#06#'), findsOneWidget);
    expect(find.byKey(const Key('purchase-imei')), findsOneWidget);

    // A tap anywhere closes it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.textContaining('*#06#'), findsNothing);
  });

  group('what is typed joins the shop lists', () {
    testWidgets('a brand the shop has never seen is filed on save', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      expect(
        lastSettings.settings.list(OptionKind.brands).contains('Honor'),
        isFalse,
      );

      await fillValid(tester);
      await tapText(tester, 'Save');

      expect(store.devices, hasLength(1));
      expect(
        lastSettings.settings.list(OptionKind.brands).contains('Honor'),
        isTrue,
      );
      // And the model lands under that brand, not loose.
      expect(lastSettings.settings.modelsFor('Honor').values, ['Hot 30']);
    });

    testWidgets('a new colour is filed too', (tester) async {
      await pumpForm(tester);
      await fillValid(tester, colour: 'Awesome Violet');
      await tapText(tester, 'Save');
      expect(
        lastSettings.settings
            .list(OptionKind.colours)
            .contains('Awesome Violet'),
        isTrue,
      );
    });

    testWidgets('a new RAM and storage are filed too', (tester) async {
      await pumpForm(tester);
      await fillValid(tester, ram: '24GB', rom: '2TB');
      await tapText(tester, 'Save');
      expect(
        lastSettings.settings.list(OptionKind.ram).contains('24GB'),
        isTrue,
      );
      expect(
        lastSettings.settings.list(OptionKind.rom).contains('2TB'),
        isTrue,
      );
    });

    testWidgets("typed in any case, it is saved in the shop's spelling", (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(
        tester,
        brand: 'samsung',
        model: 'galaxy a54',
        ram: '8gb',
      );
      await tapText(tester, 'Save');
      expect(store.devices.single.brand, 'Samsung');
      expect(store.devices.single.model, 'Galaxy A54');
      expect(store.devices.single.ram, '8GB');
    });

    testWidgets('typing narrows the list to what matches', (tester) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Samsung');
      await fill(tester, 'model', 'a5');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('option-model-Galaxy A54')), findsOneWidget);
      expect(find.byKey(const Key('option-model-Galaxy M14')), findsNothing);
    });

    testWidgets('the brands are in a row before anything is typed', (
      tester,
    ) async {
      // As on New repair: the row is there to tap, typing only narrows it.
      await pumpForm(tester);
      await step(tester, 1);
      expect(find.byKey(const Key('option-brand-Samsung')), findsOneWidget);
      expect(find.byKey(const Key('option-brand-Apple')), findsOneWidget);
      await fill(tester, 'brand', 'sam');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('option-brand-Samsung')), findsOneWidget);
      expect(find.byKey(const Key('option-brand-Apple')), findsNothing);
    });

    testWidgets('the row is one line that scrolls, not a block', (
      tester,
    ) async {
      await pumpForm(tester);
      await step(tester, 1);
      final rows = find.ancestor(
        of: find.byKey(const Key('option-brand-Samsung')),
        matching: find.byType(ListView),
      );
      expect(
        tester.widget<ListView>(rows.first).scrollDirection,
        Axis.horizontal,
      );
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('something the shop has never had is flagged as new', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Samsung');
      await tester.pumpAndSettle();
      expect(find.textContaining('New —'), findsNothing);

      await fill(tester, 'model', 'Galaxy Z Fold 9');
      await tester.pumpAndSettle();
      // While typing, the list offers to add it…
      expect(find.text('Add "Galaxy Z Fold 9" as a new model'), findsOneWidget);
      // …and once the box is left, the note says it will be filed on save.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.textContaining('New —'), findsOneWidget);
    });

    testWidgets('"+ Add" puts a new brand on the list straight away', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Nothing');
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-brand');
      expect(
        lastSettings.settings.list(OptionKind.brands).contains('Nothing'),
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('purchase-brand')))
            .controller!
            .text,
        'Nothing',
      );
    });

    testWidgets('a new model is added under its own brand only', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Apple');
      await fill(tester, 'model', 'iPhone 16');
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-model');
      expect(
        lastSettings.settings.modelsFor('Apple').contains('iPhone 16'),
        isTrue,
      );
      expect(
        lastSettings.settings.modelsFor('Samsung').contains('iPhone 16'),
        isFalse,
      );
    });

    testWidgets('a brand typed in another case is not offered as new', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'SAMSUNG');
      await tester.pumpAndSettle();
      // Already on the list in another case: ticked as known, no "+ Add".
      expect(find.byKey(const Key('create-brand')), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('new RAM and storage sizes can be added the same way', (
      tester,
    ) async {
      await pumpForm(tester);
      await fill(tester, 'ram', '24GB');
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-ram');
      await fill(tester, 'rom', '2TB');
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-rom');
      expect(
        lastSettings.settings.list(OptionKind.ram).contains('24GB'),
        isTrue,
      );
      expect(
        lastSettings.settings.list(OptionKind.rom).contains('2TB'),
        isTrue,
      );
    });

    testWidgets('a brand already on the list files nothing new', (
      tester,
    ) async {
      await pumpForm(tester);
      final before = lastSettings.settings.list(OptionKind.brands).length;
      await fillValid(tester, brand: 'Samsung', model: 'Galaxy A54');
      await tapText(tester, 'Save');
      expect(lastSettings.settings.list(OptionKind.brands).length, before);
    });

    testWidgets('a failed filing does not lose the purchase', (tester) async {
      // The customer is standing at the counter for the purchase, not for a
      // dropdown entry.
      final store = await pumpForm(tester);
      lastSettings.failWith = 'The shop network is down';

      await fillValid(tester);
      await tapText(tester, 'Save');

      expect(store.devices, hasLength(1));
      expect(store.devices.single.brand, 'Honor');
      expect(
        lastSettings.settings.list(OptionKind.brands).contains('Honor'),
        isFalse,
      );
    });

    testWidgets('tapping a suggestion fills the field', (tester) async {
      await pumpForm(tester);
      await fill(tester, 'brand', 'Samsung');
      await fill(tester, 'model', 'a54');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('option-model-Galaxy A54')));
      await tester.pumpAndSettle();
      // The row stays, with the picked one marked, so a wrong tap is undone
      // with one more.
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('option-model-Galaxy A54')),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const Key('option-model-Galaxy M14')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('purchase-model')))
            .controller!
            .text,
        'Galaxy A54',
      );
    });
  });

  group('the declaration', () {
    testWidgets('agreeing and checking the ID are kept on the record', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapKey(tester, 'declaration-agreed');
      await tapKey(tester, 'declaration-id-checked');
      await tapText(tester, 'Save');

      final saved = store.devices.single;
      expect(saved.agreementAcceptedAt, isNotNull);
      expect(saved.sellerIdVerified, isTrue);
    });

    testWidgets('untouched, nothing is claimed', (tester) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await tapText(tester, 'Save');

      final saved = store.devices.single;
      expect(saved.agreementAcceptedAt, isNull);
      expect(saved.sellerIdVerified, isFalse);
      expect(saved.sellerSignature, isNull);
    });

    testWidgets('a signature drawn with a finger is saved as a picture', (
      tester,
    ) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      final pad = find.byKey(const Key('signature-pad'));
      await reveal(tester, pad);
      await tester.ensureVisible(pad);
      await tester.runAsync(() async {
        await tester.drag(pad, const Offset(120, 30));
        // The picture is encoded off the UI thread; under a full test run
        // 300 ms was sometimes not enough.
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pumpAndSettle();
      await tapText(tester, 'Save');

      expect(
        store.devices.single.sellerSignature,
        startsWith('data:image/png;base64,'),
      );
    });

    testWidgets('battery health is saved as a number', (tester) async {
      final store = await pumpForm(tester);
      await fillValid(tester);
      await fill(tester, 'batteryHealth', '88');
      await tapText(tester, 'Save');
      expect(store.devices.single.batteryHealth, 88);
    });

    testWidgets('brand, RAM and storage are one tap', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      final ram = find.byKey(const Key('option-ram-8GB'));
      await tester.ensureVisible(ram);
      await tester.pumpAndSettle();
      await tester.tap(ram);
      await tester.pumpAndSettle();
      final field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('purchase-ram')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, '8GB');
      expect(find.byKey(const Key('option-rom-128GB')), findsOneWidget);
      expect(find.byKey(const Key('option-brand-Samsung')), findsOneWidget);
    });

    testWidgets('the IMEI box has a camera button', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      expect(find.byKey(const Key('imei-scan')), findsOneWidget);
    });

    testWidgets('Next with a box empty puts the cursor in it', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      await tester.tap(find.byKey(const Key('wizard-next')));
      await tester.pumpAndSettle();
      // Still on the Phone step, in the first box that needs something.
      final brand = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('purchase-brand')),
          matching: find.byType(EditableText),
        ),
      );
      expect(brand.focusNode.hasFocus, isTrue);
      expect(find.text('Brand is needed'), findsOneWidget);
    });

    testWidgets('required boxes carry a red *', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      expect(
        find.descendant(
          of: find.byKey(const Key('purchase-brand')),
          matching: find.byType(RequiredMark),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('purchase-imei2')),
          matching: find.byType(RequiredMark),
        ),
        findsNothing,
      );
    });

    testWidgets('the serial box has a camera button too', (tester) async {
      await pumpForm(tester);
      await step(tester, 1);
      expect(
        find.descendant(
          of: find.byKey(const Key('purchase-serial')),
          matching: find.byKey(const Key('serial-scan')),
        ),
        findsOneWidget,
      );
    });
  });

  group('drafts', () {
    testWidgets('typing is kept, under the new-record key', (tester) async {
      final drafts = InMemoryDraftStore();
      await pumpForm(tester, drafts: drafts);
      await fill(tester, 'brand', 'Vivo');
      await tester.pumpAndSettle();

      final draft = await drafts.read(draftKey('second_hand'));
      expect(draft, isNotNull);
      expect(draft!.values['brand'], 'Vivo');
    });

    testWidgets('the X discards it', (tester) async {
      final drafts = InMemoryDraftStore();
      await pumpForm(tester, drafts: drafts);
      await fill(tester, 'brand', 'Vivo');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Discard this draft'));
      await tester.pumpAndSettle();
      expect(await drafts.read(draftKey('second_hand')), isNull);
    });

    testWidgets('a saved form leaves no draft behind', (tester) async {
      final drafts = InMemoryDraftStore();
      await pumpForm(tester, drafts: drafts);
      await fillValid(tester);
      await tapText(tester, 'Save');

      expect(await drafts.read(draftKey('second_hand')), isNull);
    });
  });

  group('several phones from one seller', () {
    Widget opener() => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => openPurchaseSheet(context),
          child: const Text('Buy phone'),
        ),
      ),
    );

    testWidgets('buy another: the seller carries over, both share a batch', (
      tester,
    ) async {
      final store = await pumpForm(tester, home: opener());
      await tester.tap(find.text('Buy phone'));
      await tester.pumpAndSettle();
      await fillValid(tester, brand: 'Samsung', model: 'Galaxy A54');
      await tapKey(tester, 'purchase-save-another');

      // The next phone: straight to the phone step, seller already there.
      expect(find.byKey(const Key('purchase-batch-banner')), findsOneWidget);
      expect(find.text('Another phone from Ramesh Kumar'), findsOneWidget);
      await fill(tester, 'brand', 'Vivo');
      await fill(tester, 'model', 'Y21');
      await fill(tester, 'ram', '4GB');
      await fill(tester, 'rom', '64GB');
      await fill(tester, 'imei', '356938035643809');
      await fill(tester, 'purchasePrice', '3000');
      await fill(tester, 'askingPrice', '5000');
      await tapKey(tester, 'photo-front');
      await tapText(tester, 'Save');

      expect(store.devices, hasLength(2));
      expect(store.devices.map((d) => d.batchId).toSet(), hasLength(1));
      expect(store.devices.first.batchId, isNotEmpty);
      expect(store.devices.map((d) => d.sellerName).toSet(), {'Ramesh Kumar'});
      expect(store.devices.map((d) => d.sellerPhone).toSet(), {'9876543210'});
      // The first went on the shelf with its sticker (the button prints);
      // the second was saved with plain Save.
      expect(store.devices.where((d) => d.labelNumber != null), hasLength(1));
    });
  });
}
