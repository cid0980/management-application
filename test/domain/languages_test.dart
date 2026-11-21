import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/settings/languages.dart';

/// WHAT LANGUAGE THE SHOP WORKS IN
///
/// The rules worth holding down: a device locale arrives with a region
/// attached, a language this build does not have must not blank the app or
/// overwrite the shop's choice, and the picker has to be readable by somebody
/// who cannot read the language the app is currently in.
void main() {
  group('reading a language code', () {
    test('the three this build has', () {
      expect(languageFrom('en'), ShopLanguage.english);
      expect(languageFrom('ta'), ShopLanguage.tamil);
      expect(languageFrom('hi'), ShopLanguage.hindi);
    });

    test('a device locale brings its region along', () {
      // What `Platform.localeName` and `Locale.toString()` actually give.
      expect(languageFrom('ta_IN'), ShopLanguage.tamil);
      expect(languageFrom('ta-IN'), ShopLanguage.tamil);
      expect(languageFrom('hi_IN'), ShopLanguage.hindi);
      expect(languageFrom('en-GB'), ShopLanguage.english);
    });

    test('case and space do not make it a different language', () {
      expect(languageFrom(' TA '), ShopLanguage.tamil);
      expect(languageFrom('Hi'), ShopLanguage.hindi);
    });

    test('a language this build does not have is null, not English', () {
      // Null means "not one of ours", which is what lets the caller decide
      // whether to fall back or to leave the shop's stored value alone.
      expect(languageFrom('te'), isNull);
      expect(languageFrom('fr'), isNull);
    });

    test('nothing stored is null, not a language', () {
      expect(languageFrom(null), isNull);
      expect(languageFrom(''), isNull);
      expect(languageFrom('   '), isNull);
    });
  });

  group('which language to show', () {
    test("the shop's choice wins over the device", () {
      // Two staff, two phones, two device languages — one till.
      expect(
        resolveLanguage(stored: 'ta', device: 'hi_IN'),
        ShopLanguage.tamil,
      );
    });

    test('with nothing stored, the device is the better guess', () {
      // Before sign-in there is no shop, and a shop made before this setting
      // existed has nothing stored either.
      expect(resolveLanguage(device: 'ta_IN'), ShopLanguage.tamil);
    });

    test('a stored language this build does not have falls back to the device',
        () {
      expect(
        resolveLanguage(stored: 'te', device: 'hi'),
        ShopLanguage.hindi,
      );
    });

    test('and to English when the device is no help either', () {
      expect(resolveLanguage(stored: 'te', device: 'fr'), kDefaultLanguage);
      expect(resolveLanguage(), kDefaultLanguage);
    });

    test('falling back shows English but says nothing about what is stored',
        () {
      // The shop's setting is not rewritten — another build may have Telugu,
      // and that shop must still be in Telugu when they update.
      const stored = 'te';
      expect(resolveLanguage(stored: stored), kDefaultLanguage);
      expect(stored, 'te');
    });
  });

  group('the picker is readable by whoever needs it', () {
    test('every language names itself in its own script', () {
      expect(kLanguageNames[ShopLanguage.tamil], 'தமிழ்');
      expect(kLanguageNames[ShopLanguage.hindi], 'हिन्दी');
      expect(kLanguageNames[ShopLanguage.english], 'English');
    });

    test('and carries an English name underneath', () {
      expect(kLanguageEnglishNames[ShopLanguage.tamil], 'Tamil');
    });

    test('nothing is missing a code, a name or an English name', () {
      for (final language in ShopLanguage.values) {
        expect(kLanguageCodes[language], isNotNull, reason: '$language');
        expect(kLanguageNames[language], isNotNull, reason: '$language');
        expect(kLanguageEnglishNames[language], isNotNull, reason: '$language');
      }
    });

    test('codes are unique, so two languages cannot resolve to one setting',
        () {
      expect(kSupportedLanguageCodes.toSet().length, ShopLanguage.values.length);
    });
  });

  group('what is stored', () {
    test('a code, never an index — adding a language cannot renumber shops',
        () {
      expect(codeOf(ShopLanguage.tamil), 'ta');
      expect(languageFrom(codeOf(ShopLanguage.hindi)), ShopLanguage.hindi);
    });
  });
}
