import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_list.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

SecondHandDevice _d(
  String id,
  num paid, {
  String brand = 'Redmi',
  String model = 'Note 12',
  num? sold,
}) => SecondHandDevice(
  id: id,
  brand: brand,
  model: model,
  purchasePrice: paid,
  status: sold == null ? kAvailable : kSold,
  soldPrice: sold,
);

void main() {
  test("what this model was bought and sold for before", () {
    final h = priceHistoryFor(
      [
        _d('a', 9000, sold: 13000),
        _d('b', 11500, sold: 14000),
        _d('c', 10000),
        _d('x', 30000, brand: 'Apple', model: 'iPhone 13'),
      ],
      brand: ' redmi ',
      model: 'NOTE  12',
    )!;
    expect(h.bought, 3);
    expect(h.paidLow, 9000);
    expect(h.paidHigh, 11500);
    expect(h.sold, 2);
    expect(h.soldAverage, 13500);
  });

  test('never bought, or no model typed yet, says nothing', () {
    expect(priceHistoryFor([_d('a', 9000)], brand: 'Vivo', model: 'Y21'),
        isNull);
    expect(priceHistoryFor([_d('a', 9000)], brand: 'Redmi', model: ''),
        isNull);
  });

  test('the phone being edited is not its own history', () {
    expect(
      priceHistoryFor([_d('a', 9000)],
          brand: 'Redmi', model: 'Note 12', excludeId: 'a'),
      isNull,
    );
  });
}
