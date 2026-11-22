/// THE SHOP'S LISTS, OUT OF FIRESTORE
///
/// The same `SettingsRepository` the screens already talk to, backed by the
/// single document `shops/{shopId}/settings/options`. One document rather than
/// a collection, because the shop's vocabulary is one thing that is read
/// whole.
///
/// **Union-append, never a whole-document write.** Two staff adding a brand in
/// the same minute both succeed. A whole-document write means the second one
/// read the list before the first one's brand was on it and wrote it back
/// without — so one of the two brands silently vanished, and the person who
/// typed it could not work out why their dropdown was wrong. Every append here
/// is `FieldValue.arrayUnion` on one field, which the in-memory store models
/// exactly.
///
/// `arrayUnion` matches values exactly, while the shop's lists treat case and
/// space as the same value. So two staff adding `Infinix` and `infinix` in the
/// same minute do both land in the array — and `OptionSet` folds them back
/// into one on read, keeping the first spelling. Both brands surviving as one
/// entry is the outcome that matters; neither person loses their typing.
///
/// **A write here must never fail the thing that caused it.** Adding "Infinix"
/// to a dropdown is not what the customer is standing at the counter for, so
/// [append] returns a result and swallows its own errors.
///
/// **A shop that has never had a settings document gets the defaults.** [load]
/// writes `ShopSettings.initial()` the first time it finds nothing there,
/// which is what gives a shop signed up five minutes ago a usable dropdown on
/// day one. It is written rather than held in memory so the other till sees
/// the same list.
///
/// Removals and reorders are different: deliberate edits made on the settings
/// page by one admin, with nobody waiting, so they are ordinary writes and
/// they report failure.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/settings/option_learning.dart';
import '../domain/settings/option_set.dart';
import '../domain/settings/shop_settings.dart';
import 'firestore_errors.dart';
import 'firestore_paths.dart';
import 'settings_repository.dart';

