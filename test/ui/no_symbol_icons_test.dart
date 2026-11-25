import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The owner's rule: no emoji, and no symbol characters standing in for
/// icons (arrows, stars, ticks) anywhere a person can see — icons are
/// Icon widgets. Comments may use them; strings may not.
void main() {
  test('no emoji or icon-like symbols in on-screen text', () {
    final symbol = RegExp(
      '[\u{1F000}-\u{1FAFF}☀-➿⬀-⯿←-⇿'
      '⌀-⏿■-◿️]',
      unicode: true,
    );
    final offenders = <String>[];
    final files = [
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.arb')),
      ...Directory('android/app/src/main/res')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.xml')),
    ];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final t = lines[i].trimLeft();
        if (t.startsWith('//') || t.startsWith('<!--') || t.startsWith('*')) {
          continue;
        }
        if (symbol.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
