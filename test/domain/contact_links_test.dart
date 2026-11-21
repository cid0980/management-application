import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/contact_links.dart';

void main() {
  group('WhatsApp gets the number with its country code and nothing else', () {
    test('however it was typed', () {
      expect(whatsAppNumber('98765 43210'), '919876543210');
      expect(whatsAppNumber('+91 98765-43210'), '919876543210');
      expect(whatsAppNumber('098765 43210'), '919876543210');
    });

    test('not a mobile number, no link', () {
      expect(whatsAppNumber('12345'), isNull);
      expect(whatsAppUri('0413 2234567'), isNull);
      expect(callUri(''), isNull);
    });

    test('the message rides along, encoded', () {
      final uri = whatsAppUri('9876543210', 'Your phone is ready & paid');
      expect(uri.toString(),
          startsWith('https://wa.me/919876543210?text=Your'));
      expect(uri!.queryParameters['text'], 'Your phone is ready & paid');
    });
  });

  test('the dialler gets the clean ten digits', () {
    expect(callUri('+91 98765 43210').toString(), 'tel:9876543210');
  });
}
