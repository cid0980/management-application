import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/settings/model_choices.dart';
import 'package:fm_shop/domain/settings/option_set.dart';

void main() {
  group('the models offered for a brand', () {
    test('nothing before a brand is chosen', () {
      expect(modelChoices(OptionSet(['A54']), '  ', const []), isEmpty);
    });

    test('a brand with no list still offers what its records carry', () {
      // Redmi had no built-in models: the row was empty for it.
      final got = modelChoices(OptionSet.empty(), 'Redmi', const [
        ('Redmi', 'Note 13'),
        ('redmi ', 'note 13'),
        ('Redmi', '13C'),
        ('Samsung', 'Galaxy A54'),
        ('Redmi', '  '),
      ]);
      expect(got, ['Note 13', '13C']);
    });

    test('most used first, then the list by name', () {
      final got = modelChoices(
        OptionSet(['Galaxy S23', 'Galaxy A14', 'Galaxy M14']),
        'samsung',
        const [
          ('Samsung', 'Galaxy M14'),
          ('Samsung', 'Galaxy M14'),
          ('Samsung', 'Galaxy A35'),
        ],
      );
      expect(got, ['Galaxy M14', 'Galaxy A35', 'Galaxy A14', 'Galaxy S23']);
    });

    test("the list's spelling wins over a record's", () {
      final got = modelChoices(OptionSet(['iPhone 13']), 'Apple', const [
        ('Apple', 'IPHONE 13'),
      ]);
      expect(got, ['iPhone 13']);
    });
  });
}
