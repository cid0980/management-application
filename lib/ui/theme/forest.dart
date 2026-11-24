import 'package:flutter/material.dart';

/// FOREST & LIME — the owner's Home design (test_shop_forest_lime.html,
/// 2026-11-25). Used by Home and the floating menu; the other pages keep
/// [AppTheme]'s navy until the owner says otherwise.
///
/// Lime is a background behind dark ink only: as text on white it cannot be
/// read.
abstract final class Forest {
  static const Color canvas = Color(0xFFEFF2EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFE3E8DE);
  static const Color forest950 = Color(0xFF0C1D13);
  static const Color forest900 = Color(0xFF102418);
  static const Color forest800 = Color(0xFF163300);
  static const Color dock = Color(0xFF111A14);
  static const Color lime = Color(0xFF9FE870);
  static const Color amber = Color(0xFFF59E0B);
  static const Color onForest = Color(0xFFF4F7F2);
  static const Color onForestMuted = Color(0xA3F4F7F2);

  static const Color ink900 = Color(0xFF111713);
  static const Color ink600 = Color(0xFF566159);
  static const Color ink400 = Color(0xFF6E7A72);
  static const Color hairline = Color(0x14111713);

  static const Color lateBg = Color(0xFFFEE2E2);
  static const Color lateInk = Color(0xFF991B1B);
  static const Color dueBg = Color(0xFFFEF3C7);
  static const Color dueInk = Color(0xFF92400E);
  static const Color readyBg = Color(0xFFDCFCE7);
  static const Color readyInk = Color(0xFF166534);

  static const Color stepAlert = Color(0xFFDC2626);
  static const Color stepOk = Color(0xFF16A34A);

  /// The other ways money came in, after UPI and cash, on the till bar.
  static const Color otherMethod = Color(0xFF8FB3A0);
}
