import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/printing/tspl.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/printing/label_printer_prefs.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/settings/option_set.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';
import 'package:fm_shop/ui/screens/settings/settings_screen.dart';

/// One Settings page, or the menu when [screen] is not given.
Future<InMemorySettingsStore> pumpSettings(
  WidgetTester tester, {
  ShopSettings? seed,
  Widget screen = const SettingsScreen(),
}) async {
  tester.view.physicalSize = const Size(560, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final store = InMemorySettingsStore(
    seed:
        seed ??
        ShopSettings(
          lists: {
            OptionKind.brands: OptionSet(['Samsung', 'Apple']),
            OptionKind.colours: OptionSet(['Black']),
          },
          modelsByBrand: {
            'samsung': OptionSet(['Galaxy A54']),
          },
          preDeliveryChecklist: OptionSet(['Display OK', 'Charging tested']),
        ),
  );
  addTearDown(store.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsRepository>.value(
      value: store,
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

const brandsPage = SettingsPageScreen(page: SettingsPage.brands);
const coloursPage = SettingsPageScreen(page: SettingsPage.colours);
const checklistPage = SettingsPageScreen(page: SettingsPage.checklist);

Future<void> addVia(WidgetTester tester, String fieldKey, String value) async {
  final field = find.byKey(Key(fieldKey));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.tap(find.byKey(Key('$fieldKey-go')));
  await tester.pumpAndSettle();
}

void main() {
  group('the menu', () {
    testWidgets('says the lists grow by themselves', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining('joins it'), findsOneWidget);
    });

    testWidgets('the app tour can be started again from Settings, first', (
      tester,
    ) async {
      await pumpSettings(tester);
      final tour = find.byKey(const Key('settings-tour'));
      expect(tour, findsOneWidget);
      expect(find.text('App tour'), findsOneWidget);
      // At the top, above the shop's own settings.
      expect(
        tester.getTopLeft(tour).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('settings-shop'))).dy),
      );
    });

    testWidgets('groups every setting, each with its own page', (tester) async {
      await pumpSettings(tester);
      for (final group in [
        'Shop',
        'Phones & stock lists',
        'Repairs',
        'Printing',
        'Staff & money',
        'Online',
      ]) {
        expect(find.text(group), findsOneWidget, reason: group);
      }
      for (final page in SettingsPage.values) {
        expect(
          find.byKey(Key('settings-${page.name}')),
          findsOneWidget,
          reason: page.name,
        );
      }
      // Every list is reachable: brands, RAM and storage share pages.
      for (final kind in OptionKind.values) {
        if (SettingsPage.forKind(kind) == null) continue;
        expect(find.text(kOptionKindLabels[kind]!), findsOneWidget);
      }
      expect(find.text('Brands & models'), findsOneWidget);
      expect(find.text('RAM & storage'), findsOneWidget);
    });

    testWidgets('RAM and storage are one page, each list named', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        screen: const SettingsPageScreen(page: SettingsPage.memory),
      );
      expect(find.text(kOptionKindLabels[OptionKind.ram]!), findsOneWidget);
      expect(find.text(kOptionKindLabels[OptionKind.rom]!), findsOneWidget);
      expect(find.byKey(const Key('add-ram')), findsOneWidget);
      expect(find.byKey(const Key('add-rom')), findsOneWidget);
    });
  });

  group('adding', () {
    testWidgets('a value joins the list', (tester) async {
      final store = await pumpSettings(tester, screen: brandsPage);
      await addVia(tester, 'add-brands', 'Infinix');
      expect(
        store.settings.list(OptionKind.brands).contains('Infinix'),
        isTrue,
      );
      expect(find.text('Added "Infinix"'), findsOneWidget);
    });

    testWidgets('a value already on the list says so rather than duplicating', (
      tester,
    ) async {
      final store = await pumpSettings(tester, screen: brandsPage);
      await addVia(tester, 'add-brands', 'samsung');
      // Case and space do not make a new value.
      expect(store.settings.list(OptionKind.brands).length, 2);
      expect(find.textContaining('already on the list'), findsOneWidget);
    });

    testWidgets('a blank value files nothing', (tester) async {
      final store = await pumpSettings(tester, screen: coloursPage);
      await addVia(tester, 'add-colours', '   ');
      expect(store.settings.list(OptionKind.colours).length, 1);
    });
  });

  group('removing', () {
    testWidgets('asks first, and says records are untouched', (tester) async {
      final store = await pumpSettings(tester, screen: brandsPage);
      final remove = find.byKey(const Key('remove-brands-Apple'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();

      // The thing people actually worry about when they hesitate.
      expect(
        find.textContaining('Records that already use it are not changed'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(store.settings.list(OptionKind.brands).contains('Apple'), isFalse);
    });

    testWidgets('keeping it changes nothing', (tester) async {
      final store = await pumpSettings(tester, screen: brandsPage);
      final remove = find.byKey(const Key('remove-brands-Apple'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Keep it'));
      await tester.pumpAndSettle();
      expect(store.settings.list(OptionKind.brands).contains('Apple'), isTrue);
    });

    testWidgets('an emptied list says the next typed value will refill it', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        screen: coloursPage,
        seed: ShopSettings(
          lists: {OptionKind.colours: OptionSet(const [])},
          preDeliveryChecklist: OptionSet(['Display OK']),
        ),
      );
      expect(
        find.textContaining('next value typed into a form will start it off'),
        findsWidgets,
      );
    });
  });

  group('models hang off brands', () {
    testWidgets('each brand shows how many it has', (tester) async {
      await pumpSettings(tester, screen: brandsPage);
      expect(find.byKey(const Key('option-brands-Samsung')), findsOneWidget);
      expect(find.text('1 model(s)'), findsOneWidget);
    });

    testWidgets('a model can be added under a brand', (tester) async {
      final store = await pumpSettings(
        tester,
        screen: const BrandModelsScreen(brand: 'Samsung'),
      );
      await addVia(tester, 'add-model-Samsung', 'Galaxy S24');
      expect(store.settings.modelsFor('Samsung').values, [
        'Galaxy A54',
        'Galaxy S24',
      ]);
    });

    testWidgets('a brand with no models says the next one typed will land '
        'there', (tester) async {
      await pumpSettings(
        tester,
        screen: const BrandModelsScreen(brand: 'Apple'),
      );
      expect(find.textContaining('None yet'), findsOneWidget);
    });

    testWidgets('renaming a brand takes its models with it', (tester) async {
      final store = await pumpSettings(tester, screen: brandsPage);
      await tester.tap(find.byKey(const Key('rename-brands-Samsung')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('rename-field')), 'SAMSUNG');
      await tester.tap(find.byKey(const Key('rename-save')));
      await tester.pumpAndSettle();
      expect(
        store.settings.list(OptionKind.brands).values,
        contains('SAMSUNG'),
      );
      expect(store.settings.modelsFor('SAMSUNG').values, ['Galaxy A54']);
    });
  });

  group('the list editor', () {
    testWidgets('one value per row, with rename and remove', (tester) async {
      await pumpSettings(tester, screen: coloursPage);
      expect(find.byKey(const Key('option-colours-Black')), findsOneWidget);
      expect(find.byKey(const Key('rename-colours-Black')), findsOneWidget);
      expect(find.byKey(const Key('remove-colours-Black')), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('a typo is fixed by renaming', (tester) async {
      final store = await pumpSettings(
        tester,
        screen: coloursPage,
        seed: ShopSettings(
          lists: {
            OptionKind.colours: OptionSet(['Blak']),
          },
        ),
      );
      await tester.tap(find.byKey(const Key('rename-colours-Blak')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('rename-field')), 'Black');
      await tester.tap(find.byKey(const Key('rename-save')));
      await tester.pumpAndSettle();
      expect(store.settings.list(OptionKind.colours).values, ['Black']);
    });

    testWidgets('a long list gets a search box that narrows it', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        screen: coloursPage,
        seed: ShopSettings(
          lists: {
            OptionKind.colours: OptionSet([
              for (final c in [
                'Black',
                'White',
                'Blue',
                'Green',
                'Red',
                'Gold',
                'Silver',
                'Grey',
                'Purple',
                'Pink',
                'Mint',
              ])
                c,
            ]),
          },
        ),
      );
      await tester.enterText(find.byKey(const Key('search-colours')), 'bl');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('option-colours-Black')), findsOneWidget);
      expect(find.byKey(const Key('option-colours-Blue')), findsOneWidget);
      expect(find.byKey(const Key('option-colours-Gold')), findsNothing);
    });
  });

  group('the pre-delivery checklist', () {
    testWidgets('is numbered, because the order is how it is worked through', (
      tester,
    ) async {
      await pumpSettings(tester, screen: checklistPage);
      expect(find.text('1'), findsWidgets);
      expect(find.byKey(const Key('checklist-Display OK')), findsOneWidget);
    });

    testWidgets('an item moves down, and the rest keep their order', (
      tester,
    ) async {
      final store = await pumpSettings(tester, screen: checklistPage);
      final button = find.byKey(const Key('checklist-down-Display OK'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(store.settings.preDeliveryChecklist.values, [
        'Charging tested',
        'Display OK',
      ]);
    });

    testWidgets('the first item cannot move up and the last cannot move down', (
      tester,
    ) async {
      await pumpSettings(tester, screen: checklistPage);
      final up = find.byKey(const Key('checklist-up-Display OK'));
      await tester.ensureVisible(up);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(up).onPressed, isNull);

      final down = find.byKey(const Key('checklist-down-Charging tested'));
      await tester.ensureVisible(down);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(down).onPressed, isNull);
    });

    testWidgets('an item can be added and removed', (tester) async {
      final store = await pumpSettings(tester, screen: checklistPage);
      await addVia(tester, 'add-checklist', 'Camera tested');
      expect(store.settings.preDeliveryChecklist.values.last, 'Camera tested');

      final remove = find.byKey(const Key('checklist-remove-Camera tested'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(
        store.settings.preDeliveryChecklist.contains('Camera tested'),
        isFalse,
      );
    });

    testWidgets('an empty checklist says plainly that the gate is off', (
      tester,
    ) async {
      // It quietly lets any repair be handed back once it has been charged.
      await pumpSettings(
        tester,
        screen: checklistPage,
        seed: ShopSettings(preDeliveryChecklist: OptionSet(const [])),
      );
      expect(
        find.textContaining('nothing to verify and any repair can be handed'),
        findsOneWidget,
      );
    });

    testWidgets('two labels that slug to one key are called out', (
      tester,
    ) async {
      // They are kept apart by checklistEntries, but they will look like
      // duplicates to whoever is ticking them.
      await pumpSettings(
        tester,
        screen: checklistPage,
        seed: ShopSettings(
          preDeliveryChecklist: OptionSet(['Display OK', 'Display: OK!']),
        ),
      );
      expect(find.textContaining('read as the same item'), findsOneWidget);
      expect(find.textContaining('Display: OK!'), findsWidgets);
    });
  });

  group('the label printer', () {
    Future<LabelPrinterPrefs> pumpWithPrinter(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = InMemorySettingsStore();
      final prefs = LabelPrinterPrefs();
      addTearDown(store.dispose);
      addTearDown(prefs.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsRepository>.value(value: store),
            ChangeNotifierProvider<LabelPrinterPrefs>.value(value: prefs),
            Provider<PrintServer>.value(value: RecordingPrintServer()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsPageScreen(page: SettingsPage.printer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A long page that builds only what is on screen: scroll to the section.
      await tester.scrollUntilVisible(
        find.byKey(const Key('print-test-label')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      return prefs;
    }

    testWidgets('there is no print-server address to type any more', (
      tester,
    ) async {
      await pumpWithPrinter(tester);
      expect(find.byKey(const Key('print-server-url')), findsNothing);
      expect(find.byKey(const Key('label-print-mode')), findsOneWidget);
    });

    testWidgets('choosing Bluetooth offers the printer, size and darkness', (
      tester,
    ) async {
      final prefs = await pumpWithPrinter(tester);
      final bt = find.text('Bluetooth printer');
      await tester.ensureVisible(bt);
      await tester.pumpAndSettle();
      await tester.tap(bt);
      await tester.pumpAndSettle();
      expect(prefs.mode, LabelPrintMode.bluetooth);
      expect(find.byKey(const Key('choose-printer')), findsOneWidget);
      expect(find.text('No printer chosen'), findsOneWidget);
      expect(find.text('50 × 25 mm'), findsOneWidget);

      await tester.ensureVisible(find.text('40 × 30 mm'));
      await tester.tap(find.text('40 × 30 mm'));
      await tester.pumpAndSettle();
      expect(prefs.size, LabelSize.mm40x30);
    });

    testWidgets('the test label goes to the printer and says so', (
      tester,
    ) async {
      await pumpWithPrinter(tester);
      final test = find.byKey(const Key('print-test-label'));
      await tester.ensureVisible(test);
      await tester.pumpAndSettle();
      await tester.tap(test);
      await tester.pumpAndSettle();
      expect(find.text('Test label sent to the printer'), findsOneWidget);
    });
  });
}
