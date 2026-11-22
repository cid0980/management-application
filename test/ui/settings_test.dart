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

Future<InMemorySettingsStore> pumpSettings(
  WidgetTester tester, {
  ShopSettings? seed,
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
      child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> addVia(WidgetTester tester, String fieldKey, String value) async {
  final field = find.byKey(Key(fieldKey));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.tap(find.byKey(Key('$fieldKey-go')));
  await tester.pumpAndSettle();
}

void main() {
  group('the page says the lists grow by themselves', () {
    testWidgets('because staff do not come here to add a brand', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('These lists grow by themselves'), findsOneWidget);
      expect(find.textContaining('joins it'), findsOneWidget);
    });

    testWidgets('every list has a section with a name and a purpose', (
      tester,
    ) async {
      await pumpSettings(tester);
      for (final kind in OptionKind.values) {
        expect(
          find.text(kOptionKindLabels[kind]!),
          findsOneWidget,
          reason: kind.name,
        );
      }
    });
  });

  group('adding', () {
    testWidgets('a value joins the list', (tester) async {
      final store = await pumpSettings(tester);
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
      final store = await pumpSettings(tester);
      await addVia(tester, 'add-brands', 'samsung');
      // Case and space do not make a new value.
      expect(store.settings.list(OptionKind.brands).length, 2);
      expect(find.textContaining('already on the list'), findsOneWidget);
    });

    testWidgets('a blank value files nothing', (tester) async {
      final store = await pumpSettings(tester);
      await addVia(tester, 'add-colours', '   ');
      expect(store.settings.list(OptionKind.colours).length, 1);
    });
  });

  group('removing', () {
    testWidgets('asks first, and says records are untouched', (tester) async {
      final store = await pumpSettings(tester);
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
      final store = await pumpSettings(tester);
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
        seed: ShopSettings(
          lists: {OptionKind.brands: OptionSet(const [])},
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
      await pumpSettings(tester);
      final tile = find.byKey(const Key('models-Samsung'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      expect(find.text('1 model(s)'), findsOneWidget);
    });

    testWidgets('a model can be added under a brand', (tester) async {
      final store = await pumpSettings(tester);
      final tile = find.byKey(const Key('models-Samsung'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      await addVia(tester, 'add-model-Samsung', 'Galaxy S24');
      expect(store.settings.modelsFor('Samsung').values, [
        'Galaxy A54',
        'Galaxy S24',
      ]);
    });

    testWidgets('a brand with no models says the next one typed will land '
        'there', (tester) async {
      await pumpSettings(tester);
      final tile = find.byKey(const Key('models-Apple'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.textContaining('None yet'), findsOneWidget);
    });
  });

  group('the pre-delivery checklist', () {
    testWidgets('is numbered, because the order is how it is worked through', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('1'), findsWidgets);
      expect(find.byKey(const Key('checklist-Display OK')), findsOneWidget);
    });

    testWidgets('an item moves down, and the rest keep their order', (
      tester,
    ) async {
      final store = await pumpSettings(tester);
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
      await pumpSettings(tester);
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
      final store = await pumpSettings(tester);
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
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
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
