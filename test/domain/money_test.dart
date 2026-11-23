import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/money.dart';

void main() {
  group('money is grouped the Indian way, not in thousands', () {
    test('lakhs and crores', () {
      expect(formatIndianNumber(125000), '1,25,000');
      expect(formatIndianNumber(12500000), '1,25,00,000');
      expect(formatIndianNumber(999), '999');
      expect(formatIndianNumber(1000), '1,000');
    });

    test('paise, never more than two places', () {
      expect(formatIndianNumber(99.5), '99.5');
      expect(formatIndianNumber(1234.567), '1,234.57');
      expect(formatIndianNumber(10.0), '10');
    });

    test('with the rupee sign', () {
      expect(rupees(9500), '₹9,500');
      expect(rupees(null), '₹0');
      expect(rupees(-200), '-₹200');
    });
  });

  group('the amount in words, for the printed bill', () {
    test('Indian units', () {
      expect(amountInWords(125000),
          'One Lakh Twenty Five Thousand Rupees Only');
      expect(amountInWords(10000000), 'One Crore Rupees Only');
      expect(amountInWords(9999), 'Nine Thousand Nine Hundred Ninety Nine '
          'Rupees Only');
    });

    test('paise are said too', () {
      expect(amountInWords(10.5), 'Ten Rupees and Fifty Paise Only');
      expect(amountInWords(0.25), 'Twenty Five Paise Only');
    });

    test('nothing is still a sentence', () {
      expect(amountInWords(0), 'Zero Rupees Only');
    });
  });
}
