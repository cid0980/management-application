/// Dates arrive from Firestore as a `Timestamp` on some documents and as an
/// ISO string on others, depending on which build wrote them. Every read goes
/// through here, so nothing downstream has to care which it got.
library;

/// A [DateTime] from either shape, or null when there isn't a usable one.
///
/// Accepts a `DateTime`, an ISO-8601 string, epoch milliseconds, or anything
/// exposing `toDate()` — which is what `cloud_firestore`'s `Timestamp` does,
/// so this works without importing Firestore into the domain layer.
DateTime? normalizeDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  try {
    final dynamic d = (value as dynamic).toDate();
    return d is DateTime ? d : null;
  } catch (_) {
    return null;
  }
}

/// Whether two moments fall on the same calendar day, in local time.
///
/// Local, not UTC: "today's takings" means the day the shop was open, and a
/// sale at nine in the evening in Chennai is not tomorrow's.
bool isSameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

/// A span of days, inclusive at both ends.
///
/// Inclusive because that is what a shop means by "the 1st to the 7th", and
/// the off-by-one the other way round silently drops the last day of every
/// report — which is the day somebody is usually looking for.
///
/// The bounds are snapped to the start and the end of their days, so a range
/// built from `DateTime.now()` does not cut this morning off its own report.
class DateRange {
  DateRange(DateTime from, DateTime to)
    : start = _startOfDay(from.isAfter(to) ? to : from),
      end = _endOfDay(from.isAfter(to) ? from : to);

  /// Today, from midnight to midnight.
  factory DateRange.day(DateTime day) => DateRange(day, day);

  /// The last [days] days, today included — so "7 days" is today and the six
  /// before it, not today and seven before it.
  factory DateRange.lastDays(int days, {required DateTime ending}) => DateRange(
    ending.subtract(Duration(days: days < 1 ? 0 : days - 1)),
    ending,
  );

  /// The calendar month [day] falls in.
  factory DateRange.month(DateTime day) => DateRange(
    DateTime(day.year, day.month),
    DateTime(day.year, day.month + 1, 0),
  );

  final DateTime start;
  final DateTime end;

  bool contains(DateTime? at) =>
      at != null && !at.isBefore(start) && !at.isAfter(end);

  /// How many days the range covers, both ends included.
  int get days => end.difference(start).inDays + 1;

  bool get isOneDay => days == 1;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  @override
  String toString() =>
      'DateRange(${start.toIso8601String()} … '
      '${end.toIso8601String()})';
}

/// "6:00 PM" — the 12-hour clock, as people in the shop say a time.
String formatTime12(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "25/11/2026, 6:00 PM".
String formatDayTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}, ${formatTime12(d)}';

/// "25/11/2026".
String formatDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
