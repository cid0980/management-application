import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/widgets/pattern_lock.dart';

void main() {
  test('the stored pattern is dots 1-9 joined with dashes, as before', () {
    expect(PatternLock.parse('1-2-3-6-9'), [0, 1, 2, 5, 8]);
    expect(PatternLock.format([0, 1, 2, 5, 8]), '1-2-3-6-9');
    // An older record written with commas or spaces still reads.
    expect(PatternLock.parse('1, 5 9'), [0, 4, 8]);
    // Nothing outside the grid is guessed at.
    expect(PatternLock.parse('0-10-x-4'), [3]);
  });

  testWidgets('drawing across the top row stores 1-2-3', (tester) async {
    String stored = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PatternLock(value: '', onChanged: (v) => stored = v),
        ),
      ),
    ));
    final grid = tester.getTopLeft(find.byKey(const Key('pattern-lock')));
    // Cells are 80 px; the dots sit at the centre of each.
    final gesture = await tester.startGesture(grid + const Offset(40, 40));
    await gesture.moveTo(grid + const Offset(120, 40));
    await gesture.moveTo(grid + const Offset(200, 40));
    await gesture.up();
    await tester.pump();
    expect(stored, '1-2-3');
  });
}
