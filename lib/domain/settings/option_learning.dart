/// A VALUE TYPED INTO A FORM JOINS THE LIST
///
/// Somebody takes in a handset of a brand the dropdown has never heard of,
/// types it, and saves. The next person finds that brand in the dropdown. That
/// is the whole feature, and it is why the shop's lists are worth anything —
/// a vocabulary somebody has to maintain by hand does not get maintained.
///
/// **Deciding what is new is kept separate from writing it.** This module only
/// decides: it is pure, it reads the settings and the values a form submitted,
/// and it returns the additions. The repository writes them.
///
/// The separation is not tidiness. It is what makes the next rule possible:
///
/// **Filing a brand name must never fail the sale that was just made.** The
/// sale is the thing the customer is standing there for; adding "Infinix" to a
/// dropdown is not. So the save completes first, and the additions are written
/// afterwards in a call nothing waits on and nothing rolls back. A decision
/// that is already made, held in a plain value, can be written late — a
/// decision tangled into the save path cannot.
library;

import 'option_set.dart';
import 'shop_settings.dart';

/// What a form wants to file, before anything has been decided about it.
///
/// Built by a form from its own fields, so the form says what it means rather
/// than this module knowing about intakes and purchases.
class TypedValues {
  const TypedValues({
    this.values = const {},
    this.brand,
    this.models = const [],
    this.checklistItems = const [],
  });

  /// Plain lists, by kind.
  final Map<OptionKind, List<String?>> values;

  /// The brand the [models] belong under. Models without a brand are dropped:
  /// a model filed under nothing is how "Galaxy A54" ends up offered for every
  /// brand in the shop.
  final String? brand;

  final List<String?> models;

  /// Rarely used from a form — the settings page edits the checklist directly —
  /// but kept so the same path can file one.
  final List<String?> checklistItems;
}

/// What is actually new, ready to be written.
class OptionAdditions {
  const OptionAdditions({
    this.values = const {},
    this.modelsByBrand = const {},
    this.checklistItems = const [],
  });

  /// Only kinds with something to add appear here. An empty map is the normal
  /// case — most saves file nothing.
  final Map<OptionKind, List<String>> values;

  /// Keyed by the brand's normalized key, the same key the settings document
  /// stores models under.
  final Map<String, List<String>> modelsByBrand;

  final List<String> checklistItems;

  bool get isEmpty =>
      values.isEmpty && modelsByBrand.isEmpty && checklistItems.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// How many values in total, for a message that says what was filed.
  int get count =>
      values.values.fold<int>(0, (sum, v) => sum + v.length) +
      modelsByBrand.values.fold<int>(0, (sum, v) => sum + v.length) +
      checklistItems.length;

  /// A one-line summary for the snackbar after a save. Null when nothing was
  /// filed, which is most of the time.
  String? get summary {
    if (isEmpty) return null;
    final parts = <String>[
      for (final entry in values.entries) entry.value.join(', '),
      for (final entry in modelsByBrand.entries) entry.value.join(', '),
      ...checklistItems,
    ];
    return 'Added to the shop lists: ${parts.join(', ')}';
  }
}

/// Decide what [typed] adds to [settings]. Writes nothing.
///
/// Deduped against the existing lists and against itself, so a form that
/// submitted the same colour twice files it once.
OptionAdditions pendingAdditions(ShopSettings settings, TypedValues typed) {
  final values = <OptionKind, List<String>>{};
  typed.values.forEach((kind, candidates) {
    final additions = settings.list(kind).additionsFrom(candidates);
    if (additions.isNotEmpty) values[kind] = additions;
  });

  final modelsByBrand = <String, List<String>>{};
  final brandKey = normalizeOption(typed.brand);
  // A model with no brand to sit under is dropped rather than filed loose.
  if (brandKey.isNotEmpty && typed.models.isNotEmpty) {
    final additions = settings
        .modelsFor(typed.brand)
        .additionsFrom(typed.models);
    if (additions.isNotEmpty) modelsByBrand[brandKey] = additions;
  }

  final checklist = settings.preDeliveryChecklist.additionsFrom(
    typed.checklistItems,
  );

  return OptionAdditions(
    values: values,
    modelsByBrand: modelsByBrand,
    checklistItems: checklist,
  );
}

/// What a service intake files: the brand, the model under it, and any
/// complaint the shop has not seen before.
TypedValues serviceIntakeValues({
  String? brand,
  String? model,
  List<String> complaints = const [],
  List<String> accessories = const [],
  String? lockType,
}) => TypedValues(
  values: {
    OptionKind.brands: [brand],
    OptionKind.complaintTypes: complaints,
    OptionKind.accessories: accessories,
    OptionKind.lockTypes: [lockType],
  },
  brand: brand,
  models: [model],
);

/// What a second-hand purchase files: the brand, the model under it, the
/// RAM, the storage, the colour and the supplier.
TypedValues purchaseValues({
  String? brand,
  String? model,
  String? ram,
  String? rom,
  String? colour,
  String? supplier,
}) => TypedValues(
  values: {
    OptionKind.brands: [brand],
    OptionKind.ram: [ram],
    OptionKind.rom: [rom],
    OptionKind.colours: [colour],
    OptionKind.suppliers: [supplier],
  },
  brand: brand,
  models: [model],
);

/// What a product form files.
TypedValues productValues({
  String? brand,
  String? category,
  String? colour,
  String? supplier,
}) => TypedValues(
  values: {
    OptionKind.brands: [brand],
    OptionKind.categories: [category],
    OptionKind.colours: [colour],
    OptionKind.suppliers: [supplier],
  },
  brand: brand,
);
