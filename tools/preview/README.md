# Screenshot preview (web build of the real app)

Used to show the owner screens on the phone-sized viewport (412×892, 2×).

1. Flutter 3.47.9 at /opt/flutter (see `.claude/memory/handoff-2026-11-22.md`).
2. Once per container: `flutter create --platforms=web .`, then
   `git checkout .metadata pubspec.lock && rm test/widget_test.dart`
   (`web/` stays untracked via `.git/info/exclude`).
3. `tools/preview/preview_build.sh` — builds `build/web` signed in as admin with seed data,
   restores `lib/main.dart` after.
4. `cd build/web && python3 -m http.server 8812 &`
5. `node tools/preview/appshots.js /tmp/out /dashboard /inventory/second-hand:600 /service`
   (route, optional `:pixels` to scroll; Playwright is preinstalled).
   `fabshots.js` opens a route, taps the + button, shots the form and its scrolled half.
6. Contact sheet: `COLS=3 python3 tools/preview/sheet.py out.png a.png=Home b.png=Mobiles`
