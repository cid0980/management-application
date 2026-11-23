import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One reminder for the phone to show at a set time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// The page a tap on it opens.
  final String route;
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

  /// What is scheduled becomes exactly [reminders]: the old ones go.
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (!_ready) return;
    for (final id in _scheduled) {
      await _plugin.cancel(id: id);
    }
    _scheduled.clear();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'shop-reminders',
        'Shop reminders',
        channelDescription: 'The morning summary and enquiries to ring back',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    final now = DateTime.now();
    for (final r in reminders) {
      if (!r.at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        // Within a few minutes is fine for a morning summary, and needs no
        // exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.route,
      );
      _scheduled.add(r.id);
    }
  }
}
