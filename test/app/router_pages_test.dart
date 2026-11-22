import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// go_router 18 gives a route that only has `builder:` a NoTransitionPage
/// in this app (it looks for package:material_ui's MaterialApp and does not
/// find the app's own), so the page appears with no movement. Every route
/// therefore builds its own page (`_page` / `_tab` in router.dart). This
/// fails if a `builder:` route comes back.
void main() {
  test('every route builds a page that slides', () {
    final source = File('lib/app/router.dart').readAsLinesSync();
    final plain = <String>[];
    for (var i = 0; i < source.length; i++) {
      final line = source[i].trim();
      if (!line.startsWith('builder:')) continue;
      // The shell (bottom bar frame) takes a child and is not a page.
      if (line.contains('child)')) continue;
      plain.add('router.dart:${i + 1}  $line');
    }
    expect(plain, isEmpty, reason: plain.join('\n'));
  });
}
