import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/gst.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/shops/shop.dart';

void main() {
  test('18% inside ₹1180 is ₹1000 plus ₹90 CGST and ₹90 SGST', () {
    final g = gstInclusive(1180, 18)!;
    expect(g.taxable, 1000);
    expect(g.cgst, 90);
    expect(g.sgst, 90);
    expect(g.tax, 180);
  });

  test('odd amounts still add up to the total, to the paisa', () {
    final g = gstInclusive(350, 18)!;
    expect(g.taxable + g.cgst + g.sgst, closeTo(350, 0.001));
  });

  test('no rate, no split', () {
    expect(gstInclusive(1000, 0), isNull);
  });

  test('used handsets are left out of the taxable amount', () {
    const sale = Sale(
      id: 's',
      items: [
        SaleItem(
          description: 'iPhone 13',
          unitPrice: 32000,
          source: LineSource.secondHand,
        ),
        SaleItem(description: 'Tempered glass', unitPrice: 350),
      ],
    );
    expect(taxableAmountOf(sale), 350);
    expect(hasMarginSchemeLines(sale), isTrue);
  });

  test("the shop's rate round-trips, and old shops read as off", () {
    const shop = Shop(id: 's', name: 'FM', gstin: '33ABCDE1234F1Z5', gstRate: 18);
    expect(Shop.fromMap('s', shop.toMap()).gstRate, 18);
    expect(Shop.fromMap('s', const {'name': 'FM'}).gstRate, 0);
  });

  test('a customer in another state pays it all as IGST', () {
    final g = gstInclusive(1180, 18, interState: true)!;
    expect(g.taxable, 1000);
    expect(g.igst, 180);
    expect(g.cgst, 0);
    expect(g.sgst, 0);
    expect(g.tax, 180);
    expect(g.interState, isTrue);
  });

  test('within the state there is no IGST', () {
    final g = gstInclusive(1180, 18)!;
    expect(g.igst, 0);
    expect(g.interState, isFalse);
  });

  test('a bill remembers it is inter-state', () {
    const sale = Sale(id: 's', interState: true);
    expect(Sale.fromMap('s', sale.toMap()).interState, isTrue);
    expect(Sale.fromMap('s', const {}).interState, isFalse);
  });
}
