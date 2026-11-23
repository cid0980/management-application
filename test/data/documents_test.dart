import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/expenses/expense.dart';
import 'package:fm_shop/data/printing/documents.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/reports/sales_breakdown.dart';
import 'package:fm_shop/domain/reports/shop_report.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:pdf/widgets.dart' as pw;

/// Every printed document builds, with the shop's real fonts, from the record
/// shapes that cause trouble: a customer with no name, a discount, a balance
/// still owed, a lock code, a signature.
const _shop = ShopHeader(
  name: 'Sri Mobiles',
  address: '12 Gandhi Road, Puducherry',
  phone: '98765 43210',
  gstin: '34ABCDE1234F1Z5',
);

bool _isPdf(List<int> bytes) =>
    bytes.length > 500 && ascii.decode(bytes.take(5).toList()) == '%PDF-';

void main() {
  setUpAll(() {
    // The same files the app bundles, so a rupee sign is drawn, not a box.
    usePrintFonts(
      base: pw.Font.ttf(
        File('assets/fonts/NotoSans-Regular.ttf')
            .readAsBytesSync()
            .buffer
            .asByteData(),
      ),
      bold: pw.Font.ttf(
        File('assets/fonts/NotoSans-Bold.ttf')
            .readAsBytesSync()
            .buffer
            .asByteData(),
      ),
    );
  });

  final order = ServiceOrder(
    id: 'so-1',
    orderNumber: 'SRV-20261112-001',
    customerName: 'Ramesh K',
    customerPhone: '9876543210',
    brand: 'Samsung',
    model: 'Galaxy A54',
    imei: '490154203237518',
    lockType: 'Pattern',
    lockValue: '1-2-3-6-9',
    accessories: const ['Charger', 'Back cover'],
    complaints: const ['Display broken', 'Battery drains'],
    complaintNotes: 'Dropped in water last week',
    estimatedPrice: 4500,
    technician: 'Mani',
    status: 'Received',
    receivedAt: DateTime(2026, 11, 12, 10, 30),
    expectedCompletionAt: DateTime(2026, 11, 14, 18),
  );

  test('the job card builds, with and without the lock code', () async {
    expect(
      _isPdf(
        await buildJobCardPdf(
          order: order,
          shop: _shop,
          checklist: const ['Display', 'Touch', 'Camera'],
        ),
      ),
      isTrue,
    );
    expect(
      _isPdf(
        await buildJobCardPdf(order: order, shop: _shop, includeLock: false),
      ),
      isTrue,
    );
  });

  test('the final bill builds from what was charged', () async {
    final done = order.copyWith(
      status: 'Completed',
      finalPrice: 4200,
      completedAt: DateTime(2026, 11, 13, 17),
    );
    expect(_isPdf(await buildFinalBillPdf(order: done, shop: _shop)), isTrue);
  });

  test(
    'two phones in one visit: two job cards and one bill, in one print',
    () async {
      final second = ServiceOrder.fromMap('so-2', {
        ...order.toMap(),
        'orderNumber': 'SRV-20261112-002',
        'brand': 'Vivo',
        'model': 'Y21',
        'visitId': 'so-1',
      });
      final first = order.copyWith(visitId: 'so-1');
      final one = await buildJobCardPdf(order: first, shop: _shop);
      final both = await buildJobCardPdf(
        order: first,
        shop: _shop,
        visit: [first, second],
      );
      expect(_isPdf(both), isTrue);
      expect(both.length, greaterThan(one.length));

      final done = [
        for (final o in [first, second])
          o.copyWith(
            status: 'Completed',
            finalPrice: 1500,
            completedAt: DateTime(2026, 11, 13, 17),
          ),
      ];
      expect(
        _isPdf(await buildVisitFinalBillPdf(orders: done, shop: _shop)),
        isTrue,
      );
    },
  );

  test('the bill builds with a discount and a balance still owed', () async {
    final sale = Sale(
      id: 's-1',
      invoiceNumber: 'INV-20261112-004',
      customerPhone: '9123456780', // no name: still prints
      paymentMethod: 'Cash',
      amountPaid: 10000,
      status: SaleStatus.completed,
      completedAt: DateTime(2026, 11, 12, 15),
      items: const [
        SaleItem(
          description: 'Samsung Galaxy A54 8/128',
          unitPrice: 18500,
          source: LineSource.secondHand,
          imei: '490154203237518',
          discount: 500,
        ),
        SaleItem(description: 'Tempered glass', unitPrice: 150, quantity: 2),
      ],
    );
    expect(sale.balanceDue, greaterThan(0));
    expect(_isPdf(await buildInvoicePdf(sale: sale, shop: _shop)), isTrue);
  });

  test('the declaration builds with the seller signature drawn on it', () async {
    // A real 1x1 PNG, as the signature pad would store it.
    const png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    final device = SecondHandDevice(
      id: 'sh-1',
      brand: 'Apple',
      model: 'iPhone 11',
      ram: '4GB',
      rom: '128GB',
      imei: '356789012345678',
      purchasePrice: 15000,
      sellerName: 'Anbu',
      sellerPhone: '9000011111',
      sellerSignature: 'data:image/png;base64,$png',
      sellerIdVerified: true,
      agreementAcceptedAt: DateTime(2026, 11, 12, 11),
      purchasedAt: DateTime(2026, 11, 12, 11),
    );
    expect(
      _isPdf(
        await buildPurchaseDeclarationPdf(
          device: device,
          shop: _shop,
          terms: const ['I am the lawful owner.', 'It is not stolen.'],
          staffName: 'Suresh',
        ),
      ),
      isTrue,
    );
  });

  test(
    'a declaration without a signature still prints a line to sign',
    () async {
      const device = SecondHandDevice(id: 'sh-2', brand: 'Vivo', model: 'Y21');
      expect(
        _isPdf(
          await buildPurchaseDeclarationPdf(
            device: device,
            shop: _shop,
            terms: const [],
          ),
        ),
        isTrue,
      );
    },
  );

  test('the label sticker builds, one page per copy', () async {
    final bytes = await buildLabelPdf(
      number: 26042,
      title: 'Galaxy A54',
      subtitle: '8GB / 128GB',
      price: 18500,
      copies: 2,
    );
    expect(_isPdf(bytes), isTrue);
  });

  test('the report builds as a page to send, with how it was paid', () async {
    final day = DateRange(DateTime(2026, 11, 22), DateTime(2026, 11, 22));
    final sales = [
      Sale(
        id: 's1',
        status: SaleStatus.completed,
        paymentMethod: 'UPI',
        amountPaid: 32000,
        completedAt: DateTime(2026, 11, 22, 12),
        items: const [SaleItem(description: 'iPhone 13', unitPrice: 32000)],
      ),
    ];
    final report = buildReport(
      range: day,
      sales: sales,
      orders: const [],
      stock: const [],
      customers: const [],
    );
    final bytes = await buildShopReportPdf(
      shop: _shop,
      rangeLabel: '22/11/2026',
      report: report,
      split: paymentSplit(sales, day),
      topSellers: topSellers(sales, day),
    );
    expect(_isPdf(bytes), isTrue);

    // With the period's expenses: money out and the cash left.
    final withSpent = await buildShopReportPdf(
      shop: _shop,
      rangeLabel: '22/11/2026',
      report: report,
      split: paymentSplit(sales, day),
      topSellers: topSellers(sales, day),
      spent: summarizeExpenses([
        Expense(
          id: 'e1',
          amount: 60,
          kind: 'Tea & food',
          spentAt: day.start.add(const Duration(hours: 11)),
        ),
      ], day),
    );
    expect(_isPdf(withSpent), isTrue);
    expect(withSpent.length, greaterThan(bytes.length));
  });

  test('a GST shop gets a tax invoice that builds', () async {
    const gstShop = ShopHeader(
      name: 'Sri Mobiles',
      gstin: '34ABCDE1234F1Z5',
      gstRate: 18,
    );
    expect(gstShop.chargesGst, isTrue);
    final bill = Sale(
      id: 's9',
      invoiceNumber: 'INV-1',
      status: SaleStatus.completed,
      amountPaid: 1180,
      completedAt: DateTime(2026, 11, 22),
      items: const [SaleItem(description: 'Charger', unitPrice: 1180)],
    );
    expect(_isPdf(await buildInvoicePdf(sale: bill, shop: gstShop)), isTrue);
    expect(const ShopHeader(name: 'x', gstRate: 18).chargesGst, isFalse);
  });
}
