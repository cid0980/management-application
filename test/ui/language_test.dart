import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fm_shop/app/nav.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/settings/languages.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/l10n/l10n.dart';
import 'package:fm_shop/ui/widgets/language_picker.dart';

/// THE SHOP'S LANGUAGE, ON SCREEN
///
/// `languages_test.dart` holds the resolution rules down. This holds down the
/// two things only a widget can be wrong about: that the words actually come
/// out in the chosen language, and that a widget built without the delegate
/// falls back to English rather than throwing.
Widget _app({Locale? locale, required Widget child}) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

class _ShowsNavLabel extends StatelessWidget {
  const _ShowsNavLabel();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final item in kNavItems.take(7)) Text(item.labelIn(context.l10n)),
        ],
      );
}

void main() {
  testWidgets('the nav labels come out in Tamil', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('ta'), child: const _ShowsNavLabel()),
    );

    expect(find.text('விற்பனை'), findsOneWidget); // Sales
    expect(find.text('வாடிக்கையாளர்கள்'), findsOneWidget); // Customers
    expect(find.text('Sales'), findsNothing);
  });

  testWidgets('and in Hindi', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('hi'), child: const _ShowsNavLabel()),
    );

    expect(find.text('बिक्री'), findsOneWidget); // Sales
    expect(find.text('ग्राहक'), findsOneWidget); // Customers
  });

  testWidgets('and in English', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('en'), child: const _ShowsNavLabel()),
    );

    expect(find.text('Sales'), findsOneWidget);
  });

  testWidgets('a widget with no delegate above it falls back to English',
      (tester) async {
    // A sheet pumped on its own in a test, an error screen built before
    // MaterialApp is ready. English is a till; a red screen is not.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _ShowsNavLabel())),
    );

    expect(find.text('Sales'), findsOneWidget);
  });

  testWidgets('a language this build does not have still renders',
      (tester) async {
    // Telugu is not in supportedLocales; Flutter falls back rather than
    // leaving a shop with a blank app.
    await tester.pumpWidget(
      _app(locale: const Locale('te'), child: const _ShowsNavLabel()),
    );

    expect(find.text('Sales'), findsOneWidget);
  });

  group('the picker', () {
    testWidgets('names every language in its own script', (tester) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: LanguagePicker(
            selected: ShopLanguage.english,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      // With the English name underneath, for whoever is setting it up.
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('Hindi'), findsOneWidget);
    });

    testWidgets('picking one reports it', (tester) async {
      ShopLanguage? picked;
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: LanguagePicker(
            selected: ShopLanguage.english,
            onChanged: (l) => picked = l,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('language-ta')));
      await tester.pumpAndSettle();

      expect(picked, ShopLanguage.tamil);
    });

    testWidgets('a busy picker ignores taps rather than vanishing',
        (tester) async {
      ShopLanguage? picked;
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: LanguagePicker(
            selected: ShopLanguage.english,
            enabled: false,
            onChanged: (l) => picked = l,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('language-hi')));
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.text('हिन्दी'), findsOneWidget);
    });
  });

  group('what the shop stores', () {
    test('the code goes in and comes back out', () async {
      final store = InMemorySettingsStore();
      addTearDown(store.dispose);

      final result = await store.setLanguage(codeOf(ShopLanguage.tamil));

      expect(result.ok, isTrue);
      expect(store.settings.language, 'ta');
      expect(
        resolveLanguage(stored: store.settings.language),
        ShopLanguage.tamil,
      );
    });

    test('it survives a round trip through the document', () {
      final stored = ShopSettings.initial().copyWith(language: 'hi').toMap();

      expect(ShopSettings.fromMap(stored).language, 'hi');
    });

    test('a shop that has never picked one has nothing stored', () {
      // Not 'en': an empty setting falls back to the device's own language,
      // and a stored one does not.
      expect(ShopSettings.initial().language, '');
    });

    test('changing it notifies, so the whole app redraws', () async {
      final store = InMemorySettingsStore();
      addTearDown(store.dispose);

      var notices = 0;
      store.addListener(() => notices++);
      await store.setLanguage('ta');

      expect(notices, 1);
    });
  });

  group('every string is translated', () {
    // The generated class carries one getter per key, so a key missing from
    // Tamil or Hindi silently falls back to English rather than failing a
    // build. This is the check that notices.
    test('Tamil and Hindi have every key English has', () {
      final en = File('lib/l10n/app_en.arb').readAsStringSync();
      final ta = File('lib/l10n/app_ta.arb').readAsStringSync();
      final hi = File('lib/l10n/app_hi.arb').readAsStringSync();

      Set<String> keysOf(String raw) => (jsonDecode(raw) as Map)
          .keys
          .cast<String>()
          .where((k) => !k.startsWith('@'))
          .toSet();

      final english = keysOf(en);
      expect(english, isNotEmpty);
      expect(english.difference(keysOf(ta)), isEmpty,
          reason: 'missing from Tamil');
      expect(english.difference(keysOf(hi)), isEmpty,
          reason: 'missing from Hindi');
    });

    test('nothing is left in English in a translated file', () {
      // A copied-but-not-translated string is worse than a missing one: it
      // looks finished. These are the few that are the same word in every
      // language — a tax code, a product name — and are listed on purpose.
      const sameInEveryLanguage = {
        // A tax code and a dual-SIM field: the same letters everywhere.
        'shopGstin',
        'imei2',
        // Just the two placeholders and a comma.
        'greetingNamed',
        // A product name, written the same in every language.
        'contactWhatsApp',
      };

      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      final ta = jsonDecode(File('lib/l10n/app_ta.arb').readAsStringSync())
          as Map<String, dynamic>;

      final untranslated = <String>[
        for (final key in en.keys)
          if (!key.startsWith('@') &&
              !sameInEveryLanguage.contains(key) &&
              en[key] == ta[key])
            key,
      ];

      expect(untranslated, isEmpty, reason: 'still English in Tamil');
    });
  });
}
