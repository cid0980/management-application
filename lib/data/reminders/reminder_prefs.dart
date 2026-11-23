import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone shows the shop's reminders, and when the morning
/// summary comes. Kept on the phone: each person decides for their own.
class ReminderPrefs extends ChangeNotifier {
  static const _onKey = 'reminders.on';
  static const _timeKey = 'reminders.minutes';
  static const _askedKey = 'reminders.asked';

  bool _on = true;
  int _minutes = 9 * 60 + 30;
  bool _asked = false;

  /// On unless turned off.
  bool get on => _on;

  /// Minutes after midnight for the morning summary (9:30 unless changed).
  int get minutes => _minutes;
  int get hour => _minutes ~/ 60;
  int get minute => _minutes % 60;

  /// Whether Android's "allow notifications" question has been asked.
  bool get asked => _asked;

  Future<void> load() async {
    try {
      final p = SharedPreferencesAsync();
      _on = await p.getBool(_onKey) ?? true;
      _minutes = await p.getInt(_timeKey) ?? _minutes;
      _asked = await p.getBool(_askedKey) ?? false;
      notifyListeners();
    } catch (_) {
      // No storage (a test): the defaults stand.
    }
  }

  Future<void> setOn(bool on) async {
    _on = on;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setBool(_onKey, on);
    } catch (_) {}
  }

  Future<void> setMinutes(int minutes) async {
    _minutes = minutes;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setInt(_timeKey, minutes);
    } catch (_) {}
  }

  Future<void> markAsked() async {
    _asked = true;
    try {
      await SharedPreferencesAsync().setBool(_askedKey, true);
    } catch (_) {}
  }
}
