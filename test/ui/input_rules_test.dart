import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/money.dart';
import 'package:fm_shop/domain/customers/wallet.dart';
import 'package:fm_shop/domain/inventory/purchase_costing.dart';
import 'package:fm_shop/ui/widgets/input_rules.dart';

void main() {
  Future<String> typeInto(
    WidgetTester tester,
    List<dynamic> rule,
    String text,
  ) async {
    final c = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: c, inputFormatters: rule.cast()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), text);
    return c.text;
  }

  group('money boxes', () {
    testWidgets('no minus, no letters, two decimals, eight digits', (
      tester,
    ) async {
      expect(await typeInto(tester, moneyInput(), '-50'), '50');
      expect(await typeInto(tester, moneyInput(), 'abc'), '');
      expect(await typeInto(tester, moneyInput(), '₹1,500'), '1500');
      expect(await typeInto(tester, moneyInput(), '12.34'), '12.34');
      // Typed whole, a third decimal or a ninth digit is refused.
      expect(await typeInto(tester, moneyInput(), '12.345'), '');
      expect(await typeInto(tester, moneyInput(), '99999999999999999999'), '');
      expect(await typeInto(tester, moneyInput(), '99999999'), '99999999');
    });

    testWidgets('quantities and codes are digits only', (tester) async {
      expect(await typeInto(tester, wholeNumberInput(), '1.5'), '15');
      expect(await typeInto(tester, wholeNumberInput(), '-3'), '3');
      expect(await typeInto(tester, inputRuleFor('imei')!, 'AB35C1'), '351');
    });
  });

  group('phone boxes hold the ten digits', () {
    testWidgets('pasted with +91, 0, spaces or dashes: just the number', (
      tester,
    ) async {
      final rule = inputRuleFor('customerPhone')!;
      expect(await typeInto(tester, rule, '9876543210'), '9876543210');
      expect(await typeInto(tester, rule, '+91 98765 43210'), '9876543210');
      expect(await typeInto(tester, rule, '098765-43210'), '9876543210');
      expect(await typeInto(tester, rule, '919876543210'), '9876543210');
      expect(await typeInto(tester, rule, '+9'), '+9');
    });

    testWidgets('an eleventh digit, letters or another code are refused', (
      tester,
    ) async {
      final rule = phoneInput();
      expect(await typeInto(tester, rule, '98765432101'), '');
      expect(await typeInto(tester, rule, '98765abc10'), '');
      expect(await typeInto(tester, rule, '+44 7700 900123'), '');
    });

    test('every phone box counts to 10, IMEI to 15', () {
      for (final key in [
        'phone',
        'altPhone',
        'customerPhone',
        'sellerPhone',
        'sellerAltPhone',
      ]) {
        expect(maxDigitsFor(key), kPhoneDigits, reason: key);
        expect(inputRuleFor(key), isNotNull, reason: key);
      }
      expect(maxDigitsFor('imei'), 15);
      expect(maxDigitsFor('name'), isNull);
    });

    test('number-only boxes open the number pad; money has a point key', () {
      for (final key in [
        'estimatedPrice',
        'advancePaid',
        'sellingPrice',
        'purchasePrice',
        'askingPrice',
        'mrp',
        'budget',
        'quotedPrice',
      ]) {
        expect(keyboardFor(key), moneyKeyboard, reason: key);
      }
      expect(moneyKeyboard.decimal, isTrue);
      for (final key in [
        'imei',
        'imei2',
        'batteryHealth',
        'stock',
        'reorderLevel',
        'openingStock',
      ]) {
        expect(keyboardFor(key), TextInputType.number, reason: key);
      }
      for (final key in [
        'phone',
        'altPhone',
        'customerPhone',
        'sellerPhone',
        'sellerAltPhone',
      ]) {
        expect(keyboardFor(key), TextInputType.phone, reason: key);
      }
      expect(keyboardFor('name'), isNull);
    });

    testWidgets('the box shows how many digits are in and stops at 10', (
      tester,
    ) async {
      final c = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: c,
              inputFormatters: phoneInput(),
              maxLength: kPhoneDigits,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '98765');
      await tester.pump();
      expect(find.text('5/10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();
      expect(find.text('10/10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '98765432109');
      await tester.pump();
      expect(c.text, '9876543210');
    });
  });

  group('paise', () {
    test('sums land on the paisa, whole amounts stay whole', () {
      expect(roundMoney(10.1 + 20.2), 30.3);
      expect(roundMoney(0.1 + 0.2), 0.3);
      expect(roundMoney(100.0), 100);
      expect(asAmount('12.345'), 12.35);
      expect(asAmount(300.005), 300.01);
    });

    test('the wallet: 10.10 + 20.20 can all be spent', () {
      var balance = applyMove(
        0,
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 10.10,
          reason: 'x',
        ),
      ).newBalance;
      balance = applyMove(
        balance,
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 20.20,
          reason: 'x',
        ),
      ).newBalance;
      expect(balance, 30.3);
      final spend = applyMove(
        balance,
        const WalletMove(
          kind: WalletMoveKind.debit,
          amount: 30.30,
          reason: 'x',
        ),
      );
      expect(spend.allowed, isTrue);
      expect(spend.newBalance, 0);
    });

    test('the wallet refuses an absurd amount', () {
      final r = applyMove(
        0,
        const WalletMove(
          kind: WalletMoveKind.credit,
          amount: 1e20,
          reason: 'x',
        ),
      );
      expect(r.refusal, WalletRefusal.notAnAmount);
    });
  });
}
