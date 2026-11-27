import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/text_codes.dart';

void main() {
  group('IMEIs in read text', () {
    test('a *#06# screen with two IMEIs', () {
      final got = codesInText('''
IMEI
354879104523682
IMEI 2
354879104523690
IMEI 3
354879104523681
12:41  86%
''');
      expect(got.imeis, ['354879104523682', '354879104523690']);
      // 354879104523681 fails the check digit: a misread, not offered.
    });

    test('spaces, slashes and dashes inside an IMEI are taken out', () {
      expect(codesInText('IMEI: 35 487910 452368 2').imeis, [
        '354879104523682',
      ]);
      expect(codesInText('354879/10/452368/2').imeis, ['354879104523682']);
      expect(codesInText('35-487910-452368-2').imeis, ['354879104523682']);
    });

    test('an O or an l read inside the digits is put right', () {
      expect(codesInText('3548791O4523682').imeis, ['354879104523682']);
      expect(codesInText('354879l04523682').imeis, ['354879104523682']);
    });

    test('a number next to "IMEI" comes before other 15 digits on the box', () {
      final got = codesInText('''
Part no
354879104523690
IMEI
354879104523682
''');
      expect(got.imeis.first, '354879104523682');
    });

    test('numbers that are not IMEIs are left alone', () {
      expect(codesInText('Battery 86%  12:41  +91 98765 43210').imeis, isEmpty);
    });

    test('the same IMEI twice is offered once', () {
      expect(
        codesInText('354879104523682\n354879104523682').imeis,
        hasLength(1),
      );
    });
  });

  group('serials in read text', () {
    test('iPhone About screen: the serial is found', () {
      final got = codesInText('''
Name  Asen's iPhone
Model Name  iPhone 13
Model Number  MLPF3HN/A
Serial Number  F2LX1234ABCD
''');
      expect(got.serials.first, 'F2LX1234ABCD');
    });

    test('a serial on the line after "Serial" comes first', () {
      final got = codesInText('BUILD99ABC1\nSerial No.\nR58M12ABCDE');
      expect(got.serials.first, 'R58M12ABCDE');
      expect(got.serials, contains('BUILD99ABC1'));
    });

    test('plain words and plain numbers are not serials', () {
      final got = codesInText('Settings General About 354879104523682');
      expect(got.serials, isEmpty);
    });
  });
}
