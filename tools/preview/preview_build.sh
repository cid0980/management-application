#!/bin/bash
# Build the real app for web, signed in locally (admin) with the built-in seed
# data, for screenshots. lib/main.dart is restored afterwards.
# Needs web/ once:  flutter create --platforms=web .   (web/ is in .git/info/exclude;
# then revert .metadata + pubspec.lock and delete test/widget_test.dart it makes)
set -e
cd "$(dirname "$0")/../.."
FLUTTER=${FLUTTER:-/opt/flutter/bin/flutter}
BAK=$(mktemp)
cp lib/main.dart "$BAK"
trap 'cp "$BAK" lib/main.dart; rm -f "$BAK"' EXIT
python3 - <<'PY'
import re
p='lib/main.dart'; s=open(p).read()
s=s.replace("seed: const [], settings","settings").replace("(seed: const [])","()").replace("            seed: const [],\n","")
s=re.sub(r"late final _auth = firebaseStartupError == null\n.*?: AuthState\(\);", "late final _auth = (AuthState()..signInLocally(email: 'asen@shop.com', role: Role.admin));", s, flags=re.S)
open(p,'w').write(s)
PY
"$FLUTTER" build web --no-web-resources-cdn 2>&1 | grep -E "error|✓" || true
