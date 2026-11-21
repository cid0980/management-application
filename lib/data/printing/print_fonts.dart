import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import 'documents.dart';

/// PRINT FONTS
///
/// Ported from the French Mobiles Flutter port. The PDF library ships
/// Helvetica, which has no rupee sign — every amount on a bill printed as an
/// empty box — so two Noto Sans files are bundled instead.
///
/// Loaded once at start-up: a font that arrives after the first print means
/// the first bill of the day is the one that comes out wrong. A failure does
/// not stop the shop opening; documents fall back to the built-in font.
bool _loaded = false;

Future<void> loadPrintFonts() async {
  if (_loaded) return;
  try {
    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    usePrintFonts(base: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
    _loaded = true;
  } catch (e) {
    debugPrint('Print fonts did not load: $e');
  }
}
