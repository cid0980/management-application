/// WHERE ENQUIRIES COME FROM
///
/// Thin, because an enquiry has no workflow to protect: any status may follow
/// any other, and reopening a Lost enquiry because the customer came back is
/// an ordinary Tuesday.
///
/// The one thing this repository will not do is close an enquiry as **Won**
/// with nothing to point at. A conversion with no sale or repair behind it is
/// a number that flatters the shop and means nothing, and the rule lives in
/// one place — `wonBlockFor` — so the form and the status chip cannot disagree
/// about it.
library;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../domain/common/phone.dart';
import '../domain/enquiries/enquiry.dart';
import '../domain/enquiries/enquiry_state.dart';

abstract class EnquiryRepository extends ChangeNotifier {
  List<Enquiry> get enquiries;
  bool get loading;
  String? get error;

  Future<void> load();

  Enquiry? byId(String id);

  Future<Enquiry> save(Enquiry enquiry);

  /// Move the status.
  ///
  /// Returns the block rather than throwing when Won is refused: a missing
  /// outcome is an ordinary thing to be told about, and the page asks for one.
  Future<EnquiryStatusResult> setStatus(
    String id,
    String status, {
    String? outcomeRef,
  });

  /// Set or clear when to ring them back.
  Future<Enquiry> setFollowUp(String id, DateTime? followUpAt);
}

class EnquiryStatusResult {
  const EnquiryStatusResult.changed(this.enquiry) : block = null;

  EnquiryStatusResult.refused(WonBlock this.block) : enquiry = null;

  final Enquiry? enquiry;
  final WonBlock? block;

  bool get ok => enquiry != null;
  String? get message => block == null ? null : kWonBlockMessages[block];
}

class NoSuchEnquiry implements Exception {
  const NoSuchEnquiry(this.id);
  final String id;
  @override
  String toString() => 'No enquiry $id';
}

class InMemoryEnquiryStore extends ChangeNotifier implements EnquiryRepository {
  InMemoryEnquiryStore({List<Enquiry>? seed}) {
    _enquiries = [...(seed ?? _seedRecords())];
  }

  late List<Enquiry> _enquiries;
  bool _loading = false;
  String? _error;

  @override
  List<Enquiry> get enquiries => List.unmodifiable(_enquiries);

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
  Enquiry? byId(String id) => _enquiries.where((e) => e.id == id).firstOrNull;

  @override
  Future<Enquiry> save(Enquiry enquiry) async {
    final existing = byId(enquiry.id);
    final now = DateTime.now();
    final stored = enquiry.copyWith(
      customerPhone: normalizePhone(enquiry.customerPhone),
      askedAt: enquiry.askedAt ?? existing?.askedAt ?? now,
      // Stamped when it becomes closed, and kept once it is — an enquiry
      // closed twice shows the first time it was dealt with.
      closedAt: enquiry.closed ? (existing?.closedAt ?? now) : null,
      updatedAt: now,
    );
    final index = _enquiries.indexWhere((e) => e.id == stored.id);
    if (index >= 0) {
      _enquiries[index] = stored;
    } else {
      _enquiries.add(stored);
    }
    notifyListeners();
    return stored;
  }

  @override
  Future<EnquiryStatusResult> setStatus(
    String id,
    String status, {
    String? outcomeRef,
  }) async {
    final enquiry = byId(id);
    if (enquiry == null) throw NoSuchEnquiry(id);

    final ref = (outcomeRef ?? enquiry.outcomeRef).trim();
    if (isEnquiryWon(status)) {
      final block = wonBlockFor(ref);
      if (block != null) return EnquiryStatusResult.refused(block);
    }

    final now = DateTime.now();
    final closing = isEnquiryClosed(status);
    final updated = enquiry.copyWith(
      status: status,
      outcomeRef: ref,
      closedAt: closing ? (enquiry.closedAt ?? now) : null,
      updatedAt: now,
    );
    _replace(updated);
    return EnquiryStatusResult.changed(updated);
  }

