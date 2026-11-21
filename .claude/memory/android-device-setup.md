---
name: android-device-setup
description: How to reach the user's phone — adb path, wireless pairing, and the debug-key gotcha
metadata:
  type: reference
---

The user's Android phone is a CPH2219 on Android 13, used over **wireless
debugging** on the same wifi.

- `adb` is at `~/Android/Sdk/platform-tools/adb` (on PATH via `~/.bashrc`
  since the 2026-11-21 reinstall).
- **`scripts/adb-wifi.sh`** (added 2026-11-21) is the way to connect: it reuses
  a paired phone if one is already there, otherwise prints a QR code for the
  phone's "Pair device with QR code", waits on mDNS, `adb pair`s and connects.
  `--pair` forces a fresh QR. The user builds on the phone, not Linux desktop.
  "Can't connect to this network" on the phone = QR scanned with the normal
  camera/Wi-Fi scanner instead of the Wireless debugging one. Connected fine
  2026-11-21 as `192.168.0.105:<port>` (CPH2219).
- Once the user turns wireless debugging on, the phone **reconnects on its
  own**: start the adb server (`adb devices` does it) and it is simply there,
  as `adb-fa1d9c7a-svUobY._adb-tls-connect._tcp`. Confirmed 2026-10-26 — no
  pairing code, no `adb connect`. Only pair again if it does not appear:
  `adb mdns services` finds the port, and the 6-digit code has to come from
  them.
- Installing over wifi is slow but fine: ~25s to build, ~64s to install.
- Builds need `export PATH="$HOME/development/flutter/bin:$PATH"`.

**Two gotchas that cost time on 2026-10-24:**

1. The backup carries `build/` and `.dart_tool/` from a Linux machine with
   `/home/cid/...` baked in. Any build fails until `flutter clean`.
2. An APK built on a different machine cannot replace one already installed —
   different debug keys, `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. The old app has
   to be uninstalled, which needs the user's approval. A shared debug keystore
   committed to `android/` would fix it permanently. **Not an issue while
   building on this Mac** — the 2026-10-26 install replaced the previous one
   cleanly.

**How to apply:** verify installs with `adb exec-out screencap -p` and read the
image — it is the only honest check that the app actually runs. See
[[no-apk-builds]] for when not to build at all.
