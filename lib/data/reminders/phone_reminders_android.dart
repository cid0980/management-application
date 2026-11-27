import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// How a reminder comes: each its own Android channel, so a person can
/// silence one kind in the phone's settings and keep the others.
enum ReminderKind {
  /// The morning summary, enquiry call-backs: an ordinary notification.
  reminder,

  /// A job just given to you: a heads-up notification with sound.
  assigned,

  /// A promised time close or here: rings with the alarm sound, again and
  /// again until it is opened or swiped away.
  alarm,
}

/// One reminder for the phone to show at a set time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
    this.kind = ReminderKind.reminder,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// The page a tap on it opens.
  final String route;
  final ReminderKind kind;
}

/// Android's scheduled notifications, through flutter_local_notifications.
class PhoneReminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  final Set<int> _scheduled = {};

  bool get _supported => Platform.isAndroid;

  /// Once, when the signed-in app opens. [onTap] gets the page to open when
  /// a reminder is tapped — also the one that started the app.
  Future<void> init(void Function(String route) onTap) async {
    if (_ready || !_supported) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // The shops are in India: when the phone does not say, IST.
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.isNotEmpty) onTap(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        route != null &&
        route.isNotEmpty) {
      onTap(route);
    }
    _ready = true;
  }

  /// Android 13 and later ask the person before an app may show
  /// notifications. True when allowed.
  Future<bool> askPermission() async {
    if (!_supported) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Whether this phone lets the app show notifications at all.
  Future<bool> enabled() async {
    if (!_supported) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Android 12 and later let an app ring at an exact minute only when the
  /// person allows it ("Alarms & reminders"). Asked once, when there is a
  /// repair alarm to set; without it alarms still come, a few minutes late.
  Future<void> askExactAlarms() async {
    if (!_supported) return;
    try {
      final can = await _android?.canScheduleExactNotifications() ?? true;
      if (!can) await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static NotificationDetails _details(ReminderKind kind) => switch (kind) {
    ReminderKind.reminder => const NotificationDetails(
      android: AndroidNotificationDetails(
        'shop-reminders',
        'Shop reminders',
        channelDescription: 'The morning summary and enquiries to ring back',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
    ReminderKind.assigned => const NotificationDetails(
      android: AndroidNotificationDetails(
        'repair-assigned',
        'Repair updates',
        channelDescription:
            'A repair given to you, or (for owners) a repair made ready',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    ),
    ReminderKind.alarm => NotificationDetails(
      android: AndroidNotificationDetails(
        'repair-alarms',
        'Repair alarms',
        channelDescription:
            'An hour before a repair is promised, and when it is due',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
        // FLAG_INSISTENT: keeps sounding until opened or swiped away.
        additionalFlags: Int32List.fromList([4]),
        ticker: 'Repair alarm',
      ),
    ),
  };

  /// Shown at once (a job just given to this person).
  Future<void> showNow(PlannedReminder r) async {
    if (!_ready) return;
    await _plugin.show(
      id: r.id,
      title: r.title,
      body: r.body,
      notificationDetails: _details(r.kind),
      payload: r.route,
    );
  }

  /// What is scheduled becomes exactly [reminders]: the old ones go —
  /// including any set before the app last closed.
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (!_ready) return;
    try {
      for (final p in await _plugin.pendingNotificationRequests()) {
        await _plugin.cancel(id: p.id);
      }
    } catch (_) {
      for (final id in _scheduled) {
        await _plugin.cancel(id: id);
      }
    }
    _scheduled.clear();
    var exact = false;
    if (reminders.any((r) => r.kind == ReminderKind.alarm)) {
      try {
        exact = await _android?.canScheduleExactNotifications() ?? false;
      } catch (_) {}
    }
    final now = DateTime.now();
    for (final r in reminders) {
      if (!r.at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: _details(r.kind),
        // An alarm at its minute when the phone allows it; a morning
        // summary within a few minutes is fine and needs no permission.
        androidScheduleMode: r.kind == ReminderKind.alarm && exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.route,
      );
      _scheduled.add(r.id);
    }
  }
}
