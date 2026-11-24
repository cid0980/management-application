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

  test('the theme is Forest & Lime, with light top bars', () {
    expect(theme.colorScheme.primary, const Color(0xFF102418));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFEFF2EC));
    expect(theme.colorScheme.onSurface, const Color(0xFF111713));
    expect(theme.appBarTheme.backgroundColor, AppTheme.page);
    expect(theme.appBarTheme.foregroundColor, AppTheme.text);
  });

  test("the phone's own font: no custom family is forced", () {
    expect(theme.textTheme.bodyMedium?.fontFamily, isNot('AnekTamil'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('AnekTamil')));
  });

  test('words and buttons are readable (4.5:1)', () {
    expect(contrast(Colors.white, AppTheme.primary), greaterThan(4.5));
    expect(contrast(AppTheme.primary, AppTheme.page), greaterThan(4.5));
    expect(contrast(AppTheme.text, AppTheme.page), greaterThan(4.5));
    expect(contrast(AppTheme.textSecondary, AppTheme.page), greaterThan(4.5));
    expect(
      contrast(AppTheme.textSecondary, AppTheme.surface),
      greaterThan(4.5),
    );
    expect(
      contrast(AppTheme.primary, AppTheme.surfaceSubtle),
      greaterThan(4.5),
    );
    // Lime is a background behind forest ink, never text on white.
    expect(contrast(AppTheme.primary, AppTheme.lime), greaterThan(4.5));
    // Field borders only need to be seen: 3:1.
    expect(contrast(AppTheme.border, AppTheme.surface), greaterThan(3));
  });
}
