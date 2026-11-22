import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chips.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/domain/common/counters.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/ui/screens/products/product_detail_screen.dart';
import 'package:fm_shop/ui/screens/products/product_list_screen.dart';

Product _p(
  String id, {
  String name = 'Tempered glass',
  int count = 10,
  int reorder = 4,
  num selling = 199,
}) =>
    Product(
      id: id,
      name: name,
      brand: 'Spigen',
      category: 'Screen guard',
      costPrice: 45,
      sellingPrice: selling,
      stockCount: count,
      reorderLevel: reorder,
    );

class Harness {
  Harness(this.products, this.labels, this.printer);
  final InMemoryProductStore products;
  final InMemoryLabelStore labels;
  final RecordingPrintServer printer;
}

Future<Harness> pumpProducts(
  WidgetTester tester,
  Widget screen, {
  List<Product>? seed,
}) async {
  tester.view.physicalSize = const Size(520, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final products = InMemoryProductStore(seed: seed ?? [_p('p-1')]);
  final labels = InMemoryLabelStore(
    counter: InMemoryCounter(),
    targets: {
      LabelTargetKind.product: LabelTargetBinding(
        snapshot: products.labelSnapshot,
        attach: (id, number) => products.attachLabel(id, number),
      ),
    },
  );
  final printer = RecordingPrintServer();
  addTearDown(products.dispose);
  addTearDown(labels.dispose);

  final settingsStore = InMemorySettingsStore();

  addTearDown(settingsStore.dispose);


  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsRepository>.value(
          value: settingsStore,
        ),
        ChangeNotifierProvider<ProductRepository>.value(value: products),
        ChangeNotifierProvider<LabelRepository>.value(value: labels),
        Provider<PrintServer>.value(value: printer),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return Harness(products, labels, printer);
}

Future<void> tapTab(WidgetTester tester, String label) =>
    tapChip(tester, label);

void main() {
  group('the list', () {
    testWidgets('each row answers how many are left', (tester) async {
      await pumpProducts(tester, const ProductListScreen());
      expect(find.text('Spigen Tempered glass'), findsOneWidget);
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('Reorder at 4'), findsOneWidget);
    });

    testWidgets('out of stock is its own answer, not a shade of low',
        (tester) async {
      await pumpProducts(tester, const ProductListScreen(), seed: [
        _p('low', name: 'Charger', count: 4, reorder: 4),
        _p('out', name: 'Cable', count: 0, reorder: 12),
      ]);
      expect(chipLabelled('Out of stock 1'), findsOneWidget);
      expect(chipLabelled('To order 2'), findsOneWidget);

      await tapTab(tester, 'Out of stock 1');
      expect(find.text('Spigen Cable'), findsOneWidget);
      expect(find.text('Spigen Charger'), findsNothing);
    });

    testWidgets('problems sort to the top', (tester) async {
      await pumpProducts(tester, const ProductListScreen(), seed: [
        _p('plenty', name: 'Alpha', count: 48, reorder: 10),
        _p('out', name: 'Zulu', count: 0, reorder: 12),
      ]);
      // Alphabetically Alpha would lead; by level Zulu does, because it has
      // run out.
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((tiles.first.title as Text).data, 'Spigen Zulu');
    });

    testWidgets('a product with no reorder level says so on the row',
        (tester) async {
      await pumpProducts(tester, const ProductListScreen(),
          seed: [_p('p-1', reorder: 0)]);
      // It will never show as low, and that is worth knowing.
      expect(find.text('No reorder level set'), findsOneWidget);
    });

    testWidgets('lines and units are shown as different numbers',
        (tester) async {
      await pumpProducts(tester, const ProductListScreen(), seed: [
        _p('a', name: 'Alpha', count: 10),
        _p('b', name: 'Bravo', count: 5),
      ]);
      expect(find.textContaining('2 product(s) · 15 unit(s)'), findsOneWidget);
    });

    testWidgets('search covers name, category and SKU', (tester) async {
      await pumpProducts(tester, const ProductListScreen(), seed: [
        _p('a', name: 'Tempered glass'),
        _p('b', name: 'Fast charger'),
      ]);
      await tester.enterText(
          find.byKey(const Key('product-search')), 'charger');
      await tester.pumpAndSettle();
      expect(find.text('Spigen Fast charger'), findsOneWidget);
      expect(find.text('Spigen Tempered glass'), findsNothing);
    });
  });

  group('the form cannot set a count', () {
    testWidgets('a new product is saved at zero, whatever is typed elsewhere',
        (tester) async {
      final h = await pumpProducts(tester, const ProductListScreen(), seed: []);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('product-name')), 'Cable');
      await tester.enterText(
          find.byKey(const Key('product-sellingPrice')), '249');
      await tester.pumpAndSettle();
      // There is no stock field at all.
      expect(find.byKey(const Key('product-stockCount')), findsNothing);
      expect(find.textContaining('A new product starts at zero'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(h.products.products, hasLength(1));
      expect(h.products.products.single.stockCount, 0);
      expect(h.products.products.single.sellingPrice, 249);
    });

    testWidgets('a name and a selling price are required', (tester) async {
      final h = await pumpProducts(tester, const ProductListScreen(), seed: []);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(h.products.products, isEmpty);
      expect(find.textContaining('A name is needed'), findsWidgets);
    });

    testWidgets('a duplicate is refused, naming the one already on the list',
        (tester) async {
      final h = await pumpProducts(tester, const ProductListScreen());
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('product-name')), 'Tempered glass');
      await tester.enterText(
          find.byKey(const Key('product-brand')), 'Spigen');
      await tester.enterText(
          find.byKey(const Key('product-sellingPrice')), '199');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Already on the list'), findsWidgets);
      expect(h.products.products, hasLength(1));
    });
  });

  group('stock changes from the detail page, with a reason', () {
    testWidgets('a delivery goes on the shelf and into the history',
        (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.tap(find.byKey(const Key('product-receive')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('move-quantity')), '20');
      await tester.enterText(
          find.byKey(const Key('move-reason')), 'Delivery from Chennai');
      await tester.tap(find.widgetWithText(FilledButton, 'Record'));
      await tester.pumpAndSettle();

      expect(h.products.byId('p-1')!.stockCount, 30);
      expect(find.text('Now 30 on the shelf'), findsOneWidget);
      expect(find.text('Delivery from Chennai'), findsOneWidget);
    });

    testWidgets('an unexplained movement is refused', (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.tap(find.byKey(const Key('product-receive')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('move-quantity')), '20');
      await tester.tap(find.widgetWithText(FilledButton, 'Record'));
      await tester.pumpAndSettle();

      expect(find.text('Say what this stock movement is for'), findsOneWidget);
      expect(h.products.byId('p-1')!.stockCount, 10);
    });

    testWidgets('writing off more than is there is refused, count untouched',
        (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.tap(find.byKey(const Key('product-damaged')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('move-quantity')), '50');
      await tester.enterText(find.byKey(const Key('move-reason')), 'Flood');
      await tester.tap(find.widgetWithText(FilledButton, 'Record'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not that much on the shelf'), findsOneWidget);
      expect(h.products.byId('p-1')!.stockCount, 10);
    });

    testWidgets('a stock-take records the difference', (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.tap(find.byKey(const Key('product-stocktake')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('stocktake-counted')), '13');
      await tester.tap(find.widgetWithText(FilledButton, 'Correct it'));
      await tester.pumpAndSettle();

      expect(h.products.byId('p-1')!.stockCount, 13);
      expect(find.textContaining('Corrected to 13'), findsOneWidget);
      expect(find.text('Stock-take: more than recorded'), findsOneWidget);
    });

    testWidgets('a stock-take that matched records nothing', (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      final before = h.products.history('p-1').length;
      await tester.tap(find.byKey(const Key('product-stocktake')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Correct it'));
      await tester.pumpAndSettle();

      expect(find.textContaining('already matched'), findsOneWidget);
      expect(h.products.history('p-1'), hasLength(before));
    });

    testWidgets('an out-of-stock product says it cannot be sold',
        (tester) async {
      await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
        seed: [_p('p-1', count: 0, reorder: 12)],
      );
      expect(find.textContaining('cannot be sold until some comes in'),
          findsOneWidget);
    });

    testWidgets('a product with no reorder level says what that means',
        (tester) async {
      await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
        seed: [_p('p-1', reorder: 0)],
      );
      expect(find.textContaining('only ever show as out of stock'),
          findsOneWidget);
    });

    testWidgets('a missing product is said so, not shown blank',
        (tester) async {
      await pumpProducts(tester, const ProductDetailScreen(id: 'nope'));
      expect(find.textContaining('No product nope'), findsOneWidget);
    });
  });

  group('labels', () {
    testWidgets('a product label comes off the one registry', (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.ensureVisible(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();

      expect(h.products.byId('p-1')!.labelNumber, 26001);
      expect(h.labels.byNumber(26001)!.kind, LabelTargetKind.product);
      expect(h.printer.jobs.single.number, 26001);
      // The selling price, never the cost.
      expect(h.printer.jobs.single.price, 199);
      expect(find.textContaining('26001 assigned'), findsOneWidget);
    });

    testWidgets('a second tap reprints rather than assigning again',
        (tester) async {
      final h = await pumpProducts(
        tester,
        const ProductDetailScreen(id: 'p-1'),
      );
      await tester.ensureVisible(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();
      // Let the first snackbar go: snackbars queue, so the second message
      // does not appear until the first has had its four seconds.
      await tester.pump(const Duration(seconds: 5));

      await tester.ensureVisible(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product-label')));
      await tester.pumpAndSettle();

      expect(h.labels.byNumber(26001)!.reprints, 1);
      // No second number was burnt.
      expect(h.labels.nextNumber, 26002);
      expect(find.textContaining('sent to the printer again'), findsOneWidget);
    });
  });
}
