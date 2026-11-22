import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/theme/app_theme.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final theme = AppTheme.light();

  test('the theme is Soft Periwinkle', () {
    expect(theme.colorScheme.primary, const Color(0xFF5A62D6));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F6FE));
    expect(theme.colorScheme.onSurface, const Color(0xFF1D1F4A));
    expect(theme.appBarTheme.backgroundColor, AppTheme.primary);
  });

  test('every text style uses the bundled Anek Tamil', () {
    final t = theme.textTheme;
    for (final s in [
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.titleLarge,
      t.titleMedium,
      t.labelLarge,
    ]) {
      expect(s?.fontFamily, AppTheme.font);
    }
  });

  test('the font files named in pubspec.yaml are in the repository', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset: (assets/fonts/\S+\.ttf)')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(assets, contains('assets/fonts/AnekTamil-Regular.ttf'));
    expect(assets, contains('assets/fonts/AnekTamilCondensed-Bold.ttf'));
    for (final a in assets) {
      expect(File(a).existsSync(), isTrue, reason: a);
    }
    expect(File('assets/fonts/AnekTamil-OFL.txt').existsSync(), isTrue);
  });

  test('words and buttons are readable (4.5:1)', () {
    expect(contrast(Colors.white, AppTheme.primary), greaterThan(4.5));
    expect(contrast(AppTheme.primary, AppTheme.page), greaterThan(4.5));
    expect(contrast(AppTheme.text, AppTheme.page), greaterThan(4.5));
    expect(contrast(AppTheme.textSecondary, AppTheme.page), greaterThan(4.5));
    expect(
      contrast(AppTheme.textSecondary, AppTheme.surfaceSubtle),
      greaterThan(4.5),
    );
    expect(
      contrast(AppTheme.primaryPressed, AppTheme.surfaceSubtle),
      greaterThan(4.5),
    );
    expect(contrast(AppTheme.onTag, AppTheme.tag), greaterThan(4.5));
    // Field borders only need to be seen: 3:1.
    expect(contrast(AppTheme.border, AppTheme.surface), greaterThan(3));
  });
}
