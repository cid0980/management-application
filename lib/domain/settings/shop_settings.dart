/// THE SHOP'S OWN VOCABULARY
///
/// Everything the forms offer in a dropdown, in one place: brands, the models
/// under each brand, suppliers, colours, product categories, complaint types,
/// accessories, lock types, and the pre-delivery checklist.
///
/// Three things about this document are worth knowing.
///
/// **Models hang off brands.** A flat list of four hundred models is unusable,
/// and "Galaxy A54" under Apple is a mistake nobody catches. So the models are
/// a map keyed by the brand's own normalized key, and asking for a brand that
/// is not on the list gives an empty list rather than everything.
///
/// **The defaults are a starting point, not a floor.** A fresh shop starts
/// with [ShopSettings.initial], and from then on the lists are the shop's.
/// Nothing re-adds a default the shop has deliberately removed — which is why
/// loading a stored document never merges the defaults back in.
///
/// **The pre-delivery checklist is an ordered list, not a set.** Order is the
/// order somebody works through a phone before handing it back, so it is
/// preserved and editable; the keys the ticks are stored under are derived
/// from the labels once, by `checklist.dart`, which resolves collisions.
library;

import '../common/money.dart';
import '../expenses/expense.dart' show kExpenseKinds;
import '../inventory/second_hand_device.dart' show kLockTypes;
import '../products/product.dart' show kProductCategories;
import '../service/complaints.dart' show kAccessories, kComplaintTypes;
import '../service/order_validation.dart' show kDefaultPreDeliveryChecklist;
import 'option_set.dart';

/// Which of the shop's lists a value belongs to.
/// The discounts a new shop starts with; changed in Settings.
const Map<String, num> kDefaultDiscountTypes = {
  'Family': 10,
  'Friends': 5,
  'Regular': 3,
};

enum OptionKind {
  brands,
  suppliers,
  colours,
  categories,
  complaintTypes,
  accessories,
  lockTypes,

  /// RAM and storage, as the box prints them — "6GB", "128GB". Two lists,
  /// because the counter asks for them apart.
  ram,
  rom,

  /// What the shop's money goes on — Expenses' "What for" row.
  expenseKinds,
}

const Map<OptionKind, String> kOptionKindLabels = {
  OptionKind.brands: 'Brands',
  OptionKind.suppliers: 'Suppliers',
  OptionKind.colours: 'Colours',
  OptionKind.categories: 'Product categories',
  OptionKind.complaintTypes: 'Complaint types',
  OptionKind.accessories: 'Accessories left with a device',
  OptionKind.lockTypes: 'Lock types',
  OptionKind.ram: 'RAM',
  OptionKind.rom: 'Storage (ROM)',
  OptionKind.expenseKinds: 'Expense types',
};

const Map<OptionKind, String> kOptionKindHints = {
  OptionKind.brands: 'Offered on every intake and purchase form.',
  OptionKind.suppliers: 'Offered when adding a product.',
  OptionKind.colours: 'Offered on purchase and product forms.',
  OptionKind.categories: 'Groups the products list.',
  OptionKind.complaintTypes:
      'The job card and the final bill are both built from these.',
  OptionKind.accessories: 'Ticked at intake, printed on the job card.',
  OptionKind.lockTypes: 'How a device was locked when it came in.',
  OptionKind.ram: 'Offered on the purchase form.',
  OptionKind.rom: 'Offered on the purchase form.',
  OptionKind.expenseKinds: 'Offered when adding an expense.',
};

