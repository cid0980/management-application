/// WHERE THE SHOP'S LISTS LIVE
///
/// Two rules shape every write in this file.
///
/// **Union-append, never a whole-document write.** Two staff adding a brand in
/// the same minute both succeed. A whole-document write means the second one
/// read the list before the first one's brand was on it, and wrote it back
/// without — so one of the two brands silently vanished, and the person who
/// typed it could not work out why their dropdown was wrong. Every append here
/// touches only the values being added, which is `FieldValue.arrayUnion` once
/// Firestore is wired and is modelled exactly that way in memory.
///
/// **A write here must never fail the thing that caused it.** Adding "Infinix"
/// to a dropdown is not what the customer is standing at the counter for. So
/// [append] returns a result and swallows its own errors, callers do not await
/// it on the save path, and nothing it does can roll a sale back.
///
/// Removals and reorders are different: they are deliberate edits made on the
/// settings page by one admin, with nobody waiting, so they are ordinary
/// writes and they report failure.
library;

import 'package:flutter/foundation.dart';

import '../domain/settings/option_learning.dart';
import '../domain/settings/option_set.dart';
import '../domain/settings/shop_settings.dart';

/// What came of an append.
class OptionWriteResult {
  const OptionWriteResult.written(this.added) : error = null;

  const OptionWriteResult.nothingToDo() : added = 0, error = null;

  const OptionWriteResult.failed(this.error) : added = 0;

  final int added;

  /// Null when it went. Never thrown — see the library note.
  final String? error;

  bool get ok => error == null;
  bool get wroteSomething => ok && added > 0;
}

abstract class SettingsRepository extends ChangeNotifier {
  ShopSettings get settings;
  bool get loading;
  String? get error;

  Future<void> load();

  /// Append whatever is new in [additions]. Never throws.
  ///
  /// Callers on a save path do not await this: the record is already saved and
  /// a failed filing is a dropdown that is briefly out of date, not a lost
  /// sale.
  Future<OptionWriteResult> append(OptionAdditions additions);

  /// Decide and append in one call, for a form that has just saved.
  ///
  /// Still two steps underneath — `pendingAdditions` decides, this writes —
  /// because the deciding has to be testable without a repository at all.
  Future<OptionWriteResult> learn(TypedValues typed);

  /// Add one value from the settings page.
  Future<OptionWriteResult> addOption(OptionKind kind, String value);

  /// Add a model under a brand from the settings page.
  Future<OptionWriteResult> addModel(String brand, String model);

  /// Take a value off a list.
  ///
  /// Records already using it are untouched: a brand removed from the list is
  /// still the brand on two hundred handsets, and rewriting those is not a
  /// settings change.
  Future<OptionWriteResult> removeOption(OptionKind kind, String value);

  Future<OptionWriteResult> removeModel(String brand, String model);

  /// Replace the pre-delivery checklist, in order.
  ///
  /// Order matters here in a way it does not for the other lists: it is the
  /// order somebody works through a phone before handing it back.
  Future<OptionWriteResult> setChecklist(List<String> items);

  /// Move one checklist item, for the arrows on the settings page.
  Future<OptionWriteResult> moveChecklistItem(String item, int toIndex);

  Future<OptionWriteResult> setPrintServerUrl(String url);

  /// Where the public pages (rating links) are served.
  Future<OptionWriteResult> setPublicWebAddress(String url);

  /// Whether staff see cost prices and profit.
  Future<OptionWriteResult> setStaffSeeCosts(bool value);

  /// The repair warranty given on handed-back jobs, in days (0 = none).
  Future<OptionWriteResult> setRepairWarrantyDays(int days);

  /// The language this shop works in, as a code. Everyone in the shop sees
  /// the same one, which is why it lives here and not on the device.
  Future<OptionWriteResult> setLanguage(String code);
}

