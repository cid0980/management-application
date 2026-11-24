import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/ui/screens/second_hand/second_hand_list_screen.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';

/// Scrolling the tab into view first: the tab track scrolls sideways on a
/// phone, so the later tabs are off-screen and a tap on one lands nowhere.
/// The tab chip whose name and count are [label] — "In stock 2".
Finder tab(String label) {
  final parts = label.split(' ');
  final count = parts.removeLast();
  final name = parts.join(' ');
  return find.ancestor(
    of: find.text(name),
    matching: find.byWidgetPredicate(
      (w) =>
          w is CountChip &&
          w.label == name &&
          '${w.count}' == count,
    ),
  );
}

Future<void> tapTab(WidgetTester tester, String label) async {
  final chip = tab(label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// A repository that failed to load, which is the case the list has to tell
/// apart from an empty shelf. Staff read a blank list as "no stock", and a
/// blank list is what a broken query looks like.
class _BrokenStore extends ChangeNotifier implements SecondHandRepository {
  @override
  List<SecondHandDevice> get devices => const [];
  @override
  bool get loading => false;
  @override
  String? get error => 'The counter PC is offline';
  @override
  Future<void> load() async {}
  @override
  SecondHandDevice? byId(String id) => null;
  @override
  Future<SecondHandDevice> save(SecondHandDevice device) async => device;
  @override
  Future<SecondHandDevice> setRepairing(String id, {required bool repairing}) =>
      throw UnimplementedError();
  @override
  Future<SecondHandDevice> markSold(String id, {required num soldPrice}) =>
      throw UnimplementedError();
  @override
  Future<SecondHandDevice> attachLabel(String id, int number) =>
      throw UnimplementedError();
  @override
  Map<String, Object?>? labelSnapshot(String id) => null;
  @override
  Future<SecondHandDevice> returnToStock(String id, {required String reason}) =>
      throw UnimplementedError();
}

Future<void> pumpList(WidgetTester tester, SecondHandRepository repo) async {
  tester.view.physicalSize = const Size(420, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final settingsStore = InMemorySettingsStore();

  addTearDown(settingsStore.dispose);


  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsRepository>.value(
          value: settingsStore,
        ),
        ChangeNotifierProvider<SecondHandRepository>.value(value: repo),
        ChangeNotifierProvider<LabelRepository>.value(
          value: InMemoryLabelStore(targets: {
            LabelTargetKind.secondHand: LabelTargetBinding(
              snapshot: repo.labelSnapshot,
              attach: (id, number) => repo.attachLabel(id, number),
            ),
          }),
        ),
        Provider<PrintServer>.value(value: RecordingPrintServer()),
      ],
      child: const MaterialApp(home: SecondHandListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a failed load says so rather than showing an empty shelf',
      (tester) async {
    final repo = _BrokenStore();
    addTearDown(repo.dispose);
    await pumpList(tester, repo);

    expect(find.text('Stock could not be loaded'), findsOneWidget);
    expect(find.text('The counter PC is offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // Not the "nothing in stock" message, which means something different.
    expect(find.textContaining('Nothing in'), findsNothing);
  });

  testWidgets('an empty tab says it is empty, and how to fill it',
      (tester) async {
    final repo = InMemorySecondHandStore(seed: []);
    addTearDown(repo.dispose);
    await pumpList(tester, repo);

    expect(find.textContaining('Nothing in'), findsOneWidget);
    expect(find.text('Buy phone'), findsOneWidget);
  });

  testWidgets('the tabs count what the current search holds', (tester) async {
    final repo = InMemorySecondHandStore();
    addTearDown(repo.dispose);
    await pumpList(tester, repo);

    // The seed is two on the shelf (one of them written by an older build with
    // a status this one has never seen), one on the bench, one sold.
    expect(tab('In stock 2'), findsOneWidget);
    expect(tab('Repairing 1'), findsOneWidget);
    expect(tab('Sold 1'), findsOneWidget);
    expect(tab('All 4'), findsOneWidget);

    // The shelf and the bench together are what the shop's money is in, which
    // is a different number from the "In stock" tab and says so.
    expect(find.textContaining('3 on hand'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xiaomi');
    await tester.pumpAndSettle();
    expect(tab('In stock 0'), findsOneWidget);
    expect(tab('Repairing 1'), findsOneWidget);
    expect(tab('All 1'), findsOneWidget);
  });

  testWidgets('a sold row shows what it made, not what it hoped for',
      (tester) async {
    final repo = InMemorySecondHandStore();
    addTearDown(repo.dispose);
    await pumpList(tester, repo);

    await tapTab(tester, 'Sold 1');
    // Seed sh-3: bought 19000, sold 24000.
    expect(find.textContaining('made ₹5,000'), findsOneWidget);
  });

  testWidgets('a device on the bench is labelled as such, not as stock',
      (tester) async {
    final repo = InMemorySecondHandStore();
    addTearDown(repo.dispose);
    await pumpList(tester, repo);

    await tapTab(tester, 'Repairing 1');
    expect(find.text(kStockLabels[kRepairing]!), findsOneWidget);
    expect(find.text('Xiaomi Redmi Note 12 6/128'), findsOneWidget);
  });
}
