import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The owner's rule (22 Nov 2026): no pop-up lists. A choice is a row you
/// tap or swipe (PickRow, ToggleRow, ChoiceRow), and a menu of actions is a
/// sheet from the bottom (PickSheet). This fails the build if a dropdown or
/// pop-up menu comes back anywhere in the app's screens.
void main() {
  test('no dropdowns or pop-up menus in the app', () {
    const banned = [
      'DropdownButton',
      'DropdownButtonFormField',
      'DropdownMenu',
      'PopupMenuButton',
      'showMenu(',
    ];
    final found = <String>[];
    for (final f in Directory('lib/ui').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        for (final b in banned) {
          if (line.contains(b)) found.add('${f.path}:${i + 1}  $b');
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
