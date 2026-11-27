/// THE PAPER
///
/// Ported from the French Mobiles Flutter port (`features/printing/
/// documents.dart`), which ported the web app's HTML bills to real PDFs, and
/// rewired to this app's records: one shop's `ServiceOrder`, `Sale` and
/// `SecondHandDevice`, with that shop's name at the top.
///
/// The documents go to the phone's own print dialog, which reaches a
/// Bluetooth thermal printer, a networked A4 printer, or the share sheet for
/// WhatsApp — what a shop actually has.
///
/// **English on paper, whatever the app's language.** The bundled print font
/// carries Latin letters and the rupee sign, not Tamil or Devanagari, so a
/// Tamil word would print as boxes. Customers' names and the shop's details
/// print as they were typed.
///
/// Building a document is plain Dart with no Flutter widgets, so every one of
/// them has a test that builds it.
library;

import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/common/money.dart';
import '../../domain/inventory/second_hand_device.dart';
import '../../domain/expenses/expense.dart';
import '../../domain/reports/sales_breakdown.dart';
import '../../domain/reports/shop_report.dart';
import '../../domain/sales/gst.dart';
import '../../domain/sales/sale.dart';
import '../../domain/service/service_order.dart';
import '../../domain/shops/shop.dart';
import '../signatures.dart';

pw.Font? _baseFont;
pw.Font? _boldFont;

/// Install the fonts the documents are drawn in. Called once at start-up.
void usePrintFonts({required pw.Font base, required pw.Font bold}) {
  _baseFont = base;
  _boldFont = bold;
}

/// Falls back to the PDF library's own font when none was installed (a test),
/// so a document never fails to build merely because a font is missing.
pw.ThemeData get _theme {
  if (_baseFont == null) return pw.ThemeData.base();
  return pw.ThemeData.withFont(
    base: _baseFont,
    bold: _boldFont ?? _baseFont,
    italic: _baseFont,
    boldItalic: _boldFont ?? _baseFont,
  );
}

/// What prints at the top of every page: the shop that is printing it.
class ShopHeader {
  const ShopHeader({
    required this.name,
    this.address = '',
    this.phone = '',
    this.gstin = '',
    this.gstRate = 0,
    this.footer = 'Thank you for your business!',
  });

  factory ShopHeader.fromShop(Shop shop) => ShopHeader(
    name: shop.name,
    address: shop.address,
    phone: shop.phone,
    gstin: shop.gstin,
    gstRate: shop.gstRate,
  );

  final String name;
  final String address;
  final String phone;
  final String gstin;

  /// See [Shop.gstRate]. A tax split prints only with a GSTIN as well.
  final num gstRate;
  final String footer;

  bool get chargesGst => gstin.isNotEmpty && gstRate > 0;
}

String _date(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  return '${two(l.day)}/${two(l.month)}/${l.year} '
      '${two(h)}:${two(l.minute)} ${l.hour < 12 ? 'AM' : 'PM'}';
}

const _small = pw.TextStyle(fontSize: 8);
final _bold8 = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);

pw.Widget _header(ShopHeader shop, String title) {
  final contact = [
    if (shop.phone.isNotEmpty) shop.phone,
    if (shop.gstin.isNotEmpty) 'GSTIN ${shop.gstin}',
  ].join('  ·  ');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Center(
        child: pw.Text(
          shop.name,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ),
      if (shop.address.isNotEmpty)
        pw.Center(
          child: pw.Text(
            shop.address,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5),
          ),
        ),
      if (contact.isNotEmpty)
        pw.Center(
          child: pw.Text(contact, style: const pw.TextStyle(fontSize: 7.5)),
        ),
      pw.SizedBox(height: 6),
      pw.Divider(height: 1),
      pw.SizedBox(height: 6),
      pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _row(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(width: 92, child: pw.Text(label, style: _small)),
      pw.Expanded(
        child: pw.Text(value.trim().isEmpty ? '-' : value, style: _bold8),
      ),
    ],
  ),
);

