/// THE READ-ONLY DEVICE DATABASE
///
/// An IMEI's first eight digits are its **TAC** — the Type Allocation Code,
/// which identifies the model. Scanning the back of a phone therefore tells
/// you what the phone is, and an intake can prefill brand and model instead of
/// asking someone to find "Redmi Note 13 Pro+ 5G" in a dropdown of four
/// hundred.
///
/// Read-only, and treated as a hint rather than an answer. Two things make it
/// wrong sometimes: the table is never complete, and a refurbished or
/// grey-market handset can carry a TAC that does not match what is in the
/// hand. So a lookup **prefills, and the form stays editable** — it never
/// replaces what somebody typed, and never blocks a save.
library;

class TacEntry {
  const TacEntry({
    required this.tac,
    required this.brand,
    required this.model,
    this.variant = '',
  });

  final String tac;
  final String brand;
  final String model;
  final String variant;

  String get device =>
      [brand, model, variant].where((p) => p.isNotEmpty).join(' ');
}

/// What a TAC lookup can tell an intake form.
abstract class TacRegistry {
  /// The device for this TAC, or null when the table does not have it.
  ///
  /// Null is the ordinary case, not an error: the table is a convenience and
  /// most of the shop's stock is not in it.
  TacEntry? lookup(String? tacOrImei);
}

/// The TACs the shop sees most. Stands in for the `tac_registry` collection
/// until it is loaded from Firestore; the real table is thousands of rows.
const List<TacEntry> kSeedTacTable = [
  TacEntry(tac: '35487910', brand: 'Samsung', model: 'Galaxy A54'),
  TacEntry(tac: '35291911', brand: 'Samsung', model: 'Galaxy M14'),
  TacEntry(tac: '86123450', brand: 'Xiaomi', model: 'Redmi Note 12'),
  TacEntry(tac: '86774105', brand: 'Xiaomi', model: 'Redmi 13C'),
  TacEntry(tac: '35301210', brand: 'Apple', model: 'iPhone 11'),
  TacEntry(tac: '35692711', brand: 'Apple', model: 'iPhone 12'),
  TacEntry(tac: '86891104', brand: 'Vivo', model: 'T2x'),
  TacEntry(tac: '86045604', brand: 'Oppo', model: 'A78'),
  TacEntry(tac: '35847411', brand: 'OnePlus', model: 'Nord CE 3'),
  TacEntry(tac: '86622105', brand: 'Realme', model: 'Narzo 60'),
];

class SeedTacRegistry implements TacRegistry {
  SeedTacRegistry([List<TacEntry> table = kSeedTacTable])
    : _byTac = {for (final e in table) e.tac: e};

  final Map<String, TacEntry> _byTac;

  @override
  TacEntry? lookup(String? tacOrImei) {
    // Takes a full IMEI or a bare TAC: the caller has whatever the scanner
    // gave it, and making it slice the string first is how a lookup gets done
    // against fifteen digits and silently finds nothing.
    final digits = (tacOrImei ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    return _byTac[digits.substring(0, 8)];
  }
}
