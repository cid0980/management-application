import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/serial.dart';

void main() {
  group('a serial off a barcode', () {
    test('letters and digits are taken, trimmed and upper-cased', () {
      expect(serialFromBarcode(' r58m12abcde '), 'R58M12ABCDE');
    });

    test('an IMEI or a shop barcode is not a serial', () {
      expect(serialFromBarcode('354879104523681'), isNull);
      expect(serialFromBarcode('8901234567890'), isNull);
    });

    test('a part number with a slash is not a serial', () {
      expect(serialFromBarcode('MPXT3HN/A'), isNull);
    });

    test('too short or too long is not a serial', () {
      expect(serialFromBarcode('AB12'), isNull);
      expect(serialFromBarcode('ABCDEFG123456789'), isNull);
    });

    test("Apple's S marker is dropped, for Apple only", () {
      expect(serialFromBarcode('SF2LX1234ABCD', apple: true), 'F2LX1234ABCD');
      expect(serialFromBarcode('SK7Q2XYZ9AB', apple: true), 'K7Q2XYZ9AB');
      // A 12- or 10-long code is already the serial.
      expect(serialFromBarcode('SF2LX1234ABC', apple: true), 'SF2LX1234ABC');
      // Not Apple: left as it is.
      expect(serialFromBarcode('SF2LX1234ABCD'), 'SF2LX1234ABCD');
    });
  });
}
