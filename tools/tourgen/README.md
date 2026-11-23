# Tour text generator

`chapters.py` holds every tour chapter's steps in English, Tamil and Hindi.
`gen.py` (run from the repo root: `python3 tools/tourgen/gen.py`) adds any
missing `tour*` strings to `lib/l10n/app_{en,ta,hi}.arb` and writes the Dart
chapter list to `tools/tourgen/chapters.dart.part`, which was pasted into
`lib/ui/tour/app_tour.dart` (`tourChapters`). Existing keys are never
overwritten — to change a step's text, edit the ARB files directly (and
chapters.py, to keep them in step). Then `flutter gen-l10n`.

Since the first generation, steps were added by hand in app_tour.dart
(money chapter steps 5-7: Expenses) and kept in chapters.py.
