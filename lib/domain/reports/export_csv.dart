import '../inventory/second_hand_device.dart';
import '../inventory/stock_state.dart';
import '../sales/sale.dart';
import '../service/service_order.dart';

/// THE SHOP'S RECORDS AS A SPREADSHEET
///
/// Reports › Export gives the period's bills and repairs as CSV files: they
/// open in Excel or Google Sheets and are what an accountant asks for. One
/// row per bill or repair, money as plain numbers (no ₹, no commas), dates as
/// 2026-11-23 so a spreadsheet sorts them.

/// A cell, quoted when it holds a comma, a quote or a line break.
String csvCell(Object? value) {
  final s = value == null ? '' : '$value';
  if (s.contains(RegExp(r'[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}

String _row(List<Object?> cells) => cells.map(csvCell).join(',');

String _date(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

bool _within(DateTime? d, DateTime from, DateTime to) =>
    d != null && !d.isBefore(from) && d.isBefore(to);

/// Completed bills from [from] up to (not including) [to].
String billsCsv(Iterable<Sale> sales, DateTime from, DateTime to) {
  final rows =
      sales
          .where((s) => s.completed && _within(s.completedAt, from, to))
          .toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  return [
    _row([
      'Date',
      'Invoice',
      'Customer',
      'Phone',
      'Items',
      'Total',
      'Paid',
      'Due',
      'Paid by',
    ]),
    for (final s in rows)
      _row([
        _date(s.completedAt),
        s.invoiceNumber,
        s.customerName,
        s.customerPhone,
        s.items.map((i) => i.description).join('; '),
        s.total,
        s.amountPaid,
        s.balanceDue,
        s.paymentMethod,
      ]),
  ].join('\r\n');
}

/// Repairs taken in from [from] up to (not including) [to].
String repairsCsv(Iterable<ServiceOrder> orders, DateTime from, DateTime to) {
  final rows = orders.where((o) => _within(o.receivedAt, from, to)).toList()
    ..sort((a, b) => a.receivedAt!.compareTo(b.receivedAt!));
  return [
    _row([
      'Received',
      'Job',
      'Customer',
      'Phone',
      'Brand',
      'Model',
      'IMEI',
      'Complaints',
      'Status',
      'Estimate',
      'Charged',
      'Advance',
      'Completed',
    ]),
    for (final o in rows)
      _row([
        _date(o.receivedAt),
        o.orderNumber,
        o.customerName,
        o.customerPhone,
        o.brand,
        o.model,
        o.imei,
        o.complaints.join('; '),
        o.status,
        o.estimatedPrice,
        o.finalPrice ?? '',
        o.advancePaid,
        _date(o.completedAt),
      ]),
  ].join('\r\n');
}

/// Every phone in stock now — for a stock count, or the bank.
String stockCsv(Iterable<SecondHandDevice> devices) {
  final rows = devices.where((d) => d.stockState == kAvailable).toList()
    ..sort(
      (a, b) => (a.purchasedAt ?? DateTime(2000)).compareTo(
        b.purchasedAt ?? DateTime(2000),
      ),
    );
  return [
    _row([
      'Bought',
      'Label',
      'Brand',
      'Model',
      'RAM',
      'Storage',
      'IMEI',
      'Paid',
      'Selling price',
    ]),
    for (final d in rows)
      _row([
        _date(d.purchasedAt),
        d.labelNumber ?? '',
        d.brand,
        d.model,
        d.ram,
        d.rom,
        d.imei,
        d.purchasePrice,
        d.askingPrice,
      ]),
  ].join('\r\n');
}
