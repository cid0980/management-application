---
name: languages
description: fm_shop is multi-language — English, Tamil, Hindi — and the language belongs to the shop, not the phone
metadata:
  type: project
---

fm_shop is sold across states, so the UI is translated. English, Tamil and
Hindi as of 2026-10-26; more are an enum entry plus an `.arb` file.

- Strings live in `lib/l10n/app_{en,ta,hi}.arb`, built by `flutter gen-l10n`
  (run it after editing an `.arb`). `context.l10n` comes from
  `lib/l10n/l10n.dart` and falls back to English when no delegate is above the
  widget, which is what keeps widget tests working untouched.
- The language is **the shop's**, stored as a code in its settings document —
  not the device's. Picked at the end of shop setup, changed on the settings
  page, applied without a restart.
- `lib/domain/settings/languages.dart` owns the resolution rule: stored wins,
  then the device, then English. A stored language this build lacks is NOT
  rewritten.

**Why:** two staff on two phones with two device languages work one till. And
a shop that picks a language in a later build must not be downgraded by an
older one.

**How to apply:** never translate stored data — brands, models and colours are
the shop's own words, and statuses like `Completed` are rule keys that
`canComplete` and `firestore.rules` compare against. Only display labels get
translated, and `lib/l10n/display_labels.dart` is the single place that turns
a stored key into words (falling back to the stored value). Every screen is
translated as of 2026-10-26 — 562 keys — and `test/ui/language_test.dart`
fails if Tamil or Hindi is missing a key or still holds the English string. See [[fm-shop-architecture]].
