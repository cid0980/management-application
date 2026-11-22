import 'package:flutter/material.dart';

/// THE SHOP'S COLOURS — Design System v3, "Soft Periwinkle + mint"
///
/// Chosen by the owner on 2026-11-21 from rendered mockups
/// (docs/design/periwinkle/), replacing v2's rose and dark green. The layout
/// follows the quick-commerce apps the shop already knows: a coloured header
/// with search, big tiles, sliding cards. Every colour has one job, and keeps
/// it on every screen, because many of the people at the counter read the
/// screen by colour before they read the words:
///
/// - **Periwinkle is the brand and the action** — the header, the active tab,
///   the main button, what is selected. White on it is 5.1:1, and it reads as
///   text on the page (4.7:1) and on white (5.1:1).
/// - **Ink is the writing** — all text, and the one dark floating button.
/// - **Soft periwinkle tile** is the calm background: photos, selected rows,
///   icon backs. Never under white text.
/// - **Mint is a tag** — "Today", "Offer", a grade — always with dark mint
///   words on it (7:1). Never a button.
/// - **Meaning colours never change meaning**: green is success / money in,
///   amber is wait / due, red is stop / loss / error, blue is information,
///   grey is finished. Each always comes with a word and, where it helps, an
///   icon.
///
/// The font is Anek Tamil, bundled (pubspec.yaml), with a condensed cut
/// ([numbers]) for big amounts.
abstract final class AppTheme {
  /// The app's font family, bundled in assets/fonts.
  static const String font = 'AnekTamil';

  /// The condensed cut, bold and extra-bold only: big amounts and counts.
  static const String numbers = 'AnekTamilCondensed';

  // Brand
  /// Periwinkle: the header, the active tab, selection, the main button.
  static const Color primary = Color(0xFF5A62D6);

  /// A deeper periwinkle, for words that sit on the soft tile.
  static const Color primaryPressed = Color(0xFF3F45B0);

  /// Ink: the dark floating button and strong labels.
  static const Color secondary = Color(0xFF1D1F4A);

  /// Every filled control: periwinkle.
  static const Color action = primary;

  // Surfaces
  static const Color page = Color(0xFFF6F6FE);
  static const Color surface = Color(0xFFFFFFFF);

  /// Soft periwinkle: photo backs, what is selected, icon backs.
  static const Color surfaceSubtle = Color(0xFFE8E9FB);

  /// Soft mint: tips and quiet "all good" backgrounds.
  static const Color surfaceCalm = Color(0xFFDDF7EE);

  /// Mint tag and the words on it.
  static const Color tag = Color(0xFF2DD4A7);
  static const Color onTag = Color(0xFF06372B);

  // Text
  static const Color text = Color(0xFF1D1F4A);
  static const Color textSecondary = Color(0xFF5D6080);

  /// Hints, inactive tabs, struck-out prices: decoration, not reading text.
  static const Color textMuted = Color(0xFF8A8CA8);

  // Borders
  /// Field borders: 4:1 on white, so a box is visible.
  static const Color border = Color(0xFF7A7D9C);
  static const Color borderSubtle = Color(0xFFDDDEF3);

  static const Color danger = Color(0xFF991B1B);

