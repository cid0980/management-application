import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/products/product_list.dart';

void main() {
  test('the order list groups what is low by supplier, with how many', () {
    final msg = orderListMessage([
      const Product(
        id: 'a',
        name: 'Tempered glass',
        supplier: 'Raj Traders',
        stockCount: 1,
        reorderLevel: 5,
      ),
      const Product(
        id: 'b',
        name: 'Type-C cable',
        stockCount: 0,
        reorderLevel: 3,
      ),
      const Product(
        id: 'c',
        name: 'Back case',
        supplier: 'Raj Traders',
        stockCount: 20,
        reorderLevel: 5,
      ),
    ], shopName: 'French Mobiles');
    expect(msg, startsWith('Order list — French Mobiles'));
    expect(msg, contains('Raj Traders:'));
    expect(msg, contains('Tempered glass'));
    expect(msg, contains('(have 1)'));
    expect(msg, contains('Other:'));
    expect(msg, isNot(contains('Back case')));
  });

  test('nothing low, no message', () {
    expect(orderListMessage(const []), isEmpty);
  });
}
