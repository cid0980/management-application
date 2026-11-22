import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/printing/tspl.dart';

void main() {
  group('a TSPL label', () {
    final program = tsplLabel(
      number: 26001,
      title: 'Samsung Galaxy A54 8/128',
      subtitle: 'Grade A',
      price: 18500,
      copies: 2,
    );
    final lines = program.split('\r\n');

    test('is sized for a 50 × 25 mm sticker at 203 dpi', () {
      expect(lines.first, 'SIZE 50 mm,25 mm');
      expect(lines, contains('GAP 2 mm,0 mm'));
      expect(lines, contains('CLS'));
    });

    test('the barcode is Code 128 of the label number alone', () {
      final barcode = lines.firstWhere((l) => l.startsWith('BARCODE'));
      expect(barcode, contains('"128"'));
      expect(barcode, endsWith('"26001"'));
    });

    test('says what it is and what it costs', () {
      expect(program, contains('"Samsung Galaxy A54 8/128"'));
      expect(program, contains('Grade A - Rs.18,500'));
    });

    test('prints the copies asked for, at least one', () {
      expect(lines, contains('PRINT 1,2'));
      expect(
        tsplLabel(number: 1, title: 'x', copies: 0),
        contains('PRINT 1,1'),
      );
    });

    test('ends every line the way the printer expects', () {
      expect(program, endsWith('\r\n'));
      expect(program.contains('\n') && !program.contains('\r\n\n'), isTrue);
    });

    test('darkness is kept to what the printer accepts', () {
      expect(
        tsplLabel(number: 1, title: 'x', darkness: 40),
        contains('DENSITY 15'),
      );
      expect(
        tsplLabel(number: 1, title: 'x', darkness: -3),
        contains('DENSITY 0'),
      );
    });

    test('other sticker sizes change the page, not the content', () {
      final small = tsplLabel(
        number: 26001,
        title: 'Vivo Y21',
        size: LabelSize.mm38x25,
      );
      expect(small, startsWith('SIZE 38 mm,25 mm'));
      expect(small, contains('"26001"'));
    });
  });

  group('text the printer font can draw', () {
    test('the rupee sign is written Rs.', () {
      expect(tsplText('₹999', maxChars: 30), 'Rs.999');
    });

    test('Tamil and Hindi letters are left out, the rest kept', () {
      expect(tsplText('Vivo Y21 விவோ', maxChars: 30), 'Vivo Y21');
      expect(tsplText('फ़ोन Redmi 13C', maxChars: 30), 'Redmi 13C');
    });

    test('a double quote cannot end the string early', () {
      expect(tsplText('6.5" display', maxChars: 30), "6.5' display");
    });

    test('a long name is cut to the sticker', () {
      final cut = tsplText(
        'Samsung Galaxy S24 Ultra 12/512 Titanium Gray',
        maxChars: 20,
      );
      expect(cut.length, lessThanOrEqualTo(20));
      expect(cut, startsWith('Samsung Galaxy S24'));
    });
  });

  test('a stored size reads back, and an unknown one is 50 × 25', () {
    expect(LabelSize.fromName('mm40x30'), LabelSize.mm40x30);
    expect(LabelSize.fromName('nonsense'), LabelSize.mm50x25);
    expect(LabelSize.fromName(null), LabelSize.mm50x25);
  });
}