  @override
  Future<Enquiry> setFollowUp(String id, DateTime? followUpAt) async {
    final enquiry = byId(id);
    if (enquiry == null) throw NoSuchEnquiry(id);
    // Rebuilt rather than copied, because copyWith cannot set a date back to
    // null — and clearing a follow-up is a real thing to want.
    final updated = Enquiry(
      id: enquiry.id,
      customerId: enquiry.customerId,
      customerName: enquiry.customerName,
      customerPhone: enquiry.customerPhone,
      about: enquiry.about,
      question: enquiry.question,
      brand: enquiry.brand,
      model: enquiry.model,
      budget: enquiry.budget,
      quotedPrice: enquiry.quotedPrice,
      status: enquiry.status,
      outcomeRef: enquiry.outcomeRef,
      notes: enquiry.notes,
      handledBy: enquiry.handledBy,
      askedAt: enquiry.askedAt,
      followUpAt: followUpAt,
      closedAt: enquiry.closedAt,
      createdAt: enquiry.createdAt,
      updatedAt: DateTime.now(),
    );
    _replace(updated);
    return updated;
  }

  void _replace(Enquiry enquiry) {
    final index = _enquiries.indexWhere((e) => e.id == enquiry.id);
    if (index < 0) throw NoSuchEnquiry(enquiry.id);
    _enquiries[index] = enquiry;
    notifyListeners();
  }
}

/// Seed enquiries, each one a state the list has to get right.
List<Enquiry> _seedRecords() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    // Overdue: should have been rung back two days ago.
    Enquiry(
      id: 'enq-1',
      customerId: 'c-1',
      customerName: 'Ramesh K',
      customerPhone: '9876543210',
      about: 'Second-hand handset',
      question: 'Wants an A54 in second hand, budget around 17,000',
      brand: 'Samsung',
      model: 'Galaxy A54',
      budget: 17000,
      status: 'Waiting For Stock',
      handledBy: 'Suresh',
      askedAt: today.subtract(const Duration(days: 7)),
      followUpAt: today.subtract(const Duration(days: 2)),
      createdAt: today.subtract(const Duration(days: 7)),
    ),
    // Due today.
    Enquiry(
      id: 'enq-2',
      customerPhone: '9123456780',
      customerName: 'Priya S',
      about: 'Repair',
      question: 'Asked what a Redmi 13C display costs',
      brand: 'Xiaomi',
      model: 'Redmi 13C',
      quotedPrice: 2600,
      status: 'Quoted',
      handledBy: 'Mani',
      askedAt: today.subtract(const Duration(days: 1)),
      followUpAt: today.add(const Duration(hours: 16)),
      createdAt: today.subtract(const Duration(days: 1)),
    ),
    // Won last month, with something to point at. Closed beats overdue: its
    // follow-up date is long past and it is not an alarm.
    Enquiry(
      id: 'enq-3',
      customerId: 'c-5',
      customerName: 'Anand M',
      customerPhone: '9988776655',
      about: 'Second-hand handset',
      question: 'Wanted an iPhone 11',
      status: 'Won',
      outcomeRef: 'INV-20260304-001',
      handledBy: 'Suresh',
      askedAt: today.subtract(const Duration(days: 40)),
      followUpAt: today.subtract(const Duration(days: 38)),
      closedAt: today.subtract(const Duration(days: 36)),
      createdAt: today.subtract(const Duration(days: 40)),
    ),
    // Answered on the spot, with no follow-up date. Not urgent, just not
    // scheduled — it sorts last rather than first.
    Enquiry(
      id: 'enq-4',
      customerPhone: '9000022222',
      about: 'Accessory',
      question: 'Asked whether the shop stocks 65W chargers',
      status: 'Open',
      askedAt: today.subtract(const Duration(days: 3)),
      createdAt: today.subtract(const Duration(days: 3)),
    ),
    // Written by an older build: the question under its old key, and a status
    // this one has never heard of.
    Enquiry.fromMap('enq-5', {
      'customerPhone': '+91 90000 11111',
      'customerName': 'Kavitha R',
      'enquiry': 'Asked about trading in a Vivo Y21',
      'about': 'Trade-in value',
      'status': 'Call Back Later',
      'budget': '8,000',
      'askedAt': today.subtract(const Duration(days: 5)).toIso8601String(),
      'followUpAt': today.add(const Duration(days: 2)).toIso8601String(),
    }),
  ];
}
