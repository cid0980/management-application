/// IS THIS PRODUCT GOOD TO SAVE
///
/// One validator, as everywhere else in this app.
///
/// What is deliberately **not** validated here is the stock count. A form
/// cannot set a count: stock moves through `stock_movement.dart` and nowhere
/// else, so there is no field here to be wrong. A new product starts at zero
/// and the first delivery is a `received` movement — which also means the very
/// first thing in its history says where the stock came from.
library;

import 'product.dart';

class ProductValidation {
  const ProductValidation(this.errors, this.warnings);

  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

ProductValidation validateProduct(
  Product product, {

  /// Everything already on the shelf, so a second record for the same thing
  /// can be caught here rather than discovered when the counts disagree.
  Iterable<Product> existing = const [],
}) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  if (product.name.trim().isEmpty) {
    errors['name'] = 'A name is needed — it is what the counter searches for';
  }
  if (product.category.trim().isEmpty) {
    warnings['category'] =
        'No category, so this will not group with anything on the list';
  }

  if (product.sellingPrice <= 0) {
    errors['sellingPrice'] = 'A selling price is needed';
  }
  if (product.costPrice < 0 || product.mrp < 0) {
    errors['costPrice'] = 'A price cannot be negative';
  }
  if (product.reorderLevel < 0) {
    errors['reorderLevel'] = 'A reorder level cannot be negative';
  }

  // Two records for one thing is how the counts start disagreeing: one till
  // sells from each and neither is right.
  final clash = _duplicateOf(product, existing);
  if (clash != null) {
    errors['name'] = 'Already on the list as "${clash.title}"';
  }

  // An SKU is the shop's own code, so two products sharing one makes the code
  // useless for exactly the job it exists for.
  if (product.sku.trim().isNotEmpty) {
    final sameSku = existing.where(
      (p) =>
          p.id != product.id &&
          p.sku.trim().toLowerCase() == product.sku.trim().toLowerCase(),
    );
    if (sameSku.isNotEmpty) {
      errors['sku'] = 'That SKU is already on "${sameSku.first.title}"';
    }
  }

  if (product.costPrice == 0) {
    warnings['costPrice'] =
        'No cost price, so the margin on this product cannot be worked out';
  } else if (product.soldAtALoss) {
    warnings['sellingPrice'] =
        'Selling at ₹${product.sellingPrice} against a ₹${product.costPrice} '
        'cost';
  }

  if (product.aboveMrp) {
    // Selling above the MRP is against the law, not a matter of taste
    // (FM #39): refused, not just warned.
    errors['sellingPrice'] =
        'Priced above the printed maximum of ₹${product.mrp}';
  }

  if (product.frontPhoto == null) {
    warnings['photos'] =
        'No photo — the counter has only the name to go on when searching';
  }

  if (product.reorderLevel == 0) {
    // Said rather than guessed at. An alert nobody chose is an alert nobody
    // trusts.
    warnings['reorderLevel'] =
        'No reorder level, so this will never show as low — only as out of '
        'stock';
  }

  return ProductValidation(errors, warnings);
}

/// The same thing already on the list.
///
/// Matched on brand, name, variant and colour together, because "Case" on its
/// own is a dozen different products and "Spigen Case A54 Black" is one.
Product? _duplicateOf(Product product, Iterable<Product> existing) {
  String key(Product p) => [
    p.brand,
    p.name,
    p.variant,
    p.colour,
  ].map((s) => s.trim().toLowerCase()).join('|');
  final mine = key(product);
  if (product.name.trim().isEmpty) return null;
  for (final other in existing) {
    if (other.id == product.id) continue;
    if (key(other) == mine) return other;
  }
  return null;
}
