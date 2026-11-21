import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/wallet.dart';

WalletMove _credit(num amount, {String reason = 'Part-exchange difference'}) =>
    WalletMove(kind: WalletMoveKind.credit, amount: amount, reason: reason);

WalletMove _debit(num amount, {String reason = 'Against bill INV-1'}) =>
    WalletMove(kind: WalletMoveKind.debit, amount: amount, reason: reason);

void main() {
  group('direction is the kind, never a sign', () {
    test('a credit adds and a debit takes away', () {
      expect(_credit(300).signed, 300);
      expect(_debit(300).signed, -300);
    });
  });

  group('a move below zero is refused, not clamped', () {
    test('spending more than the wallet holds leaves the balance alone', () {
      final result = applyMove(300, _debit(500));
      expect(result.allowed, isFalse);
      expect(result.refusal, WalletRefusal.insufficientBalance);
      // The 200 the shop would otherwise never find.
      expect(result.newBalance, 300);
      expect(result.refusalMessage, contains('take the rest another way'));
    });

    test('spending exactly the balance is allowed, down to zero', () {
      final result = applyMove(300, _debit(300));
      expect(result.allowed, isTrue);
      expect(result.newBalance, 0);
    });

    test('an empty wallet cannot be spent from at all', () {
      expect(applyMove(0, _debit(1)).allowed, isFalse);
    });
  });

  group('a move has to be a move', () {
    test('zero is a mistake, not a no-op', () {
      final result = applyMove(300, _credit(0));
      expect(result.allowed, isFalse);
      expect(result.refusal, WalletRefusal.notAnAmount);
    });

    test('a negative amount is refused — the kind carries the direction', () {
      expect(applyMove(300, _credit(-100)).allowed, isFalse);
      expect(applyMove(300, _debit(-100)).allowed, isFalse);
    });

    test('an unexplained move is refused', () {
      final result = applyMove(300, _credit(100, reason: '   '));
      expect(result.allowed, isFalse);
      expect(result.refusal, WalletRefusal.noReason);
    });
  });

  test('credit goes in', () {
    final result = applyMove(0, _credit(350));
    expect(result.allowed, isTrue);
    expect(result.newBalance, 350);
  });

  group('the history should add up to the stored balance', () {
    test('an empty history is zero', () {
      expect(balanceFromHistory(const []), 0);
    });

    test('credits and debits net out', () {
      expect(
        balanceFromHistory([_credit(500), _debit(200), _credit(100)]),
        400,
      );
    });
  });

  group('a wallet covers what it can, not all or nothing', () {
    test('a short wallet covers its balance and the rest is taken elsewhere',
        () {
      expect(walletCoverage(300, 500), 300);
    });

    test('a wallet with enough covers the whole bill', () {
      expect(walletCoverage(900, 500), 500);
    });

    test('nothing to cover, or nothing to cover it with', () {
      expect(walletCoverage(0, 500), 0);
      expect(walletCoverage(300, 0), 0);
      expect(walletCoverage(-50, 500), 0);
    });
  });

  group('a history line read back out of storage', () {
    test('a move survives a round trip', () {
      final move = WalletMove(
        kind: WalletMoveKind.debit,
        amount: 450,
        reason: 'Paid against INV-20260304-007',
        reference: 'sale-7',
        at: DateTime(2026, 3, 4, 11, 30),
        by: 'uid-1',
      );
      final back = WalletMove.fromMap(move.toMap());

      expect(back.kind, WalletMoveKind.debit);
      expect(back.amount, 450);
      expect(back.reason, 'Paid against INV-20260304-007');
      expect(back.reference, 'sale-7');
      expect(back.at, DateTime(2026, 3, 4, 11, 30));
      expect(back.by, 'uid-1');
    });

    test('the direction is the kind, so a negative amount comes back positive',
        () {
      final back = WalletMove.fromMap({
        'kind': 'debit',
        'amount': -450,
        'reason': 'Written by an older build',
      });

      expect(back.amount, 450);
      // -450 as a debit would have added to the balance.
      expect(back.signed, -450);
    });

    test('an amount stored as text is still an amount', () {
      expect(WalletMove.fromMap({
        'kind': 'credit',
        'amount': '1,250',
        'reason': 'Part-exchange difference',
      }).amount, 1250);
    });

    test('a kind this build does not know reads as a credit, not an exception',
        () {
      // The stored balance is what the till reads; the history is for showing.
      // A line nobody can parse still has to appear.
      final back = WalletMove.fromMap({
        'kind': 'adjustment_v2',
        'amount': 100,
        'reason': 'Written by a newer build',
      });

      expect(back.kind, WalletMoveKind.credit);
    });

    test('an empty reference is null, not an empty string to open', () {
      expect(
        WalletMove.fromMap({'kind': 'credit', 'amount': 1, 'reference': '  '})
            .reference,
        isNull,
      );
    });

    test('the history still adds up after a round trip', () {
      final moves = [
        WalletMove(kind: WalletMoveKind.credit, amount: 500, reason: 'Deposit'),
        WalletMove(kind: WalletMoveKind.debit, amount: 200, reason: 'Bill'),
      ].map((m) => WalletMove.fromMap(m.toMap()));

      expect(balanceFromHistory(moves), 300);
    });
  });
}
