#!/usr/bin/env bash
# Connect the phone over wireless debugging by scanning a QR code — the same
# handshake Android Studio's "Pair device with QR code" does, without Studio.
#
#   scripts/adb-wifi.sh          reuse a paired phone if it is already there,
#                                otherwise show a QR code to pair it
#   scripts/adb-wifi.sh --pair   always show the QR code (new phone, or the
#                                phone forgot this computer)
#
# On the phone: Settings > Developer options > Wireless debugging (on) >
# "Pair device with QR code", then scan what this prints. Phone and computer
# must be on the same wifi.
#
# How it works: the QR holds WIFI:T:ADB;S:<name>;P:<password>;; . After the
# scan the phone advertises a pairing service called <name> over mDNS; we wait
# for it, `adb pair` with the password, and adb then connects on its own.
set -euo pipefail

FORCE_PAIR=0
[[ "${1:-}" == "--pair" ]] && FORCE_PAIR=1

SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
if [[ -x "$SDK/platform-tools/adb" ]]; then
  ADB="$SDK/platform-tools/adb"
elif command -v adb >/dev/null; then
  ADB="$(command -v adb)"
else
  echo "adb not found — install platform-tools into $SDK" >&2
  exit 1
fi

wifi_devices() { "$ADB" devices | awk '$2=="device" && $1 ~ /_adb-tls-connect|:[0-9]+$/ {print $1}'; }

"$ADB" start-server >/dev/null

# A phone paired before reconnects by itself once wireless debugging is on.
if [[ $FORCE_PAIR -eq 0 ]]; then
  for _ in 1 2 3 4 5; do
    if [[ -n "$(wifi_devices)" ]]; then
      echo "Already connected:"; wifi_devices | sed 's/^/  /'
      exit 0
    fi
    sleep 1
  done
fi

NAME="fmshop-$(python3 -I -c 'import secrets; print(secrets.token_hex(3))')"
PASS="$(python3 -I -c 'import secrets; print(secrets.token_urlsafe(8).replace("-","x").replace("_","y"))')"
PAYLOAD="WIFI:T:ADB;S:${NAME};P:${PASS};;"

echo
echo "Phone: Developer options > Wireless debugging > Pair device with QR code"
echo
if command -v uv >/dev/null; then
  # invert=True draws dark modules as light blocks, which scans on a dark terminal.
  uv run --quiet --no-project --with 'qrcode==8.*' python3 -I -c \
    'import sys,qrcode; q=qrcode.QRCode(border=2); q.add_data(sys.argv[1]); q.print_ascii(invert=True)' \
    "$PAYLOAD"
elif command -v qrencode >/dev/null; then
  qrencode -t ANSIUTF8 "$PAYLOAD"
else
  echo "Need uv or qrencode to draw the QR code." >&2
  exit 1
fi
echo "Waiting for the phone to scan (2 min)…  Ctrl+C to give up"

# adb mdns services lines look like:  <name>\t_adb-tls-pairing._tcp\t<ip>:<port>
ADDR=""
for _ in $(seq 1 120); do
  ADDR="$("$ADB" mdns services 2>/dev/null | awk -v n="$NAME" '$1==n && $2 ~ /_adb-tls-pairing/ {print $3; exit}')"
  [[ -n "$ADDR" ]] && break
  sleep 1
done
if [[ -z "$ADDR" ]]; then
  echo "The phone never showed up. Same wifi? Some routers block mDNS (client isolation)." >&2
  echo "Fallback: 'Pair device with pairing code' on the phone, then: $ADB pair <ip:port> <code>" >&2
  exit 1
fi

echo "Pairing with $ADDR…"
"$ADB" pair "$ADDR" "$PASS"

# adb auto-connects to a freshly paired phone; nudge it if it does not.
for i in $(seq 1 20); do
  if [[ -n "$(wifi_devices)" ]]; then
    echo "Connected:"; wifi_devices | sed 's/^/  /'
    echo "Now: flutter run"
    exit 0
  fi
  if [[ $i -eq 8 ]]; then
    IP="${ADDR%:*}"
    CONN="$("$ADB" mdns services 2>/dev/null | awk -v ip="$IP" '$2 ~ /_adb-tls-connect/ && index($3, ip":")==1 {print $3; exit}')"
    [[ -n "$CONN" ]] && "$ADB" connect "$CONN" >/dev/null || true
  fi
  sleep 1
done
echo "Paired, but not connected yet. Toggle Wireless debugging off/on, then run this again." >&2
exit 1
