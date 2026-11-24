import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/app/router.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/devices/tac_registry.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/ui/screens/labels/label_registry_screen.dart';
import 'package:fm_shop/ui/screens/labels/public_scan_screen.dart';
import 'package:fm_shop/ui/screens/scanner/scanner_screen.dart';

SecondHandDevice _device(String id, {num asking = 18500}) => SecondHandDevice(
      id: id,
      brand: 'Samsung',
      model: 'Galaxy A54',
      imei: '354879104523681',
      grade: 'A',
      askingPrice: asking,
    );

class Harness {
  Harness(this.stock, this.labels, this.printer);
  final InMemorySecondHandStore stock;
  final InMemoryLabelStore labels;
  final RecordingPrintServer printer;
}

Future<Harness> pumpScan(
  WidgetTester tester,
  Widget screen, {
  List<SecondHandDevice>? devices,
  List<LabelEntry>? seed,
}) async {
  tester.view.physicalSize = const Size(520, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final stock = InMemorySecondHandStore(seed: devices ?? [_device('sh-1')]);
  final labels = InMemoryLabelStore(
    seed: seed,
    counter: InMemoryCounter(),
    targets: {
      LabelTargetKind.secondHand: LabelTargetBinding(
        snapshot: stock.labelSnapshot,
        attach: (id, number) => stock.attachLabel(id, number),
      ),
    },
  );
  final printer = RecordingPrintServer();
  addTearDown(stock.dispose);
  addTearDown(labels.dispose);

  final settingsStore = InMemorySettingsStore();

  addTearDown(settingsStore.dispose);


  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsRepository>.value(
          value: settingsStore,
        ),
        ChangeNotifierProvider<SecondHandRepository>.value(value: stock),
        ChangeNotifierProvider<LabelRepository>.value(value: labels),
        Provider<TacRegistry>.value(value: SeedTacRegistry()),
        Provider<PrintServer>.value(value: printer),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
  return Harness(stock, labels, printer);
}

/// The whole app, through the real router, so a scan's query parameters
/// actually travel from the scanner to the intake form.
Future<Harness> pumpRouted(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(520, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final stock = InMemorySecondHandStore(seed: [_device('sh-1')]);
  final customers = InMemoryCustomerStore();
  final service = InMemoryServiceStore(seed: []);
  final products = InMemoryProductStore();
  // The dashboard this router lands on counts every area, so the tree needs
  // all of them even when the test is about the scanner.
  final enquiries = InMemoryEnquiryStore();
  final sales = InMemorySalesStore(
    stock: stock,
    products: products,
    customers: customers,
  );
  final labels = InMemoryLabelStore(
    counter: InMemoryCounter(),
    targets: {
      LabelTargetKind.secondHand: LabelTargetBinding(
        snapshot: stock.labelSnapshot,
        attach: (id, number) => stock.attachLabel(id, number),
      ),
      LabelTargetKind.service: LabelTargetBinding(
        snapshot: service.labelSnapshot,
        attach: (_, _) async {},
      ),
    },
  );
  final printer = RecordingPrintServer();
  final settings = InMemorySettingsStore();
  final auth = AuthState();
  await auth.signInLocally(email: 'a@b.c', role: Role.admin);

  for (final d in [
    stock,
    customers,
    service,
    products,
    enquiries,
    sales,
    labels,
    settings,
    auth,
  ]) {
    addTearDown(d.dispose);
  }

  final router = buildRouter(auth);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        ChangeNotifierProvider<SecondHandRepository>.value(value: stock),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<ServiceRepository>.value(value: service),
        ChangeNotifierProvider<ProductRepository>.value(value: products),
        ChangeNotifierProvider<EnquiryRepository>.value(value: enquiries),
        ChangeNotifierProvider<SalesRepository>.value(value: sales),
        ChangeNotifierProvider<LabelRepository>.value(value: labels),
        Provider<TacRegistry>.value(value: SeedTacRegistry()),
        Provider<PrintServer>.value(value: printer),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.go(location);
  await tester.pumpAndSettle();
  return Harness(stock, labels, printer);
}

Future<void> scan(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const Key('scan-code')), code);
  await tester.tap(find.byKey(const Key('scan-go')));
  await tester.pumpAndSettle();
}

