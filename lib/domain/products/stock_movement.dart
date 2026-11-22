/// HOW A STOCK COUNT CHANGES
///
/// Never by writing a new count. Every change is a **movement** with a reason,
/// and the count is what the movements add up to.
///
/// That is not bookkeeping for its own sake. The question the shop actually
/// asks is "the system says three and I have counted five" — and a count with
/// no history has no answer to it. A movement ledger says who took two out on
/// Tuesday and why.
///
/// It also settles the race. Two tills selling the last screen guard at the
/// same moment both read "two in stock" and both wrote "one", and the shop was
/// a guard short with nothing to show where it went. A movement is an append,
/// and the count is read, checked and written in one step around it.
///
/// **The amount is always positive; the direction is the kind.** A negative
/// "received" and a positive "sold" are the same thing written two ways, and a
/// ledger with both in it cannot be added up. A stock-take correction can go
/// either way, so it gets two kinds rather than a signed amount.
library;

import '../common/dates.dart';

enum StockMoveKind {
  /// A delivery from a supplier.
  received,

  /// Sold on a bill. Written when the sale completes, never while it is being
  /// built.
  sold,

  /// Came back. A customer return, or a cancelled bill putting stock back.
  returned,

  /// A stock-take found more than the system believed.
  adjustedUp,

  /// A stock-take found less.
  adjustedDown,

  /// Broken, lost, or written off. Kept apart from an adjustment because the
  /// shop wants to know what it is losing to damage, not just that the count
  /// moved.
  damaged,

  /// Fitted into a customer's phone on a repair — a battery, a display. The
  /// reference is the service order, so the part can be followed to the job.
  usedOnRepair,
}

const Map<StockMoveKind, String> kStockMoveLabels = {
  StockMoveKind.received: 'Received',
  StockMoveKind.sold: 'Sold',
  StockMoveKind.returned: 'Returned',
  StockMoveKind.adjustedUp: 'Stock-take: more than recorded',
  StockMoveKind.adjustedDown: 'Stock-take: less than recorded',
  StockMoveKind.damaged: 'Damaged or written off',
  StockMoveKind.usedOnRepair: 'Used on a repair',
};

/// Which way each kind moves the count.
int stockMoveSign(StockMoveKind kind) => switch (kind) {
  StockMoveKind.received ||
  StockMoveKind.returned ||
  StockMoveKind.adjustedUp => 1,
  StockMoveKind.sold ||
  StockMoveKind.adjustedDown ||
  StockMoveKind.damaged ||
  StockMoveKind.usedOnRepair => -1,
};

class StockMovement {
  const StockMovement({
    required this.kind,
    required this.quantity,
    required this.reason,
    this.reference,
    this.at,
    this.by,
  });

  final StockMoveKind kind;

  /// Always positive. See the library note.
  final int quantity;

  final String reason;

  /// The bill, supplier invoice or stock-take this belongs to, so a line in
  /// the history can be followed.
  final String? reference;

  final DateTime? at;
  final String? by;

  int get signed => stockMoveSign(kind) * quantity;

  Map<String, Object?> toMap() => {
    'kind': kind.name,
    'quantity': quantity,
    'reason': reason,
    'reference': reference,
    'at': at?.toIso8601String(),
    'by': by,
  };

  static StockMovement fromMap(Map<String, Object?> map) => StockMovement(
    kind: _kind(map['kind']),
    quantity: _int(map['quantity']) ?? 0,
    reason: (map['reason'] ?? '').toString().trim(),
    reference: map['reference'] as String?,
    at: normalizeDate(map['at']),
    by: map['by'] as String?,
  );

  /// An unrecognised kind reads as a stock-take correction rather than a sale
  /// or a delivery: it is the kind that claims least about why the count
  /// moved.
  static StockMoveKind _kind(Object? raw) => switch (raw?.toString()) {
    'received' => StockMoveKind.received,
    'sold' => StockMoveKind.sold,
    'returned' => StockMoveKind.returned,
    'adjustedUp' => StockMoveKind.adjustedUp,
    'adjustedDown' => StockMoveKind.adjustedDown,
    'damaged' => StockMoveKind.damaged,
    'usedOnRepair' => StockMoveKind.usedOnRepair,
    _ => StockMoveKind.adjustedUp,
  };

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// Why a movement was refused.
enum StockRefusal {
  /// Zero or negative. A movement of nothing is a mistake, not a no-op — it
  /// would sit in the history looking like something happened.
  notAQuantity,

  /// It would take the count below zero.
  ///
  /// Refused, not clamped to zero. A count is what the shop believes it has,
  /// and a negative count is a belief that is certainly wrong; clamping hides
  /// the discrepancy instead of making somebody look at it.
  insufficientStock,

  /// No reason given. "Why is the count three" has no answer if the lines in
  /// the history do not say.
  noReason,
}

const Map<StockRefusal, String> kStockRefusalMessages = {
  StockRefusal.notAQuantity: 'Enter a quantity above zero',
  StockRefusal.insufficientStock:
      'There is not that much on the shelf — count it, or adjust the stock '
      'first',
  StockRefusal.noReason: 'Say what this stock movement is for',
};

class StockMoveResult {
  const StockMoveResult.allowed(this.newCount) : refusal = null, message = null;

  StockMoveResult.refused(StockRefusal this.refusal, this.newCount)
    : message = kStockRefusalMessages[refusal];

  final StockRefusal? refusal;
  final String? message;

  /// The count after the movement, or the count left untouched on a refusal.
  final int newCount;

  bool get allowed => refusal == null;
}

/// Whether a movement may be applied to [count], and what the count becomes.
///
/// Pure. The repository does the read-check-write around it; this decides.
StockMoveResult applyStockMove(int count, StockMovement move) {
  if (move.quantity <= 0) {
    return StockMoveResult.refused(StockRefusal.notAQuantity, count);
  }
  if (move.reason.trim().isEmpty) {
    return StockMoveResult.refused(StockRefusal.noReason, count);
  }
  final next = count + move.signed;
  if (next < 0) {
    return StockMoveResult.refused(StockRefusal.insufficientStock, count);
  }
  return StockMoveResult.allowed(next);
}

/// The count the history adds up to.
///
/// Used to check the stored count rather than replace it: the stored value is
/// what the till reads, and recomputing it from a year of movements to sell a
/// screen guard would be absurd. When the two disagree the record is broken,
/// and the detail page says so instead of picking one to believe.
int countFromMovements(Iterable<StockMovement> moves) =>
    moves.fold<int>(0, (sum, m) => sum + m.signed);

/// The movement a stock-take correction becomes.
///
/// Null when the counted number matches what was recorded — nothing moved, and
/// a zero-quantity line in the history would look like something had.
StockMovement? stockTakeMovement({
  required int recorded,
  required int counted,
  required String reason,
  DateTime? at,
}) {
  if (counted == recorded) return null;
  final delta = counted - recorded;
  return StockMovement(
    kind: delta > 0 ? StockMoveKind.adjustedUp : StockMoveKind.adjustedDown,
    quantity: delta.abs(),
    reason: reason,
    at: at,
  );
}
