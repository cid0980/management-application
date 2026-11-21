import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/labels/intake_prefill.dart';

void main() {
  group('a scan travels to the form as query parameters', () {
    test('so the link can be bookmarked or sent on', () {
      expect(
        IntakePrefill.toQuery(
          imei: '354879104523681',
          brand: 'Samsung',
          model: 'Galaxy A54',
        ),
        '?imei=354879104523681&brand=Samsung&model=Galaxy+A54',
      );
    });

    test('a TAC the table does not know sends the IMEI alone', () {
      expect(
        IntakePrefill.toQuery(imei: '999999999999999'),
        '?imei=999999999999999',
      );
    });

    test('nothing to say means no query string at all', () {
      expect(IntakePrefill.toQuery(), '');
      expect(IntakePrefill.toQuery(imei: '', brand: '', model: ''), '');
    });

    test('what is written is what is read back', () {
      final query = IntakePrefill.toQuery(
        imei: '354879104523681',
        brand: 'Xiaomi',
        model: 'Redmi Note 12 Pro+',
      );
      final back = IntakePrefill.fromQuery(
        Uri.parse('/service$query').queryParameters,
      );
      expect(back.imei, '354879104523681');
      expect(back.brand, 'Xiaomi');
      expect(back.model, 'Redmi Note 12 Pro+');
    });
  });

  group('reading a route', () {
    test('an IMEI with spaces reads as digits', () {
      expect(
        IntakePrefill.fromQuery(const {'imei': '354 879 104 523681'}).imei,
        '354879104523681',
      );
    });

    test('a shop label in the IMEI parameter is dropped', () {
      // It would otherwise land in the IMEI field and fail validation there,
      // which reads as the form being broken.
      expect(IntakePrefill.fromQuery(const {'imei': '26001'}).imei, '');
    });

    test('a hand-edited URL opens an empty form rather than an error', () {
      expect(IntakePrefill.fromQuery(const {}).isEmpty, isTrue);
      expect(IntakePrefill.fromQuery(const {'imei': 'nonsense'}).isEmpty,
          isTrue);
      expect(IntakePrefill.fromQuery(const {'unexpected': 'x'}).isEmpty,
          isTrue);
    });

    test('a brand with no IMEI is still a prefill worth having', () {
      final prefill = IntakePrefill.fromQuery(const {'brand': 'Samsung'});
      expect(prefill.isEmpty, isFalse);
      expect(prefill.brand, 'Samsung');
      expect(prefill.imei, '');
    });

    test('whitespace is trimmed', () {
      expect(
        IntakePrefill.fromQuery(const {'brand': '  Samsung  '}).brand,
        'Samsung',
      );
    });
  });
}
