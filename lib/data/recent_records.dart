import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RECENTLY OPENED
///
/// The record pages (a repair, a phone, a bill, a customer, a product, an
/// enquiry) opened lately on this phone, newest first. The Search page lists
/// them before anything is typed, so the repair looked at a minute ago is
/// one tap away. Kept on the phone only; it holds page addresses, not data.
class RecentRecords extends ChangeNotifier {
  RecentRecords({this.keep = 12});

  static const _key = 'recent.records.v1';

  /// How many are remembered.
  final int keep;

  List<String> _routes = const [];

  List<String> get routes => _routes;

  Future<void> load() async {
    try {
      final saved = await SharedPreferencesAsync().getStringList(_key);
      if (saved == null) return;
      // Anything opened before loading finished stays on top.
      _routes = _merge(_routes, saved);
      notifyListeners();
    } catch (_) {
      // No storage (a test): starts empty.
    }
  }

  /// [route] was just opened.
  void visit(String route) {
    if (_routes.isNotEmpty && _routes.first == route) return;
    _routes = _merge([route], _routes);
    notifyListeners();
    _save();
  }

  /// Forget them all.
  void clear() {
    if (_routes.isEmpty) return;
    _routes = const [];
    notifyListeners();
    _save();
  }

  List<String> _merge(List<String> first, List<String> then) {
    final out = <String>[];
    for (final r in [...first, ...then]) {
      if (!out.contains(r)) out.add(r);
      if (out.length == keep) break;
    }
    return List.unmodifiable(out);
  }

  Future<void> _save() async {
    try {
      await SharedPreferencesAsync().setStringList(_key, _routes);
    } catch (_) {}
  }
}
