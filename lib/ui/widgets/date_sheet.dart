import 'package:flutter/material.dart';

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
