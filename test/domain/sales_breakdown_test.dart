import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/reports/sales_breakdown.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

Sale _sale(
  String id,
  DateTime at, {
  SaleStatus status = SaleStatus.completed,
  List<SaleItem> items = const [
    SaleItem(description: 'Charger', unitPrice: 500),
  ],
}) => Sale(id: id, status: status, completedAt: at, items: items);

void main() {
  final range = DateRange(DateTime(2026, 11, 8), DateTime(2026, 11, 12));

  group('takings day by day', () {
    test('every day is there, the quiet ones as zero', () {
      final days = dailyTakings([
        _sale('a', DateTime(2026, 11, 8, 10)),
        _sale('b', DateTime(2026, 11, 8, 18)),
        _sale('c', DateTime(2026, 11, 11, 12)),
      ], range);
      expect(days.map((d) => d.day.day), [8, 9, 10, 11, 12]);
      expect(days.map((d) => d.amount), [1000, 0, 0, 500, 0]);
      expect(days.first.bills, 2);
    });

    test('drafts and cancelled bills are not takings', () {
      final days = dailyTakings([
        _sale('a', DateTime(2026, 11, 9), status: SaleStatus.draft),
        _sale('b', DateTime(2026, 11, 9), status: SaleStatus.cancelled),
      ], range);
      expect(days.every((d) => d.amount == 0), isTrue);
    });

    test('a long range shows its latest days only', () {
      final year = DateRange(DateTime(2026, 1, 1), DateTime(2026, 11, 12));
      final days = dailyTakings(const [], year, maxDays: 31);
      expect(days, hasLength(31));
      expect(days.last.day, DateTime(2026, 11, 12));
    });
  });

  group('what sold', () {
    test('biggest earner first, the same item typed two ways is one row', () {
      final rows = topSellers([
        _sale(
          'a',
          DateTime(2026, 11, 9),
          items: const [
            SaleItem(
              description: 'Tempered glass',
              unitPrice: 150,
              quantity: 2,
            ),
            SaleItem(description: 'Galaxy A54', unitPrice: 18000),
          ],
        ),
        _sale(
          'b',
          DateTime(2026, 11, 10),
          items: const [
            SaleItem(description: 'tempered  GLASS', unitPrice: 150),
          ],
        ),
      ], range);
      expect(rows.map((r) => r.description), ['Galaxy A54', 'Tempered glass']);
      expect(rows[1].quantity, 3);
      expect(rows[1].amount, 450);
    });

    test('outside the range, not counted', () {
      expect(topSellers([_sale('a', DateTime(2026, 10, 1))], range), isEmpty);
    });
  });
}
