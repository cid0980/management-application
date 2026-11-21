/// EVERYTHING ONE CUSTOMER HAS DONE WITH THE SHOP
///
/// FLOW §7: the customer page carries history across all areas. A record
/// belongs to a customer when it points at them by id, **or** carries their
/// number — the number is the identity (see `customer.dart`), and most older
/// records were written before a customer was picked from the book, so an
/// id-only match would show a regular customer with no history at all.
///
/// Newest first within each area, because "what did they last bring in" is
/// the question at the counter.
library;

import '../common/phone.dart';
import '../enquiries/enquiry.dart';
import '../sales/sale.dart';
import '../service/service_order.dart';
import 'customer.dart';

class CustomerHistory {
  const CustomerHistory({
    required this.repairs,
    required this.bills,
    required this.enquiries,
  });

  final List<ServiceOrder> repairs;
  final List<Sale> bills;
  final List<Enquiry> enquiries;

  bool get isEmpty => repairs.isEmpty && bills.isEmpty && enquiries.isEmpty;
}

bool _belongs(Customer c, String? id, String? phone) =>
    (id != null && id.isNotEmpty && id == c.id) ||
    samePhone(phone, c.phone) ||
    (c.altPhone.isNotEmpty && samePhone(phone, c.altPhone));

int _newestFirst(DateTime? a, DateTime? b) =>
    (b ?? DateTime(0)).compareTo(a ?? DateTime(0));

CustomerHistory historyOf(
  Customer customer, {
  Iterable<ServiceOrder> orders = const [],
  Iterable<Sale> sales = const [],
  Iterable<Enquiry> enquiries = const [],
}) => CustomerHistory(
  repairs:
      orders
          .where((o) => _belongs(customer, o.customerId, o.customerPhone))
          .toList()
        ..sort(
          (a, b) => _newestFirst(
            a.receivedAt ?? a.createdAt,
            b.receivedAt ?? b.createdAt,
          ),
        ),
  bills:
      sales
          .where((s) => _belongs(customer, s.customerId, s.customerPhone))
          .toList()
        ..sort(
          (a, b) => _newestFirst(
            a.completedAt ?? a.createdAt,
            b.completedAt ?? b.createdAt,
          ),
        ),
  enquiries:
      enquiries
          .where((e) => _belongs(customer, e.customerId, e.customerPhone))
          .toList()
        ..sort(
          (a, b) =>
              _newestFirst(a.askedAt ?? a.createdAt, b.askedAt ?? b.createdAt),
        ),
);
