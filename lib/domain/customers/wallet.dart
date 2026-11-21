/// THE CUSTOMER WALLET
///
/// Shop credit: a part-exchange that came out in the shop's favour, a refund
/// the customer chose to leave on account, a deposit against a repair. It is
/// money the shop owes, so the rules are strict in one direction only.
///
/// **A move that would take the balance below zero is refused.** Not clamped
/// to zero — refused, and the till says so. Clamping is how 300 rupees of
/// credit paid for a 500 rupee accessory and the shop never found the other
/// 200. If the wallet cannot cover it, the rest is taken another way, and that
/// decision belongs to the person at the counter.
///
/// **Every move stamps `updatedAt`.** That stamp is how the other till learns
/// this customer changed: the collection cache refreshes on it. A balance
/// written without it is a balance the second till keeps showing the old
/// value of, which is how one credit got spent twice.
///
/// The move itself runs in a transaction — read the balance, check it, write
/// the new one — because two tills spending the same credit at the same moment
/// is exactly the race this is for. The transaction is the repository's job;
/// what is ALLOWED is this module's.
library;

import '../common/dates.dart';

/// Which way the money went.
enum WalletMoveKind {
  /// Into the wallet: part-exchange difference, refund left on account,
  /// deposit.
  credit,

  /// Out of the wallet: spent against a bill.
  debit,
}

/// One line of the wallet's history.
class WalletMove {
  const WalletMove({
    required this.kind,
    required this.amount,
    required this.reason,
    this.reference,
    this.at,
    this.by,
  });

  final WalletMoveKind kind;

  /// Always positive. The direction is [kind], never a sign — a negative
  /// credit and a positive debit are the same thing written two ways, and the
  /// ledger could not be added up.
  final num amount;

  final String reason;

  /// The sale, service order or purchase this move belongs to, so a line in
  /// the history can be opened.
  final String? reference;

  final DateTime? at;
  final String? by;

  /// What this move does to a balance.
  num get signed => kind == WalletMoveKind.credit ? amount : -amount;

  /// Read back out of storage.
  ///
  /// The stored balance is what the till reads, so a history line is for
  /// showing and for the mismatch check in [balanceFromHistory] — which is
  /// why a `kind` this build does not recognise reads as a credit rather than
  /// throwing. A line nobody can parse still has to appear: a wallet history
  /// with a gap in it is how an argument at the counter becomes unwinnable.
  static WalletMove fromMap(Map<String, Object?> map) => WalletMove(
    kind: map['kind'] == WalletMoveKind.debit.name
        ? WalletMoveKind.debit
        : WalletMoveKind.credit,
    // Always positive on the way in, whatever was written: the direction
    // is the kind, never the sign.
    amount: _amount(map['amount']),
    reason: (map['reason'] ?? '').toString(),
    reference: (map['reference'] as String?)?.trim().isEmpty ?? true
        ? null
        : (map['reference'] as String).trim(),
    at: normalizeDate(map['at']),
    by: (map['by'] as String?),
  );

  static num _amount(Object? value) {
    final parsed = switch (value) {
      num n => n,
      String s => num.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      _ => 0,
    };
    return parsed < 0 ? -parsed : parsed;
  }

  Map<String, Object?> toMap() => {
    'kind': kind.name,
    'amount': amount,
    'reason': reason,
    'reference': reference,
    'at': at?.toIso8601String(),
    'by': by,
  };
}

/// Why a move was refused. The till shows this; it is not a log line.
enum WalletRefusal {
  /// Zero or negative. A move of nothing is a mistake, not a no-op: it would
  /// sit in the history looking like something happened.
  notAnAmount,

  /// The wallet does not hold enough. The balance is left alone and the rest
  /// is taken another way.
  insufficientBalance,

  /// No reason given. An unexplained line in someone's wallet history is how
  /// an argument at the counter becomes unwinnable.
  noReason,
}

const Map<WalletRefusal, String> kWalletRefusalMessages = {
  WalletRefusal.notAnAmount: 'A wallet move needs an amount above zero',
  WalletRefusal.insufficientBalance:
      'The wallet does not hold that much — take the rest another way',
  WalletRefusal.noReason: 'Say what this wallet move is for',
};

class WalletMoveResult {
  const WalletMoveResult.allowed(this.newBalance)
    : refusal = null,
      refusalMessage = null;

  WalletMoveResult.refused(WalletRefusal this.refusal, this.newBalance)
    : refusalMessage = kWalletRefusalMessages[refusal];

  final WalletRefusal? refusal;
  final String? refusalMessage;

  /// The balance after the move, or the balance left untouched on a refusal.
  final num newBalance;

  bool get allowed => refusal == null;
}

/// Whether a move may be applied to [balance], and what the balance becomes.
///
/// Pure. The repository does the transaction around it; this decides.
WalletMoveResult applyMove(num balance, WalletMove move) {
  if (move.amount <= 0) {
    return WalletMoveResult.refused(WalletRefusal.notAnAmount, balance);
  }
  if (move.reason.trim().isEmpty) {
    return WalletMoveResult.refused(WalletRefusal.noReason, balance);
  }
  final next = balance + move.signed;
  if (next < 0) {
    // Refused, not clamped. See the library note.
    return WalletMoveResult.refused(WalletRefusal.insufficientBalance, balance);
  }
  return WalletMoveResult.allowed(next);
}

/// The balance the history adds up to.
///
/// Used to check the stored balance rather than to replace it: the stored
/// value is what the till reads, and recomputing it on every open would mean
/// loading a year of history to sell a screen guard. When the two disagree,
/// the record is broken and the detail page says so instead of picking one.
num balanceFromHistory(Iterable<WalletMove> moves) =>
    moves.fold<num>(0, (sum, m) => sum + m.signed);

/// How much of [total] this wallet can cover.
///
/// The counter asks this before offering "pay from wallet": a wallet with 300
/// against a 500 bill covers 300, and the remaining 200 is taken another way.
/// Offering all-or-nothing is how staff stopped using the wallet at all.
num walletCoverage(num balance, num total) {
  if (balance <= 0 || total <= 0) return 0;
  return balance < total ? balance : total;
}
