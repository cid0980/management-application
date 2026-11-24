/// IS THIS PURCHASE GOOD TO SAVE
///
/// **One** place answers that, for the same reason the service intake
/// validates its two dates in one place: "Save" and "Save & Print" must not
/// disagree about what a valid record is. The shop had a declaration printed
/// with a blank seller name on it, because printing took a different path to
/// saving and only one of them checked.
///
/// Errors block the save. Warnings do not — they are things worth a second
/// look that the shop is still allowed to decide for itself:
///
/// - an IMEI that fails its check digit, because a mis-scan is still the only
///   record of which handset this is and refusing it means refusing the
///   purchase;
/// - an asking price at or below cost, because a clearance is a decision.
///
/// What is required is what the shop's counter app requires: the seller, the
/// phone down to its RAM and storage, its IMEI (and serial, on an iPhone),
/// what was paid, what it will sell for, when it was bought, and a front
/// photo.
library;

import 'condition_grade.dart';
import 'imei.dart';
import 'second_hand_device.dart';
import '../common/phone.dart';

class ValidationResult {
  const ValidationResult(this.errors, this.warnings);

  /// Field key to message. Keyed so the form can put the message under the
  /// field rather than in a snackbar nobody reads.
  final Map<String, String> errors;
  final Map<String, String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// The one validator. Both save paths call this and nothing else.
ValidationResult validatePurchase(SecondHandDevice d) {
  final errors = <String, String>{};
  final warnings = <String, String>{};

  if (d.brand.trim().isEmpty) errors['brand'] = 'Brand is needed';
  if (d.model.trim().isEmpty) errors['model'] = 'Model is needed';
  // Records from before RAM and storage were asked apart carry the old
  // one-box variant, and are not made invalid by this.
  if (d.variant.isEmpty) {
    if (d.ram.trim().isEmpty) errors['ram'] = 'RAM is needed';
    if (d.rom.trim().isEmpty) errors['rom'] = 'Storage (ROM) is needed';
  }
  // A size, as the box prints it: 8GB, 128GB, 1TB.
  final size = RegExp(r'^\d{1,4}(\.\d)?\s?(MB|GB|TB)$', caseSensitive: false);
  if (d.ram.trim().isNotEmpty && !size.hasMatch(d.ram.trim())) {
    errors['ram'] = 'Write RAM as the box does, like 8GB';
  }
  if (d.rom.trim().isNotEmpty && !size.hasMatch(d.rom.trim())) {
    errors['rom'] = 'Write storage as the box does, like 128GB or 1TB';
  }
  final battery = d.batteryHealth;
  if (battery != null && (battery < 0 || battery > 100)) {
    errors['batteryHealth'] = 'Battery health is 0 to 100%';
  }
  // An iPhone's serial is what Apple's own checks run on.
  if (isApple(d.brand) && d.serial.trim().isEmpty) {
    errors['serial'] = 'The serial number is needed for an iPhone';
  }

  // The IMEI is the handset's identity: without it a warranty claim, a
  // blacklist check and a scan all have nothing to go on.
  if (d.imei.isEmpty) {
    errors['imei'] = 'IMEI is needed — take it off the phone, not the box';
  } else if (!looksLikeImei(d.imei)) {
    errors['imei'] = 'An IMEI is 14 to 16 digits; this is ${d.imei.length}';
  } else if (d.imei.length == 15 && !passesLuhn(d.imei)) {
    // Stock is bought on its IMEI: one that cannot be real is refused.
    errors['imei'] = 'This IMEI\'s check digit does not add up — re-scan it';
  }

  if (d.imei2.isNotEmpty && !looksLikeImei(d.imei2)) {
    errors['imei2'] = 'An IMEI is 14 to 16 digits';
  }
  if (d.imei2.isNotEmpty && d.imei2 == d.imei) {
    errors['imei2'] = 'The two IMEIs are the same number';
  }

  if (d.purchasePrice <= 0) {
    errors['purchasePrice'] = 'What was paid for it is needed';
  }
  if (d.askingPrice < 0) {
    errors['askingPrice'] = 'A selling price cannot be negative';
  } else if (d.askingPrice == 0) {
    errors['askingPrice'] = 'The selling price is needed';
  }
  if (d.purchasedAt == null) {
    errors['purchasedAt'] = 'The purchase date is needed';
  }

  // A listing with no picture of the front is not a listing.
  if (d.frontPhoto == null) {
    errors['photos'] = 'A front view of the device is needed';
  }

  if (d.sellerName.trim().isEmpty) {
    errors['sellerName'] = "The seller's name is needed for the declaration";
  }
  if (d.sellerPhone.trim().isEmpty) {
    errors['sellerPhone'] = "The seller's phone number is needed";
  } else if (!isDiallablePhone(d.sellerPhone)) {
    errors['sellerPhone'] = 'That is not a ten-digit mobile number';
  }
  if (d.sellerAltPhone.isNotEmpty && !isDiallablePhone(d.sellerAltPhone)) {
    errors['sellerAltPhone'] = 'That is not a ten-digit mobile number';
  }

  for (final r in d.repairs) {
    if (r.amount < 0) {
      errors['repairs'] = 'A repair cannot cost a negative amount';
      break;
    }
    if (r.description.trim().isEmpty && r.amount > 0) {
      errors['repairs'] = 'A costed repair needs saying what it was';
      break;
    }
  }

  final grade = d.computedGrade;

  if (d.costing.atALoss) {
    warnings['askingPrice'] =
        'Asking price is at or below the ${d.costing.totalCost} this handset '
        'has cost';
  }

  // A phone that is damaged or locked should be on the bench, not on the
  // shelf. Worth saying, but the shop decides.
  if (d.isSellable && grade.gradeFaults.isNotEmpty) {
    warnings['status'] = 'Marked sellable with ${grade.gradeFaults.join(', ')}';
  }

  return ValidationResult(errors, warnings);
}

/// Whether the seller's declaration can be printed.
///
/// The same errors as a save, plus the signature. Printing a declaration
/// nobody signed is worse than not printing one: it looks like proof.
ValidationResult validateDeclaration(SecondHandDevice d) {
  final base = validatePurchase(d);
  final errors = Map<String, String>.from(base.errors);
  if ((d.sellerSignature ?? '').isEmpty) {
    errors['sellerSignature'] = 'The seller has to sign the declaration';
  }
  if (d.sellerIdProof.trim().isEmpty) {
    errors['sellerIdProof'] = 'An ID proof reference is needed to print';
  }
  return ValidationResult(errors, base.warnings);
}
