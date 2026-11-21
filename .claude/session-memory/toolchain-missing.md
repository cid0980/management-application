---
name: toolchain-missing
description: Toolchain was wiped and reinstalled 2026-11-21 — Flutter + JDK back; Android SDK packages pending license acceptance; disk is tight
metadata:
  type: project
---

On 2026-11-21 `~/development` and `~/Android` had vanished (graphify too).
Reinstalled the same day: Flutter 3.47.7 (revision abaf9c5, matches .metadata)
at `~/development/flutter`, Temurin 17 at `~/development/jdk`, Android
cmdline-tools at `~/Android/Sdk/cmdline-tools/latest`. PATH exports were
re-added to `~/.bashrc`. Baseline then: `flutter analyze` clean, 1050 tests pass.

Android SDK packages (platform-tools 37.0.3, platforms;android-36,
build-tools;36.0.0) installed with licenses accepted (user approved);
`flutter doctor` Android ✓. Linux desktop ✗: clang/cmake/ninja/pkg-config were
removed too and need `sudo apt install` by the user.

**Extra disk:** `/dev/sda3` (117 GB, ext4, UUID a98c167a…) is mounted at
`/mnt/data` via /etc/fstab (`nofail`), owned by pugal — added 2026-11-21. Plan:
move ~/Android, ~/.gradle and the Flutter SDK there with symlinks back.

Disk `/` is ~95% full (≈5 GB free); `build/` was deleted to make room.

**Network gotcha:** Java cannot connect to `release-assets.githubusercontent.com`
(first DNS address unreachable; curl falls back fine, IPv4 flag doesn't help).
Anything Gradle fetches from GitHub releases — e.g. a new Gradle wrapper
distribution — must be pre-downloaded with `curl -4` into
`~/.gradle/wrapper/dists/<dist>/<hash>/`. Maven/Google repos work from Java.

**Git:** repo initialised 2026-11-21, pushed to
github.com/cid0980/management-application (PUBLIC) on `main`. `gh` 2.105.0 in
`~/.local/bin`, logged in as cid0980 and set as git credential helper.
`.gitignore` keeps `.claude/` (personal notes) and node_modules out.

**Why:** verification is `flutter analyze` + `flutter test` (repo's
`.claude/memory/no-apk-builds.md`); the repo memory lives in
`/home/pugal/Desktop/new_app_plan/.claude/memory/`.

**How to apply:** if `command -v flutter` fails in a non-login shell, prefix
`export PATH="$HOME/development/flutter/bin:$PATH"`. Watch disk space before
anything that fills Gradle/pub caches.
