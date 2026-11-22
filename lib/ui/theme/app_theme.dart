import 'package:flutter/material.dart';

/// THE SHOP'S COLOURS — Design System v4, "Navy"
///
/// Chosen by the owner on 2026-11-22 from a Flutter mockup, replacing the
/// periwinkle try-out (v3) and v2's rose and dark green. The aim is the feel
/// of an ordinary Android app: Material's own parts, the phone's own font
/// (Roboto, and the phone's Noto for Tamil and Hindi), big text, one column.
/// Every colour has one job, and keeps it on every screen, because many of
/// the people at the counter read the screen by colour before the words:
///
/// - **Navy is the brand and the action** — the top bar, the main button,
///   what is selected. White on it is about 16:1.
/// - **White cards on a grey page**, with a thin border instead of shadows.
/// - **Meaning colours never change meaning**: green is success / paid /
///   ready, amber is wait / due, red is stop / late / error, blue is
///   information, grey is finished. Each always comes with a word and, where
///   it helps, an icon.
abstract final class AppTheme {
  // Brand
  /// Navy: the top bar, the main button, selection.
  static const Color primary = Color(0xFF0C1A3D);

  /// A lighter navy, for the avatar and pressed states on the bar.
  static const Color primaryPressed = Color(0xFF2A3A63);

  /// Kept as navy too: there is one brand colour.
  static const Color secondary = primary;

  /// Every filled control.
  static const Color action = primary;

  // Surfaces
  static const Color page = Color(0xFFF1F3F7);
  static const Color surface = Color(0xFFFFFFFF);

  /// Pale navy: what is selected, the active tab's pill.
  static const Color surfaceSubtle = Color(0xFFDCE3F5);

  /// Pale grey: small boxes inside a card (Cash / UPI / Card).
  static const Color surfaceCalm = Color(0xFFF1F3F7);

  // Text
  static const Color text = Color(0xFF151B28);
  static const Color textSecondary = Color(0xFF5B6475);

  // Borders
  /// Field and outlined-button borders: visible on white (3:1).
  static const Color border = Color(0xFF8A93A6);

  /// Card borders and dividers.
  static const Color borderSubtle = Color(0xFFD9DEE7);

  static const Color danger = Color(0xFFC62828);

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
      surfaceContainerHighest: const Color(0xFFE9ECF2),
      outline: border,
      outlineVariant: borderSubtle,
      error: danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
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
      // The top bar is navy: structure, the same on every screen.
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        // Stays navy when a list scrolls under it, so the bar and the search
        // block below it read as one piece.
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
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
      // Primary: navy, white label. One per screen or section.
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
      // Outlined: white, navy text, grey border — secondary and cancel.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: action,
          side: const BorderSide(color: border),
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
      // Selected filters are pale navy, with navy words.
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
      // Material's own bottom bar: the selected tab sits on a pale-navy pill.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: surfaceSubtle,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? primary : textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 13,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? primary : textSecondary,
          ),
        ),
      ),
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
    doneSoft: Color(0xFFE9ECF2),
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
