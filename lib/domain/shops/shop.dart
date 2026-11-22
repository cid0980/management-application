/// ONE SHOP
///
/// The app is sold to many mobile shops. A shop is the tenant: everything the
/// app records — stock, customers, sales, service orders, labels, settings —
/// hangs off one shop and is invisible to every other.
///
/// The record itself is small. What matters about a shop is not its fields,
/// it is that it is the boundary.
library;

import '../common/dates.dart';
import '../common/phone.dart';

class Shop {
  const Shop({
    required this.id,
    required this.name,
    this.ownerUid = '',
    this.phone = '',
    this.address = '',
    this.gstin = '',
    this.gstRate = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// What the shop calls itself. Printed on bills and job cards, so it is the
  /// one field a shop cannot be created without.
  final String name;

  /// Whoever created it. They are an admin of it by definition, and they are
  /// the one member who cannot be removed — a shop with no admin is a shop
  /// nobody can administer.
  final String ownerUid;

  final String phone;
  final String address;

  /// India's tax registration, printed on an invoice when the shop has one.
  final String gstin;

  /// The GST rate, in percent, the shop's prices include; 0 is off. Printed
  /// as a CGST/SGST split on bills only when there is also a [gstin].
  final num gstRate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Shop fromMap(String id, Map<String, Object?> map) => Shop(
    id: id,
    name: (map['name'] ?? '').toString().trim(),
    ownerUid: (map['ownerUid'] ?? '').toString().trim(),
    phone: normalizePhone((map['phone'] ?? '').toString()),
    address: (map['address'] ?? '').toString().trim(),
    gstin: (map['gstin'] ?? '').toString().trim().toUpperCase(),
    gstRate: map['gstRate'] is num ? map['gstRate'] as num : 0,
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'ownerUid': ownerUid,
    'phone': phone,
    'address': address,
    'gstin': gstin,
    'gstRate': gstRate,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  Shop copyWith({
    String? name,
    String? phone,
    String? address,
    String? gstin,
    num? gstRate,
    DateTime? updatedAt,
  }) => Shop(
    id: id,
    name: name ?? this.name,
    ownerUid: ownerUid,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    gstin: gstin ?? this.gstin,
    gstRate: gstRate ?? this.gstRate,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// IS THIS SHOP GOOD TO CREATE
///
/// Deliberately short. Somebody signing up for the first time is standing in
/// their shop with a customer waiting, and a long form is a reason to give up.
/// The name is the only thing that cannot be filled in later, because it goes
/// on every bill the shop prints.
class ShopValidation {
  const ShopValidation(this.errors, this.warnings);

  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

ShopValidation validateShop(Shop shop) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  if (shop.name.trim().isEmpty) {
    errors['name'] = "The shop's name is needed — it goes on every bill";
  } else if (shop.name.trim().length < 2) {
    errors['name'] = 'That is too short to be a shop name';
  }

  if (shop.phone.isNotEmpty && !isDiallablePhone(shop.phone)) {
    errors['phone'] = 'That is not a ten-digit mobile number';
  }

  // 15 characters: two state digits, ten of PAN, then three more. Checked for
  // shape only — verifying a GSTIN is the tax portal's job, and refusing a
  // real one because of an over-strict pattern would stop the shop printing.
  if (shop.gstin.isNotEmpty && shop.gstin.length != 15) {
    warnings['gstin'] =
        'A GSTIN is 15 characters — this one is ${shop.gstin.length}';
  }

  if (shop.phone.isEmpty) {
    warnings['phone'] = 'No phone number, so bills will not carry one';
  }

  return ShopValidation(errors, warnings);
}

/// A readable shop id from the shop's name.
///
/// `Sri Balaji Mobiles` becomes `sri-balaji-mobiles`, with a short suffix to
/// keep it unique. Readable because it shows up in support conversations and
/// in the console, and a wall of random ids makes those conversations harder
/// than they need to be.
String shopIdFrom(String name, {required String suffix}) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final base = slug.isEmpty ? 'shop' : slug;
  // Firestore document ids have a length limit, and a very long shop name
  // would otherwise push the suffix past it.
  final trimmed = base.length > 40 ? base.substring(0, 40) : base;
  return '$trimmed-$suffix';
}
