---
name: android-emulator
description: "Running fm_shop on the virtual phone — the AVD name, the PATH exports, and roughly how long a debug run takes"
metadata:
  node_type: memory
  type: reference
  originSessionId: c1bc2847-1ceb-4d2f-8a5e-6263c85382b4
  modified: 2026-10-25T10:46:59.865Z
---

The Mac has an Android AVD called **`flutter_pixel`** (an arm64 Pixel), and
that is how fm_shop is run without a physical phone. On 2026-10-25 a full
`flutter run -d emulator-5554` from cold took about 95 seconds — ~77s for
`assembleDebug`, ~19s to install — and the app reached its Firebase Auth login
screen.

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
flutter emulators --launch flutter_pixel
flutter run -d emulator-5554
```

- Wait for the boot with
  `until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 3; done`.
- `flutter run` belongs in a Terminal panel tab, not Bash — it keeps running
  and the user gets hot reload.
- Check what is on screen with `adb exec-out screencap -p > shot.png` and read
  the image.
- `android/local.properties` is correct for the Mac now
  (`sdk.dir=/Users/pugl/Library/Android/sdk`); the Linux paths in
  [[android-device-setup]] were the old box.

**This does not override [[no-apk-builds]]** — still no `flutter build apk` to
"verify" work. This is for when the user asks to see the app running.
