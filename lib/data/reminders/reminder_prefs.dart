import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone shows the shop's reminders, and when the morning
/// summary comes. Kept on the phone: each person decides for their own.
class ReminderPrefs extends ChangeNotifier {
  static const _onKey = 'reminders.on';
  static const _timeKey = 'reminders.minutes';
  static const _askedKey = 'reminders.asked';
  static const _alarmsKey = 'reminders.alarms';
  static const _exactKey = 'reminders.exactAsked';
  static const _seenKey = 'reminders.seenAssignments';

  bool _on = true;
  int _minutes = 9 * 60 + 30;
  bool _asked = false;
  bool _alarms = true;
  bool _exactAsked = false;
  Set<String>? _seen;

  /// Repair alarms (an hour before, and when due): on unless turned off.
  bool get alarms => _alarms;

  /// Whether Android's "Alarms & reminders" question has been asked.
  bool get exactAsked => _exactAsked;

  /// Assignments this phone has already announced (null until the first
  /// look: then everything already given is taken as known, so a new phone
  /// does not announce a pile of old jobs).
  Set<String>? get seenAssignments => _seen;

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
      _alarms = await p.getBool(_alarmsKey) ?? true;
      _exactAsked = await p.getBool(_exactKey) ?? false;
      final seen = await p.getStringList(_seenKey);
      _seen = seen?.toSet();
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

  Future<void> setAlarms(bool on) async {
    _alarms = on;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setBool(_alarmsKey, on);
    } catch (_) {}
  }

  Future<void> markExactAsked() async {
    _exactAsked = true;
    try {
      await SharedPreferencesAsync().setBool(_exactKey, true);
    } catch (_) {}
  }

  /// Remembers [keys] as announced; the newest 300 are kept.
  Future<void> markSeen(Iterable<String> keys) async {
    final all = [...?_seen, ...keys];
    final kept = all.length > 300 ? all.sublist(all.length - 300) : all;
    _seen = kept.toSet();
    try {
      await SharedPreferencesAsync().setStringList(_seenKey, _seen!.toList());
    } catch (_) {}
  }
}
