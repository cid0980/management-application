import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/settings/option_set.dart';

void main() {
  group('case and space do not make a new value', () {
    test('one brand, however it was typed', () {
      final set = OptionSet(['Samsung', 'samsung', ' SAMSUNG ']);
      expect(set.values, ['Samsung']);
      expect(set.length, 1);
    });

    test('runs of whitespace collapse', () {
      // A phone keyboard produces both.
      final set = OptionSet(['Screen  Guard', 'screen guard']);
      expect(set.values, ['Screen  Guard']);
      expect(normalizeOption('Screen  Guard'), 'screen guard');
    });

    test('contains ignores case and space', () {
      final set = OptionSet(['Samsung']);
      expect(set.contains('samsung'), isTrue);
      expect(set.contains(' Samsung '), isTrue);
      expect(set.contains('Sams'), isFalse);
      expect(set.contains(''), isFalse);
      expect(set.contains(null), isFalse);
    });
  });

  group('the first spelling to arrive keeps the list casing', () {
    test('a later spelling does not rewrite it', () {
      // Records already written carry the first spelling; rewriting the entry
      // would make the dropdown disagree with the records.
      final set = OptionSet(['samsung']);
      set.add('Samsung');
      expect(set.values, ['samsung']);
    });

    test('canonical gives the list spelling, so a form can write that', () {
      final set = OptionSet(['Samsung']);
      expect(set.canonical('samsung'), 'Samsung');
      expect(set.canonical('nokia'), isNull);
    });
  });

  group('adding', () {
    test('a new value grows the list and says so', () {
      final set = OptionSet(['Samsung']);
      expect(set.add('Nokia'), isTrue);
      expect(set.add('Nokia'), isFalse);
      expect(set.values, ['Samsung', 'Nokia']);
    });

    test('a blank value is never added', () {
      // An empty entry in a dropdown is a trap, and an untouched form must
      // file nothing.
      final set = OptionSet.empty();
      expect(set.add(''), isFalse);
      expect(set.add('   '), isFalse);
      expect(set.add(null), isFalse);
      expect(set.isEmpty, isTrue);
    });

    test('a value is stored trimmed', () {
      final set = OptionSet.empty();
      set.add('  Nokia  ');
      expect(set.values, ['Nokia']);
    });
  });

  group('order is the order values arrived', () {
    test('not alphabetical, because an append is what gives the order', () {
      final set = OptionSet(['Zebra', 'Apple', 'Mango']);
      expect(set.values, ['Zebra', 'Apple', 'Mango']);
    });

    test('sorted is offered separately, and ignores case', () {
      final set = OptionSet(['iPhone', 'Infinix', 'Apple']);
      expect(set.sorted, ['Apple', 'Infinix', 'iPhone']);
      // And does not disturb the stored order.
      expect(set.values, ['iPhone', 'Infinix', 'Apple']);
    });
  });

  group('removing', () {
    test('ignores case, and says whether it was there', () {
      final set = OptionSet(['Samsung', 'Nokia']);
      expect(set.remove('samsung'), isTrue);
      expect(set.values, ['Nokia']);
      expect(set.remove('Samsung'), isFalse);
    });
  });

  group('moving, for a list people work through', () {
    test('an item moves to a position', () {
      final set = OptionSet(['a', 'b', 'c']);
      expect(set.moveTo('c', 0), isTrue);
      expect(set.values, ['c', 'a', 'b']);
    });

    test('an index past the ends is clamped rather than throwing', () {
      final set = OptionSet(['a', 'b', 'c']);
      expect(set.moveTo('a', 99), isTrue);
      expect(set.values, ['b', 'c', 'a']);
      expect(set.moveTo('a', -5), isTrue);
      expect(set.values, ['a', 'b', 'c']);
    });

    test('moving to where it already is changes nothing', () {
      final set = OptionSet(['a', 'b']);
      expect(set.moveTo('a', 0), isFalse);
      expect(set.values, ['a', 'b']);
    });

    test('moving something not on the list changes nothing', () {
      final set = OptionSet(['a']);
      expect(set.moveTo('z', 0), isFalse);
    });
  });

  group('deciding what is new', () {
    test('only what is not already there', () {
      final set = OptionSet(['Samsung', 'Nokia']);
      expect(
        set.additionsFrom(['samsung', 'Infinix', 'NOKIA', 'Lava']),
        ['Infinix', 'Lava'],
      );
    });

    test('deduped against itself too', () {
      // A form that submitted the same colour twice files it once.
      final set = OptionSet.empty();
      expect(set.additionsFrom(['Black', 'black', 'BLACK']), ['Black']);
    });

    test('blanks and nulls are dropped', () {
      expect(OptionSet.empty().additionsFrom(['', '  ', null]), isEmpty);
    });

    test('and nothing is written — this only decides', () {
      final set = OptionSet(['Samsung']);
      set.additionsFrom(['Nokia']);
      expect(set.values, ['Samsung']);
    });
  });

  test('a copy does not share state with its original', () {
    final original = OptionSet(['a']);
    final copy = original.copy();
    copy.add('b');
    expect(original.values, ['a']);
    expect(copy.values, ['a', 'b']);
  });

  group('suggestions narrow as someone types', () {
    final models = OptionSet(['Galaxy A54', 'Galaxy M14', 'Galaxy S23', 'A14']);

    test("an empty field offers the whole list, in the shop's order", () {
      expect(models.suggestionsFor(''),
          ['Galaxy A54', 'Galaxy M14', 'Galaxy S23', 'A14']);
    });

    test('or by name, when asked — storage sizes read best that way', () {
      expect(OptionSet(['8/128', '2/32', '4/64']).suggestionsFor('',
              sortByName: true),
          ['2/32', '4/64', '8/128']);
    });

    test('what starts with the typing comes first, then what contains it', () {
      expect(models.suggestionsFor('a'),
          ['A14', 'Galaxy A54', 'Galaxy M14', 'Galaxy S23']);
      expect(models.suggestionsFor('a5'), ['Galaxy A54']);
    });

    test('case and spacing do not matter', () {
      expect(models.suggestionsFor('GALAXY  m'), ['Galaxy M14']);
    });

    test('a finished value offers nothing more', () {
      expect(models.suggestionsFor('galaxy a54'), isEmpty);
    });

    test('nothing matching offers nothing', () {
      expect(models.suggestionsFor('iphone'), isEmpty);
    });

    test('the list is capped so the chips stay one glance long', () {
      final many = OptionSet([for (var i = 0; i < 30; i++) 'Model $i']);
      expect(many.suggestionsFor('model', limit: 12), hasLength(12));
    });

    test('isNew is only for something typed and not on the list', () {
      expect(models.isNew(''), isFalse);
      expect(models.isNew('galaxy a54'), isFalse);
      expect(models.isNew('Galaxy A55'), isTrue);
    });
  });

  test('numbers in a name sort as numbers', () {
    expect(OptionSet(['12/256', '2/32', '4/128', '4/64']).sorted,
        ['2/32', '4/64', '4/128', '12/256']);
    expect(OptionSet(['iPhone 11', 'iPhone 8', 'Galaxy']).sorted,
        ['Galaxy', 'iPhone 8', 'iPhone 11']);
  });
}
