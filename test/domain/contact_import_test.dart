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

  group('a contact file (CSV or VCF)', () {
    test(
      'a Google Contacts CSV: names from the name columns, first mobile',
      () {
        const csv =
            'First Name,Middle Name,Last Name,E-mail 1 - Value,Phone 1 - Label,Phone 1 - Value,Phone 2 - Value\n'
            'Ramesh,,Kumar,ramesh@x.com,Mobile,+91 98765 43210 ::: 044 2345 6789,\n'
            '"Priya, S",,,,Mobile,,091234 56780\n'
            'Electricity,,Office,,Work,044 2345 6789,\n';
        final found = parseContactFile(csv);
        expect(
          [for (final c in found) '${c.name}|${c.phone}'],
          ['Ramesh Kumar|9876543210', 'Priya, S|9123456780'],
        );
      },
    );

    test('a sheet saved as CSV with Name and Mobile columns', () {
      const csv =
          'Name;Mobile\r\nAnand;9443122110\r\nBhavani S;90031 45567\r\n';
      final found = parseContactFile(csv);
      expect(found.map((c) => c.phone), ['9443122110', '9003145567']);
      expect(found.first.name, 'Anand');
    });

    test('a CSV with no header is read like a pasted list', () {
      final found = parseContactFile('Anand,9443122110\nBhavani,9003145567');
      expect(found.map((c) => c.name), ['Anand', 'Bhavani']);
    });

    test('a .vcf file keeps the names', () {
      const vcf =
          '﻿BEGIN:VCARD\nVERSION:3.0\nFN:Kavitha R\nTEL;TYPE=CELL:+919000011111\nEND:VCARD\n';
      final found = parseContactFile(vcf);
      expect(found.single.name, 'Kavitha R');
      expect(found.single.phone, '9000011111');
    });

    test('the same number twice is one contact', () {
      const csv = 'Name,Phone\nA,9443122110\nB,+91 94431 22110\n';
      expect(parseContactFile(csv), hasLength(1));
    });
  });

  group("the phone's own contacts", () {
    test('first mobile per person; landlines and repeats left out', () {
      final found = contactsFromPhoneBook([
        ('Ramesh K', ['044 2345 6789', '+91 98765 43210']),
        ('Shop landline', ['044 2345 6789']),
        ('Ramesh again', ['9876543210']),
        ('Priya', ['91234 56780']),
      ]);
      expect(
        [for (final c in found) '${c.name}|${c.phone}'],
        ['Ramesh K|9876543210', 'Priya|9123456780'],
      );
    });
  });
}
