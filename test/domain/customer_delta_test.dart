import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/customer.dart';

void main() {
  test('caught up from the newest change held, less a day', () {
    final synced = DateTime(2026, 11, 20);
    final held = [
      Customer(
        id: 'a',
        name: 'A',
        phone: '9000000001',
        updatedAt: DateTime(2026, 11, 25, 10),
      ),
      Customer(
        id: 'b',
        name: 'B',
        phone: '9000000002',
        updatedAt: DateTime(2026, 11, 22),
      ),
      const Customer(id: 'c', name: 'C', phone: '9000000003'),
    ];
    expect(sinceForDelta(held, synced), DateTime(2026, 11, 24, 10));
  });

  test('nothing newer than the download: from the download, less a day', () {
    expect(
      sinceForDelta(const [], DateTime(2026, 11, 20)),
      DateTime(2026, 11, 19),
    );
  });
}
