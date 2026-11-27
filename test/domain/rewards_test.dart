import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/wallet.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';

void main() {
  test('points off by default; a new shop has the usual discounts', () {
    final s = ShopSettings.fromMap(const {});
    expect(s.rewardFor(5000), 0);
    expect(s.discountTypes, kDefaultDiscountTypes);
  });

  test('₹100 = 1 point, 1 point = ₹1: a ₹1,250 bill earns ₹12', () {
    final s = ShopSettings.fromMap(const {
      'rewardEvery': 100,
      'rewardPoints': 1,
      'pointValue': 1,
    });
    expect(s.rewardFor(1250), 12);
    expect(s.rewardFor(99), 0);
  });

  test('the rules and the discounts round-trip; saved empty stays empty', () {
    final s = ShopSettings.fromMap(const {
      'rewardEvery': 500,
      'rewardPoints': 2,
      'pointValue': 0.5,
      'discountTypes': {'Staff': 15},
    });
    final back = ShopSettings.fromMap(s.toMap());
    expect(back.rewardFor(1000), 2);
    expect(back.discountTypes, {'Staff': 15});
    expect(
      ShopSettings.fromMap(const {'discountTypes': {}}).discountTypes,
      isEmpty,
    );
  });

  test('a bill\'s points are found by its id', () {
    final moves = [
      const WalletMove(
        kind: WalletMoveKind.credit,
        amount: 12,
        reason: '$kPointsReason SO-1',
        reference: 's1',
      ),
      const WalletMove(
        kind: WalletMoveKind.credit,
        amount: 50,
        reason: 'Bill SO-1 cancelled',
        reference: 's1',
      ),
    ];
    expect(pointsIn(moves, 's1'), 12);
    expect(pointsIn(moves, 's2'), 0);
  });
}
