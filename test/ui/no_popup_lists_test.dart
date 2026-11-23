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
      // Owner, 22 Nov: no boxes popping up in the middle of the screen.
      // Questions, messages and dates come up from the bottom
      // (input_sheet.dart, date_sheet.dart).
      'showDialog(',
      'AlertDialog(',
      'showDatePicker(',
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

  test('no wrapped chip "bubbles": choices are one sideways row', () {
    // A Wrap of chips spills onto a second and third line. Choices go in a
    // ChoiceRow / PickRow / ToggleRow (shop_ui.dart), which scroll sideways.
    final chip = RegExp(r'(Choice|Filter|Action|Input)Chip\(');
    final found = <String>[];
    for (final f in Directory('lib/ui').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('shop_ui.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].trim().startsWith('Wrap(') &&
            !lines[i].contains(': Wrap(')) {
          continue;
        }
        final next = lines.skip(i + 1).take(8).join('\n');
        if (chip.hasMatch(next)) found.add('${f.path}:${i + 1}');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