class ShopSettings {
  ShopSettings({
    Map<OptionKind, OptionSet>? lists,
    Map<String, OptionSet>? modelsByBrand,
    OptionSet? preDeliveryChecklist,
    this.publicWebAddress = '',
    this.staffSeeCosts = false,
    this.repairWarrantyDays = 0,
    this.discountTypes = kDefaultDiscountTypes,
    this.rewardEvery = 0,
    this.rewardPoints = 1,
    this.pointValue = 1,
    this.language = '',
    this.updatedAt,
  }) : _lists = {
         for (final kind in OptionKind.values)
           kind: lists?[kind]?.copy() ?? OptionSet.empty(),
       },
       _models = {
         for (final entry in (modelsByBrand ?? const {}).entries)
           entry.key: entry.value.copy(),
       },
       preDeliveryChecklist = preDeliveryChecklist?.copy() ?? OptionSet.empty();

  /// What a fresh shop starts with.
  ///
  /// The same lists that were hard-coded in the forms before this document
  /// existed, which is why those constants are still where they are: they are
  /// the defaults, and each one's own module is the right place to explain
  /// what it is for.
  factory ShopSettings.initial() => ShopSettings(
    lists: {
      OptionKind.brands: OptionSet(kDefaultBrands),
      OptionKind.suppliers: OptionSet(kDefaultSuppliers),
      OptionKind.colours: OptionSet(kDefaultColours),
      OptionKind.categories: OptionSet(kProductCategories),
      OptionKind.complaintTypes: OptionSet(kComplaintTypes),
      OptionKind.accessories: OptionSet(kAccessories),
      OptionKind.lockTypes: OptionSet(kLockTypes),
      OptionKind.ram: OptionSet(kDefaultRam),
      OptionKind.rom: OptionSet(kDefaultRom),
      OptionKind.expenseKinds: OptionSet(kExpenseKinds),
    },
    modelsByBrand: {
      for (final entry in kDefaultModels.entries)
        normalizeOption(entry.key): OptionSet(entry.value),
    },
    preDeliveryChecklist: OptionSet(kDefaultPreDeliveryChecklist),
  );

  final Map<OptionKind, OptionSet> _lists;
  final Map<String, OptionSet> _models;

  /// Ordered: the order somebody works through a phone.
  final OptionSet preDeliveryChecklist;

  /// Where this app's public pages are served, e.g. `https://fm-shop.web.app`.
  /// Rating links are built on it; empty means links cannot be shared yet.
  final String publicWebAddress;

  /// Whether staff see what the shop paid and what it makes — purchase
  /// prices, repair costs, profit. Off unless the owner turns it on: in most
  /// shops margins are the owner's, and a counter that shows the cost price
  /// is a counter that gets bargained down to it. Admins always see them.
  final bool staffSeeCosts;

  /// The shop's repair warranty, in days; 0 is none. Stamped onto a job when
  /// it is handed back, so changing the policy later does not rewrite what
  /// was promised on bills already given out.
  final int repairWarrantyDays;

  /// Discounts by who is buying ("Family" 10, "Friends" 5): a percentage
  /// the shop sets, picked on a bill with one tap.
  final Map<String, num> discountTypes;

  /// Wallet points: for every [rewardEvery] rupees paid on a bill the
  /// customer earns [rewardPoints] points, each worth [pointValue] rupees
  /// off a later bill (put on their wallet). 0 = no points.
  final num rewardEvery;
  final num rewardPoints;
  final num pointValue;

  /// What a bill paid at [paid] puts on the customer's wallet, in rupees.
  num rewardFor(num paid) {
    if (rewardEvery <= 0 || paid <= 0) return 0;
    final points = (paid ~/ rewardEvery) * rewardPoints;
    return roundMoney(points * pointValue);
  }

  /// The language code this shop works in — `ta`, `hi`, `en`. Empty until
  /// somebody picks one, which is not the same as English: an empty setting
  /// falls back to the device's own language, and a stored one does not.
  ///
  /// Stored as the code rather than an index so adding a language later
  /// cannot renumber what shops already chose, and kept as written even when
  /// this build does not have that language — see `languages.dart`.
  final String language;

  final DateTime? updatedAt;

  OptionSet list(OptionKind kind) => _lists[kind]!;

