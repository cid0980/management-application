import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

Sale _s({
  List<SaleItem>? items,
  String method = 'Cash',
  num paid = 0,
  num walletUsed = 0,
  String? customerId = 'c-1',
  String customerPhone = '9876543210',
  SaleStatus status = SaleStatus.draft,
}) =>
    Sale(
      id: 's',
      customerId: customerId,
      customerPhone: customerPhone,
      items: items ??
          const [SaleItem(description: 'Screen guard', unitPrice: 500)],
      paymentMethod: method,
      amountPaid: paid,
      walletUsed: walletUsed,
      status: status,
    );

void main() {
  group('a financed sale leaves the customer owing nothing', () {
    test('whatever was handed over at the counter', () {
      // The customer pays the financier; the financier pays the shop. What is
      // outstanding is not this number.
      final sale = _s(method: 'Bajaj Finance', paid: 2000);
      expect(sale.total, 500);
      expect(sale.isFinanced, isTrue);
      expect(sale.balanceDue, 0);
      expect(sale.settled, isTrue);
    });

    test('even with nothing paid at all', () {
      expect(_s(method: 'IDFC Finance', paid: 0).balanceDue, 0);
    });

    test('every financier the shop uses', () {
      for (final m in [
        'Bajaj Finance',
        'IDFC Finance',
        'Samsung Finance',
        'Poonawalla',
        'TVS Credit',
      ]) {
        expect(_s(method: m, paid: 0).balanceDue, 0, reason: m);
      }
    });
  });

  group('a direct sale leaves what is not paid', () {
    test('a short payment leaves a balance', () {
      expect(_s(method: 'Cash', paid: 300).balanceDue, 200);
    });

    test('paid in full leaves nothing', () {
      expect(_s(method: 'UPI', paid: 500).balanceDue, 0);
      expect(_s(method: 'UPI', paid: 500).settled, isTrue);
    });

    test('an overpayment is not a negative balance', () {
      expect(_s(method: 'Cash', paid: 900).balanceDue, 0);
    });
  });

  test('the stock lines are the ones completing the sale has to write', () {
    final sale = _s(items: const [
      SaleItem(description: 'Handset', unitPrice: 18500,
          source: LineSource.secondHand, recordId: 'sh-1'),
      SaleItem(description: 'Fitting', unitPrice: 100),
    ]);
    expect(sale.stockLines.map((l) => l.recordId), ['sh-1']);
  });

  group('validation', () {
    test('a complete bill is valid', () {
      expect(validateSale(_s(paid: 500)).isValid, isTrue);
    });

    test('an empty bill is not', () {
      expect(validateSale(_s(items: const [])).errors, contains('items'));
    });

    test('a customer is needed — a balance belongs to somebody', () {
      expect(
        validateSale(_s(customerId: null, customerPhone: '')).errors,
        contains('customer'),
      );
    });

    test('a line needs saying what it is', () {
      expect(
        validateSale(_s(items: const [SaleItem(description: '  ', unitPrice: 1)]))
            .errors,
        contains('items'),
      );
    });

    test('a negative price is refused', () {
      expect(
        validateSale(_s(items: const [SaleItem(description: 'x', unitPrice: -1)]))
            .errors,
        contains('items'),
      );
    });

    test('more from the wallet than the whole bill is refused', () {
      expect(
        validateSale(_s(paid: 600, walletUsed: 600)).errors,
        contains('walletUsed'),
      );
      expect(
        validateSale(_s(paid: 500, walletUsed: 300)).errors,
        isNot(contains('walletUsed')),
      );
    });

    test('a balance warns but never blocks the sale', () {
      final result = validateSale(_s(paid: 300));
      expect(result.isValid, isTrue);
      expect(result.warnings['amountPaid'], contains('only an admin'));
    });

    test('a financed sale says it will not reach Due Payments', () {
      final result = validateSale(_s(method: 'Bajaj Finance'));
      expect(result.isValid, isTrue);
      expect(result.warnings['paymentMethod'], contains('Due Payments'));
    });

    test('change to give back is pointed out', () {
      final result = validateSale(_s(paid: 900));
      expect(result.warnings['amountPaid'], contains('to give back'));
    });

    test('a method this build has never seen is treated as a direct payment',
        () {
      // Not refused — the shop may have added a financier. But it cannot be
      // KNOWN to be finance, so the safe reading is direct, and the counter
      // is told.
      final result = validateSale(_s(method: 'Some New Financier', paid: 0));
      expect(result.isValid, isTrue);
      expect(result.warnings['paymentMethod'], contains('direct payment'));
      expect(_s(method: 'Some New Financier', paid: 0).balanceDue, 500);
    });

    test('a capped discount is flagged', () {
      final result = validateSale(_s(
        items: const [SaleItem(description: 'Cable', unitPrice: 200,
            discount: 500)],
      ));
      expect(result.warnings['items'], contains('capped'));
    });
  });

  group('every read normalizes', () {
    test('an unrecognised status reads as a draft — the state that moves '
        'nothing', () {
      expect(Sale.fromMap('s', {'status': 'whatever'}).status,
          SaleStatus.draft);
      expect(Sale.fromMap('s', const {}).status, SaleStatus.draft);
      expect(Sale.fromMap('s', {'status': 'completed'}).status,
          SaleStatus.completed);
    });

    test('a number written with +91 reads as ten digits', () {
      expect(Sale.fromMap('s', {'customerPhone': '+91 90000 11111'})
          .customerPhone, '9000011111');
    });

    test('an amount written as a string reads as a number', () {
      expect(Sale.fromMap('s', {'amountPaid': '18,500'}).amountPaid, 18500);
    });

    test('a bill written here reads back the same', () {
      final sale = _s(
        items: const [
          SaleItem(description: 'Handset', unitPrice: 18500,
              source: LineSource.secondHand, recordId: 'sh-1'),
        ],
        method: 'Bajaj Finance',
        paid: 2000,
        status: SaleStatus.completed,
      );
      final back = Sale.fromMap('s', sale.toMap());
      expect(back.items, hasLength(1));
      expect(back.items.single.source, LineSource.secondHand);
      expect(back.paymentMethod, 'Bajaj Finance');
      expect(back.status, SaleStatus.completed);
      expect(back.balanceDue, 0);
    });
  });

  group('search', () {
    final sale = Sale(
      id: 's',
      invoiceNumber: 'INV-20260304-007',
      customerName: 'Ramesh K',
      customerPhone: '9876543210',
      paymentMethod: 'UPI',
      items: const [
        SaleItem(description: 'Samsung A54', unitPrice: 18500,
            source: LineSource.secondHand, imei: '354879104523681'),
      ],
    );

    test('by invoice, customer, item, IMEI or method', () {
      for (final q in [
        'INV-20260304-007',
        'ramesh',
        'samsung',
        '354879104523681',
        'upi',
      ]) {
        expect(sale.matches(q), isTrue, reason: q);
      }
    });

    test('a word that is nowhere on the bill does not match', () {
      expect(sale.matches('iphone'), isFalse);
    });
  });
}
