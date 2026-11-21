import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/imei.dart';

void main() {
  test('scanners interleave spaces and dashes', () {
    expect(normalizeImei('354 879-104 523681'), '354879104523681');
    expect(normalizeImei(null), '');
  });

  group('length alone tells an IMEI from a shop label', () {
    test('14 to 16 digits is an IMEI', () {
      expect(looksLikeImei('35487910452368'), isTrue); // 14, no check digit
      expect(looksLikeImei('354879104523681'), isTrue); // 15, standard
      expect(looksLikeImei('3548791045236812'), isTrue); // 16, IMEISV
    });

    test('a shop label is never an IMEI', () {
      expect(looksLikeImei('26001'), isFalse);
      expect(looksLikeImei(''), isFalse);
      expect(looksLikeImei('1234567890123'), isFalse); // 13
      expect(looksLikeImei('35487910452368123'), isFalse); // 17
    });

    test('an IMEI scanned in label mode is recognised, not failed', () {
      expect(classifyScan('354879104523681'), ScannedCode.imei);
      expect(classifyScan('26001'), ScannedCode.shopLabel);
      expect(classifyScan(''), ScannedCode.unknown);
      expect(classifyScan('SKU-ABC-9'), ScannedCode.unknown);
    });
  });

  test('the TAC is the first eight digits', () {
    expect(tacOf('354879104523681'), '35487910');
    expect(tacOf('1234567'), isNull);
  });

  group('the check digit is a warning, not a gate', () {
    test('a valid IMEI passes Luhn', () {
      expect(passesLuhn('490154203237518'), isTrue);
    });

    test('a mis-scan fails it', () {
      expect(passesLuhn('490154203237519'), isFalse);
    });

    test('14 and 16 digit numbers have no check digit to test', () {
      expect(passesLuhn('49015420323751'), isFalse);
      expect(passesLuhn('4901542032375181'), isFalse);
      // ...but they are still IMEIs, which is the point of keeping the two
      // questions apart.
      expect(looksLikeImei('49015420323751'), isTrue);
      expect(looksLikeImei('4901542032375181'), isTrue);
    });
  });
}
