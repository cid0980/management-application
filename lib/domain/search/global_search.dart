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
        if (o.matches(query)) repairHit(o, query),
    ],
    HitKind.phone: [
      for (final d in devices)
        if (d.matches(query)) phoneHit(d, query),
    ],
    HitKind.bill: [
      for (final s in sales)
        if (s.matches(query)) billHit(s, query),
    ],
    HitKind.customer: [
      for (final c in customers)
        if (c.matches(query)) customerHit(c, query),
    ],
    HitKind.product: [
      for (final p in products)
        if (p.matches(query)) productHit(p, query),
    ],
    HitKind.enquiry: [
      for (final e in enquiries)
        if (e.matches(query)) enquiryHit(e, query),
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

SearchHit repairHit(ServiceOrder o, [String query = '']) => SearchHit(
  kind: HitKind.repair,
  id: o.id,
  title: o.device.isEmpty ? o.orderNumber : o.device,
  subtitle: _join([o.orderNumber, o.customerName, o.status]),
  route: '/service/${o.id}',
  exact: _same(query, [o.orderNumber, o.imei, o.customerPhone]),
);

SearchHit phoneHit(SecondHandDevice d, [String query = '']) => SearchHit(
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
);

SearchHit billHit(Sale s, [String query = '']) => SearchHit(
  kind: HitKind.bill,
  id: s.id,
  title: s.title,
  subtitle: _join([s.customerName, '₹${s.total}']),
  route: '/sales/${s.id}',
  exact: _same(query, [s.invoiceNumber, s.customerPhone]),
);

SearchHit customerHit(Customer c, [String query = '']) => SearchHit(
  kind: HitKind.customer,
  id: c.id,
  title: c.name.isEmpty ? formatPhone(c.phone) : c.name,
  subtitle: formatPhone(c.phone),
  route: '/customers/${c.id}',
  exact: _same(query, [c.phone, c.altPhone]),
);

SearchHit productHit(Product p, [String query = '']) => SearchHit(
  kind: HitKind.product,
  id: p.id,
  title: p.title,
  subtitle: '₹${p.sellingPrice}',
  route: '/products/${p.id}',
  exact: _same(query, [p.sku]),
);

SearchHit enquiryHit(Enquiry e, [String query = '']) => SearchHit(
  kind: HitKind.enquiry,
  id: e.id,
  title: e.headline,
  subtitle: _join([e.customerName, e.status]),
  route: '/enquiries/${e.id}',
  exact: _same(query, [e.customerPhone]),
);

/// RECENTLY OPENED
///
/// The record pages opened lately, newest first, as search rows — what the
/// Search page shows before anything is typed, so going back to the repair
/// or bill just looked at is one tap. A route whose record is gone (deleted,
/// or older than the phone keeps) is left out.
List<SearchHit> recentHits(
  Iterable<String> routes, {
  Iterable<ServiceOrder> orders = const [],
  Iterable<SecondHandDevice> devices = const [],
  Iterable<Sale> sales = const [],
  Iterable<Customer> customers = const [],
  Iterable<Product> products = const [],
  Iterable<Enquiry> enquiries = const [],
}) {
  T? byId<T>(Iterable<T> all, String id, String Function(T) idOf) {
    for (final x in all) {
      if (idOf(x) == id) return x;
    }
    return null;
  }

  final hits = <SearchHit>[];
  for (final route in routes) {
    final parts = Uri.parse(route).pathSegments;
    if (parts.length < 2) continue;
    final id = parts.last;
    final area = parts.length == 3 ? '${parts[0]}/${parts[1]}' : parts[0];
    final hit = switch (area) {
      'service' => switch (byId(orders, id, (o) => o.id)) {
        final o? => repairHit(o),
        null => null,
      },
      'inventory/second-hand' => switch (byId(devices, id, (d) => d.id)) {
        final d? => phoneHit(d),
        null => null,
      },
      'sales' => switch (byId(sales, id, (s) => s.id)) {
        final s? => billHit(s),
        null => null,
      },
      'customers' => switch (byId(customers, id, (c) => c.id)) {
        final c? => customerHit(c),
        null => null,
      },
      'products' => switch (byId(products, id, (p) => p.id)) {
        final p? => productHit(p),
        null => null,
      },
      'enquiries' => switch (byId(enquiries, id, (e) => e.id)) {
        final e? => enquiryHit(e),
        null => null,
      },
      _ => null,
    };
    if (hit != null) hits.add(hit);
  }
  return hits;
}

/// Whether [path] is one record's page, worth remembering as recent.
bool isRecordPage(String path) => RegExp(
  r'^/(service|sales|customers|products|enquiries|inventory/second-hand)/[^/]+$',
).hasMatch(path);
