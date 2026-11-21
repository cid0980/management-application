---
name: no-apk-builds
description: Don't run `flutter build apk` in this project — the user considers it wasted tokens/time
metadata:
  type: feedback
---

Do not run `flutter build apk` (or other release builds) to verify work in
fm_shop unless the user explicitly asks for an APK.

**Why:** the user said outright "no need to build the apk right now we trust you
so don't waste tolken by building apks". The build is slow and its output is
long, and `flutter analyze` + `flutter test` already catch what matters.

**How to apply:** verify with `flutter analyze` and `flutter test` only. The
Flutter SDK is not on PATH in this session's shell — prefix commands with
`export PATH="$HOME/development/flutter/bin:$PATH"`. See [[graphify-available]]
for the other check they installed.
