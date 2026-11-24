import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/l10n/value_labels.dart';

void main() {
  Future<String> shown(WidgetTester tester, String lang, String value) async {
    late String out;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            out = shopValue(context, value);
            return const SizedBox();
          },
        ),
      ),
    );
    return out;
  }

  testWidgets('built-in faults and checks read in Hindi and Tamil (FM #24)', (
    tester,
  ) async {
    expect(await shown(tester, 'hi', 'Not charging'), 'चार्ज नहीं होता');
    expect(await shown(tester, 'ta', 'Display OK'), 'டிஸ்ப்ளே சரி');
    expect(await shown(tester, 'en', 'Not charging'), 'Not charging');
    // What the shop typed itself stays as typed.
    expect(await shown(tester, 'hi', 'Probe fault'), 'Probe fault');
  });
}
