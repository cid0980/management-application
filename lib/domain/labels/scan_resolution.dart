/// WHAT A SCAN MEANS
///
/// Two kinds of number get scanned at this counter, and **length alone tells
/// them apart**: 14–16 digits is a factory IMEI, anything shorter and numeric
/// is a shop label. The shop's labels start at 26001, so five digits for years.
///
/// The failure this replaces: scanning the back of a phone while in label mode
/// returned "not found". Staff read that as "the label was never printed" and
/// printed a second one. The right answer is "that is an IMEI — did you mean to
/// start an intake", and that is only possible because classifying the code is
/// kept separate from looking it up.
///
/// The scanner has three modes because it is used for three jobs: find the
/// record a label belongs to, take a phone in for repair, or buy a phone. The
/// mode decides what a scan *does*, never what it *is*.
library;

import '../devices/tac_registry.dart';
import '../inventory/imei.dart';
import 'label_entry.dart';

enum ScannerMode {
  /// Find the record this label belongs to.
  label,

  /// Start a service intake from the phone in your hand.
  intakeService,

  /// Start a second-hand purchase from the phone in your hand.
  intakePurchase,
}

const Map<ScannerMode, String> kScannerModeLabels = {
  ScannerMode.label: 'Shop label',
  ScannerMode.intakeService: 'New repair',
  ScannerMode.intakePurchase: 'Buy a handset',
};

const Map<ScannerMode, String> kScannerModeHints = {
  ScannerMode.label: 'Scan a sticker to open the record it was printed for.',
  ScannerMode.intakeService:
      "Scan the phone's barcode to start a repair with the brand and model "
      'filled in.',
  ScannerMode.intakePurchase:
      "Scan the phone's barcode to start a purchase with the brand and model "
      'filled in.',
};

/// What the scanner should do about a code.
sealed class ScanOutcome {
  const ScanOutcome();
}

/// A shop label that resolves. [view] already has the live record laid over
/// the printed copy.
class ScanOpensRecord extends ScanOutcome {
  const ScanOpensRecord(this.view);

  final LabelView view;

  /// Null when the record is gone or the label's kind is unreadable — the
  /// label still resolved, there is just nowhere to go.
  String? get route => view.canOpen ? view.route : null;
}

/// A shop label number the registry has never heard of.
///
/// Said plainly, with the number, because the number is written on the sticker
/// and is what someone will quote down the phone.
class ScanUnknownLabel extends ScanOutcome {
  const ScanUnknownLabel(this.number);

  final int number;
}

/// An IMEI, and what the device table makes of it.
///
/// In an intake mode this starts the form. In label mode it is the "did you
/// mean to start an intake" answer, instead of a bare failure.
class ScanIsImei extends ScanOutcome {
  const ScanIsImei({
    required this.imei,
    required this.tac,
    this.device,
    required this.wasLookingForALabel,
  });

  final String imei;
  final String? tac;

  /// Null whenever the table does not have this TAC, which is the ordinary
  /// case. The form opens either way; it just has less filled in.
  final TacEntry? device;

  /// True when this was scanned in label mode. The scanner says so rather than
  /// failing, which is the whole point of classifying before looking up.
  final bool wasLookingForALabel;
}

/// Not a number this shop uses. A barcode off a retail box, a loyalty card,
/// a QR code for a Wi-Fi network.
class ScanUnreadable extends ScanOutcome {
  const ScanUnreadable(this.raw);

  final String raw;
}

/// Resolve a scanned code.
///
/// [lookupLabel] is the registry read and [liveRecord] fetches the record the
/// label points at, both passed in so this stays pure and the whole decision
/// can be stated in a test.
ScanOutcome resolveScan(
  String? raw, {
  required ScannerMode mode,
  required LabelEntry? Function(int number) lookupLabel,
  required Map<String, Object?>? Function(LabelEntry entry) liveRecord,
  TacRegistry? tacs,
}) {
  final code = (raw ?? '').trim();
  if (code.isEmpty) return ScanUnreadable(code);

  switch (classifyScan(code)) {
    case ScannedCode.imei:
      final imei = normalizeImei(code);
      return ScanIsImei(
        imei: imei,
        tac: tacOf(imei),
        device: tacs?.lookup(imei),
        // The mode did not change what the code IS. It only changes what the
        // scanner offers to do next.
        wasLookingForALabel: mode == ScannerMode.label,
      );

    case ScannedCode.shopLabel:
      final number = int.tryParse(normalizeImei(code));
      if (number == null) return ScanUnreadable(code);
      final entry = lookupLabel(number);
      if (entry == null) return ScanUnknownLabel(number);
      return ScanOpensRecord(resolveLabel(entry, liveRecord(entry)));

    case ScannedCode.unknown:
      return ScanUnreadable(code);
  }
}