pw.Widget _totalRow(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 9,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}

pw.Widget _section(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
  child: pw.Text(
    title,
    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
  ),
);

/// THE JOB CARD — what goes onto the bench with the phone: what is wrong,
/// how to open it, and what must be checked before it goes back.
///
/// The PIN or pattern prints only when [includeLock] is true: a job card can
/// be left lying on the counter, and the customer may not want their PIN on
/// it.
Future<Uint8List> buildJobCardPdf({
  required ServiceOrder order,
  required ShopHeader shop,
  List<String> checklist = const [],
  bool includeLock = true,
  String technicianLabel = 'Repair Engineer',
  List<ServiceOrder> visit = const [],
}) {
  final doc = pw.Document(
    theme: _theme,
    title: 'Job card ${order.orderNumber}',
  );
  // Several phones from one customer: one card per phone, in one print.
  final jobs = visit.length > 1 ? visit : [order];
  for (final (n, job) in jobs.indexed) {
    _addJobCardPage(
      doc,
      job,
      shop: shop,
      checklist: checklist,
      includeLock: includeLock,
      technicianLabel: technicianLabel,
      visitNote: jobs.length > 1
          ? 'Phone ${n + 1} of ${jobs.length} in this visit: '
                '${[for (final o in jobs) o.orderNumber].join(', ')}'
          : null,
    );
  }
  return doc.save();
}

void _addJobCardPage(
  pw.Document doc,
  ServiceOrder order, {
  required ShopHeader shop,
  required List<String> checklist,
  required bool includeLock,
  required String technicianLabel,
  String? visitNote,
}) {
  final hasLock = order.lockType.isNotEmpty && order.lockType != 'None';
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(18),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(shop, 'SERVICE JOB CARD'),
          if (visitNote != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(visitNote, style: _bold8),
            ),
          _row('Order', order.orderNumber),
          _row('Received', _date(order.receivedAt)),
          _row('Promised', _date(order.expectedCompletionAt)),
          _row('Customer', '${order.customerName}  ${order.customerPhone}'),
          _row('Device', order.device),
          _row('IMEI', order.imei),
          _row(technicianLabel, order.technician),
          pw.Divider(height: 10),
          pw.Text('REPORTED PROBLEM', style: _bold8),
          pw.SizedBox(height: 3),
          pw.Text(
            [
              if (order.complaints.isNotEmpty) order.complaints.join(', '),
              if (order.complaintNotes.isNotEmpty) order.complaintNotes,
            ].join('\n').ifEmpty('-'),
            style: _small,
          ),
          if (order.accessories.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'WITH THE DEVICE: ${order.accessories.join(', ')}',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
          if (hasLock) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              includeLock && order.lockValue.isNotEmpty
                  ? 'LOCK: ${order.lockType} — ${order.lockValue}'
                  : 'LOCK: ${order.lockType}',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
          if (checklist.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('BEFORE HANDING BACK', style: _bold8),
            pw.SizedBox(height: 3),
            pw.Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                for (final item in checklist)
                  pw.Text('[  ] $item', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ],
          pw.Spacer(),
          pw.Divider(height: 1),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                order.advancePaid > 0
                    ? 'Estimate ${rupees(order.estimatedPrice)}  ·  '
                          'Advance ${rupees(order.advancePaid)}  ·  '
                          'Balance ${rupees(order.toCollect)}'
                    : 'Estimate ${rupees(order.estimatedPrice)}',
                style: _bold8,
              ),
              pw.Text(shop.footer, style: const pw.TextStyle(fontSize: 6.5)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Customer signature', style: _small),
              pw.Text('For ${shop.name}', style: _small),
            ],
          ),
        ],
      ),
    ),
  );
}

