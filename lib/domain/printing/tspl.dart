/// TSPL LABELS
///
/// TSPL is the command language of the cheap 2-inch Bluetooth label printers
/// shops actually buy (Xprinter, Gainscha, HPRT, the unbranded ones). The
/// phone sends a few lines of text and the printer draws the sticker itself —
/// including the barcode, which comes out sharp at the printer's own 203 dots
/// per inch rather than as a scaled picture.
///
/// What goes on the sticker is the same as the PDF label: the product line,
/// a Code 128 barcode of the label number alone (with the number under it),
/// and the details and price. Only the number is in the barcode: anything
/// else and the scanner's length rule — 14 to 16 digits is an IMEI — stops
/// telling the two apart.
///
/// The printer's built-in fonts are ASCII only. Tamil and Hindi letters are
/// left out of the text lines (the model and price are what matters on a
/// sticker), and the rupee sign is written "Rs.".
library;

/// Sticker sizes the app offers, width × height in millimetres.
enum LabelSize {
  mm50x25(50, 25),
  mm40x30(40, 30),
  mm38x25(38, 25);

  const LabelSize(this.widthMm, this.heightMm);

  final int widthMm;
  final int heightMm;

  String get label => '$widthMm × $heightMm mm';

  /// Parsed from storage; the common 50 × 25 when unknown.
  static LabelSize fromName(String? name) => LabelSize.values.firstWhere(
    (s) => s.name == name,
    orElse: () => LabelSize.mm50x25,
  );
}

/// Dots per millimetre at 203 dpi, which is what these printers are.
const int kDotsPerMm = 8;

/// Darkness the printer accepts (TSPL DENSITY).
const int kMinDarkness = 0;
const int kMaxDarkness = 15;
const int kDefaultDarkness = 8;

/// A line of text the printer's built-in font can draw: ASCII only, the
/// rupee sign as "Rs.", quotes made single (a double quote ends a TSPL
/// string), runs of spaces closed up, and cut to [maxChars].
String tsplText(String text, {required int maxChars}) {
  final ascii = text
      .replaceAll('₹', 'Rs.')
      .replaceAll('"', "'")
      .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (maxChars <= 0) return '';
  if (ascii.length <= maxChars) return ascii;
  return ascii.substring(0, maxChars).trimRight();
}

/// The TSPL program for one label, [copies] times.
String tsplLabel({
  required int number,
  required String title,
  String subtitle = '',
  num? price,
  int copies = 1,
  LabelSize size = LabelSize.mm50x25,
  int darkness = kDefaultDarkness,
}) {
  final width = size.widthMm * kDotsPerMm;
  final height = size.heightMm * kDotsPerMm;
  const margin = 12;
  // Font "2" is 12 × 20 dots.
  final chars = (width - margin * 2) ~/ 12;

  const titleY = 8;
  const barcodeY = 34;
  const textLine = 22;
  // The bottom line, and the number the printer writes under the barcode
  // (about 24 dots), share what is left.
  final bottomY = height - textLine - 6;
  final barcodeHeight = (bottomY - barcodeY - 30).clamp(30, 200);

  final bottom = [
    if (subtitle.trim().isNotEmpty) subtitle.trim(),
    if (price != null && price > 0) 'Rs.${_amount(price)}',
  ].join(' - ');

  final lines = <String>[
    'SIZE ${size.widthMm} mm,${size.heightMm} mm',
    'GAP 2 mm,0 mm',
    'DENSITY ${darkness.clamp(kMinDarkness, kMaxDarkness)}',
    'SPEED 4',
    'DIRECTION 1',
    'REFERENCE 0,0',
    'CLS',
    'TEXT $margin,$titleY,"2",0,1,1,"${tsplText(title, maxChars: chars)}"',
    // Code 128, human-readable line under it, narrow bar 2 dots, wide 4.
    'BARCODE $margin,$barcodeY,"128",$barcodeHeight,1,0,2,4,"$number"',
    if (bottom.isNotEmpty)
      'TEXT $margin,$bottomY,"2",0,1,1,"${tsplText(bottom, maxChars: chars)}"',
    'PRINT 1,${copies < 1 ? 1 : copies}',
  ];
  return '${lines.join('\r\n')}\r\n';
}

/// Indian grouping without the symbol: 18500 → "18,500".
String _amount(num value) {
  final whole = value.round().abs().toString();
  if (whole.length <= 3) return whole;
  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}
