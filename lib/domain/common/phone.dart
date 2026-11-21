/// PHONE NUMBERS
///
/// The same customer is in the book three times as `98765 43210`,
/// `+919876543210` and `098765-43210`. Every number is normalized on the way
/// in so the customer autocomplete can actually find the person who was here
/// last month, and the seller of a second-hand device can be matched to the
/// customer record the shop already has.
///
/// Indian numbers: ten digits, optionally carrying a `+91`/`91`/`0` prefix.
/// Anything else is kept as its digits — a foreign number is still a number
/// worth storing, it just will not match the ten-digit shape.
library;

/// Just the digits, with an Indian country or trunk prefix removed.
String normalizePhone(String? raw) {
  if (raw == null) return '';
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Whether this is a number someone can actually be rung on.
///
/// Ten digits starting 6–9, which is every Indian mobile series in use. The
/// shop takes mobile numbers; a landline in this field is a typo.
bool isDiallablePhone(String? raw) {
  final n = normalizePhone(raw);
  return n.length == 10 && RegExp(r'^[6-9]').hasMatch(n);
}

/// Two numbers written differently are the same number.
bool samePhone(String? a, String? b) {
  final x = normalizePhone(a);
  final y = normalizePhone(b);
  return x.isNotEmpty && x == y;
}

/// `98765 43210` — how a number is shown back, once stored clean.
String formatPhone(String? raw) {
  final n = normalizePhone(raw);
  if (n.length != 10) return n;
  return '${n.substring(0, 5)} ${n.substring(5)}';
}