/// THE BILL — a sale, with its lines, its discount, what was paid, and the
/// amount in words.
Future<Uint8List> buildInvoicePdf({
  required Sale sale,
  required ShopHeader shop,
  List<String> terms = const [],
}) {
  final doc = pw.Document(theme: _theme, title: 'Bill ${sale.invoiceNumber}');
  final totals = sale.totals;
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _header(
          shop,
          sale.cancelled
              ? 'BILL — CANCELLED'
              : (shop.chargesGst ? 'TAX INVOICE' : 'BILL'),
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _row('Bill number', sale.invoiceNumber),
                  _row('Customer', sale.customerName),
                  _row('Phone', sale.customerPhone),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _date(sale.completedAt ?? sale.createdAt),
                  style: _small,
                ),
                pw.Text(sale.paymentMethod, style: _bold8),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Qty', 'Rate', 'Discount', 'Amount'],
          headerStyle: _bold8,
          cellStyle: _small,
          cellAlignments: const {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          data: [
            for (final item in sale.items)
              [
                [
                  item.description,
                  if ((item.imei ?? '').isNotEmpty) 'IMEI ${item.imei}',
                ].join('\n'),
                '${item.effectiveQuantity}',
                formatIndianNumber(item.unitPrice),
                item.discount > 0 ? formatIndianNumber(item.discount) : '-',
                formatIndianNumber(item.total),
              ],
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              children: [
                if (totals.discount > 0) ...[
                  _totalRow('Before discount', rupees(totals.gross)),
                  _totalRow('Discount', '- ${rupees(totals.discount)}'),
                ],
                _totalRow('Total', rupees(totals.total), bold: true),
                if (sale.walletUsed > 0)
                  _totalRow('From wallet', rupees(sale.walletUsed)),
                _totalRow('Paid', rupees(sale.amountPaid)),
                if (sale.balanceDue > 0)
                  _totalRow('Balance due', rupees(sale.balanceDue), bold: true),
                ..._gstRows(
                  shop.chargesGst
                      ? gstInclusive(
                          taxableAmountOf(sale),
                          shop.gstRate,
                          interState: sale.interState,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(amountInWords(totals.total), style: _bold8),
        if (shop.chargesGst && hasMarginSchemeLines(sale))
          pw.Text(
            'Used handsets: GST under the margin scheme, not shown as tax on '
            'this bill.',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
        if (terms.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Divider(height: 1),
          pw.SizedBox(height: 4),
          for (final term in terms)
            pw.Text('· $term', style: const pw.TextStyle(fontSize: 6.5)),
        ],
        pw.SizedBox(height: 18),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(shop.footer, style: const pw.TextStyle(fontSize: 7)),
            pw.Text('For ${shop.name}', style: _small),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

/// THE FINAL BILL — what the customer is handed with their repaired phone,
/// and signs to say they have it back.
Future<Uint8List> buildFinalBillPdf({
  required ServiceOrder order,
  required ShopHeader shop,
}) {
  final doc = pw.Document(
    theme: _theme,
    title: 'Final bill ${order.orderNumber}',
  );
  // What was actually charged, once it is known; the estimate until then.
  final total = order.finalPrice ?? order.estimatedPrice;
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _header(
          shop,
          shop.chargesGst ? 'SERVICE — TAX INVOICE' : 'SERVICE — FINAL BILL',
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _row('Order', order.orderNumber),
                  _row('Customer', order.customerName),
                  _row('Phone', order.customerPhone),
                  _row('Device', order.device),
                  _row('IMEI', order.imei),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 170,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _row('Received', _date(order.receivedAt)),
                  _row('Completed', _date(order.completedAt)),
                  _row('Status', order.status),
                ],
              ),
            ),
          ],
        ),
        _section('Work carried out'),
        for (final complaint in order.complaints)
          pw.Text('· $complaint', style: _small),
        if (order.complaintNotes.isNotEmpty)
          pw.Text(order.complaintNotes, style: _small),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              children: [
                _totalRow(
                  'Service charge',
                  rupees(total),
                  bold: order.advancePaid <= 0,
                ),
                if (order.advancePaid > 0) ...[
                  _totalRow('Less advance', '- ${rupees(order.advancePaid)}'),
                  // More was paid in advance than the charge: the bill says
                  // the difference went back, so it adds up.
                  if (order.advancePaid > total)
                    _totalRow(
                      'Change given back',
                      rupees(order.advancePaid - total),
                      bold: true,
                    )
                  else
                    _totalRow(
                      'Balance to pay',
                      rupees(order.toCollect),
                      bold: true,
                    ),
                ],
                ..._gstRows(
                  shop.chargesGst ? gstInclusive(total, shop.gstRate) : null,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(amountInWords(total), style: _bold8),
        if (order.warrantyUntil != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Repair warranty: ${order.warrantyDays} days, until '
            '${_date(order.warrantyUntil).split(' ').first}. '
            'Covers the work done on this bill.',
            style: _small,
          ),
        ],
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Customer signature — phone received', style: _small),
            pw.Text('For ${shop.name}', style: _small),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(shop.footer, style: const pw.TextStyle(fontSize: 7)),
      ],
    ),
  );
  return doc.save();
}

/// ONE BILL FOR A VISIT — every phone the customer brought, handed back,
/// on one bill: a line per phone with its work and charge, the total, the
/// advances, and what is left to pay.
Future<Uint8List> buildVisitFinalBillPdf({
  required List<ServiceOrder> orders,
  required ShopHeader shop,
}) {
  final first = orders.first;
  final doc = pw.Document(
    theme: _theme,
    title: 'Final bill ${[for (final o in orders) o.orderNumber].join(' ')}',
  );
  num charge(ServiceOrder o) => o.finalPrice ?? o.estimatedPrice;
  final total = orders.fold<num>(0, (t, o) => t + charge(o));
  final advance = orders.fold<num>(0, (t, o) => t + o.advancePaid);
  final balance = orders.fold<num>(0, (t, o) => t + o.toCollect);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _header(
          shop,
          shop.chargesGst ? 'SERVICE — TAX INVOICE' : 'SERVICE — FINAL BILL',
        ),
        _row('Customer', first.customerName),
        _row('Phone', first.customerPhone),
        _row('Orders', [for (final o in orders) o.orderNumber].join(', ')),
        _section('Phones repaired'),
        for (final o in orders)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _totalRow(
                  '${o.orderNumber}  ${o.device}',
                  rupees(charge(o)),
                  bold: true,
                ),
                if (o.imei.isNotEmpty) pw.Text('IMEI ${o.imei}', style: _small),
                pw.Text(
                  [
                    if (o.complaints.isNotEmpty) o.complaints.join(', '),
                    if (o.complaintNotes.isNotEmpty) o.complaintNotes,
                  ].join(' · ').ifEmpty('-'),
                  style: _small,
                ),
                if (o.warrantyUntil != null)
                  pw.Text(
                    'Warranty ${o.warrantyDays} days, until '
                    '${_date(o.warrantyUntil).split(' ').first}',
                    style: _small,
                  ),
              ],
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              children: [
                _totalRow('Total', rupees(total), bold: advance <= 0),
                if (advance > 0) ...[
                  _totalRow('Less advance', '- ${rupees(advance)}'),
                  if (advance > total)
                    _totalRow(
                      'Change given back',
                      rupees(advance - total),
                      bold: true,
                    )
                  else
                    _totalRow('Balance to pay', rupees(balance), bold: true),
                ],
                ..._gstRows(
                  shop.chargesGst ? gstInclusive(total, shop.gstRate) : null,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(amountInWords(total), style: _bold8),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Customer signature — phones received', style: _small),
            pw.Text('For ${shop.name}', style: _small),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(shop.footer, style: const pw.TextStyle(fontSize: 7)),
      ],
    ),
  );
  return doc.save();
}

