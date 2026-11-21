/// HALF-FINISHED FORMS
///
/// A purchase form is long, and the shop is a shop: the phone rings, a
/// customer walks in, the sheet gets pulled down. Losing twenty fields to that
/// is why staff stopped using the form and wrote on a pad instead.
///
/// Two rules, both learned the hard way.
///
/// **A draft is per form INSTANCE, not per form.** A new intake and an edit of
/// an existing record are different drafts. They shared one key once, and a
/// half-typed new purchase overwrote itself into an existing device's record.
/// The key carries the id — `second_hand:new` and `second_hand:sh-2` are not
/// the same drawer.
///
/// **Dismissing is not discarding.** Dragging the sheet down is a slip as
/// often as it is a decision, so it KEEPS the draft. The X discards it, and
/// that is the only thing that does.
library;

/// The key a form instance stores its draft under.
///
/// [id] is null for a new record. Two different existing records, and a new
/// one, all get their own.
String draftKey(String form, {String? id}) => 'draft:$form:${id ?? 'new'}';

/// Whether a draft is worth keeping, given how the sheet was closed.
enum SheetExit {
  /// Dragged down, tapped outside, back gesture — a slip as often as not.
  dismissed,

  /// The X, or an explicit discard. The only thing that throws work away.
  discarded,

  /// Saved. The draft has served its purpose.
  saved,
}

bool keepsDraft(SheetExit exit) => exit == SheetExit.dismissed;

/// What a form stores and restores. A map, because every form's fields differ
/// and the draft store has no business knowing them.
class FormDraft {
  const FormDraft({required this.key, required this.values, this.savedAt});

  final String key;
  final Map<String, Object?> values;
  final DateTime? savedAt;

  /// An empty draft is not a draft. Restoring one would make a form look as if
  /// it had unsaved work when it has none.
  bool get isEmpty => values.values.every(_blank);

  static bool _blank(Object? v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is Iterable) return v.isEmpty;
    if (v is Map) return v.isEmpty;
    if (v is num) return v == 0;
    if (v is bool) return v == false;
    return false;
  }
}

/// Where drafts live. `shared_preferences` in the app; a map in a test.
abstract class DraftStore {
  Future<FormDraft?> read(String key);
  Future<void> write(String key, Map<String, Object?> values);
  Future<void> clear(String key);
}

/// For tests and for the first run, before `shared_preferences` is reachable.
class InMemoryDraftStore implements DraftStore {
  final Map<String, FormDraft> _drafts = {};

  @override
  Future<FormDraft?> read(String key) async => _drafts[key];

  @override
  Future<void> write(String key, Map<String, Object?> values) async {
    final draft = FormDraft(key: key, values: values, savedAt: DateTime.now());
    // Writing a blank form would resurrect a draft the user just discarded.
    if (draft.isEmpty) {
      _drafts.remove(key);
      return;
    }
    _drafts[key] = draft;
  }

  @override
  Future<void> clear(String key) async => _drafts.remove(key);
}
