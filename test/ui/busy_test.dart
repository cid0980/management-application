import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/widgets/busy.dart';
import 'package:fm_shop/ui/widgets/save_guard.dart';

Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext ctx;
  var taps = 0;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            ctx = context;
            return TextButton(
              onPressed: () => taps++,
              child: Text('tap $taps'),
            );
          },
        ),
      ),
    ),
  );
  return ctx;
}

void main() {
  testWidgets('a slow save says "Saving…" and takes no second tap', (
    tester,
  ) async {
    final context = await _pump(tester);
    final work = Completer<int>();
    final result = whileBusy(context, work.future);
    await tester.pump();

    // At once: no card yet (a quick save does not flash), but no taps either.
    expect(find.text('Saving…'), findsNothing);
    await tester.tap(find.text('tap 0'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('tap 0'), findsOneWidget);

    // A moment later the card says what is happening.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving…'), findsOneWidget);

    work.complete(7);
    expect(await result, 7);
    await tester.pump();
    expect(find.text('Saving…'), findsNothing);
  });

  testWidgets('every guarded save shows it too', (tester) async {
    final context = await _pump(tester);
    final work = Completer<String>();
    final saved = guardSave(context, () => work.future);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving…'), findsOneWidget);
    work.complete('ok');
    expect(await saved, 'ok');
    await tester.pump();
    expect(find.text('Saving…'), findsNothing);
  });
}
