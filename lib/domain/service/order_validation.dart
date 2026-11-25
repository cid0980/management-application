/// IS THIS ORDER GOOD TO SAVE
///
/// One validator, both save paths. The service intake is where this rule came
/// from: the two dates were checked on "Save" and not on "Save & Print", so a
/// job card went out carrying an Invalid Date, and the order it was printed
/// for then read as neither overdue nor due nor anything else.
///
/// `requireOrderDates` is the one that throws, and it stays that way — a
/// caller cannot forget to look at an exception. This wraps it so a form can
/// put the message under the field instead of catching.
library;

import 'checklist.dart';
import 'order_state.dart';
import 'service_order.dart';

class OrderValidation {
  const OrderValidation(this.errors, this.warnings);

  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

OrderValidation validateOrder(ServiceOrder order) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  // The customer, because an order under nobody cannot be rung when the part
  // arrives, and cannot be chased when the phone sits here for a month.
  if (order.customerPhone.trim().isEmpty && order.customerId == null) {
    errors['customer'] = 'A customer is needed — pick one or add them';
  }

  if (order.brand.trim().isEmpty) errors['brand'] = 'Brand is needed';
  if (order.model.trim().isEmpty) errors['model'] = 'Model is needed';

  if (order.imei.isEmpty) {
    warnings['imei'] =
        'No IMEI — take it off the phone if it powers on, not the box';
  } else if (order.imei.length < 14 || order.imei.length > 16) {
    errors['imei'] = 'An IMEI is 14 to 16 digits; this is ${order.imei.length}';
  }

  // At least one complaint: the job card and the final bill are both built
  // from these, so an order with none produces two blank documents.
  if (order.complaints.isEmpty) {
    errors['complaints'] = 'Say what is wrong with it — at least one complaint';
  }

  // Both dates, in the one place that decides.
  try {
    final dates = requireOrderDates(
      order.receivedAt,
      order.expectedCompletionAt,
    );
    if (dates.expected.isBefore(dates.received)) {
      errors['expectedCompletionAt'] =
          'The promised date is before the device came in';
    }
    // A day still to come would push today's advance out of today's
    // figures. A new job only: an old one keeps the day it was given.
    final now = DateTime.now();
    if (order.createdAt == null &&
        dates.received.isAfter(
          DateTime(now.year, now.month, now.day, 23, 59),
        )) {
      errors['receivedAt'] = 'A phone cannot come in on a day still to come';
    }
  } on ArgumentError {
    if (order.receivedAt == null) {
      errors['receivedAt'] = 'When the device came in is needed';
    }
    if (order.expectedCompletionAt == null) {
      errors['expectedCompletionAt'] =
          'What the customer was promised is needed';
    }
  }

  if (order.estimatedPrice < 0) {
    errors['estimatedPrice'] = 'An estimate cannot be negative';
  } else if (order.estimatedPrice == 0) {
    // Required: a phone is not taken in without telling the customer what
    // it will cost (the owner's rule).
    errors['estimatedPrice'] = 'Give the customer an estimate';
  }
  if (order.advancePaid < 0) {
    errors['advancePaid'] = 'An advance cannot be negative';
  }
  if (order.rawMaterialCost < 0 || order.outsideLabourCost < 0) {
    errors['costs'] = 'A cost cannot be negative';
  }

  if (order.estimatedPrice > 0 && order.quotedAtALoss) {
    warnings['estimatedPrice'] =
        'Quoted ₹${order.estimatedPrice} against ₹${order.costs} of costs';
  }

  if (order.advanceExceedsCharge) {
    warnings['advancePaid'] =
        'The advance (₹${order.advancePaid}) is more than the job — there is '
        'change to give back';
  }

  // A locked phone with no way in cannot be tested, and an untested job comes
  // straight back. Worth saying; the shop decides.
  if (order.lockType != 'None' && order.lockValue.trim().isEmpty) {
    warnings['lockValue'] =
        'Locked with ${order.lockType} but nothing recorded to unlock it';
  }

  if (order.technician.trim().isEmpty) {
    warnings['technician'] = 'Nobody is on this job yet';
  }

  return OrderValidation(errors, warnings);
}

/// Whether the job card can be printed.
///
/// The same errors as a save. Printing saves first, so there is nothing extra
/// to ask for — unlike the seller's declaration, which needs a signature.
OrderValidation validateJobCard(ServiceOrder order) => validateOrder(order);

/// Why an order cannot be completed yet.
///
/// Completion is the one transition that is not a status change: it is passing
/// the pre-delivery checklist. This is the gate, and the only thing allowed to
/// open it.
enum CompletionBlock {
  /// Already handed back.
  alreadyClosed,

  /// The list is not fully ticked.
  checklistIncomplete,

  /// Nothing has been charged. A completed order with no final price is a
  /// phone handed back for free, which is sometimes true and never implicit.
  noFinalPrice,
}

const Map<CompletionBlock, String> kCompletionBlockMessages = {
  CompletionBlock.alreadyClosed: 'This order has already been handed back',
  CompletionBlock.checklistIncomplete:
      'Every pre-delivery check has to be ticked before the phone goes back',
  CompletionBlock.noFinalPrice:
      'Say what is being charged — zero is allowed, but say it',
};

class CompletionCheck {
  const CompletionCheck(this.blocks, this.remaining);

  final List<CompletionBlock> blocks;

  /// The labels still unticked, so the page names them instead of saying the
  /// list is incomplete.
  final List<String> remaining;

  bool get allowed => blocks.isEmpty;

  String? get firstMessage =>
      blocks.isEmpty ? null : kCompletionBlockMessages[blocks.first];
}

/// Whether [order] may be completed against [checklistItems] from settings.
///
/// An empty checklist passes: a shop that has not configured one has nothing
/// to verify, and failing it would stop every order in the shop from being
/// finished until somebody built a list nobody asked for.
CompletionCheck canComplete(
  ServiceOrder order, {
  required List<String> checklistItems,
}) {
  final blocks = <CompletionBlock>[];
  if (order.closed) blocks.add(CompletionBlock.alreadyClosed);
  if (!allChecked(checklistItems, order.checklist)) {
    blocks.add(CompletionBlock.checklistIncomplete);
  }
  if (order.finalPrice == null) blocks.add(CompletionBlock.noFinalPrice);

  final remaining = [
    for (final e in checklistEntries(checklistItems))
      if (order.checklist[e.key] != true) e.item,
  ];
  return CompletionCheck(blocks, remaining);
}

/// The shop's default pre-delivery checklist. Lives in `settings` once the
/// backend is wired; these are the checks a fresh shop starts with.
///
/// Deliberately includes two labels a person reads as different — they are
/// exactly the case `checklistEntries` resolves, and keeping them here means a
/// collision is caught by the default list rather than by a shop that typed
/// one.
const List<String> kDefaultPreDeliveryChecklist = [
  'Display OK',
  'Touch working across the screen',
  'Charging tested',
  'Battery holds charge',
  'Both SIM slots register',
  'Wi-Fi and Bluetooth',
  'Speaker and earpiece',
  'Microphone',
  'Front and rear camera',
  'Fingerprint / face unlock',
  'Original complaint fixed',
  'Accessories returned to the customer',
  'Device cleaned',
];
