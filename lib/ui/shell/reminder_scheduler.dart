import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/demo_stores.dart';
import '../../data/enquiry_repository.dart';
import '../../data/reminders/phone_reminders.dart';
import '../../data/reminders/reminder_prefs.dart';
import '../../data/service_repository.dart';
import '../../domain/reminders/morning_summary.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

/// Keeps the phone's reminders in step with the shop's records: a few
/// seconds after a repair or an enquiry changes, the morning summary and the
/// enquiry call-backs are planned again. A tap on a reminder opens its page.
///
/// Draws nothing. Does nothing during a tour (practice data must not set
/// real reminders) or where the app gives it no reminders (tests, the web).
class ReminderScheduler extends StatefulWidget {
  const ReminderScheduler({super.key});

  @override
  State<ReminderScheduler> createState() => _ReminderSchedulerState();
}

class _ReminderSchedulerState extends State<ReminderScheduler> {
  Timer? _soon;
  bool _started = false;
  bool _ready = false;

  T? _maybe<T>({bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phone = _maybe<PhoneReminders>();
    final prefs = _maybe<ReminderPrefs>();
    if (phone == null || prefs == null) return;
    if (!_started) {
      _started = true;
      final router = GoRouter.of(context);
      unawaited(() async {
        try {
          await phone.init(router.go);
          if (prefs.on && !prefs.asked) {
            await prefs.markAsked();
            await phone.askPermission();
          }
        } catch (_) {
          return; // No reminders on this phone: the app works without them.
        }
        _ready = true;
        _replanSoon();
      }());
    }
  }

  void _replanSoon() {
    _soon?.cancel();
    _soon = Timer(const Duration(seconds: 3), _replan);
  }

  Future<void> _replan() async {
    if (!mounted || !_ready) return;
    final phone = _maybe<PhoneReminders>();
    final prefs = _maybe<ReminderPrefs>();
    final service = _maybe<ServiceRepository>();
    final enquiries = _maybe<EnquiryRepository>();
    if (phone == null || prefs == null) return;
    if (_maybe<TourSandbox>()?.active ?? false) return;
    if (!prefs.on || service == null || enquiries == null) {
      await phone.replaceAll(const []);
      return;
    }
    final l10n = context.l10n;
    final now = DateTime.now();
    final at = nextReminderAt(now, prefs.hour, prefs.minute);
    final summary = morningSummary(
      orders: service.orders,
      enquiries: enquiries.enquiries,
      day: at,
    );
    final planned = <PlannedReminder>[
      if (!summary.isEmpty)
        PlannedReminder(
          id: 1,
          at: at,
          title: l10n.reminderMorningTitle,
          body: summaryText(l10n, summary),
          route: summary.route,
        ),
      // Each enquiry due a call back, on its own day at the reminder time.
      for (final e
          in enquiries.enquiries
              .where((e) => !e.closed && e.followUpAt != null)
              .where((e) => e.followUpAt!.isAfter(now))
              .take(20))
        PlannedReminder(
          id: 100 + e.id.hashCode.abs() % 100000,
          at: DateTime(
            e.followUpAt!.year,
            e.followUpAt!.month,
            e.followUpAt!.day,
            prefs.hour,
            prefs.minute,
          ),
          title: l10n.reminderRingBackTitle(
            e.customerName.trim().isNotEmpty
                ? e.customerName.trim()
                : e.customerPhone,
          ),
          body: e.question.trim().isNotEmpty ? e.question.trim() : e.about,
          route: '/enquiries/${e.id}',
        ),
    ];
    await phone.replaceAll(planned);
  }

  @override
  void dispose() {
    _soon?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listened to, so any change to them plans the reminders again.
    _maybe<ServiceRepository>(listen: true);
    _maybe<EnquiryRepository>(listen: true);
    _maybe<ReminderPrefs>(listen: true);
    if (_ready) _replanSoon();
    return const SizedBox.shrink();
  }
}

/// "2 due today · 1 late · 3 ready to hand back · 2 to ring back".
String summaryText(AppLocalizations l10n, MorningSummary s) => [
  if (s.dueToday > 0) l10n.reminderDue(s.dueToday),
  if (s.late > 0) l10n.reminderLate(s.late),
  if (s.ready > 0) l10n.reminderReady(s.ready),
  if (s.ringBack > 0) l10n.reminderRingBack(s.ringBack),
].join(' · ');
