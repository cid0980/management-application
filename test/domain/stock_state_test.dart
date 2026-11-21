import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

void main() {
  test('anything unrecognised is plain stock', () {
    expect(stockStateOf(null), kAvailable);
    expect(stockStateOf(''), kAvailable);
    expect(stockStateOf('whatever'), kAvailable);
  });

  test('a device on the bench is not sellable', () {
    expect(isSellable(kRepairing), isFalse);
    expect(isBeingRepaired(kRepairing), isTrue);
  });

  test('only available stock can go on a bill', () {
    expect(isSellable(kAvailable), isTrue);
    expect(isSellable(kSold), isFalse);
  });

  group('statusForSave', () {
    test('sold always wins — an edit cannot put it back on the shelf', () {
      expect(statusForSave(current: kSold, stillBeingRepaired: true), kSold);
      expect(statusForSave(current: kSold), kSold);
    });

    test('still being repaired holds it off the shelf', () {
      expect(statusForSave(current: kAvailable, stillBeingRepaired: true),
          kRepairing);
    });

    test('a finished repair returns to stock', () {
      expect(statusForSave(current: kRepairing), kAvailable);
    });
  });
}
