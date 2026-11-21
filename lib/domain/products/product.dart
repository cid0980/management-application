/// ONE NEW-GOODS PRODUCT
///
/// Accessories and new handsets: things the shop buys in quantity and sells
/// many of. That is the whole difference from a second-hand record, and it is
/// a big one — a used handset is one of one, with a state (on the shelf, on
/// the bench, sold), while a product has a **count**, and the question about it
/// is "how many are left".
///
/// So this record carries no status. A product is never "sold"; some of it is.
/// What it carries instead is a count and the product's own reorder level, and
/// `stock_level.dart` turns those two into the only question the list answers.
library;

import '../common/dates.dart';
import '../common/search.dart';
import '../inventory/purchase_costing.dart' show asAmount;
import 'stock_level.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    this.brand = '',
    this.category = '',
    this.variant = '',
    this.colour = '',
    this.sku = '',
    this.supplier = '',
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.mrp = 0,
    this.stockCount = 0,
    this.reorderLevel = 0,
    this.photos = const [],
    this.labelNumber,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String brand;

  /// From the shop's own vocabulary in settings — a category typed into the
  /// form that is not on the list joins it, so the next person finds it.
  final String category;

  final String variant;
  final String colour;

  /// The shop's own code, if it uses one. Not the shop label: a label is
  /// minted by the registry and is unique across every kind of record, while
  /// an SKU is whatever the shop writes on the box.
  final String sku;

  final String supplier;

  /// What the shop pays. Never printed on a label and never shown on the
  /// public scan page.
  final num costPrice;

  final num sellingPrice;

  /// The printed maximum price. Kept so the counter can see at a glance that
  /// it is not selling above it.
  final num mrp;

  /// How many are on the shelf. Changed only through a movement — see
  /// `stock_movement.dart` for why there is no setter for this anywhere.
  final int stockCount;

  /// This product's own low-stock threshold. Zero means no alert is
  /// configured, and nothing invents one.
  final int reorderLevel;

  final List<String> photos;

  /// The shop label on the shelf edge, once the registry has minted one.
  final int? labelNumber;

  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get title =>
      [brand, name, variant, colour].where((p) => p.isNotEmpty).join(' ');

  StockLevel get level => stockLevelFor(stockCount, reorderLevel);
  bool get needsOrdering => needsReordering(stockCount, reorderLevel);
  bool get isSellable => stockCount > 0;

  /// Null when no reorder level is set — there is no target to get back to.
  int? get suggestedOrder => suggestedReorderQuantity(stockCount, reorderLevel);

  /// What the shop makes on one.
  num get unitProfit => sellingPrice - costPrice;

  /// What the stock on the shelf cost, and what it would bring in.
  num get stockCost => costPrice * stockCount;
  num get stockValue => sellingPrice * stockCount;

  /// Priced at or below what it cost. Flagged, never refused — a loss leader
  /// is a decision.
  bool get soldAtALoss => sellingPrice > 0 && unitProfit <= 0;

  /// Priced above the printed maximum. Worth saying loudly: it is the kind of
  /// thing a customer photographs.
  bool get aboveMrp => mrp > 0 && sellingPrice > mrp;

  String? get frontPhoto => photos.isEmpty ? null : photos.first;

  bool matches(String? query) => matchesQuery(query, [
    name,
    brand,
    category,
    variant,
    colour,
    sku,
    supplier,
    labelNumber?.toString(),
  ]);

  Product copyWith({
    String? name,
    String? brand,
    String? category,
    String? variant,
    String? colour,
    String? sku,
    String? supplier,
    num? costPrice,
    num? sellingPrice,
    num? mrp,
    int? stockCount,
    int? reorderLevel,
    List<String>? photos,
    int? labelNumber,
    String? notes,
    DateTime? updatedAt,
  }) => Product(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    variant: variant ?? this.variant,
    colour: colour ?? this.colour,
    sku: sku ?? this.sku,
    supplier: supplier ?? this.supplier,
    costPrice: costPrice ?? this.costPrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    mrp: mrp ?? this.mrp,
    stockCount: stockCount ?? this.stockCount,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    photos: photos ?? this.photos,
    labelNumber: labelNumber ?? this.labelNumber,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Product fromMap(String id, Map<String, Object?> map) => Product(
    id: id,
    name: _str(map['name']),
    brand: _str(map['brand']),
    category: _str(map['category']),
    variant: _str(map['variant']),
    colour: _str(map['colour'] ?? map['color']),
    sku: _str(map['sku']),
    supplier: _str(map['supplier']),
    costPrice: asAmount(map['costPrice'] ?? map['purchasePrice']),
    sellingPrice: asAmount(map['sellingPrice'] ?? map['price']),
    mrp: asAmount(map['mrp']),
    // A count written as a string, or a double from a build that stored it
    // as a number field. Negative is read as zero: a negative count is a
    // belief that is certainly wrong, and carrying it forward would let a
    // sale "succeed" against stock that does not exist.
    stockCount: _count(map['stockCount'] ?? map['stock'] ?? map['quantity']),
    reorderLevel: _count(map['reorderLevel'] ?? map['lowStockThreshold']),
    photos: _strings(map['photos']),
    labelNumber: _int(map['labelNumber']),
    notes: _str(map['notes']),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'brand': brand,
    'category': category,
    'variant': variant,
    'colour': colour,
    'sku': sku,
    'supplier': supplier,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'mrp': mrp,
    'stockCount': stockCount,
    'reorderLevel': reorderLevel,
    'photos': photos,
    'labelNumber': labelNumber,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static String _str(Object? v) => v == null ? '' : v.toString().trim();

  static int _count(Object? v) {
    final n = _int(v) ?? 0;
    return n < 0 ? 0 : n;
  }

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim().replaceAll(',', ''));
    return null;
  }

  static List<String> _strings(Object? v) => v is Iterable
      ? [
          for (final e in v)
            if (e != null) e.toString(),
        ]
      : const [];
}

/// The shop's own product categories. Lives in `settings` once the backend is
/// wired; this is what a fresh shop starts with, and a category typed into the
/// form that is not here joins the list.
const List<String> kProductCategories = [
  'Screen guard',
  'Back cover',
  'Charger',
  'Cable',
  'Earphones',
  'Bluetooth earbuds',
  'Power bank',
  'Memory card',
  'SIM tools',
  'Car accessory',
  'Speaker',
  'Smartwatch',
  'New handset',
  'Other',
];
