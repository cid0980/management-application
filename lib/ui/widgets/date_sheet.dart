import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/common/dates.dart';

import '../../l10n/l10n.dart';
import 'input_sheet.dart';

/// PICKING A DAY: FROM THE BOTTOM, WITH THE USUAL ANSWERS FIRST
///
/// Most dates in the shop are one of a few: today, tomorrow, in a couple of
/// days, next week (a repair's promised date, a call-back), or today and
/// yesterday (when a phone was bought). Those are one tap, in a row across
/// the top; the month below is for anything else, and a tap on a day closes
/// the sheet with it. No box in the middle of the screen, no OK button.
///
/// Null if the sheet is swiped away. Only days between [first] and [last]
/// are offered.
Future<DateTime?> pickDateSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
}) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final lo = day(first);
  final hi = day(last);
  DateTime clamp(DateTime d) =>
      d.isBefore(lo) ? lo : (d.isAfter(hi) ? hi : day(d));
  return showInputSheet<DateTime>(
    context: context,
    builder: (sheet) {
      final l10n = sheet.l10n;
      final today = day(DateTime.now());
      final quick = <(String, DateTime, String)>[
        if (hi.isAfter(today)) ...[
          (l10n.today, today, 'today'),
          (l10n.dateTomorrow, today.add(const Duration(days: 1)), 'tomorrow'),
          (l10n.dateInDays(3), today.add(const Duration(days: 3)), 'in3'),
          (l10n.dateNextWeek, today.add(const Duration(days: 7)), 'week'),
        ] else ...[
          (l10n.today, today, 'today'),
          (
            l10n.dateYesterday,
            today.subtract(const Duration(days: 1)),
            'yesterday',
          ),
          (
            l10n.dateDaysAgo(2),
            today.subtract(const Duration(days: 2)),
            'ago2',
          ),
        ],
      ];
      final offered = [
        for (final q in quick)
          if (!q.$2.isBefore(lo) && !q.$2.isAfter(hi)) q,
      ];
      return InputSheet(
        title: title == null ? null : Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (label, d, key) in offered) ...[
                    OutlinedButton(
                      key: Key('date-$key'),
                      onPressed: () => Navigator.of(sheet).pop(d),
                      child: Text(label),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            CalendarDatePicker(
              key: const Key('date-calendar'),
              initialDate: clamp(initial),
              firstDate: lo,
              lastDate: hi,
              onDateChanged: (d) => Navigator.of(sheet).pop(d),
            ),
          ],
        ),
      );
    },
  );
}

/// PICKING A TIME: FROM THE BOTTOM, 12-HOUR, THE USUAL ONES FIRST
///
/// The usual promise times are one tap in a row across the top; the wheel
/// below (hour, minute in fives, AM/PM) is for anything else, then Done. No
/// clock face in the middle of the screen. Null if swiped away.
Future<TimeOfDay?> pickTimeSheet(
  BuildContext context, {
  required TimeOfDay initial,
  String? title,
}) {
  var minute = (initial.minute / 5).round() * 5;
  if (minute == 60) minute = 55;
  var picked = TimeOfDay(hour: initial.hour, minute: minute);
  const quick = [10, 12, 14, 16, 18, 20];
  return showInputSheet<TimeOfDay>(
    context: context,
    builder: (sheet) {
      final l10n = sheet.l10n;
      return InputSheet(
        title: Text(title ?? l10n.pickTimeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final h in quick) ...[
                    OutlinedButton(
                      key: Key('time-$h'),
                      onPressed: () =>
                          Navigator.of(sheet)
                              .pop(TimeOfDay(hour: h, minute: 0)),
                      child: Text(formatTime12(DateTime(2000, 1, 1, h))),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                key: const Key('time-wheel'),
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minuteInterval: 5,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  picked.hour,
                  picked.minute,
                ),
                onDateTimeChanged: (d) =>
                    picked = TimeOfDay(hour: d.hour, minute: d.minute),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            key: const Key('time-done'),
            onPressed: () => Navigator.of(sheet).pop(picked),
            child: Text(l10n.pickTimeDone),
          ),
        ],
      );
    },
  );
}

/// A DAY AND A TIME, EACH ITS OWN BUTTON
///
/// "📅 25/11/2026   🕕 6:00 PM": the day opens the day sheet, the time the
/// time sheet. Used for a repair's dates and an enquiry's call-back. Before,
/// only the day could be picked and the time stayed 18:00.
class DayTimeField extends StatelessWidget {
  const DayTimeField({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.onPicked,
    required this.first,
    required this.last,
    this.defaultHour = 18,
    this.error,
    this.emptyText,
    this.onCleared,
    this.clearTooltip,
  });

  final Widget label;
  final String fieldKey;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final DateTime first;
  final DateTime last;
  final int defaultHour;
  final String? error;

  /// Said when there is no value yet (instead of "Not set").
  final String? emptyText;

  /// Shows an × that clears the value.
  final VoidCallback? onCleared;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final v = value;
    return Padding(
      key: Key(fieldKey),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: label),
              if (v != null && onCleared != null)
                IconButton(
                  key: Key('$fieldKey-clear'),
                  icon: const Icon(Icons.close),
                  tooltip: clearTooltip,
                  onPressed: onCleared,
                ),
            ],
          ),
          if (v == null && emptyText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(emptyText!, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  key: Key('$fieldKey-day'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await pickDateSheet(
                      context,
                      initial: v ?? now,
                      first: first,
                      last: last,
                    );
                    if (d == null) return;
                    onPicked(
                      DateTime(
                        d.year,
                        d.month,
                        d.day,
                        v?.hour ?? defaultHour,
                        v?.minute ?? 0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(v == null ? l10n.notSetTitle : formatDay(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  key: Key('$fieldKey-time'),
                  onPressed: () async {
                    final base = v ?? DateTime.now();
                    final t = await pickTimeSheet(
                      context,
                      initial: v == null
                          ? TimeOfDay(hour: defaultHour, minute: 0)
                          : TimeOfDay(hour: v.hour, minute: v.minute),
                    );
                    if (t == null) return;
                    onPicked(
                      DateTime(
                        base.year,
                        base.month,
                        base.day,
                        t.hour,
                        t.minute,
                      ),
                    );
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    v == null ? l10n.pickTimeButton : formatTime12(v),
                  ),
                ),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
