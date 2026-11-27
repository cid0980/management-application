import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

/// The in-memory stores answer the "older records" questions from what they
/// hold, so screens behave the same with or without a live window.
void main() {
  SecondHandDevice phone(
    String id, {
    String seller = '',
    String? sellerId,
    String imei = '',
    DateTime? bought,
    DateTime? sold,
  }) => SecondHandDevice(
    id: id,
    brand: 'Samsung',
    model: 'A54',
    status: sold == null ? kAvailable : kSold,
    sellerPhone: seller,
    sellerCustomerId: sellerId,
    imei: imei,
    purchasedAt: bought,
    soldAt: sold,
  );

  group('stock', () {
    final store = InMemorySecondHandStore(
      seed: [
        phone('a', seller: '9876543210', bought: DateTime(2025, 1, 5)),
        phone('b', sellerId: 'c1', bought: DateTime(2025, 3, 1)),
        phone(
          'c',
          imei: '356789012345678',
          bought: DateTime(2024, 12, 1),
          sold: DateTime(2025, 2, 10),
        ),
      ],
    );

    test('everything is loaded, so there is no window', () async {
      expect(store.liveSince, isNull);
      expect((await store.fetchById('c'))?.id, 'c');
      expect(await store.fetchById('nope'), isNull);
    });

    test('a seller by number however it was typed, or by customer', () async {
      final byPhone = await store.fetchOlder(sellerPhone: '+91 98765 43210');
      expect(byPhone.map((d) => d.id), ['a']);
      final byId = await store.fetchOlder(sellerCustomerId: 'c1');
      expect(byId.map((d) => d.id), ['b']);
    });

    test('one IMEI', () async {
      final found = await store.fetchOlder(imei: '356789012345678');
      expect(found.map((d) => d.id), ['c']);
      expect(await store.fetchOlder(), isEmpty);
    });

    test('bought or sold in a range', () async {
      final feb = await store.fetchActiveBetween(
        DateTime(2025, 2, 1),
        DateTime(2025, 2, 28),
      );
      expect(feb.map((d) => d.id), ['c']);
      final jan = await store.fetchActiveBetween(
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 31),
      );
      expect(jan.map((d) => d.id), ['a']);
    });
  });

  group('enquiries', () {
    final store = InMemoryEnquiryStore(
      seed: const [
        Enquiry(id: 'e1', customerPhone: '9876543210', status: 'Lost'),
        Enquiry(id: 'e2', customerId: 'c1', status: 'Won'),
        Enquiry(id: 'e3', customerPhone: '9000000000'),
      ],
    );

    test('everything is loaded, so there is no window', () async {
      expect(store.liveSince, isNull);
      expect((await store.fetchById('e1'))?.id, 'e1');
    });

    test("a customer's, by number or by id", () async {
      final found = await store.fetchOlder(
        customerId: 'c1',
        phone: '98765 43210',
      );
      expect(found.map((e) => e.id), unorderedEquals(['e1', 'e2']));
    });
  });
}