  /// Every brand key that has models, to its models.
  ///
  /// Keyed by the normalized brand key, which is how the stored document keys
  /// them. Exposed because the repository has to add a model under a brand key
  /// that may not be on the brand list yet — rebuilding this map by walking
  /// the brand list would silently drop exactly that case.
  Map<String, OptionSet> get modelsByBrand => Map.unmodifiable(_models);

  /// The brands, as a list.
  List<String> get brands => list(OptionKind.brands).values;

  /// The models recorded under a brand.
  ///
  /// An empty list for a brand that is not on the list — never every model the
  /// shop knows, which would put "Galaxy A54" under Apple.
  OptionSet modelsFor(String? brand) =>
      _models[normalizeOption(brand)] ?? OptionSet.empty();

  /// Every brand that has at least one model recorded, as the brand list
  /// spells it where it can.
  List<String> get brandsWithModels => [
    for (final key in _models.keys)
      if (_models[key]!.isNotEmpty)
        list(OptionKind.brands).values
            .firstWhere((b) => normalizeOption(b) == key, orElse: () => key),
  ];

  int get modelCount =>
      _models.values.fold<int>(0, (sum, set) => sum + set.length);

  ShopSettings copyWith({
    Map<OptionKind, OptionSet>? lists,
    Map<String, OptionSet>? modelsByBrand,
    OptionSet? preDeliveryChecklist,
    String? publicWebAddress,
    bool? staffSeeCosts,
    int? repairWarrantyDays,
    Map<String, num>? discountTypes,
    num? rewardEvery,
    num? rewardPoints,
    num? pointValue,
    String? language,
    DateTime? updatedAt,
  }) => ShopSettings(
    lists: lists ?? _lists,
    modelsByBrand: modelsByBrand ?? _models,
    preDeliveryChecklist: preDeliveryChecklist ?? this.preDeliveryChecklist,
    publicWebAddress: publicWebAddress ?? this.publicWebAddress,
    staffSeeCosts: staffSeeCosts ?? this.staffSeeCosts,
    repairWarrantyDays: repairWarrantyDays ?? this.repairWarrantyDays,
    discountTypes: discountTypes ?? this.discountTypes,
    rewardEvery: rewardEvery ?? this.rewardEvery,
    rewardPoints: rewardPoints ?? this.rewardPoints,
    pointValue: pointValue ?? this.pointValue,
    language: language ?? this.language,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// A mutable copy, for the repository to apply changes to.
  ShopSettings mutableCopy() => copyWith(
    lists: {for (final entry in _lists.entries) entry.key: entry.value.copy()},
    modelsByBrand: {
      for (final entry in _models.entries) entry.key: entry.value.copy(),
    },
    preDeliveryChecklist: preDeliveryChecklist.copy(),
  );

  /// Read a stored document.
  ///
  /// **The defaults are not merged back in.** A shop that removed a complaint
  /// type meant to remove it, and quietly restoring it on the next load would
  /// make the setting impossible to change. An empty stored list is an empty
  /// list.
  static ShopSettings fromMap(Map<String, Object?> map) {
    return ShopSettings(
      lists: {
        for (final kind in OptionKind.values)
          kind: OptionSet(
            // A shop saved before expense types existed has no such key:
            // that is "never set", not "all removed", so it gets the usual
            // ones. Once saved, an empty list stays empty like any other.
            kind == OptionKind.expenseKinds && !map.containsKey(kind.name)
                ? kExpenseKinds
                : _strings(map[kind.name]),
          ),
      },
      modelsByBrand: {
        if (map['modelsByBrand'] is Map)
          for (final entry in (map['modelsByBrand'] as Map).entries)
            normalizeOption(entry.key?.toString()): OptionSet(
              _strings(entry.value),
            ),
      },
      preDeliveryChecklist: OptionSet(
        _strings(map['preDeliveryChecklist'] ?? map['checklist']),
      ),
      publicWebAddress: (map['publicWebAddress'] ?? '').toString().trim(),
      staffSeeCosts: map['staffSeeCosts'] == true,
      repairWarrantyDays: map['repairWarrantyDays'] is num
          ? (map['repairWarrantyDays'] as num).toInt().clamp(0, 3650)
          : 0,
      // Never set: the usual three. Saved empty: none.
      discountTypes: map['discountTypes'] is Map
          ? {
              for (final e in (map['discountTypes'] as Map).entries)
                if (e.value is num && (e.value as num) > 0)
                  e.key.toString(): (e.value as num).clamp(0, 100),
            }
          : kDefaultDiscountTypes,
      rewardEvery: map['rewardEvery'] is num
          ? (map['rewardEvery'] as num).clamp(0, 1000000)
          : 0,
      rewardPoints: map['rewardPoints'] is num
          ? (map['rewardPoints'] as num).clamp(0, 100000)
          : 1,
      pointValue: map['pointValue'] is num
          ? (map['pointValue'] as num).clamp(0, 100000)
          : 1,
      language: (map['language'] ?? '').toString().trim(),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.tryParse(map['updatedAt'].toString()),
    );
  }

  Map<String, Object?> toMap() => {
    for (final kind in OptionKind.values) kind.name: list(kind).values,
    'modelsByBrand': {
      for (final entry in _models.entries) entry.key: entry.value.values,
    },
    'preDeliveryChecklist': preDeliveryChecklist.values,
    'publicWebAddress': publicWebAddress,
    'staffSeeCosts': staffSeeCosts,
    'repairWarrantyDays': repairWarrantyDays,
    'discountTypes': discountTypes,
    'rewardEvery': rewardEvery,
    'rewardPoints': rewardPoints,
    'pointValue': pointValue,
    'language': language,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static List<String> _strings(Object? v) => v is Iterable
      ? [
          for (final e in v)
            if (e != null && e.toString().trim().isNotEmpty)
              e.toString().trim(),
        ]
      : const [];
}

/// Brands the shop sees most. A default, not a floor.
const List<String> kDefaultBrands = [
  'Samsung',
  'Xiaomi',
  'Redmi',
  'Apple',
  'Vivo',
  'Oppo',
  'Realme',
  'OnePlus',
  'Motorola',
  'Nokia',
  'Infinix',
  'Tecno',
  'Poco',
  'iQOO',
  'Lava',
  'Micromax',
  'Other',
];

/// A few models per brand, so the dropdown is useful on day one. The list
/// grows itself from what staff type.
const Map<String, List<String>> kDefaultModels = {
  'Samsung': ['Galaxy A54', 'Galaxy M14', 'Galaxy S23', 'Galaxy A14'],
  'Xiaomi': ['Redmi Note 12', 'Redmi 13C', 'Redmi Note 13 Pro'],
  'Apple': ['iPhone 11', 'iPhone 12', 'iPhone 13', 'iPhone 14'],
  'Vivo': ['T2x', 'Y21', 'V29'],
  'Oppo': ['A78', 'A17', 'Reno 10'],
  'Realme': ['Narzo 60', 'C53', '11 Pro'],
};

/// Empty on purpose. Suppliers are each shop's own — the first build carried
/// the first shop's Chennai and Coimbatore traders, which every new shop on
/// the Play Store would have started with. The list fills itself from what
/// is typed (see option_learning.dart).
const List<String> kDefaultSuppliers = [];

const List<String> kDefaultColours = [
  'Black',
  'White',
  'Blue',
  'Green',
  'Red',
  'Gold',
  'Silver',
  'Grey',
  'Purple',
  'Clear',
];

/// RAM and storage as the shop's counter app offers them on day one;
/// anything else typed joins the list.
const List<String> kDefaultRam = [
  '1GB', '2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB', //
];

const List<String> kDefaultRom = [
  '8GB', '16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB', //
];
