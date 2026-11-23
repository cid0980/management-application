import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';

void main() {
  Widget row(String selected) => ChoiceRow<String>(
    key: Key('row-$selected'),
    values: [for (var i = 0; i < 12; i++) 'Option number $i'],
    selected: selected,
    labelOf: (v) => v,
    keyOf: (v) => Key(v),
    onPicked: (_) {},
  );

  testWidgets('a row lower down the form does not scroll the form', (
    tester,
  ) async {
    final page = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: page,
            children: [const SizedBox(height: 1500), row('Option number 9')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(page.offset, 0);
  });

  testWidgets('the pick is brought into sight; the start stays when it shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: row('Option number 9'))),
    );
    await tester.pumpAndSettle();
    final chip = tester.getRect(find.byKey(const Key('Option number 9')));
    expect(chip.right, lessThanOrEqualTo(800));
    expect(chip.left, greaterThanOrEqualTo(0));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: row('Option number 1'))),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('Option number 0'))).left,
      greaterThanOrEqualTo(0),
    );
  });
}
