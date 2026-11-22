import 'package:flutter/material.dart';

/// THE SHOP'S COLOURS — Design System v2, "Sage + Rose", rose leading
///
/// Five colours the owner picked on 2026-11-11 from one photograph — dark
/// green, sage, blush grey, pink and dusty rose — replacing v1's blue and
/// teal. Every colour has one job, and keeps it on every screen, because many
/// of the people at the counter read the screen by colour before they read
/// the words:
///
/// - **Rose is structure** — the header, the active tab, what is selected.
/// - **Dark green is the main action and the writing** — the one primary
///   button on a screen, and all text. It is the strongest colour of the
///   five, so it carries what has to be read and what has to be pressed.
/// - **Soft pink and soft sage are calm** — backgrounds behind icons, tips,
///   selected rows. Never text, and never under white text: they are too
///   pale to carry either.
/// - **Blush grey is the page and the thin lines.**
/// - **Meaning colours never change meaning**: green is success / money in,
///   amber is wait / due, red is stop / loss / error, blue is information,
///   grey is finished. Each always comes with a word and, where it helps, an
///   icon. The error red is deliberately much stronger than the rose, and is
///   never used without its icon, so the two are not confused.
///
/// Body text, button labels and the header all meet WCAG's 4.5:1. Rose used
/// as text on the tinted page sits just under it (about 4.4:1), so rose is
/// kept for fills, icons and large titles — small words are dark green.
abstract final class AppTheme {
  // Brand
  /// Rose: the header, the active tab, selection.
  static const Color primary = Color(0xFFA65D64);

  /// A darker rose, for words that sit on soft pink.
  static const Color primaryPressed = Color(0xFF7A3940);

  /// Dark green: the main button, and — as [action] — every filled control.
  static const Color secondary = Color(0xFF2F5550);
  static const Color action = secondary;

  // Surfaces
  static const Color page = Color(0xFFFBF3F2);
  static const Color surface = Color(0xFFFFFFFF);

  /// Soft pink: what is selected.
  static const Color surfaceSubtle = Color(0xFFFBE0DF);

  /// Soft sage: tips and quiet backgrounds.
  static const Color surfaceCalm = Color(0xFFDDE7DE);

  // Text
  static const Color text = Color(0xFF1E3532);
  static const Color textSecondary = Color(0xFF556965);

  // Borders
  static const Color border = Color(0xFF7F8F8B);
  static const Color borderSubtle = Color(0xFFDCD3D3);

  static const Color danger = Color(0xFF991B1B);

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
      surfaceContainerHighest: const Color(0xFFF1E9E8),
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
      // The header is rose: structure, the same on every screen.
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
      // Primary: dark green, white label. One per screen or section.
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
      // Outlined: white, green border and text — secondary and cancel.
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
      // Selected filters are soft pink, with dark rose words.
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
          (s) => s.contains(WidgetState.selected) ? secondary : borderSubtle,
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
    doneSoft: Color(0xFFF1E9E8),
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
