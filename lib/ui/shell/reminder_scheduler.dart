import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../data/demo_stores.dart';
import '../../data/enquiry_repository.dart';
import '../../data/product_repository.dart';
import '../../data/reminders/phone_reminders.dart';
import '../../data/reminders/reminder_prefs.dart';
import '../../data/service_repository.dart';
import '../../domain/reminders/morning_summary.dart';
import '../../domain/reminders/repair_alarms.dart';
import '../../domain/service/service_order.dart';
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
    if ((!prefs.on && !prefs.alarms) || service == null || enquiries == null) {
      await phone.replaceAll(const []);
      return;
    }
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final auth = _maybe<AuthState>();
    final myUid = auth?.user?.uid ?? '';
    final isAdmin = auth?.isAdmin ?? false;
    final now = DateTime.now();
    final at = nextReminderAt(now, prefs.hour, prefs.minute);
    // Staff get their own jobs in the morning; admins the whole shop.
    final summary = morningSummary(
      orders: isAdmin
          ? service.orders
          : service.orders.where(
              (o) => isMyJob(o, myUid: myUid, isAdmin: false),
            ),
      enquiries: enquiries.enquiries,
      day: at,
      products: isAdmin
          ? _maybe<ProductRepository>()?.products ?? const []
          : const [],
    );
    final alarms = prefs.alarms && myUid.isNotEmpty
        ? repairAlarms(service.orders, myUid: myUid, isAdmin: isAdmin, now: now)
        : const <RepairAlarm>[];
    if (alarms.isNotEmpty && !prefs.exactAsked) {
      await prefs.markExactAsked();
      await phone.askExactAlarms();
    }
    if (prefs.alarms && myUid.isNotEmpty && !service.loading) {
      await _announceAssignments(
        phone,
        prefs,
        service.orders,
        myUid,
        l10n,
        locale,
      );
      if (isAdmin) {
        await _announceReadies(phone, prefs, service.orders, myUid, l10n);
      }
    }
    final planned = <PlannedReminder>[
      for (final a in alarms)
        PlannedReminder(
          id: a.id,
          at: a.at,
          kind: ReminderKind.alarm,
          title: a.kind == RepairAlarmKind.hourBefore
              ? l10n.alarmHourTitle(_device(a.order))
              : l10n.alarmDueTitle(_device(a.order)),
          body: _jobLine(a.order),
          route: '/service/${a.order.id}',
        ),
      if (prefs.on && !summary.isEmpty)
        PlannedReminder(
          id: 1,
          at: at,
          title: isAdmin
              ? l10n.reminderMorningTitle
              : l10n.reminderMorningMineTitle,
          body: summaryText(l10n, summary),
          route: summary.route,
        ),
      // Each enquiry due a call back, on its own day at the reminder time.
      if (prefs.on)
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

  /// A job given to this person by somebody else, told once, at once.
  Future<void> _announceAssignments(
    PhoneReminders phone,
    ReminderPrefs prefs,
    List<ServiceOrder> orders,
    String myUid,
    AppLocalizations l10n,
    String locale,
  ) async {
    final seen = prefs.seenAssignments;
    final fresh = newAssignments(orders, myUid: myUid, seen: seen ?? {});
    if (fresh.isEmpty) return;
    // First look on this phone: what was already given is not news.
    if (seen != null) {
      for (final o in fresh.take(5)) {
        final due = o.expectedCompletionAt;
        await phone.showNow(
          PlannedReminder(
            id: 700000 + o.id.hashCode.abs() % 100000,
            at: DateTime.now(),
            kind: ReminderKind.assigned,
            title: l10n.assignedTitle(_device(o)),
            body: due == null
                ? _jobLine(o)
                : l10n.assignedBody(_customer(o), _when(due, locale)),
            route: '/service/${o.id}',
          ),
        );
      }
    }
    await prefs.markSeen(fresh.map(assignmentKey));
  }

  /// A job somebody else made Ready: the owner's phone says so once, so
  /// the customer can be called.
  Future<void> _announceReadies(
    PhoneReminders phone,
    ReminderPrefs prefs,
    List<ServiceOrder> orders,
    String myUid,
    AppLocalizations l10n,
  ) async {
    final seen = prefs.seenAssignments;
    final fresh = newReadies(orders, myUid: myUid, seen: seen ?? {});
    if (fresh.isEmpty) return;
    if (seen != null) {
      for (final r in fresh.take(5)) {
        await phone.showNow(
          PlannedReminder(
            id: 800000 + r.order.id.hashCode.abs() % 100000,
            at: DateTime.now(),
            kind: ReminderKind.assigned,
            title: l10n.readyTitle(_device(r.order)),
            body: l10n.readyBody(_customer(r.order), r.by),
            route: '/service/${r.order.id}',
          ),
        );
      }
    }
    await prefs.markSeen(fresh.map((r) => r.key));
  }

  static String _device(ServiceOrder o) =>
      o.device.isEmpty ? o.orderNumber : o.device;

  static String _customer(ServiceOrder o) => o.customerName.trim().isNotEmpty
      ? o.customerName.trim()
      : o.customerPhone;

  /// "Ramesh K · Not charging, Display".
  static String _jobLine(ServiceOrder o) => [
    _customer(o),
    if (o.complaints.isNotEmpty) o.complaints.join(', '),
  ].where((p) => p.isNotEmpty).join(' · ');

  static String _when(DateTime d, String locale) {
    try {
      return DateFormat('d MMM, h:mm a', locale).format(d);
    } catch (_) {
      return DateFormat('d MMM, h:mm a').format(d);
    }
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
    _maybe<ProductRepository>(listen: true);
    _maybe<ReminderPrefs>(listen: true);
    _maybe<AuthState>(listen: true);
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
  if (s.reorder > 0) l10n.reminderReorder(s.reorder),
].join(' · ');
