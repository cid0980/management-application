import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/widgets/date_sheet.dart';

void main() {
  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold();
          },
        ),
      ),
    );
    return ctx;
  }

  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  testWidgets('a promised date: Tomorrow is one tap, from the bottom', (
    tester,
  ) async {
    final ctx = await host(tester);
    final now = DateTime.now();
    DateTime? got;
    pickDateSheet(
      ctx,
      initial: now,
      first: DateTime(now.year - 1),
      last: DateTime(now.year + 2),
    ).then((d) => got = d);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const Key('date-yesterday')), findsNothing);
    await tester.tap(find.byKey(const Key('date-tomorrow')));
    await tester.pumpAndSettle();
    expect(got, today().add(const Duration(days: 1)));
  });

  testWidgets('a purchase date offers today and the days before, not after', (
    tester,
  ) async {
    final ctx = await host(tester);
    DateTime? got;
    pickDateSheet(
      ctx,
      initial: DateTime.now(),
      first: DateTime(2015),
      last: DateTime.now(),
    ).then((d) => got = d);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('date-tomorrow')), findsNothing);
    await tester.tap(find.byKey(const Key('date-yesterday')));
    await tester.pumpAndSettle();
    expect(got, today().subtract(const Duration(days: 1)));
  });

  testWidgets('any other day: a tap on the month closes it with that day', (
    tester,
  ) async {
    final ctx = await host(tester);
    final now = DateTime.now();
    DateTime? got;
    pickDateSheet(
      ctx,
      initial: DateTime(now.year, now.month, 1),
      first: DateTime(now.year - 1),
      last: DateTime(now.year + 1),
    ).then((d) => got = d);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('date-calendar')),
        matching: find.text('15'),
      ),
    );
    await tester.pumpAndSettle();
    expect(got, DateTime(now.year, now.month, 15));
    expect(find.byType(BottomSheet), findsNothing);
  });
}
