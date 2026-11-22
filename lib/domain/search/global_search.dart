/// ONE BOX THAT FINDS ANYTHING
///
/// At the counter the question is rarely "which area is this in". A customer
/// says a name, reads out a number, or holds up a phone; staff should not
/// have to guess whether that is a repair, a bill or a handset first.
///
/// Every area already knows how to match its own rows (`matches` on each
/// model, built on `matchesQuery`), so this asks each of them the same
/// question and puts the answers together:
///
/// - **Nothing typed finds nothing.** An empty box is not "show me all".
/// - **An exact identifier goes first** — a full phone number, IMEI, job or
///   bill number, or label — because someone who typed all fifteen digits
///   knows which phone they mean.
/// - **A few per area**, so one busy area cannot push the rest off the
///   screen; each area says how many more it has.
library;

import '../common/phone.dart';
import '../customers/customer.dart';
import '../enquiries/enquiry.dart';
import '../inventory/second_hand_device.dart';
import '../products/product.dart';
import '../sales/sale.dart';
import '../service/service_order.dart';

enum HitKind { repair, phone, bill, customer, product, enquiry }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    this.exact = false,
  });

  final HitKind kind;
  final String id;
  final String title;
  final String subtitle;

  /// Where tapping it goes: the record itself.
  final String route;

  /// The query was this record's own identifier, typed in full.
  final bool exact;
}

class SearchGroup {
  const SearchGroup(this.kind, this.hits, this.total);

  final HitKind kind;

  /// At most the limit, exact matches first.
  final List<SearchHit> hits;

  /// How many matched in all.
  final int total;

  int get more => total - hits.length;
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

bool _same(String query, Iterable<String?> ids) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return false;
  final qd = _digits(q);
  for (final id in ids) {
    final v = (id ?? '').trim().toLowerCase();
    if (v.isEmpty) continue;
    if (v == q) return true;
    if (qd.length >= 6 && _digits(v) == qd) return true;
  }
  return false;
}

String _join(Iterable<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

/// Searches every area for [query]. Areas with no match are left out; the
/// order is the order of [HitKind].
List<SearchGroup> searchEverything(
  String query, {
  Iterable<ServiceOrder> orders = const [],
  Iterable<SecondHandDevice> devices = const [],
  Iterable<Sale> sales = const [],
  Iterable<Customer> customers = const [],
  Iterable<Product> products = const [],
  Iterable<Enquiry> enquiries = const [],
  int limit = 5,
}) {
  if (query.trim().isEmpty) return const [];

  final groups = <HitKind, List<SearchHit>>{
    HitKind.repair: [
      for (final o in orders)
        if (o.matches(query))
          SearchHit(
            kind: HitKind.repair,
            id: o.id,
            title: o.device.isEmpty ? o.orderNumber : o.device,
            subtitle: _join([o.orderNumber, o.customerName, o.status]),
            route: '/service/${o.id}',
            exact: _same(query, [o.orderNumber, o.imei, o.customerPhone]),
          ),
    ],
    HitKind.phone: [
      for (final d in devices)
        if (d.matches(query))
          SearchHit(
            kind: HitKind.phone,
            id: d.id,
            title: d.title,
            subtitle: _join([
              if (d.imei.isNotEmpty) 'IMEI ${d.imei}',
              if (d.labelNumber != null) '#${d.labelNumber}',
              d.stockState,
            ]),
            route: '/inventory/second-hand/${d.id}',
            exact: _same(query, [
              d.imei,
              d.imei2,
              d.labelNumber?.toString(),
              d.sellerPhone,
            ]),
          ),
    ],
    HitKind.bill: [
      for (final s in sales)
        if (s.matches(query))
          SearchHit(
            kind: HitKind.bill,
            id: s.id,
            title: s.title,
            subtitle: _join([s.customerName, '₹${s.total}']),
            route: '/sales/${s.id}',
            exact: _same(query, [s.invoiceNumber, s.customerPhone]),
          ),
    ],
    HitKind.customer: [
      for (final c in customers)
        if (c.matches(query))
          SearchHit(
            kind: HitKind.customer,
            id: c.id,
            title: c.name.isEmpty ? formatPhone(c.phone) : c.name,
            subtitle: formatPhone(c.phone),
            route: '/customers/${c.id}',
            exact: _same(query, [c.phone, c.altPhone]),
          ),
    ],
    HitKind.product: [
      for (final p in products)
        if (p.matches(query))
          SearchHit(
            kind: HitKind.product,
            id: p.id,
            title: p.title,
            subtitle: '₹${p.sellingPrice}',
            route: '/products/${p.id}',
            exact: _same(query, [p.sku]),
          ),
    ],
    HitKind.enquiry: [
      for (final e in enquiries)
        if (e.matches(query))
          SearchHit(
            kind: HitKind.enquiry,
            id: e.id,
            title: e.headline,
            subtitle: _join([e.customerName, e.status]),
            route: '/enquiries/${e.id}',
            exact: _same(query, [e.customerPhone]),
          ),
    ],
  };

  return [
    for (final kind in HitKind.values)
      if (groups[kind]!.isNotEmpty)
        SearchGroup(
          kind,
          [
            ...groups[kind]!.where((h) => h.exact),
            ...groups[kind]!.where((h) => !h.exact),
          ].take(limit).toList(),
          groups[kind]!.length,
        ),
  ];
}
