import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/checklist.dart';

void main() {
  test('labels that read differently never share a key', () {
    final entries = checklistEntries(['Display OK', 'Display: OK!']);
    expect(entries.map((e) => e.key).toSet().length, 2);
    expect(entries[0].key, 'display_ok');
    expect(entries[1].key, 'display_ok_2');
  });

  test('every label is kept exactly as written, in order', () {
    final items = ['Charging port', 'Speaker', 'Charging port'];
    expect(checklistEntries(items).map((e) => e.item).toList(), items);
  });

  test('a label with no letters or digits still gets a key', () {
    expect(checklistKey('!!!'), 'item');
    expect(checklistKey(''), 'item');
  });

  test('a blank checklist is every key false', () {
    expect(blankChecklist(['A', 'B']), {'a': false, 'b': false});
  });

  test('carry over keeps ticks and drops what is gone', () {
    final previous = {'a': true, 'gone': true};
    expect(carryOver(['A', 'B'], previous), {'a': true, 'b': false});
  });

  group('allChecked', () {
    test('asks about the list, not the stored map', () {
      // A leftover tick from a removed item must not carry the vote.
      expect(allChecked(['A', 'B'], {'a': true, 'removed': true}), isFalse);
    });

    test('a key never written counts as unticked', () {
      expect(allChecked(['A'], {}), isFalse);
    });

    test('an empty list passes — a shop with no checklist is not blocked', () {
      expect(allChecked([], {}), isTrue);
    });

    test('all ticked passes', () {
      expect(allChecked(['A', 'B'], {'a': true, 'b': true}), isTrue);
    });
  });
}
