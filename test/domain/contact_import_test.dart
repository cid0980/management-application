import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/contact_import.dart';
import 'package:fm_shop/domain/customers/customer.dart';

void main() {
  group('a pasted list', () {
    test('the words beside a number are the name', () {
      final found = parseContacts('''
Ramesh Kumar, 98765 43210
Priya S	+91 91234-56780
(0)9000011111 Anbu
''');
      expect(found.map((c) => c.phone), [
        '9876543210',
        '9123456780',
        '9000011111',
      ]);
      expect(found.map((c) => c.name), ['Ramesh Kumar', 'Priya S', 'Anbu']);
    });

    test('a line with no mobile number is skipped', () {
      expect(parseContacts('Shop landline 0413 2234567\nhello'), isEmpty);
    });

    test('a number pasted twice is one contact', () {
      expect(parseContacts('A 9876543210\nB +919876543210'), hasLength(1));
    });

    test('no name is kept as no name, not invented', () {
      expect(parseContacts('9876543210').single.name, '');
    });
  });

  group('a phone-book file keeps its names', () {
    test('FN goes with the TEL line under it', () {
      final found = parseContacts('''
BEGIN:VCARD
VERSION:3.0
FN:Kavitha R
TEL;TYPE=CELL:+91 98400 12345
END:VCARD
BEGIN:VCARD
N:Kumar;Mani;;;
TEL:9500012345
END:VCARD
''');
      expect(found.map((c) => c.name), ['Kavitha R', 'Mani Kumar']);
      expect(found.map((c) => c.phone), ['9840012345', '9500012345']);
    });
  });

  test('somebody already on the books is not added again, by number', () {
    final found = parseContacts('Ramesh 98765 43210\nNew one 9123456780');
    final fresh = newContacts(found, const [
      Customer(id: 'c1', name: 'R. Kumar', phone: '+91 98765-43210'),
    ]);
    expect(fresh.map((c) => c.phone), ['9123456780']);
  });
}
