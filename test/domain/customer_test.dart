import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/customer.dart';

Customer _c(
  String id, {
  String name = 'Ramesh K',
  String phone = '9876543210',
  String altPhone = '',
  String email = '',
  DateTime? updatedAt,
}) =>
    Customer(
      id: id,
      name: name,
      phone: phone,
      altPhone: altPhone,
      email: email,
      updatedAt: updatedAt,
    );

void main() {
  group('the number is the identity', () {
    test('the same number written three ways reads as one number', () {
      for (final written in ['98765 43210', '+919876543210', '098765-43210']) {
        expect(Customer.fromMap('a', {'phone': written}).phone, '9876543210');
      }
    });

    test('an existing customer is found by number however it is typed', () {
      final all = [_c('a'), _c('b', phone: '9123456780')];
      expect(findByPhone(all, '+91 98765 43210')!.id, 'a');
      expect(findByPhone(all, '09123456780')!.id, 'b');
      expect(findByPhone(all, '9000000000'), isNull);
      expect(findByPhone(all, ''), isNull);
    });

    test('a second number finds them too', () {
      final all = [_c('a', altPhone: '9000011111')];
      expect(findByPhone(all, '9000011111')!.id, 'a');
    });
  });

  group('a walk-in with no name is still a customer', () {
    test('the record saves', () {
      final result = validateCustomer(_c('a', name: ''));
      expect(result.isValid, isTrue);
    });

    test('and is shown by number rather than as a blank row', () {
      expect(_c('a', name: '').display, '98765 43210');
      expect(_c('a', name: '').initials, '9');
    });
  });

  group('validation', () {
    test('a number is required — it is how the shop finds them', () {
      expect(validateCustomer(_c('a', phone: '')).errors, contains('phone'));
    });

    test('a number that cannot be rung is refused', () {
      expect(
        validateCustomer(_c('a', phone: '12345')).errors,
        contains('phone'),
      );
      // A landline series in a mobile field is a typo.
      expect(
        validateCustomer(_c('a', phone: '1234567890')).errors,
        contains('phone'),
      );
    });

    test('a number already in the book is refused, with who has it', () {
      final existing = [_c('a', name: 'Ramesh K')];
      final result = validateCustomer(
        _c('new', name: 'Ramesh Kumar'),
        existing: existing,
      );
      expect(result.errors['phone'], contains('Already in the book'));
      expect(result.errors['phone'], contains('Ramesh K'));
    });

    test('editing an existing record does not clash with itself', () {
      final existing = [_c('a')];
      final result = validateCustomer(
        _c('a', name: 'Ramesh Kumar'),
        existing: existing,
      );
      expect(result.isValid, isTrue);
    });

    test('the same number in both fields is a slip', () {
      expect(
        validateCustomer(_c('a', altPhone: '9876543210')).errors,
        contains('altPhone'),
      );
    });

    test('a malformed email is refused, a missing one is not', () {
      expect(
        validateCustomer(_c('a', email: 'nope')).errors,
        contains('email'),
      );
      expect(validateCustomer(_c('a', email: '')).isValid, isTrue);
    });
  });

  group('the autocomplete', () {
    final all = [
      _c('a', name: 'Ramesh K', updatedAt: DateTime(2026, 1, 1)),
      _c('b', name: 'Ramesh Kumar', phone: '9123456780',
          updatedAt: DateTime(2026, 6, 1)),
      _c('c', name: 'Priya S', phone: '9988776655',
          updatedAt: DateTime(2026, 3, 1)),
    ];

    test('a number typed in full puts that person first', () {
      // Even though Ramesh Kumar was dealt with more recently.
      expect(suggestCustomers(all, '9876543210').first.id, 'a');
    });

    test('by name, most recently dealt with first', () {
      expect(suggestCustomers(all, 'ramesh').map((c) => c.id), ['b', 'a']);
    });

    test('an empty query is everyone, newest first', () {
      expect(suggestCustomers(all, '').map((c) => c.id), ['b', 'c', 'a']);
    });

    test('the list is capped', () {
      expect(suggestCustomers(all, '', limit: 2), hasLength(2));
    });
  });

  test('a record written here reads back the same', () {
    final c = Customer(
      id: 'a',
      name: 'Ramesh K',
      phone: '9876543210',
      walletBalance: 350,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final back = Customer.fromMap('a', c.toMap());
    expect(back.name, c.name);
    expect(back.phone, c.phone);
    expect(back.walletBalance, 350);
    expect(back.createdAt, c.createdAt);
  });

  test('a balance written as a string reads as a number', () {
    expect(Customer.fromMap('a', {'walletBalance': '350'}).walletBalance, 350);
  });
}
