import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/theme/app_theme.dart';
import 'package:fm_shop/ui/widgets/input_sheet.dart';

void main() {
  testWidgets('filling something in opens from the bottom, not a box', (
    tester,
  ) async {
    String? got;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                got = await showInputSheet<String>(
                  context: context,
                  builder: (sheet) => InputSheet(
                    title: const Text('Why?'),
                    content: const TextField(key: Key('why')),
                    actions: [
                      TextButton(
                        key: const Key('cancel'),
                        onPressed: () => Navigator.of(sheet).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(sheet).pop('ok'),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);

    // The two buttons share the row, each half of it.
    final cancel = tester.getSize(find.byKey(const Key('cancel')));
    final save = tester.getSize(find.widgetWithText(FilledButton, 'Save'));
    expect(cancel.width, closeTo(save.width, 1));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(got, 'ok');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('"are you sure?" comes from the bottom; swiping away is a no', (
    tester,
  ) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => answers.add(
                await confirmSheet(
                  context,
                  title: 'Remove Ravi?',
                  yes: 'Remove',
                  no: 'Keep',
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-yes')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-no')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(answers, [true, false, false]);
  });
}
