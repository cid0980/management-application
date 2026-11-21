/// IMEI, AND TELLING IT APART FROM A SHOP LABEL
///
/// Two kinds of number get scanned at this counter: a factory IMEI printed on
/// the phone, and a shop label the shop printed itself. **Length alone tells
/// them apart** — an IMEI is 14 to 16 digits, a shop label is a counter value
/// starting at 26001, so five digits for years to come. Nothing else is
/// needed, and nothing else is reliable.
///
/// This matters because the scanner used to fail silently on it. Someone in
/// label mode scanned the back of a phone, got "not found", and assumed the
/// label was never printed. The right answer is "that is an IMEI, did you mean
/// to start an intake" — which is why [looksLikeImei] exists separately from
/// any lookup.
///
/// The IMEI is taken off the PHONE, not the box. Boxes get swapped, and a
/// warranty claim against the wrong IMEI is the shop's problem, not the
/// customer's.
library;

/// Just the digits. Scanners interleave spaces and dashes, and staff typing it
/// by hand copy whatever the screen showed them.
String normalizeImei(String? raw) => (raw ?? '').replaceAll(RegExp(r'\D'), '');

/// 14–16 digits: a factory IMEI, never a shop label.
///
/// 15 is the standard. 14 is an IMEI quoted without its check digit, which is
/// how some handsets print it in *#06#. 16 is an IMEISV, with a software
/// version in place of the check digit. All three come through the door.
bool looksLikeImei(String? raw) {
  final n = normalizeImei(raw);
  return n.length >= 14 && n.length <= 16;
}

/// The TAC — the first eight digits, which identify the model.
///
/// This is what the read-only device database is keyed on, so an intake can
/// prefill brand and model from a scan instead of asking someone to pick
/// "Redmi Note 13 Pro+ 5G" out of a dropdown of four hundred.
String? tacOf(String? raw) {
  final n = normalizeImei(raw);
  return n.length >= 8 ? n.substring(0, 8) : null;
}

/// Whether the check digit adds up (Luhn), for a full 15-digit IMEI.
///
/// A WARNING, never a block. A real IMEI passes this, but a 14-digit quote and
/// an IMEISV do not have a check digit to test, and a scanner that drops one
/// character would hand the shop a number that fails Luhn while still being
/// the only record of which phone this is. Refusing the save would mean
/// refusing the purchase, so the form says "check this" and takes it.
bool passesLuhn(String? raw) {
  final n = normalizeImei(raw);
  if (n.length != 15) return false;
  var sum = 0;
  for (var i = 0; i < 15; i++) {
    var d = n.codeUnitAt(14 - i) - 0x30;
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}

/// What a scanned number most likely is, so the scanner can say so.
enum ScannedCode { imei, shopLabel, unknown }

ScannedCode classifyScan(String? raw) {
  final n = normalizeImei(raw);
  if (n.isEmpty) return ScannedCode.unknown;
  if (looksLikeImei(n)) return ScannedCode.imei;
  // A shop label is the counter's own value: all digits, and far shorter than
  // an IMEI. Labels start at 26001 and will not reach fourteen digits.
  if (n.length == (raw ?? '').trim().length && n.length >= 4 && n.length < 14) {
    return ScannedCode.shopLabel;
  }
  return ScannedCode.unknown;
}
