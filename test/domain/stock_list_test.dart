import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/purchase_costing.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_list.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

SecondHandDevice _d(
  String id, {
  String brand = 'Samsung',
  String model = 'Galaxy A54',
  String status = kAvailable,
  String imei = '',
  int? label,
  String sellerName = '',
  String sellerPhone = '',
  num purchasePrice = 0,
  num askingPrice = 0,
  num? soldPrice,
  List<RepairCost> repairs = const [],
  DateTime? purchasedAt,
}) =>
    SecondHandDevice(
      id: id,
      brand: brand,
      model: model,
      status: status,
      imei: imei,
      labelNumber: label,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      purchasePrice: purchasePrice,
      askingPrice: askingPrice,
      soldPrice: soldPrice,
      repairs: repairs,
      purchasedAt: purchasedAt,
    );

void main() {
  group('tabs read the derived state, not the raw status', () {
    final unknown = _d('u', status: 'in_stock_old');

    test('a status this build has never seen still lands somewhere', () {
      expect(inTab(unknown, StockTab.available), isTrue);
      expect(stockRows([unknown], tab: StockTab.available), hasLength(1));
    });

    test('each of the three states has its own tab', () {
      final all = [
        _d('a'),
        _d('b', status: kRepairing),
        _d('c', status: kSold),
      ];
      expect(stockRows(all, tab: StockTab.available).single.id, 'a');
      expect(stockRows(all, tab: StockTab.repairing).single.id, 'b');
      expect(stockRows(all, tab: StockTab.sold).single.id, 'c');
      expect(stockRows(all, tab: StockTab.all), hasLength(3));
    });
  });

  group('ordering', () {
    test('the newest purchase is first — it is the row being looked for', () {
      final rows = stockRows([
        _d('old', purchasedAt: DateTime(2026, 1, 1)),
        _d('new', purchasedAt: DateTime(2026, 6, 1)),
      ], tab: StockTab.available);
      expect(rows.map((r) => r.id), ['new', 'old']);
    });

    test('an undated record sorts last: incomplete, not urgent', () {
      final rows = stockRows([
        _d('undated'),
        _d('dated', purchasedAt: DateTime(2026, 1, 1)),
      ], tab: StockTab.available);
      expect(rows.map((r) => r.id), ['dated', 'undated']);
    });
  });

  group('search covers what the person holding the phone has to go on', () {
    final all = [
      _d('a', brand: 'Samsung', model: 'Galaxy A54', imei: '490154203237518'),
      _d('b', brand: 'Xiaomi', model: 'Redmi Note 12', label: 26007),
      _d('c', brand: 'Apple', model: 'iPhone 11', sellerPhone: '9988776655'),
    ];

    test('an empty box is the whole list, not an empty one', () {
      expect(stockRows(all, tab: StockTab.all, query: ''), hasLength(3));
      expect(stockRows(all, tab: StockTab.all), hasLength(3));
    });

    test('by IMEI', () {
      final rows = stockRows(all, tab: StockTab.all, query: '490154203237518');
      expect(rows.single.id, 'a');
    });

    test('by label number', () {
      expect(stockRows(all, tab: StockTab.all, query: '26007').single.id, 'b');
    });

    test("by the seller's number, however it was written", () {
      expect(
        stockRows(all, tab: StockTab.all, query: '+91 99887 76655').single.id,
        'c',
      );
    });

    test('every word has to land: "redmi 12" is not every Redmi', () {
      final rows = stockRows(all, tab: StockTab.all, query: 'redmi note');
      expect(rows.single.id, 'b');
      expect(stockRows(all, tab: StockTab.all, query: 'redmi iphone'), isEmpty);
    });
  });

  test('tab counts are counted against the same query the list is showing', () {
    final all = [
      _d('a', brand: 'Samsung'),
      _d('b', brand: 'Samsung', status: kRepairing),
      _d('c', brand: 'Apple', status: kSold),
    ];
    final counts = stockTabCounts(all, query: 'samsung');
    expect(counts[StockTab.available], 1);
    expect(counts[StockTab.repairing], 1);
    expect(counts[StockTab.sold], 0);
    expect(counts[StockTab.all], 2);
  });

  group('the sale picker', () {
    test('only sellable stock reaches it', () {
      final all = [
        _d('a'),
        _d('b', status: kRepairing),
        _d('c', status: kSold),
      ];
      expect(sellableStock(all).map((d) => d.id), ['a']);
    });

    test('the rest is still loaded, so a scan can explain itself', () {
      // Not a property of sellableStock, but of what it is given: the list it
      // filters is the whole list, not a query that dropped the others.
      final all = [_d('a'), _d('b', status: kRepairing)];
      expect(stockRows(all, tab: StockTab.all), hasLength(2));
    });
  });

  group('money tied up in stock', () {
    test('sold devices are not stock and are not counted', () {
      final all = [
        _d('a', purchasePrice: 6000, askingPrice: 9000),
        _d('b', status: kSold, purchasePrice: 19000, askingPrice: 25000),
      ];
      final value = stockValue(all);
      expect(value.count, 1);
      expect(value.cost, 6000);
      expect(value.asking, 9000);
      expect(value.expectedProfit, 3000);
    });

    test('a handset on the bench is stock, and its repairs are in the cost',
        () {
      final value = stockValue([
        _d(
          'b',
          status: kRepairing,
          purchasePrice: 6200,
          askingPrice: 11500,
          repairs: const [RepairCost(description: 'Display', amount: 2400)],
        ),
      ]);
      expect(value.count, 1);
      expect(value.cost, 8600);
      expect(value.expectedProfit, 2900);
    });
  });

  group('days in stock', () {
    final now = DateTime(2026, 11, 22, 10);

    test('counts calendar days from the purchase', () {
      final d = _d('a', purchasedAt: DateTime(2026, 11, 20, 18));
      expect(daysInStock(d, now), 2);
      expect(daysInStock(_d('b', purchasedAt: now), now), 0);
    });

    test('no date, no number', () {
      expect(daysInStock(_d('c'), now), isNull);
    });

    test('a phone unsold for 30 days on the shelf is flagged', () {
      final old = DateTime(2026, 10, 23);
      expect(isStale(_d('d', purchasedAt: old), now), isTrue);
      expect(
        isStale(_d('e', purchasedAt: DateTime(2026, 11, 1)), now),
        isFalse,
      );
    });

    test('a phone on the bench or sold is never flagged', () {
      final old = DateTime(2026, 9, 1);
      expect(isStale(_d('f', status: kRepairing, purchasedAt: old), now), isFalse);
      expect(isStale(_d('g', status: kSold, purchasedAt: old), now), isFalse);
    });
  });
}
