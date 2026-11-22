import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';

/// The counted tab chip whose name and count read [label], e.g. "Overdue 1".
/// The chip draws them as two words; tests name it as one, as people read it.
Finder chipLabelled(String label) {
  final parts = label.split(' ');
  final count = parts.removeLast();
  final name = parts.join(' ');
  return find.byWidgetPredicate(
    (w) => w is CountChip && w.label == name && '${w.count}' == count,
    description: 'CountChip "$label"',
  );
}

/// Scrolling the tab into view first: the row scrolls sideways on a phone, so
/// a later tab is off-screen and a tap on it lands nowhere.
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = chipLabelled(label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// The picked chip's "name count", for asserting which tab a list opened on.
String selectedChipLabel(WidgetTester tester) {
  final chip = tester
      .widgetList<CountChip>(find.byType(CountChip))
      .firstWhere((c) => c.selected);
  return '${chip.label} ${chip.count}';
}