class FirestoreSettingsStore extends ChangeNotifier
    implements SettingsRepository {
  FirestoreSettingsStore({required this.scope});

  /// This shop, and only this shop.
  final ShopScope scope;

  /// The defaults until the document arrives — which is also what a new shop's
  /// document is written with, so the dropdowns do not change under somebody
  /// mid-form.
  ShopSettings _settings = ShopSettings.initial();
  bool _loading = true;
  String? _error;
  bool _listening = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  DocumentReference<Map<String, dynamic>> get _ref => scope.settings;

  @override
  ShopSettings get settings => _settings;

  @override
  bool get loading => _loading;

  bool _offline = false;

  @override
  bool get offline => _offline;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    if (_listening) return;
    _listening = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // With metadata changes, so going offline and coming back are events
    // too: from the cache means the server has not confirmed it.
    _subscription = _ref
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            final offline = snapshot.metadata.isFromCache;
            if (offline != _offline) {
              _offline = offline;
              notifyListeners();
            }
            final data = snapshot.data();
            if (!snapshot.exists || data == null) {
              // A shop with no settings document yet. See the class note.
              _seedDefaults();
              return;
            }
            _settings = ShopSettings.fromMap(data).mutableCopy();
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object e) {
            _loading = false;
            _error = describeFirestoreError(e, 'settings');
            notifyListeners();
          },
        );
  }

  @override
  Future<OptionWriteResult> append(OptionAdditions additions) async {
    if (additions.isEmpty) return const OptionWriteResult.nothingToDo();

    try {
      final updates = <String, Object?>{};
      final models = <String, Object?>{};
      var added = 0;

      // Each of these touches only the values being added. Nothing reads a
      // whole list and writes it back, which is the mistake that lost one of
      // two brands.
      additions.values.forEach((kind, values) {
        final fresh = _notAlreadyThere(_settings.list(kind), values);
        if (fresh.isEmpty) return;
        updates[kind.name] = FieldValue.arrayUnion(fresh);
        added += fresh.length;
      });

      additions.modelsByBrand.forEach((brandKey, values) {
        final existing = _settings.modelsByBrand[brandKey];
        final fresh = _notAlreadyThere(existing, values);
        if (fresh.isEmpty) return;
        models[brandKey] = FieldValue.arrayUnion(fresh);
        added += fresh.length;
      });
      if (models.isNotEmpty) updates['modelsByBrand'] = models;

      final checklist = _notAlreadyThere(
        _settings.preDeliveryChecklist,
        additions.checklistItems,
      );
      if (checklist.isNotEmpty) {
        updates['preDeliveryChecklist'] = FieldValue.arrayUnion(checklist);
        added += checklist.length;
      }

      if (added == 0) return const OptionWriteResult.nothingToDo();

      updates['updatedAt'] = DateTime.now().toIso8601String();
      // Merged, so the fields nobody is adding to are not touched at all —
      // and so a shop whose document has somehow gone missing gets one.
      await localWrite(_ref.set(updates, SetOptions(merge: true)));
      return OptionWriteResult.written(added);
    } catch (e) {
      // Swallowed, always. The record this came from is already saved.
      return OptionWriteResult.failed('Could not file: $e');
    }
  }

  @override
  Future<OptionWriteResult> learn(TypedValues typed) =>
      append(pendingAdditions(_settings, typed));

  @override
  Future<OptionWriteResult> addOption(OptionKind kind, String value) => append(
    OptionAdditions(
      values: {
        kind: _settings.list(kind).additionsFrom([value]),
      },
    ),
  );

  @override
  Future<OptionWriteResult> addModel(String brand, String model) {
    final key = normalizeOption(brand);
    if (key.isEmpty) {
      return Future.value(
        const OptionWriteResult.failed('Pick a brand for this model first'),
      );
    }
    return append(
      OptionAdditions(
        // The brand joins the list too if it is new, so a model can never sit
        // under a brand the dropdown does not offer.
        values: {
          OptionKind.brands: _settings.list(OptionKind.brands).additionsFrom([
            brand,
          ]),
        },
        modelsByBrand: {
          key: _settings.modelsFor(brand).additionsFrom([model]),
        },
      ),
    );
  }

  @override
  Future<OptionWriteResult> removeOption(OptionKind kind, String value) async {
    // Every spelling of it, because `arrayUnion` matches exactly and two
    // staff may have added `Infinix` and `infinix`. Removing one spelling and
    // leaving the other is a value that comes back on the next read.
    final spellings = _spellingsOf(_settings.list(kind), value);
    if (spellings.isEmpty) return const OptionWriteResult.nothingToDo();

    try {
      await localWrite(
        _ref.set({
          kind.name: FieldValue.arrayRemove(spellings),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      // Records already using it are untouched: a brand removed from the list
      // is still the brand on two hundred handsets, and rewriting those is not
      // a settings change.
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not remove: $e');
    }
  }

  @override
  Future<OptionWriteResult> removeModel(String brand, String model) async {
    final key = normalizeOption(brand);
    final spellings = _spellingsOf(_settings.modelsByBrand[key], model);
    if (key.isEmpty || spellings.isEmpty) {
      return const OptionWriteResult.nothingToDo();
    }

    try {
      await localWrite(
        _ref.set({
          'modelsByBrand': {key: FieldValue.arrayRemove(spellings)},
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not remove: $e');
    }
  }

  @override
  Future<OptionWriteResult> setChecklist(List<String> items) async {
    try {
      // The one place a whole list is replaced rather than appended to,
      // because the order IS the value being set and an append cannot express
      // a reorder. One admin on the settings page, with nobody waiting.
      await localWrite(
        _ref.set({
          'preDeliveryChecklist': OptionSet(items).values,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return OptionWriteResult.written(items.length);
    } catch (e) {
      return OptionWriteResult.failed('Could not save the checklist: $e');
    }
  }

  @override
  Future<OptionWriteResult> moveChecklistItem(String item, int toIndex) async {
    // Worked out on a copy of the list as it stands, then written whole — for
    // the same reason as [setChecklist].
    final reordered = _settings.preDeliveryChecklist.copy();
    if (!reordered.moveTo(item, toIndex)) {
      return const OptionWriteResult.nothingToDo();
    }

    try {
      await localWrite(
        _ref.set({
          'preDeliveryChecklist': reordered.values,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not reorder: $e');
    }
  }

  @override
  Future<OptionWriteResult> setPrintServerUrl(String url) async {
    try {
      await localWrite(
        _ref.set({
          'printServerUrl': url.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not save the address: $e');
    }
  }

  @override
  Future<OptionWriteResult> setRepairWarrantyDays(int days) async {
    try {
      await localWrite(
        _ref.set({
          'repairWarrantyDays': days < 0 ? 0 : days,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not save: $e');
    }
  }

  @override
  Future<OptionWriteResult> setStaffSeeCosts(bool value) async {
    try {
      await localWrite(
        _ref.set({
          'staffSeeCosts': value,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not save: $e');
    }
  }

  @override
  Future<OptionWriteResult> setPublicWebAddress(String url) async {
    try {
      await localWrite(
        _ref.set({
          'publicWebAddress': url.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not save the address: $e');
    }
  }

  @override
  Future<OptionWriteResult> setLanguage(String code) async {
    try {
      // One field, merged: changing the language must not touch the shop's
      // lists, and the other till picks it up through the same snapshot
      // listener everything else uses.
      await localWrite(
        _ref.set({
          'language': code.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)),
      );
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not save the language: $e');
    }
  }

  /// The defaults, written once, for a shop that has no settings document.
  ///
  /// `set` without merge, and only when nothing is there: a failure here is
  /// not fatal — the in-memory copy already holds the same defaults, so the
  /// dropdowns work and the next write will create the document.
  Future<void> _seedDefaults() async {
    _settings = ShopSettings.initial().mutableCopy();
    _loading = false;
    _error = null;
    notifyListeners();
    try {
      await localWrite(_ref.set(_settings.toMap()));
    } catch (_) {
      // Left alone deliberately. See above.
    }
  }

  /// The values from [candidates] this device does not already have.
  ///
  /// Only the count depends on this — `arrayUnion` is what makes a concurrent
  /// add safe, whatever this device knew.
  List<String> _notAlreadyThere(OptionSet? set, Iterable<String> candidates) {
    final fresh = <String>[];
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (set != null && set.contains(trimmed)) continue;
      if (fresh.any((v) => normalizeOption(v) == normalizeOption(trimmed))) {
        continue;
      }
      fresh.add(trimmed);
    }
    return fresh;
  }

  /// Every stored spelling of [value], ignoring case and space.
  List<String> _spellingsOf(OptionSet? set, String value) {
    final key = normalizeOption(value);
    if (set == null || key.isEmpty) return const [];
    return [
      for (final stored in set.values)
        if (normalizeOption(stored) == key) stored,
    ];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
