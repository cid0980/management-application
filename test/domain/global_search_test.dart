import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/search/global_search.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/domain/sales/sale.dart';

void main() {
  const ravi = Customer(id: 'c1', name: 'Ravi Kumar', phone: '9876543210');
  const repair = ServiceOrder(
    id: 'o1',
    orderNumber: 'SO-20261122-001',
    customerName: 'Ravi Kumar',
    customerPhone: '9876543210',
    brand: 'Vivo',
    model: 'V27',
    imei: '356789012345678',
  );
  const bill = Sale(
    id: 's1',
    invoiceNumber: 'INV-20261122-004',
    customerName: 'Ravi Kumar',
    customerPhone: '9876543210',
  );

  test('nothing typed finds nothing', () {
    expect(
      searchEverything('  ', customers: [ravi], orders: [repair]),
      isEmpty,
    );
  });

  test('a name finds the person, their repair and their bill', () {
    final groups = searchEverything(
      'ravi',
      customers: [ravi],
      orders: [repair],
      sales: [bill],
    );
    expect(groups.map((g) => g.kind), [
      HitKind.repair,
      HitKind.bill,
      HitKind.customer,
    ]);
    expect(groups.first.hits.single.route, '/service/o1');
  });

  test('an IMEI typed in full is an exact hit', () {
    final g = searchEverything('356789012345678', orders: [repair]).single;
    expect(g.hits.single.exact, isTrue);
  });

  test('exact identifiers come first, and the rest are counted', () {
    final others = [
      for (var i = 0; i < 8; i++)
        ServiceOrder(
          id: 'x$i',
          orderNumber: 'SO-X$i',
          brand: 'Vivo',
          customerPhone: '9000000000',
        ),
    ];
    final g = searchEverything(
      'vivo',
      orders: [...others, repair],
      limit: 3,
    ).single;
    expect(g.total, 9);
    expect(g.hits, hasLength(3));
    expect(g.more, 6);
    final exact = searchEverything(
      '9876543210',
      orders: [...others, repair],
    ).single;
    expect(exact.hits.first.id, 'o1');
  });

  group('recently opened', () {
    test('turns record pages back into rows, newest first', () {
      final hits = recentHits(
        ['/sales/s1', '/customers/c1', '/service/o1'],
        orders: [repair],
        sales: [bill],
        customers: [ravi],
      );
      expect(hits.map((h) => h.kind), [
        HitKind.bill,
        HitKind.customer,
        HitKind.repair,
      ]);
      expect(hits.last.title, 'Vivo V27');
      expect(hits.last.route, '/service/o1');
    });

    test('leaves out records that are gone and pages that are not records', () {
      final hits = recentHits(
        ['/service/gone', '/service', '/settings/shop', '/customers/c1'],
        orders: [repair],
        customers: [ravi],
      );
      expect(hits.single.kind, HitKind.customer);
    });

    test('knows a record page from a list or a form', () {
      expect(isRecordPage('/service/o1'), isTrue);
      expect(isRecordPage('/inventory/second-hand/sh-1'), isTrue);
      expect(isRecordPage('/enquiries/e1'), isTrue);
      expect(isRecordPage('/service'), isFalse);
      expect(isRecordPage('/inventory/second-hand'), isFalse);
      expect(isRecordPage('/settings/shop'), isFalse);
      expect(isRecordPage('/service/o1/edit'), isFalse);
    });
  });
}
