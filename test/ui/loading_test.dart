import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/widgets/loading.dart';

void main() {
  testWidgets('loading says what it is getting, then keeps talking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LoadingWords(first: 'Getting your repairs…')),
      ),
    );
    expect(find.text('Getting your repairs…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(LoadingWords.step);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Still working on it…'), findsOneWidget);

    await tester.pump(LoadingWords.step);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Almost there…'), findsOneWidget);

    await tester.pump(LoadingWords.step);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Slow internet? Hang on…'), findsOneWidget);

    // Round again, without going back to the first line.
    await tester.pump(LoadingWords.step);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Still working on it…'), findsOneWidget);
    expect(find.text('Getting your repairs…'), findsNothing);
  });
}
