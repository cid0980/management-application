import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/reports/export_csv.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  final from = DateTime(2026, 11, 1);
  final to = DateTime(2026, 12, 1);

  test('a cell with a comma or a quote is quoted', () {
    expect(csvCell('plain'), 'plain');
    expect(csvCell('Ramesh, K'), '"Ramesh, K"');
    expect(csvCell('6" screen'), '"6"" screen"');
    expect(csvCell(null), '');
  });

  test('bills: completed ones in the period, oldest first', () {
    Sale bill(
      String id,
      DateTime at, {
      SaleStatus status = SaleStatus.completed,
    }) => Sale(
      id: id,
      invoiceNumber: 'INV-$id',
      customerName: 'Ramesh, K',
      items: const [SaleItem(description: 'Cover', unitPrice: 300)],
      amountPaid: 100,
      paymentMethod: 'UPI',
      status: status,
      completedAt: at,
    );
    final csv = billsCsv(
      [
        bill('2', DateTime(2026, 11, 20)),
        bill('1', DateTime(2026, 11, 2)),
        bill('old', DateTime(2026, 10, 30)),
        bill('draft', DateTime(2026, 11, 5), status: SaleStatus.draft),
      ],
      from,
      to,
    );
    final lines = csv.split('\r\n');
    expect(lines.first, startsWith('Date,Invoice,Customer'));
    expect(lines, hasLength(3));
    expect(lines[1], '2026-11-02,INV-1,"Ramesh, K",,Cover,300,100,200,UPI');
    expect(lines[2], startsWith('2026-11-20,INV-2'));
  });

  test('repairs: taken in during the period', () {
    final csv = repairsCsv(
      [
        ServiceOrder(
          id: 'a',
          orderNumber: 'SO-1',
          brand: 'Samsung',
          model: 'A54',
          complaints: const ['Not charging', 'Display broken'],
          status: 'Ready',
          estimatedPrice: 1500,
          receivedAt: DateTime(2026, 11, 10),
        ),
        ServiceOrder(
          id: 'b',
          orderNumber: 'SO-0',
          brand: 'Vivo',
          model: 'Y21',
          receivedAt: DateTime(2026, 9, 1),
        ),
      ],
      from,
      to,
    );
    final lines = csv.split('\r\n');
    expect(lines, hasLength(2));
    expect(lines[1], contains('SO-1'));
    expect(lines[1], contains('Not charging; Display broken'));
  });

  test('stock: phones in stock only', () {
    final csv = stockCsv([
      SecondHandDevice(
        id: 'a',
        brand: 'Samsung',
        model: 'Galaxy A54',
        ram: '8GB',
        rom: '128GB',
        imei: '354879104523682',
        purchasePrice: 12000,
        askingPrice: 15500,
        purchasedAt: DateTime(2026, 11, 20),
      ),
      SecondHandDevice(id: 'b', brand: 'Vivo', model: 'Y21', status: 'sold'),
    ]);
    final lines = csv.split('\r\n');
    expect(lines, hasLength(2));
    expect(
      lines[1],
      '2026-11-20,,Samsung,Galaxy A54,8GB,128GB,354879104523682,12000,15500',
    );
  });
}
