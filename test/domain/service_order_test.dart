import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/order_state.dart';
import 'package:fm_shop/domain/service/service_order.dart';

final _now = DateTime(2026, 3, 4, 12);

ServiceOrder _o({
  String status = 'In Progress',
  DateTime? expected,
  num estimate = 2000,
  num raw = 0,
  num labour = 0,
  num? finalPrice,
}) => ServiceOrder(
  id: 'o',
  brand: 'Samsung',
  model: 'Galaxy M14',
  status: status,
  estimatedPrice: estimate,
  rawMaterialCost: raw,
  outsideLabourCost: labour,
  finalPrice: finalPrice,
  receivedAt: DateTime(2026, 3, 1),
  expectedCompletionAt: expected,
);

void main() {
  group('derived state, not the raw status', () {
    test('promised and the time has passed is overdue', () {
      expect(
        _o(expected: DateTime(2026, 3, 2)).lifecycleAt(_now),
        OrderLifecycle.overdue,
      );
    });

    test('still time left is open', () {
      expect(
        _o(expected: DateTime(2026, 3, 6)).lifecycleAt(_now),
        OrderLifecycle.open,
      );
    });

    test(
      'closed beats overdue — a job finished last month is not an alarm',
      () {
        final finished = _o(
          status: 'Completed',
          expected: DateTime(2026, 1, 1),
        );
        expect(finished.lifecycleAt(_now), OrderLifecycle.closed);
        expect(finished.isOverdueAt(_now), isFalse);
        expect(finished.closed, isTrue);
      },
    );

    test('returned is closed too', () {
      expect(_o(status: 'Returned').closed, isTrue);
    });

    test('a status this build has never seen is still open, not dropped', () {
      final unknown = _o(
        status: 'Waiting For Spare',
        expected: DateTime(2026, 3, 6),
      );
      expect(unknown.closed, isFalse);
      expect(unknown.lifecycleAt(_now), OrderLifecycle.open);
      // And it keeps saying what it actually says.
      expect(unknown.status, 'Waiting For Spare');
    });

    test('due today is the promised day, not the promised instant', () {
      expect(_o(expected: DateTime(2026, 3, 4, 1)).isDueTodayAt(_now), isTrue);
      expect(
        _o(expected: DateTime(2026, 3, 4, 23, 59)).isDueTodayAt(_now),
        isTrue,
      );
      expect(_o(expected: DateTime(2026, 3, 5)).isDueTodayAt(_now), isFalse);
    });
  });

  group('money', () {
    test('costs are the materials plus the outside labour', () {
      expect(_o(raw: 650, labour: 300).costs, 950);
    });

    test('profit at the estimate is what the counter quotes against', () {
      expect(_o(estimate: 2000, raw: 650, labour: 300).estimatedProfit, 1050);
    });

    test('an open job has made nothing — null, not zero', () {
      expect(_o(raw: 650).realisedProfit, isNull);
    });

    test('what it made comes off what was charged', () {
      expect(_o(raw: 650, finalPrice: 1800).realisedProfit, 1150);
    });

    test('a goodwill repair at zero is a realised loss, not an open job', () {
      expect(_o(raw: 650, finalPrice: 0).realisedProfit, -650);
    });

    test('quoted at or below cost is flagged, not refused', () {
      expect(_o(estimate: 900, raw: 950).quotedAtALoss, isTrue);
      expect(
        _o(estimate: 0, raw: 950).quotedAtALoss,
        isFalse,
        reason: 'no quote given is a different thing from a bad quote',
      );
    });
  });

  group('every read normalizes', () {
    test(
      'an ISO date and a Timestamp-shaped object both read as a DateTime',
      () {
        expect(
          ServiceOrder.fromMap('o', {
            'receivedAt': '2026-03-04T10:00:00.000Z',
          }).receivedAt,
          DateTime.utc(2026, 3, 4, 10),
        );
        expect(
          ServiceOrder.fromMap('o', {
            'receivedAt': _FakeTimestamp(DateTime.utc(2026, 3, 4, 10)),
          }).receivedAt,
          DateTime.utc(2026, 3, 4, 10),
        );
      },
    );

    test('an amount written as a string reads as a number', () {
      expect(
        ServiceOrder.fromMap('o', {'estimatedPrice': '1,400'}).estimatedPrice,
        1400,
      );
    });

    test('a number written with +91 reads as ten digits', () {
      expect(
        ServiceOrder.fromMap('o', {
          'customerPhone': '+91 90000 11111',
        }).customerPhone,
        '9000011111',
      );
    });

    test('an IMEI with spaces reads as digits', () {
      expect(
        ServiceOrder.fromMap('o', {'imei': '354 879 104 523681'}).imei,
        '354879104523681',
      );
    });

    test('a missing status reads as Received, not as empty', () {
      expect(ServiceOrder.fromMap('o', const {}).status, 'Received');
      expect(ServiceOrder.fromMap('o', const {}).lockType, 'None');
    });

    test('a charge of zero is kept apart from no charge at all', () {
      expect(ServiceOrder.fromMap('o', {'finalPrice': 0}).finalPrice, 0);
      expect(ServiceOrder.fromMap('o', const {}).finalPrice, isNull);
    });

    test('blank complaints are dropped rather than stored as empty lines', () {
      expect(
        ServiceOrder.fromMap('o', {
          'complaints': ['Not charging', '', '  ', null],
        }).complaints,
        ['Not charging'],
      );
    });

    test('an empty document does not throw', () {
      final o = ServiceOrder.fromMap('o', const {});
      expect(o.complaints, isEmpty);
      expect(o.checklist, isEmpty);
      expect(o.estimatedPrice, 0);
    });

    test('a record written here reads back the same', () {
      final o = ServiceOrder(
        id: 'o',
        orderNumber: 'SO-20260304-007',
        brand: 'Samsung',
        model: 'Galaxy M14',
        complaints: const ['Not charging'],
        checklist: const {'display_ok': true},
        receivedAt: DateTime.utc(2026, 3, 1),
        expectedCompletionAt: DateTime.utc(2026, 3, 4),
      );
      final back = ServiceOrder.fromMap('o', o.toMap());
      expect(back.orderNumber, 'SO-20260304-007');
      expect(back.complaints, ['Not charging']);
      expect(back.checklist['display_ok'], isTrue);
      expect(back.expectedCompletionAt, o.expectedCompletionAt);
    });
  });

  group('search', () {
    final order = ServiceOrder(
      id: 'o',
      orderNumber: 'SO-20260304-007',
      customerName: 'Ramesh K',
      customerPhone: '9876543210',
      brand: 'Samsung',
      model: 'Galaxy M14',
      imei: '354879104523681',
      technician: 'Suresh',
      complaints: const ['Not charging'],
      receivedAt: DateTime(2026, 3, 1),
      expectedCompletionAt: DateTime(2026, 3, 4),
    );

    test(
      'by order number, customer, device, IMEI, technician or complaint',
      () {
        for (final q in [
          'SO-20260304-007',
          'ramesh',
          'galaxy m14',
          '354879104523681',
          'suresh',
          'charging',
        ]) {
          expect(order.matches(q), isTrue, reason: q);
        }
      },
    );

    test("by the customer's number however it was written", () {
      expect(order.matches('+91 98765 43210'), isTrue);
    });

    test('an empty box matches everything', () {
      expect(order.matches(''), isTrue);
      expect(order.matches(null), isTrue);
    });

    test('a word that is nowhere on the row does not match', () {
      expect(order.matches('iphone'), isFalse);
    });
  });

  group('a visit: several phones from one customer', () {
    ServiceOrder job(String id, String visit, int minute) =>
        ServiceOrder.fromMap(id, {
          'visitId': visit,
          'createdAt': DateTime(2026, 11, 23, 10, minute).toIso8601String(),
        });

    test('the visit id is kept, and old records have none', () {
      expect(job('a', 'a', 0).toMap()['visitId'], 'a');
      expect(ServiceOrder.fromMap('x', const {}).inVisit, isFalse);
      expect(
        ServiceOrder.fromMap('x', const {}).toMap(),
        isNot(contains('visitId')),
      );
    });

    test('visitOf: every phone in the visit, oldest first', () {
      final a = job('a', 'a', 0);
      final b = job('b', 'a', 5);
      final other = job('c', 'c', 1);
      expect(visitOf(b, [b, other, a]).map((o) => o.id), ['a', 'b']);
      final alone = ServiceOrder.fromMap('z', const {});
      expect(visitOf(alone, [a, b]).single.id, 'z');
    });
  });
}

/// Stands in for `cloud_firestore`'s `Timestamp`.
class _FakeTimestamp {
  _FakeTimestamp(this._value);
  final DateTime _value;
  DateTime toDate() => _value;
}
