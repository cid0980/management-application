import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/inventory/purchase_costing.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';
import 'package:fm_shop/domain/reports/shop_report.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';

/// REPORTS
///
/// The rules worth holding down here are all about what a figure is counted
/// from. The shop's old spreadsheet counted quotes as revenue and added
/// handset margin on top of takings, and every month looked better than it
/// was.
void main() {
  final march = DateTime(2026, 3, 15, 12);
  final marchRange = DateRange.month(march);

  Sale sale({
    required String id,
    SaleStatus status = SaleStatus.completed,
    DateTime? completedAt,
    DateTime? updatedAt,
    num unitPrice = 1000,
    num amountPaid = 1000,
    String paymentMethod = 'Cash',
  }) =>
      Sale(
        id: id,
        items: [SaleItem(description: 'A thing', unitPrice: unitPrice)],
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        status: status,
        completedAt: completedAt,
        updatedAt: updatedAt,
      );

  ServiceOrder order({
    required String id,
    String status = 'Completed',
    num? finalPrice,
    DateTime? completedAt,
    DateTime? received,
  }) =>
      ServiceOrder(
        id: id,
        customerName: 'A customer',
        brand: 'Samsung',
        model: 'A54',
        status: status,
        estimatedPrice: 2000,
        finalPrice: finalPrice,
        completedAt: completedAt,
        receivedAt: received,
      );

  SecondHandDevice device({
    required String id,
    String status = kAvailable,
    num purchasePrice = 14000,
    List<RepairCost> repairs = const [],
    num otherCost = 0,
    num? soldPrice,
    DateTime? purchasedAt,
    DateTime? soldAt,
  }) =>
      SecondHandDevice(
        id: id,
        brand: 'Samsung',
        model: 'Galaxy A54',
        status: status,
        purchasePrice: purchasePrice,
        repairs: repairs,
        otherCost: otherCost,
        askingPrice: 18500,
        soldPrice: soldPrice,
        purchasedAt: purchasedAt,
        soldAt: soldAt,
      );

  ShopReport report({
    DateRange? range,
    List<Sale> sales = const [],
    List<ServiceOrder> orders = const [],
    List<SecondHandDevice> stock = const [],
    List<Customer> customers = const [],
  }) =>
      buildReport(
        range: range ?? marchRange,
        sales: sales,
        orders: orders,
        stock: stock,
        customers: customers,
      );

  group('takings are completed bills, dated on when they were settled', () {
    test('a bill settled inside the period counts', () {
      final r = report(sales: [sale(id: 's-1', completedAt: march)]);

      expect(r.takings, 1000);
      expect(r.billsCompleted, 1);
    });

    test('a draft is not takings', () {
      final r = report(
        sales: [sale(id: 's-1', status: SaleStatus.draft, completedAt: march)],
      );

      expect(r.takings, 0);
      expect(r.billsCompleted, 0);
    });

    test('a cancelled bill is out of takings, but is counted as cancelled', () {
      final r = report(
        sales: [
          sale(
            id: 's-1',
            status: SaleStatus.cancelled,
            completedAt: march,
            updatedAt: march,
          ),
        ],
      );

      expect(r.takings, 0);
      expect(r.billsCancelled, 1);
    });

    test('a bill started in February and settled in March is March takings',
        () {
      final r = report(
        sales: [
          Sale(
            id: 's-1',
            items: const [SaleItem(description: 'A thing', unitPrice: 2500)],
            paymentMethod: 'Cash',
            amountPaid: 2500,
            status: SaleStatus.completed,
            createdAt: DateTime(2026, 2, 28),
            completedAt: march,
          ),
        ],
      );

      expect(r.takings, 2500);
    });

    test('a bill settled outside the period does not count', () {
      final r = report(
        sales: [sale(id: 's-1', completedAt: DateTime(2026, 4, 2))],
      );

      expect(r.takings, 0);
    });
  });

  group('service revenue is work that went back, at the price charged', () {
    test('a completed job with a final price counts', () {
      final r = report(
        orders: [order(id: 'so-1', finalPrice: 3200, completedAt: march)],
      );

      expect(r.serviceRevenue, 3200);
      expect(r.jobsCompleted, 1);
    });

    test('a quote is not revenue — an open job contributes nothing', () {
      final r = report(
        orders: [
          order(id: 'so-1', status: 'In Progress', completedAt: march),
        ],
      );

      expect(r.serviceRevenue, 0);
      expect(r.jobsCompleted, 0);
    });

    test('a completed job nobody priced contributes nothing', () {
      final r = report(orders: [order(id: 'so-1', completedAt: march)]);

      expect(r.serviceRevenue, 0);
    });

    test('jobs taken in are counted separately from jobs finished', () {
      final r = report(
        orders: [
          order(id: 'so-1', status: 'In Progress', received: march),
          order(
            id: 'so-2',
            finalPrice: 1500,
            received: DateTime(2026, 2, 1),
            completedAt: march,
          ),
        ],
      );

      expect(r.jobsTakenIn, 1);
      expect(r.jobsCompleted, 1);
    });
  });

  group('second-hand margin is honest about what a handset cost', () {
    test('repairs and other costs come off the margin', () {
      final r = report(
        stock: [
          device(
            id: 'sh-1',
            status: kSold,
            purchasePrice: 14000,
            repairs: const [RepairCost(description: 'Display', amount: 2400)],
            otherCost: 100,
            soldPrice: 18500,
            soldAt: march,
          ),
        ],
      );

      // 18500 - (14000 + 2400 + 100)
      expect(r.handsetMargin, 2000);
      expect(r.handsetRevenue, 18500);
      expect(r.handsetCost, 16500);
      expect(r.handsetsSold, 1);
    });

    test('a handset still in the cabinet has made nothing', () {
      final r = report(
        stock: [device(id: 'sh-1', purchasedAt: march)],
      );

      expect(r.handsetMargin, 0);
      expect(r.handsetsSold, 0);
      // It was still bought in the period, and that is activity.
      expect(r.handsetsBought, 1);
    });

    test('sold at a loss reports the loss rather than hiding it', () {
      final r = report(
        stock: [
          device(
            id: 'sh-1',
            status: kSold,
            purchasePrice: 14000,
            soldPrice: 12000,
            soldAt: march,
          ),
        ],
      );

      expect(r.handsetMargin, -2000);
    });

    test('bought in March, sold in April makes its money in April', () {
      final sh = device(
        id: 'sh-1',
        status: kSold,
        soldPrice: 18500,
        purchasedAt: march,
        soldAt: DateTime(2026, 4, 3),
      );

      expect(report(stock: [sh]).handsetsSold, 0);
      expect(report(stock: [sh]).handsetsBought, 1);
      expect(
        report(range: DateRange.month(DateTime(2026, 4, 1)), stock: [sh])
            .handsetsSold,
        1,
      );
    });
  });

  group('the figures are never added together', () {
    test('a handset sold on a bill is in takings and in margin, as itself',
        () {
      final r = report(
        sales: [sale(id: 's-1', unitPrice: 18500, completedAt: march)],
        stock: [
          device(
            id: 'sh-1',
            status: kSold,
            purchasePrice: 14000,
            soldPrice: 18500,
            soldAt: march,
          ),
        ],
      );

      expect(r.takings, 18500);
      expect(r.handsetMargin, 4500);
      // Four figures, each reported as itself — there is no total.
      expect(r.figures.length, 4);
      expect(
        r.figures.firstWhere((f) => f.label == 'Second-hand margin').note,
        contains('Part of takings, not on top of it'),
      );
    });
  });

  group('outstanding is a position, not a flow', () {
    test('it does not change with the period', () {
      final unpaid = sale(
        id: 's-1',
        unitPrice: 5000,
        amountPaid: 1000,
        completedAt: DateTime(2025, 1, 1),
      );

      expect(report(sales: [unpaid]).outstanding, 4000);
      expect(
        report(range: DateRange.day(march), sales: [unpaid]).outstanding,
        4000,
      );
    });

    test('a financed sale is not outstanding — the customer owes nothing', () {
      final financed = sale(
        id: 's-1',
        unitPrice: 20000,
        amountPaid: 2000,
        paymentMethod: 'Bajaj Finance',
        completedAt: march,
      );

      expect(report(sales: [financed]).outstanding, 0);
    });
  });

  group('customers added', () {
    test('counted on when the record was made', () {
      final r = report(
        customers: [
          Customer(
            id: 'c-1',
            name: 'Ramesh',
            phone: '9876543210',
            createdAt: march,
          ),
          Customer(
            id: 'c-2',
            name: 'Priya',
            phone: '9123456780',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: march,
          ),
        ],
      );

      expect(r.customersAdded, 1);
    });
  });

  group('an empty period says so rather than showing four zeroes', () {
    test('nothing happened', () {
      expect(report().isEmpty, isTrue);
    });

    test('one bill is enough to not be empty', () {
      expect(report(sales: [sale(id: 's-1', completedAt: march)]).isEmpty,
          isFalse);
    });
  });

  group('the periods mean the same thing every time', () {
    test('today is one day', () {
      final range = rangeFor(ReportPeriod.today, march);

      expect(range.isOneDay, isTrue);
      expect(range.contains(DateTime(2026, 3, 15, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 3, 16)), isFalse);
    });

    test('seven days is today and the six before it', () {
      final range = rangeFor(ReportPeriod.sevenDays, march);

      expect(range.days, 7);
      expect(range.contains(DateTime(2026, 3, 9, 12)), isTrue);
      expect(range.contains(DateTime(2026, 3, 8, 12)), isFalse);
    });

    test('this month runs to the last day of the month', () {
      final range = rangeFor(ReportPeriod.thisMonth, march);

      expect(range.contains(DateTime(2026, 3, 1)), isTrue);
      expect(range.contains(DateTime(2026, 3, 31, 23, 30)), isTrue);
      expect(range.contains(DateTime(2026, 4, 1)), isFalse);
    });

    test('a February range ends on the 28th in a non-leap year', () {
      final range = rangeFor(ReportPeriod.thisMonth, DateTime(2026, 2, 10));

      expect(range.end.day, 28);
    });

    test('a custom range is used as given, the right way round', () {
      final range = rangeFor(
        ReportPeriod.custom,
        march,
        // Backwards on purpose: a date picker lets somebody do this.
        custom: DateRange(DateTime(2026, 3, 20), DateTime(2026, 3, 10)),
      );

      expect(range.start.day, 10);
      expect(range.end.day, 20);
    });

    test('every period has a label', () {
      for (final period in ReportPeriod.values) {
        expect(kReportPeriodLabels[period], isNotNull);
      }
    });
  });
}
