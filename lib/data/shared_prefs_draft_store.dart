import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/common/form_draft.dart';

/// Drafts on disk.
///
/// JSON under the draft's own key, so a half-typed new intake and an edit of
/// an existing record sit in different drawers — which they did not, once, and
/// the new purchase overwrote itself into an existing device's record.
///
/// A draft that cannot be read is treated as no draft. A corrupt value is not
/// worth an exception on the way into a form: the worst case is someone types
/// it again, and the best case is the form opens at all.
class SharedPrefsDraftStore implements DraftStore {
  @override
  Future<FormDraft?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final values = Map<String, Object?>.from(decoded);
      final savedAt = values.remove('_savedAt');
      return FormDraft(
        key: key,
        values: values,
        savedAt: savedAt is String ? DateTime.tryParse(savedAt) : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, Object?> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = FormDraft(key: key, values: values);
      // A blank form must not resurrect a draft the user just discarded.
      if (draft.isEmpty) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(
        key,
        jsonEncode({...values, '_savedAt': DateTime.now().toIso8601String()}),
      );
    } catch (_) {
      // A draft that could not be saved is a draft lost, not a form broken.
    }
  }

  @override
  Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