  /// The soft shadow under tiles and cards, tinted with the brand.
  static const List<BoxShadow> tileShadow = [
    BoxShadow(color: Color(0x1A5A62D6), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: surfaceSubtle,
      onPrimaryContainer: primaryPressed,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: surfaceCalm,
      onSecondaryContainer: secondary,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: const Color(0xFFEEEEF9),
      outline: border,
      outlineVariant: borderSubtle,
      error: danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
    );
    // The type scale: body and labels 16, helper 14, section headings 18–20,
    // page titles 24, important numbers 24–32. A size up from Material's
    // defaults — read at arm's length, often in a hurry, sometimes slowly.
    final t = base.textTheme.apply(bodyColor: text, displayColor: text);
    final textTheme = t.copyWith(
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 17),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 16),
      bodySmall: t.bodySmall?.copyWith(fontSize: 14, color: textSecondary),
      titleLarge: t.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    const controlRadius = 12.0;
    const cardRadius = 16.0;
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    // Big targets: a thumb, not a mouse pointer, and often a busy one.
    const tall = Size(64, 52);

    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      scaffoldBackgroundColor: page,
      textTheme: textTheme,
      extensions: const [ShopColors.light],
      // The header is periwinkle: structure, the same on every screen.
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        // A thin border separates sections; shadows everywhere would not.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle),
      inputDecorationTheme: InputDecorationTheme(
        // Help and error lines wrap instead of being cut off mid-word — they
        // are longer in Tamil and Hindi than in English.
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // Field borders stay visible on white.
        border: field(border),
        enabledBorder: field(border),
        focusedBorder: field(action, 2),
        errorBorder: field(danger),
        focusedErrorBorder: field(danger, 2),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: action),
        errorStyle: textTheme.bodySmall?.copyWith(color: danger),
      ),
      // Primary: periwinkle, white label. One per screen or section.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: action,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderSubtle,
          disabledForegroundColor: textSecondary,
          minimumSize: tall,
          shape: control,
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Outlined: white, periwinkle border and text — secondary and cancel.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: action,
          side: const BorderSide(color: action),
          minimumSize: tall,
          shape: control,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: action),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: Colors.white,
        extendedTextStyle: textTheme.labelLarge,
      ),
      // Selected filters are soft periwinkle, with deep periwinkle words.
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: surfaceSubtle,
        side: const BorderSide(color: borderSubtle),
        labelStyle: textTheme.bodyMedium,
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: primaryPressed,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : border,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? action : borderSubtle,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(color: surface),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: page),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// The meaning colours — success, warning, error, information, finished —
/// that Material's scheme has no names for. Read with `context.shopColors`.
///
/// Each strong colour is readable as text on its own soft background (6:1 or
/// better), so a badge is always the soft one with the strong one on top.
@immutable
class ShopColors extends ThemeExtension<ShopColors> {
  const ShopColors({
    required this.good,
    required this.onGood,
    required this.goodSoft,
    required this.wait,
    required this.onWait,
    required this.waitSoft,
    required this.stop,
    required this.stopSoft,
    required this.info,
    required this.infoSoft,
    required this.done,
    required this.doneSoft,
  });

  /// Success: saved, paid, ready to sell, profit.
  final Color good, onGood, goodSoft;

  /// Warning: payment due, on the repair bench, needs a look.
  final Color wait, onWait, waitSoft;

  /// Error and destructive: failed, invalid, a loss, delete.
  final Color stop, stopSoft;

  /// Information: instructions, explanations, notices.
  final Color info, infoSoft;

  /// Finished: sold, closed, nothing left to do.
  final Color done, doneSoft;

  static const light = ShopColors(
    good: Color(0xFF065F46),
    onGood: Colors.white,
    goodSoft: Color(0xFFD1FAE5),
    wait: Color(0xFF92400E),
    onWait: Colors.white,
    waitSoft: Color(0xFFFEF3C7),
    stop: Color(0xFF991B1B),
    stopSoft: Color(0xFFFEE2E2),
    info: Color(0xFF1D4ED8),
    infoSoft: Color(0xFFDBEAFE),
    done: AppTheme.textSecondary,
    doneSoft: Color(0xFFEEEEF9),
  );

  @override
  ShopColors copyWith() => this;

  @override
  ShopColors lerp(ShopColors? other, double t) => other ?? this;
}

extension ShopColorsX on BuildContext {
  /// Falls back to the light set, so a widget pumped alone in a test without
  /// the app's theme still has colours rather than a null.
  ShopColors get shopColors =>
      Theme.of(this).extension<ShopColors>() ?? ShopColors.light;
}
