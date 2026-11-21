import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/order_validation.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  group('an advance taken at intake', () {
    test('comes off what is collected at pickup', () {
      const o = ServiceOrder(id: 'o', estimatedPrice: 2500, advancePaid: 500);
      expect(o.toCollect, 2000);
      expect(o.copyWith(finalPrice: 3000).toCollect, 2500);
    });

    test('never asks for a negative amount, and says there is change', () {
      const o = ServiceOrder(id: 'o', estimatedPrice: 400, advancePaid: 500);
      expect(o.toCollect, 0);
      expect(o.advanceExceedsCharge, isTrue);
      expect(validateOrder(o).warnings['advancePaid'], isNotNull);
    });

    test('round-trips through the document; old records read as none', () {
      const o = ServiceOrder(id: 'o', advancePaid: 750);
      expect(ServiceOrder.fromMap('o', o.toMap()).advancePaid, 750);
      expect(ServiceOrder.fromMap('o', const {}).advancePaid, 0);
    });

    test('a negative advance is refused', () {
      const o = ServiceOrder(id: 'o', advancePaid: -1);
      expect(validateOrder(o).errors['advancePaid'], isNotNull);
    });
  });
}