void main() {
  group('a scan starts an intake, prefilled', () {
    testWidgets('the repair form opens with the IMEI, brand and model in',
        (tester) async {
      await pumpRouted(tester, '/scanner');
      await scan(tester, '354879104523681');
      await tester.tap(find.byKey(const Key('scan-intake-service')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('service-imei')))
            .controller!
            .text,
        '354879104523681',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('service-brand')))
            .controller!
            .text,
        'Samsung',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('service-model')))
            .controller!
            .text,
        'Galaxy A54',
      );
    });

    testWidgets('the purchase form opens the same way', (tester) async {
      await pumpRouted(tester, '/scanner');
      await scan(tester, '354879104523681');
      await tester.tap(find.byKey(const Key('scan-intake-purchase')));
      await tester.pumpAndSettle();
      // The form opens on its photo step; the prefill is on the phone step.
      await tester.tap(find.byKey(const Key('step-1')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('purchase-brand')))
            .controller!
            .text,
        'Samsung',
      );
    });

    testWidgets('an IMEI the table does not know still opens the form, with '
        'the IMEI alone', (tester) async {
      await pumpRouted(tester, '/scanner');
      await scan(tester, '999999999999999');
      await tester.tap(find.byKey(const Key('scan-intake-service')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('service-imei')))
            .controller!
            .text,
        '999999999999999',
      );
      // Nothing invented: the brand is left for someone to type.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('service-brand')))
            .controller!
            .text,
        '',
      );
    });

    testWidgets('opening a list without a scan opens no form', (tester) async {
      await pumpRouted(tester, '/service');
      expect(find.text('Take in a repair'), findsNothing);
    });

    testWidgets('the form is not reopened after it is closed', (tester) async {
      // The query parameters stay on the route so the link can be sent on, so
      // the guard is what stops someone being trapped behind the form.
      await pumpRouted(tester, '/service?imei=354879104523681&brand=Samsung');
      expect(find.text('Take in a repair'), findsOneWidget);

      await tester.tap(find.byTooltip('Discard this draft'));
      await tester.pumpAndSettle();
      expect(find.text('Take in a repair'), findsNothing);
    });
  });

  group('the scanner', () {
    testWidgets('a label opens the record itself, not a summary',
        (tester) async {
      final h = await pumpScan(tester, const ScannerScreen());
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await tester.pumpAndSettle();

      await scan(tester, '26001');
      expect(find.text('Label 26001'), findsOneWidget);
      expect(find.text('Samsung Galaxy A54'), findsOneWidget);
      // Staff scan a label because they are holding the phone and have
      // something to do about it.
      expect(find.byKey(const Key('scan-open')), findsOneWidget);
      expect(find.text('Open the second-hand handset'), findsOneWidget);
    });

    testWidgets('an IMEI scanned in label mode is recognised, not failed',
        (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await scan(tester, '354879104523681');

      // The sentence this whole page exists for.
      expect(find.textContaining('factory IMEI, not a shop label'),
          findsOneWidget);
      expect(find.text('IMEI 354879104523681'), findsOneWidget);
      expect(find.text('TAC 35487910'), findsOneWidget);
      // And the device table has already been asked, so the offer is useful.
      expect(find.textContaining('Looks like a Samsung Galaxy A54'),
          findsOneWidget);
      expect(find.byKey(const Key('scan-intake-service')), findsOneWidget);
      expect(find.byKey(const Key('scan-intake-purchase')), findsOneWidget);
    });

    testWidgets('an IMEI the table does not know still offers an intake',
        (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await scan(tester, '999999999999999');
      expect(find.textContaining('Not in the device table'), findsOneWidget);
      expect(find.byKey(const Key('scan-intake-service')), findsOneWidget);
    });

    testWidgets('switching mode drops the previous answer', (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await scan(tester, '354879104523681');
      expect(find.text('IMEI 354879104523681'), findsOneWidget);

      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      // The result belonged to the previous question.
      expect(find.text('IMEI 354879104523681'), findsNothing);
    });

    testWidgets('in an intake mode the same IMEI is not called a mistake',
        (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await tester.tap(find.text('New repair'));
      await tester.pumpAndSettle();
      await scan(tester, '354879104523681');
      expect(find.textContaining('factory IMEI, not a shop label'),
          findsNothing);
      expect(find.text('IMEI 354879104523681'), findsOneWidget);
    });

    testWidgets('an unknown label says so with the number on the sticker',
        (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await scan(tester, '26099');
      expect(find.text('Label 26099 is not in the registry'), findsOneWidget);
      expect(find.text('Open the registry'), findsOneWidget);
    });

    testWidgets('a retail barcode is neither, and says which', (tester) async {
      await pumpScan(tester, const ScannerScreen());
      await scan(tester, 'SKU-ABC-9');
      expect(find.text('Not a number this shop uses'), findsOneWidget);
      expect(find.textContaining('retail box'), findsOneWidget);
    });

    testWidgets('a price corrected since printing shows the current one',
        (tester) async {
      final h = await pumpScan(tester, const ScannerScreen());
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await h.stock.save(h.stock.byId('sh-1')!.copyWith(askingPrice: 16900));
      await tester.pumpAndSettle();

      await scan(tester, '26001');
      expect(find.textContaining('₹16,900'), findsOneWidget);
      // And says the sticker is out of date, so nobody reads the old price out.
      expect(find.textContaining('Changed since this sticker was printed'),
          findsOneWidget);
    });

    testWidgets('a label whose record is gone still resolves, with no open '
        'button', (tester) async {
      final h = await pumpScan(tester, const ScannerScreen(), seed: [
        LabelEntry(
          number: 26001,
          kind: LabelTargetKind.secondHand,
          recordId: 'deleted',
          snapshot: const {
            kLabelTitle: 'Samsung Galaxy A54',
            kLabelPrice: 18500,
          },
        ),
      ]);
      expect(h.labels.byNumber(26001), isNotNull);

      await scan(tester, '26001');
      expect(find.text('Samsung Galaxy A54'), findsOneWidget);
      expect(find.textContaining('record behind this label is gone'),
          findsOneWidget);
      expect(find.byKey(const Key('scan-open')), findsNothing);
    });
  });

  group('the registry', () {
    testWidgets('shows the next number without taking it', (tester) async {
      final h = await pumpScan(tester, const LabelRegistryScreen());
      expect(find.text('Next label: 26001'), findsOneWidget);
      // Opening the page must not consume one.
      expect(h.labels.nextNumber, 26001);
      expect(find.textContaining('one counter for the whole shop'),
          findsOneWidget);
    });

    testWidgets('an empty registry explains where labels come from',
        (tester) async {
      await pumpScan(tester, const LabelRegistryScreen());
      expect(find.textContaining('Nothing printed yet'), findsOneWidget);
    });

    testWidgets('lists what has been printed, newest first', (tester) async {
      final h = await pumpScan(
        tester,
        const LabelRegistryScreen(),
        devices: [_device('sh-1'), _device('sh-2')],
      );
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-2');
      await tester.pumpAndSettle();

      expect(find.text('Next label: 26003'), findsOneWidget);
      expect(find.textContaining('26002 ·'), findsOneWidget);
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((tiles.first.title as Text).data, startsWith('26002'));
    });

    testWidgets('a reprint keeps the number and sends it to the printer',
        (tester) async {
      final h = await pumpScan(tester, const LabelRegistryScreen());
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reprint-26001')));
      await tester.pumpAndSettle();

      expect(h.labels.byNumber(26001)!.reprints, 1);
      // The number is kept: the first sticker may still be on something.
      expect(h.labels.nextNumber, 26002);
      expect(h.printer.jobs.single.number, 26001);
      // The barcode encodes the number alone, or the scanner's length rule
      // stops working.
      expect(h.printer.jobs.single.toJson()['barcode'], '26001');
      expect(find.textContaining('sent to the printer'), findsOneWidget);
    });

    testWidgets('a failed print says why, and the label is still assigned',
        (tester) async {
      final h = await pumpScan(tester, const LabelRegistryScreen());
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await tester.pumpAndSettle();
      h.printer.failWith = 'Could not reach the print server';

      await tester.tap(find.byKey(const Key('reprint-26001')));
      await tester.pumpAndSettle();

      expect(find.text('Could not reach the print server'), findsOneWidget);
      expect(h.labels.byNumber(26001), isNotNull);
    });

    testWidgets('a sticker out of date is flagged in the list', (tester) async {
      final h = await pumpScan(tester, const LabelRegistryScreen());
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await h.stock.save(h.stock.byId('sh-1')!.copyWith(askingPrice: 16900));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sticker out of date'), findsOneWidget);
    });

    testWidgets('a label with an unreadable kind is still listed',
        (tester) async {
      // The number is real and stuck to something.
      await pumpScan(tester, const LabelRegistryScreen(), seed: [
        LabelEntry.fromMap(const {
          'number': 26001,
          'kind': 'teleporter',
          'recordId': 'x',
          'snapshot': {kLabelTitle: 'Something'},
        }),
      ]);
      expect(find.text('Unreadable kind'), findsOneWidget);
      expect(find.byKey(const Key('open-26001')), findsNothing);
    });

    testWidgets('search finds a label by number', (tester) async {
      final h = await pumpScan(
        tester,
        const LabelRegistryScreen(),
        devices: [_device('sh-1'), _device('sh-2')],
      );
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-2');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('label-search')), '26002');
      await tester.pumpAndSettle();
      expect(find.textContaining('26002 ·'), findsOneWidget);
      expect(find.textContaining('26001 ·'), findsNothing);
    });
  });

  group('the public scan page', () {
    testWidgets('shows what is on the sticker and nothing more',
        (tester) async {
      final h = await pumpScan(
        tester,
        const PublicScanScreen(labelNumber: '26001'),
      );
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await tester.pumpAndSettle();

      expect(find.text('Samsung Galaxy A54'), findsOneWidget);
      expect(find.text('₹18,500'), findsOneWidget);
      // Nothing the shop paid, nothing about the seller: this page is public.
      expect(find.textContaining('14500'), findsNothing);
      expect(find.textContaining('Seller'), findsNothing);
    });

    testWidgets('an unknown number tells the customer what to do',
        (tester) async {
      await pumpScan(tester, const PublicScanScreen(labelNumber: '26099'));
      expect(find.text('Label 26099'), findsOneWidget);
      expect(find.textContaining('quote the number at the counter'),
          findsOneWidget);
    });

    testWidgets('a number that is not a number does not throw', (tester) async {
      await pumpScan(tester, const PublicScanScreen(labelNumber: 'abc'));
      expect(find.text('Label abc'), findsOneWidget);
    });

    testWidgets('a changed price is shown as current, and said so',
        (tester) async {
      final h = await pumpScan(
        tester,
        const PublicScanScreen(labelNumber: '26001'),
      );
      await h.labels.assign(LabelTargetKind.secondHand, 'sh-1');
      await h.stock.save(h.stock.byId('sh-1')!.copyWith(askingPrice: 16900));
      await tester.pumpAndSettle();

      expect(find.text('₹16,900'), findsOneWidget);
      // The alternative is a customer reading a stale price off a sticker and
      // the shop arguing about it.
      expect(find.textContaining('What is shown here is current'),
          findsOneWidget);
    });
  });
}