class InMemorySettingsStore extends ChangeNotifier
    implements SettingsRepository {
  InMemorySettingsStore({ShopSettings? seed})
    : _settings = (seed ?? ShopSettings.initial()).mutableCopy();

  ShopSettings _settings;
  bool _loading = false;
  String? _error;

  /// Set in a test to prove a failed filing does not fail the save that caused
  /// it.
  String? failWith;

  @override
  ShopSettings get settings => _settings;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }

  @override
  Future<OptionWriteResult> append(OptionAdditions additions) async {
    if (additions.isEmpty) return const OptionWriteResult.nothingToDo();
    // Swallowed, always. The record this came from is already saved.
    if (failWith != null) return OptionWriteResult.failed(failWith!);

    try {
      var added = 0;
      // Each of these touches only the values being added — the in-memory
      // stand-in for arrayUnion. Nothing reads a whole list and writes it
      // back, which is the mistake that lost one of two brands.
      additions.values.forEach((kind, values) {
        for (final value in values) {
          if (_settings.list(kind).add(value)) added++;
        }
      });
      additions.modelsByBrand.forEach((brandKey, models) {
        for (final model in models) {
          if (_addModelByKey(brandKey, model)) added++;
        }
      });
      for (final item in additions.checklistItems) {
        if (_settings.preDeliveryChecklist.add(item)) added++;
      }

      if (added == 0) return const OptionWriteResult.nothingToDo();
      _touch();
      return OptionWriteResult.written(added);
    } catch (e) {
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
    try {
      if (!_settings.list(kind).remove(value)) {
        return const OptionWriteResult.nothingToDo();
      }
      _touch();
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not remove: $e');
    }
  }

  @override
  Future<OptionWriteResult> removeModel(String brand, String model) async {
    try {
      final models = _settings.modelsFor(brand);
      if (models.isEmpty || !models.remove(model)) {
        return const OptionWriteResult.nothingToDo();
      }
      _touch();
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
      // a reorder. It is one admin on the settings page, with nobody waiting.
      _settings = _settings.copyWith(
        preDeliveryChecklist: OptionSet(items),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return OptionWriteResult.written(items.length);
    } catch (e) {
      return OptionWriteResult.failed('Could not save the checklist: $e');
    }
  }

  @override
  Future<OptionWriteResult> moveChecklistItem(String item, int toIndex) async {
    try {
      if (!_settings.preDeliveryChecklist.moveTo(item, toIndex)) {
        return const OptionWriteResult.nothingToDo();
      }
      _touch();
      return const OptionWriteResult.written(1);
    } catch (e) {
      return OptionWriteResult.failed('Could not reorder: $e');
    }
  }

  @override
  Future<OptionWriteResult> setPrintServerUrl(String url) async {
    _settings = _settings.copyWith(
      printServerUrl: url.trim(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return const OptionWriteResult.written(1);
  }

  @override
  Future<OptionWriteResult> setRepairWarrantyDays(int days) async {
    _settings = _settings.copyWith(
      repairWarrantyDays: days < 0 ? 0 : days,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return const OptionWriteResult.written(1);
  }

  @override
  Future<OptionWriteResult> setStaffSeeCosts(bool value) async {
    _settings = _settings.copyWith(
      staffSeeCosts: value,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return const OptionWriteResult.written(1);
  }

  @override
  Future<OptionWriteResult> setPublicWebAddress(String url) async {
    _settings = _settings.copyWith(
      publicWebAddress: url.trim(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return const OptionWriteResult.written(1);
  }

  @override
  Future<OptionWriteResult> setLanguage(String code) async {
    _settings = _settings.copyWith(
      language: code.trim(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return const OptionWriteResult.written(1);
  }

  bool _addModelByKey(String brandKey, String model) {
    final existing = _settings.modelsByBrand[brandKey];
    // A brand with no models yet needs its entry creating, which is the one
    // case that cannot be an append to something already there.
    if (existing == null) {
      final set = OptionSet.empty();
      if (!set.add(model)) return false;
      _settings = _settings.copyWith(
        modelsByBrand: {..._settings.modelsByBrand, brandKey: set},
      );
      return true;
    }
    return existing.add(model);
  }

  void _touch() {
    _settings = _settings.copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }
}