/// THE PURCHASE DECLARATION — the paper signed when the shop BUYS a used
/// phone. It is the shop's evidence that the seller owned it and that the
/// sale was final, which is what protects the shop if the phone turns out to
/// be stolen or on a loan.
///
/// The seller's signature prints from the pad they signed on; a record saved
/// without one prints a blank line to sign, rather than refusing while the
/// seller is standing there.
Future<Uint8List> buildPurchaseDeclarationPdf({
  required SecondHandDevice device,
  required ShopHeader shop,
  required List<String> terms,
  String staffName = '',
  List<SecondHandDevice> batch = const [],
}) async {
  // Several phones from this seller: each one's details, and the total.
  final phones = batch.length > 1 ? batch : [device];
  final paid = phones.fold<num>(0, (t, d) => t + d.purchasePrice);
  final doc = pw.Document(theme: _theme, title: 'Declaration ${device.title}');

  final signed = await loadSignature(device.sellerSignature);
  final signature = signed == null ? null : pw.MemoryImage(signed);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _header(shop, 'MOBILE PURCHASE & SELLER DECLARATION'),
        pw.Center(
          child: pw.Text(
            'FINAL SALE — NO RETURN, NO BUY-BACK',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
        ),
        _section('Seller'),
        _row('Name', device.sellerName),
        _row('Phone', device.sellerPhone),
        _row('Other phone', device.sellerAltPhone),
        _row('ID', device.sellerIdProof),
        _row('Date', _date(device.purchasedAt ?? device.createdAt)),
        for (final (n, d) in phones.indexed) ...[
          _section(
            phones.length > 1 ? 'Phone ${n + 1} of ${phones.length}' : 'Phone',
          ),
          _row('Device', [d.brand, d.model].join(' ').trim()),
          _row('RAM / storage', d.memory),
          _row('Colour', d.colour),
          _row('IMEI 1', d.imei),
          _row('IMEI 2', d.imei2),
          _row('Serial', d.serial),
          _row('Grade', d.grade ?? ''),
          if (phones.length > 1) _row('Paid', rupees(d.purchasePrice)),
        ],
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Amount paid to seller', style: _small),
                  pw.Text(
                    amountInWords(paid),
                    style: const pw.TextStyle(
                      fontSize: 6.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Text(
                rupees(paid),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _section('The seller declares'),
        for (var i = 0; i < terms.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              '${i + 1}. ${terms[i]}',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (signature != null)
                    pw.SizedBox(height: 34, child: pw.Image(signature))
                  else
                    pw.SizedBox(height: 34),
                  pw.Container(height: 0.6, color: PdfColors.grey600),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "Seller's signature",
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  if (device.agreementAcceptedAt != null)
                    pw.Text(
                      'Read to the seller and agreed on '
                      '${_date(device.agreementAcceptedAt)}',
                      style: const pw.TextStyle(
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (device.sellerIdVerified)
                    pw.Text(
                      'Original photo ID checked by shop staff',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 34),
                  pw.Container(height: 0.6, color: PdfColors.grey600),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'For ${shop.name}',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  if (staffName.isNotEmpty)
                    pw.Text(
                      staffName,
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Two copies to be signed — one kept by the shop, one given to the seller.',
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return doc.save();
}

/// THE LABEL — one 50 × 30 mm sticker: the number as a barcode, the phone,
/// the price, and the number again for when the scanner will not cooperate.
Future<Uint8List> buildLabelPdf({
  required int number,
  required String title,
  String subtitle = '',
  num? price,
  int copies = 1,
}) {
  final doc = pw.Document(theme: _theme, title: 'Label $number');
  for (var i = 0; i < (copies < 1 ? 1 : copies); i++) {
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          50 * PdfPageFormat.mm,
          30 * PdfPageFormat.mm,
        ),
        margin: const pw.EdgeInsets.all(3),
        build: (_) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (title.isNotEmpty) pw.Text(title, maxLines: 1, style: _bold8),
            if (subtitle.isNotEmpty)
              pw.Text(
                subtitle,
                maxLines: 1,
                style: const pw.TextStyle(fontSize: 6.5),
              ),
            pw.SizedBox(height: 2),
            pw.BarcodeWidget(
              barcode: Barcode.code128(),
              data: '$number',
              height: 26,
              drawText: false,
            ),
            pw.SizedBox(height: 1),
            pw.Text('$number', style: const pw.TextStyle(fontSize: 7)),
            if (price != null && price > 0)
              pw.Text(
                rupees(price),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

/// THE REPORT, AS A PAGE TO SEND
///
/// What an owner WhatsApps to a partner or an accountant at closing: the
/// figures for the dates on screen, how the money came in, and what sold.
/// The same numbers as the Reports screen, built from the same functions.
Future<Uint8List> buildShopReportPdf({
  required ShopHeader shop,
  required String rangeLabel,
  required ShopReport report,
  required PaymentSplit split,
  required List<ItemSales> topSellers,
  ExpenseSummary? spent,
}) {
  final doc = pw.Document(theme: _theme, title: 'Report $rangeLabel');
  num collected(bool Function(String) which) => split.methods
      .where((m) => which(m.method))
      .fold<num>(0, (t, m) => t + m.collected);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _header(shop, 'REPORT — $rangeLabel'),
        _section('Figures'),
        for (final f in report.figures)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _totalRow(f.label, rupees(f.amount), bold: true),
                pw.Text(f.note, style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
        _section('How it was paid'),
        if (split.isEmpty) pw.Text('No completed bills.', style: _small),
        for (final m in split.methods)
          _totalRow('${m.method} (${m.bills} bills)', rupees(m.collected)),
        if (split.wallet > 0)
          _totalRow('Customer wallet used', rupees(split.wallet)),
        if (split.owed > 0)
          _totalRow('Still owed by customers', rupees(split.owed)),
        if (spent != null) ...[
          _section('Money out'),
          if (spent.isEmpty) pw.Text('No expenses.', style: _small),
          for (final (kind, amount) in spent.byKind)
            _totalRow(kind, rupees(amount)),
          _totalRow('Total spent', rupees(spent.total), bold: true),
          _totalRow(
            'After expenses',
            rupees(collected((_) => true) - spent.total),
          ),
          _totalRow(
            'Cash left in the drawer',
            rupees(collected((m) => m == 'Cash') - spent.cash),
            bold: true,
          ),
        ],
        _section('Activity'),
        _row('Bills completed', '${report.billsCompleted}'),
        _row('Bills cancelled', '${report.billsCancelled}'),
        _row('Repairs taken in', '${report.jobsTakenIn}'),
        _row('Repairs handed back', '${report.jobsCompleted}'),
        _row('Handsets bought', '${report.handsetsBought}'),
        _row('Handsets sold', '${report.handsetsSold}'),
        _row('Customers added', '${report.customersAdded}'),
        if (topSellers.isNotEmpty) ...[
          _section('What sold'),
          for (final t in topSellers)
            _totalRow('${t.description} × ${t.quantity}', rupees(t.amount)),
        ],
      ],
    ),
  );
  return doc.save();
}

/// The tax inside a GST-inclusive total, as rows under it. Nothing for null.
List<pw.Widget> _gstRows(GstSplit? g) => g == null
    ? const []
    : [
        pw.SizedBox(height: 4),
        _totalRow('Taxable value', rupees(g.taxable)),
        if (g.interState)
          _totalRow('IGST ${g.rate}%', rupees(g.igst))
        else ...[
          _totalRow('CGST ${g.rate / 2}%', rupees(g.cgst)),
          _totalRow('SGST ${g.rate / 2}%', rupees(g.sgst)),
        ],
      ];
