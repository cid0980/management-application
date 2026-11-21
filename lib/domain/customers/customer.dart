/// ONE CUSTOMER
///
/// Everyone the shop has served. The record is thin on purpose — a name, a
/// number, where they live if they said — because the value is in the history
/// hanging off it, not in the fields.
///
/// The phone number is the identity. It is normalized on the way in, so the
/// same person is not in the book three times as `98765 43210`,
/// `+919876543210` and `098765-43210`, which is exactly how they were.
library;

import '../common/dates.dart';
import '../common/phone.dart';
import '../common/search.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.altPhone = '',
    this.email = '',
    this.address = '',
    this.idType = '',
    this.idNumber = '',
    this.walletBalance = 0,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// Stored as ten digits, whatever was typed. This is how the same person is
  /// found rather than added again.
  final String phone;

  final String altPhone;
  final String email;
  final String address;

  /// The ID they showed — Aadhaar, PAN, driving licence, voter ID — and its
  /// number. Asked when someone sells the shop a phone.
  final String idType;
  final String idNumber;

  /// What the shop owes them in credit. Moved only through the wallet rules,
  /// never written directly from a form.
  final num walletBalance;

  final String notes;
  final DateTime? createdAt;

  /// Stamped by every change, including every wallet move. The other till
  /// refreshes its cache on this.
  final DateTime? updatedAt;

  /// For the avatar, and never empty — a walk-in recorded by number alone
  /// still has a number.
  String get initials {
    final source = name.trim().isNotEmpty ? name.trim() : phone;
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.elementAt(1).substring(0, 1))
        .toUpperCase();
  }

  /// What the list and the autocomplete show.
  String get display => name.trim().isEmpty
      ? formatPhone(phone)
      : '$name · ${formatPhone(phone)}';

  bool matches(String? query) =>
      matchesQuery(query, [name, phone, altPhone, email, address]);

  Customer copyWith({
    String? name,
    String? phone,
    String? altPhone,
    String? email,
    String? address,
    String? idType,
    String? idNumber,
    num? walletBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    altPhone: altPhone ?? this.altPhone,
    email: email ?? this.email,
    address: address ?? this.address,
    idType: idType ?? this.idType,
    idNumber: idNumber ?? this.idNumber,
    walletBalance: walletBalance ?? this.walletBalance,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Customer fromMap(String id, Map<String, Object?> map) => Customer(
    id: id,
    name: (map['name'] ?? '').toString().trim(),
    phone: normalizePhone((map['phone'] ?? '').toString()),
    altPhone: normalizePhone((map['altPhone'] ?? '').toString()),
    email: (map['email'] ?? '').toString().trim(),
    address: (map['address'] ?? '').toString().trim(),
    idType: (map['idType'] ?? '').toString().trim(),
    idNumber: (map['idNumber'] ?? '').toString().trim(),
    walletBalance: _num(map['walletBalance']),
    notes: (map['notes'] ?? '').toString().trim(),
    createdAt: normalizeDate(map['createdAt']),
    updatedAt: normalizeDate(map['updatedAt']),
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'phone': phone,
    'altPhone': altPhone,
    'email': email,
    'address': address,
    'idType': idType,
    'idNumber': idNumber,
    'walletBalance': walletBalance,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static num _num(Object? v) {
    if (v is num) return v;
    if (v is String) {
      return num.tryParse(v.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    }
    return 0;
  }
}

/// The kinds of ID a seller shows, as the counter app offers them.
const List<String> kIdTypes = [
  'Aadhaar',
  'PAN',
  'Driving License',
  'Voter ID',
  'Other',
];

/// NOBODY GETS ADDED TWICE
///
/// The sale form autocompletes over everyone served before, and the question it
/// is really asking is "is this person already in the book". The number
/// answers it: two records with the same ten digits are the same person,
/// however differently the name was spelt.
Customer? findByPhone(Iterable<Customer> all, String? phone) {
  final n = normalizePhone(phone);
  if (n.isEmpty) return null;
  for (final c in all) {
    if (samePhone(c.phone, n) || samePhone(c.altPhone, n)) return c;
  }
  return null;
}

/// EVERYBODY SERVED ENDS UP IN THE BOOK
///
/// A repair, a bill or an enquiry taken for somebody who is not in the book
/// used to leave them out of it — the order carried their number, but the
/// Customers page never heard of them, so the shop's list of customers was
/// only the people somebody remembered to add by hand.
///
/// So after such a record is saved, its number is filed as a customer. Null
/// when there is nothing to file: no diallable number (a walk-in who gave
/// none), or somebody with that number is already in the book — the number
/// is the identity, so nobody is added twice.
Customer? newCustomerFor({
  required Iterable<Customer> book,
  required String name,
  required String phone,
  required String id,
  DateTime? now,
}) {
  if (!isDiallablePhone(phone)) return null;
  if (findByPhone(book, phone) != null) return null;
  return Customer(
    id: id,
    name: name.trim(),
    phone: normalizePhone(phone),
    createdAt: now,
  );
}

/// Suggestions for the autocomplete, best first.
///
/// A number typed in full puts the exact match at the top even when the name
/// would have sorted it elsewhere — someone typing ten digits knows who they
/// mean.
List<Customer> suggestCustomers(
  Iterable<Customer> all,
  String? query, {
  int limit = 8,
}) {
  final rows = all.where((c) => c.matches(query)).toList();
  final exact = findByPhone(rows, query);
  rows.sort((a, b) {
    if (exact != null) {
      if (a.id == exact.id) return -1;
      if (b.id == exact.id) return 1;
    }
    // Then whoever was dealt with most recently: the shop's repeat customers
    // come back, and the person at the counter is usually one of them.
    final x = a.updatedAt ?? a.createdAt;
    final y = b.updatedAt ?? b.createdAt;
    if (x == null && y == null) return a.name.compareTo(b.name);
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  });
  return rows.take(limit).toList();
}

/// Is this customer record good to save.
///
/// One place, as everywhere else. A name is not required — a walk-in who gives
/// only a number is a real customer, and refusing the record means the repair
/// goes in under nobody. The NUMBER is required, because it is the identity.
class CustomerValidation {
  const CustomerValidation(this.errors);

  final Map<String, String> errors;

  bool get isValid => errors.isEmpty;
}

CustomerValidation validateCustomer(
  Customer c, {

  /// Everyone already in the book, so a second record for the same number can
  /// be caught here rather than discovered a month later.
  Iterable<Customer> existing = const [],
}) {
  final errors = <String, String>{};

  if (c.phone.trim().isEmpty) {
    errors['phone'] =
        'A phone number is needed — it is how the shop finds them';
  } else if (!isDiallablePhone(c.phone)) {
    errors['phone'] = 'That is not a ten-digit mobile number';
  } else {
    final clash = findByPhone(existing.where((o) => o.id != c.id), c.phone);
    if (clash != null) {
      errors['phone'] = 'Already in the book as ${clash.display}';
    }
  }

  if (c.altPhone.isNotEmpty && !isDiallablePhone(c.altPhone)) {
    errors['altPhone'] = 'That is not a ten-digit mobile number';
  }
  if (c.altPhone.isNotEmpty && samePhone(c.altPhone, c.phone)) {
    errors['altPhone'] = 'Both numbers are the same';
  }
  if (c.email.isNotEmpty && !c.email.contains('@')) {
    errors['email'] = 'That is not an email address';
  }

  return CustomerValidation(errors);
}
