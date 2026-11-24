import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import 'page_slide.dart';

/// THE SHOP'S COLOURS — Design System v5, "Forest & Lime"
///
/// Chosen by the owner on 2026-11-25 from their own design file
/// (test_shop_forest_lime.html), first on Home and then for every page,
/// replacing v4's navy (2026-11-22). Forest green is the brand and the
/// action; lime is only ever a background behind dark ink (as text on
/// white it cannot be read). Top bars are light, like Home's. The aim is the feel
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
  /// Forest: the main button, selection, the search block's scan tile.
  static const Color primary = Color(0xFF102418);

  /// A lighter forest, for the avatar and pressed states.
  static const Color primaryPressed = Color(0xFF1F3A2A);

  /// Lime: the open tab, a selected filter — behind dark ink only.
  static const Color lime = Color(0xFF9FE870);

  /// Kept as forest too: there is one brand colour.
  static const Color secondary = primary;

  /// Every filled control.
  static const Color action = primary;

  // Surfaces
  static const Color page = Color(0xFFEFF2EC);
  static const Color surface = Color(0xFFFFFFFF);

  /// Pale green: what is selected, a pale highlight.
  static const Color surfaceSubtle = Color(0xFFDDEDD0);

  /// Pale sage: small boxes inside a card (Cash / UPI / Card).
  static const Color surfaceCalm = Color(0xFFE3E8DE);

  // Text
  static const Color text = Color(0xFF111713);
  static const Color textSecondary = Color(0xFF566159);

  // Borders
  /// Field and outlined-button borders: visible on white (3:1).
  static const Color border = Color(0xFF8A968D);

  /// Card borders and dividers.
  static const Color borderSubtle = Color(0xFFD8DFD2);

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
      surfaceContainerHighest: const Color(0xFFE3E8DE),
      outline: border,
      outlineVariant: borderSubtle,
      error: danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    // The type scale: body 15–16, helper 13, headings 17–21. Compact enough
    // that a list shows several records at once (the owner asked for it on
    // 2026-11-22), still a size above Material's defaults for arm's length.
    final t = base.textTheme.apply(bodyColor: text, displayColor: text);
    final textTheme = t.copyWith(
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 15),
      bodySmall: t.bodySmall?.copyWith(fontSize: 13, color: textSecondary),
      titleLarge: t.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    const controlRadius = 14.0;
    const cardRadius = 18.0;
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    // Thumb-sized, not mouse-sized — 48 is Android's own touch target —
    // without making every screen a wall of buttons.
    const tall = Size(64, 48);

    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      // Pages slide: in from the right over the page below, out the same way
      // on Back (page_slide.dart). iPhones keep their own sideways slide.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const SlidePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: const SlidePageTransitionsBuilder(),
          TargetPlatform.windows: const SlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: const SlidePageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: page,
      textTheme: textTheme,
      extensions: const [ShopColors.light],
      // The top bar is light, like Home's: the page's own colour, a heavy
      // dark title, dark clock and battery.
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        // Stays flat when a list scrolls under it, so the bar and the search
        // block below it read as one piece.
        scrolledUnderElevation: 0,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: text),
        actionsIconTheme: const IconThemeData(color: text),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          color: text,
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
          horizontal: 14,
          vertical: 13,
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
      // Selected filters are lime, with forest words.
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: lime,
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
    doneSoft: Color(0xFFE3E8DE),
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
