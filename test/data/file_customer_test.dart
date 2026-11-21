import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/domain/customers/customer.dart';

void main() {
  group('everybody served ends up in the book', () {
    test('a new number is filed as a customer, cleaned', () {
      final c = newCustomerFor(
        book: const [],
        name: ' Ravi Kumar ',
        phone: '+91 98765 43210',
        id: 'x',
      );
      expect(c!.name, 'Ravi Kumar');
      expect(c.phone, '9876543210');
    });

    test('a number already in the book is not added twice', () {
      const book = [Customer(id: 'c1', name: 'Ravi', phone: '9876543210')];
      expect(
        newCustomerFor(
          book: book,
          name: 'R. Kumar',
          phone: '98765-43210',
          id: 'x',
        ),
        isNull,
      );
    });

    test("somebody's second number counts as them too", () {
      const book = [
        Customer(id: 'c1', name: 'Ravi', phone: '9000000000',
            altPhone: '9876543210'),
      ];
      expect(
        newCustomerFor(book: book, name: '', phone: '9876543210', id: 'x'),
        isNull,
      );
    });

    test('no usable number, nobody to file', () {
      expect(newCustomerFor(book: const [], name: 'Walk-in', phone: '',
          id: 'x'), isNull);
      expect(newCustomerFor(book: const [], name: 'Walk-in', phone: '12345',
          id: 'x'), isNull);
    });

    test('fileCustomer adds them once, however many times it runs', () async {
      final store = InMemoryCustomerStore(seed: const []);
      await fileCustomer(store, name: 'Ravi', phone: '9876543210');
      await fileCustomer(store, name: 'Ravi K', phone: '9876543210');
      expect(store.customers, hasLength(1));
      expect(store.customers.single.name, 'Ravi');
    });
  });

  test('a customer saved without a date is stamped now, and keeps it', () async {
    final store = InMemoryCustomerStore(seed: const []);
    final saved = await store.save(
      const Customer(id: 'c9', name: 'Suresh', phone: '9988776655'),
    );
    expect(saved.createdAt, isNotNull);
    final edited = await store.save(saved.copyWith(name: 'Suresh K'));
    expect(edited.createdAt, saved.createdAt);
  });
}
