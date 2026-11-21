import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/widgets/fading_scroll.dart';

Widget _row(double width, int chips) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: width,
      child: FadingScroll(
        child: Row(
          children: [
            for (var i = 0; i < chips; i++)
              SizedBox(width: 100, child: Text('Tab $i')),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a row wider than the phone shows that it scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(_row(300, 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fading-scroll-hint')), findsOneWidget);
  });

  testWidgets('a row that fits shows no hint', (tester) async {
    await tester.pumpWidget(_row(800, 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fading-scroll-hint')), findsNothing);
  });

  testWidgets('every chip is still reachable by scrolling', (tester) async {
    await tester.pumpWidget(_row(300, 8));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tab 7'), findsOneWidget);
    // Scrolled to the end, there is still more to the left.
    expect(find.byKey(const Key('fading-scroll-hint')), findsOneWidget);
  });
}
