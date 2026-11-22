/// DOCUMENT NUMBERS
///
/// Label numbers, invoice numbers and service-order numbers all come from an
/// **atomic counter**, never from counting documents.
///
/// Counting was the original implementation and it broke in the only way it
/// could: two staff saving at the same moment both read "there are 412
/// records", both wrote 413, and the scanner then opened the wrong record for
/// one of them. A label is physical — it is stuck to a phone and handed over —
/// so a duplicate is not a display bug, it is two phones the shop cannot tell
/// apart.
///
/// The counter is read and incremented inside a transaction. This module does
/// not do the transaction; it says what the next value IS, and how it is
/// formatted, so both are stated in one place and tested.
library;

/// Labels start here. Below this are numbers the shop printed by hand years
/// ago, and a scan of one of those must not resolve to a new record.
const int kFirstLabelNumber = 26001;

/// The next value of a counter, given what it currently holds.
///
/// A counter that does not exist yet, or holds something unusable, starts at
/// [start]. It never goes backwards: a counter that somehow reads lower than
/// [start] is treated as absent, because handing out 5 when 26001 labels have
/// been printed is worse than skipping numbers.
int nextCounterValue(Object? current, {int start = 1}) {
  final value = switch (current) {
    int i => i,
    num n => n.toInt(),
    String s => int.tryParse(s.trim()) ?? 0,
    _ => 0,
  };
  return value < start ? start : value + 1;
}

/// `INV-20260304-007` — the shop's invoice number.
///
/// The date is in it because that is how the shop files them, and the sequence
/// resets per day, which is what the three digits are for. A day that somehow
/// passes 999 keeps counting rather than wrapping: a wrong number that is
/// unique beats a tidy one that is not.
String formatDocumentNumber(String prefix, DateTime day, int sequence) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$prefix-$y$m$d-${sequence.toString().padLeft(3, '0')}';
}

String invoiceNumber(DateTime day, int sequence) =>
    formatDocumentNumber('INV', day, sequence);

String serviceOrderNumber(DateTime day, int sequence) =>
    formatDocumentNumber('SO', day, sequence);

/// `SO-20261122-T134215` — a job taken in while the counter could not be
/// reached (the shop's internet was down).
///
/// The counter is a server transaction and cannot run offline; refusing the
/// intake would turn a customer away at the counter. So the job gets a number
/// of a different shape: `T` and the time to the second. It can never equal a
/// counted number (those are digits only), and two can only clash if two
/// phones take a job in offline in the same second.
String offlineServiceOrderNumber(DateTime at) {
  final base = formatDocumentNumber('SO', at, 0);
  final day = base.substring(0, base.lastIndexOf('-'));
  final h = at.hour.toString().padLeft(2, '0');
  final mi = at.minute.toString().padLeft(2, '0');
  final se = at.second.toString().padLeft(2, '0');
  return '$day-T$h$mi$se';
}

/// The counter key for a per-day sequence.
///
/// Per day, so the sequence resets without anyone resetting it, and so two
/// days cannot contend for the same counter document.
String dailyCounterKey(String name, DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$name-$y$m$d';
}

/// A counter that hands out numbers one at a time.
///
/// In the app this is backed by a Firestore transaction on `counters/*`. The
/// in-memory implementation is what the screens run against until then, and
/// what the tests drive.
abstract class NumberCounter {
  /// The next value of [key], having consumed it. Never returns the same value
  /// twice for the same key.
  Future<int> next(String key, {int start = 1});
}

class InMemoryCounter implements NumberCounter {
  InMemoryCounter([Map<String, int>? initial]) : _values = {...?initial};

  final Map<String, int> _values;

  @override
  Future<int> next(String key, {int start = 1}) async {
    final value = nextCounterValue(_values[key], start: start);
    _values[key] = value;
    return value;
  }

  /// What a key holds, without consuming anything. For tests and for showing
  /// "next label: 26043" on the labels page.
  int? peek(String key) => _values[key];
}
