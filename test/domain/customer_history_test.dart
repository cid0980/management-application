import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/customers/customer_history.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/service/service_order.dart';

const _ravi = Customer(
  id: 'c1',
  name: 'Ravi',
  phone: '9876543210',
  altPhone: '9123456780',
);

void main() {
  group("a record belongs to the customer by id OR by number", () {
    test('by id, even with no number on the record', () {
      final h = historyOf(
        _ravi,
        orders: const [ServiceOrder(id: 'o1', customerId: 'c1')],
      );
      expect(h.repairs.map((o) => o.id), ['o1']);
    });

    test('by number, written before the customer was in the book', () {
      final h = historyOf(
        _ravi,
        sales: const [Sale(id: 's1', customerPhone: '+91 98765 43210')],
      );
      expect(h.bills.map((s) => s.id), ['s1']);
    });

    test('by their second number too', () {
      final h = historyOf(
        _ravi,
        enquiries: const [Enquiry(id: 'e1', customerPhone: '9123456780')],
      );
      expect(h.enquiries.map((e) => e.id), ['e1']);
    });

    test("somebody else's records stay out, and a blank number matches "
        'nobody', () {
      final h = historyOf(
        _ravi,
        orders: const [
          ServiceOrder(id: 'o2', customerPhone: '9000000000'),
          ServiceOrder(id: 'o3'),
        ],
      );
      expect(h.repairs, isEmpty);
      expect(h.isEmpty, isTrue);
    });
  });

  test('newest first, so the last visit is on top', () {
    final h = historyOf(
      _ravi,
      orders: [
        ServiceOrder(
          id: 'old',
          customerId: 'c1',
          receivedAt: DateTime(2026, 1, 1),
        ),
        ServiceOrder(
          id: 'new',
          customerId: 'c1',
          receivedAt: DateTime(2026, 11, 1),
        ),
      ],
    );
    expect(h.repairs.map((o) => o.id), ['new', 'old']);
  });
}
