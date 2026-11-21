/// THE SHOP'S REPAIR VOCABULARY
///
/// One list of complaint types, shared by the intake form, the job card and
/// the final bill. Shared on purpose: the bill used to be typed again from
/// scratch, so a job taken in as "charging port" went out billed as "charging
/// issue", and the two could never be counted together in Reports.
///
/// As with brands and models, **a complaint typed into the form that is not on
/// the list joins it**, so the next person finds it in the dropdown. That is
/// the settings module's job; this is the default a fresh shop starts with.
library;

const List<String> kComplaintTypes = [
  'Display broken',
  'Display flickering',
  'Touch not working',
  'Battery draining',
  'Not charging',
  'Charging port loose',
  'Dead / no power',
  'Overheating',
  'Speaker not working',
  'Earpiece not working',
  'Microphone not working',
  'Front camera fault',
  'Rear camera fault',
  'Network / signal issue',
  'SIM not detected',
  'Wi-Fi not working',
  'Bluetooth not working',
  'Fingerprint not working',
  'Face unlock not working',
  'Software / hanging',
  'Water damaged',
  'Buttons not working',
  'Vibration not working',
  'Data recovery',
  'Pattern / password unlock',
  'Other',
];

/// How the device was locked when it came in.
///
/// Asked because a phone that cannot be unlocked cannot be tested, and a job
/// handed back untested comes straight back. A pattern is drawn on a 3×3
/// widget rather than typed: `1-2-3-6-9` written down is read back wrong about
/// as often as not.
const List<String> kLockTypes = [
  'None',
  'PIN',
  'Password',
  'Pattern',
  'Fingerprint',
  'Face Unlock',
  'Other',
];

/// What the customer left with the device. Printed on the job card, because
/// what came in is the only answer to "where is my charger".
const List<String> kAccessories = [
  'Charger',
  'Cable',
  'Earphones',
  'Back cover',
  'Screen guard',
  'SIM card',
  'Memory card',
  'Box',
  'Bill / warranty card',
];

/// Whether a drawn pattern is one a person could have drawn.
///
/// Dots are 1–9 on a 3×3 grid, each used at most once, and a pattern of one
/// dot is not a pattern. Stored as the sequence it was drawn in, because the
/// order is the pattern.
bool isValidPattern(List<int> dots) {
  if (dots.length < 2 || dots.length > 9) return false;
  if (dots.any((d) => d < 1 || d > 9)) return false;
  return dots.toSet().length == dots.length;
}

/// The pattern as it is stored and shown: `1-2-3-6-9`.
String formatPattern(List<int> dots) => dots.join('-');

List<int> parsePattern(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return [
    for (final part in raw.split(RegExp(r'[^0-9]+')))
      if (part.isNotEmpty) int.parse(part),
  ];
}
