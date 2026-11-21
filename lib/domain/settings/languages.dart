/// WHAT LANGUAGE THE SHOP WORKS IN
///
/// The app is sold across states. A shop in Madurai works in Tamil, one in
/// Jaipur in Hindi, and plenty of counters switch between a language and
/// English mid-sentence. So the language is the shop's own setting, picked
/// when the shop is created and changed on the settings page afterwards.
///
/// **Each language is named in its own script.** The picker says `தமிழ்`, not
/// "Tamil", because somebody changing the language is usually somebody who
/// cannot read the language the app is currently in. A list of English names
/// is no use to them.
///
/// **A language this build does not have falls back to English, and the
/// shop's choice is left alone.** Another build may add Telugu; opening this
/// one must not quietly rewrite that shop's setting to English and leave the
/// Telugu shop in English next time they update. So the stored value is kept
/// as it is, and only what is *shown* falls back.
///
/// **Nothing the shop typed is translated, and neither is anything a rule
/// reads.** Brands, models, colours and suppliers are the shop's own
/// vocabulary — translating "Awesome Violet" would be inventing words nobody
/// used. Service statuses like `Completed` are rule keys: `canComplete` and
/// the rules file both compare against the stored English string, so they are
/// stored in English and only ever *displayed* through a label lookup.
library;

/// The languages this build has.
///
/// Adding one is this enum, its code, its own-script name, and an `.arb` file.
enum ShopLanguage { english, tamil, hindi }

/// The IETF code each one is stored and resolved by.
const Map<ShopLanguage, String> kLanguageCodes = {
  ShopLanguage.english: 'en',
  ShopLanguage.tamil: 'ta',
  ShopLanguage.hindi: 'hi',
};

/// Each language in its own script. See the library note.
const Map<ShopLanguage, String> kLanguageNames = {
  ShopLanguage.english: 'English',
  ShopLanguage.tamil: 'தமிழ்',
  ShopLanguage.hindi: 'हिन्दी',
};

/// What the picker says underneath, in English, so an owner setting up a shop
/// for staff who read another script can still tell which is which.
const Map<ShopLanguage, String> kLanguageEnglishNames = {
  ShopLanguage.english: 'English',
  ShopLanguage.tamil: 'Tamil',
  ShopLanguage.hindi: 'Hindi',
};

/// English until a shop says otherwise. Not a judgement about the shop: it is
/// the one language every supplier invoice, IMEI sticker and Firebase error in
/// this app is already in.
const ShopLanguage kDefaultLanguage = ShopLanguage.english;

List<String> get kSupportedLanguageCodes => [
  for (final l in ShopLanguage.values) kLanguageCodes[l]!,
];

/// The language [code] names, or null when this build does not have it.
///
/// Accepts what a device locale actually looks like: `ta`, `ta_IN`, `ta-IN`,
/// `TA`. A phone set to Tamil (India) must not read as "no language".
ShopLanguage? languageFrom(Object? code) {
  final raw = (code ?? '').toString().trim();
  if (raw.isEmpty) return null;
  final base = raw.replaceAll('_', '-').split('-').first.toLowerCase();
  for (final language in ShopLanguage.values) {
    if (kLanguageCodes[language] == base) return language;
  }
  return null;
}

/// Which language to show, given what the shop stored and what the device is
/// set to.
///
/// The shop's choice wins — two staff on two phones set to two languages must
/// see the same till. With nothing stored (a shop made before this setting
/// existed, or before sign-in when there is no shop at all) the device's own
/// language is the better guess than English. Neither being known, or neither
/// being one this build has, falls back to English.
ShopLanguage resolveLanguage({Object? stored, Object? device}) =>
    languageFrom(stored) ?? languageFrom(device) ?? kDefaultLanguage;

/// The code to store for [language]. Stored as a code rather than an index, so
/// adding a language later cannot renumber what shops already chose.
String codeOf(ShopLanguage language) => kLanguageCodes[language]!;
