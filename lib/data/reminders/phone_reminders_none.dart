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
  final String route;
}

/// No reminders on this platform.
class PhoneReminders {
  Future<void> init(void Function(String route) onTap) async {}
  Future<bool> askPermission() async => false;
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}
}
