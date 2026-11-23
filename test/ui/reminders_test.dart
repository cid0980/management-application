import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/reminders/morning_summary.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/shell/reminder_scheduler.dart';

void main() {
  test('the morning reminder says only what there is', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(
      summaryText(
        l,
        const MorningSummary(dueToday: 2, late: 1, ready: 3, ringBack: 0),
      ),
      '2 due today · 1 late · 3 ready to hand back',
    );
    expect(
      summaryText(
        l,
        const MorningSummary(dueToday: 0, late: 0, ready: 0, ringBack: 2),
      ),
      '2 to ring back',
    );
  });
}
