/// PRINTING A LABEL
///
/// Where a label goes — a Bluetooth printer or the phone's print menu — is
/// `printing/system_print_server.dart`. Two things shape this interface.
///
/// **Printing saves first.** Always, everywhere in this app. A document
/// printed from unsaved state is a document for a record that does not exist,
/// and a label is the worst case of it: it goes onto a phone and into a
/// customer's hands.
///
/// **A failed print is not a failed save.** The counter PC is off, the printer
/// is out of labels, the Wi-Fi dropped — none of that should undo the work. So
/// printing returns an outcome the screen can report, and never throws into a
/// save path.
library;

class PrintResult {
  const PrintResult.sent() : error = null;
  const PrintResult.failed(this.error);

  /// Null when it went. Shown as itself — "could not print" with no reason is
  /// how someone spends ten minutes on a printer that is simply switched off.
  final String? error;

  bool get sent => error == null;
}

/// What goes on a label: the number, a barcode of that number, and enough text
/// for a human to read the sticker without scanning it.
class LabelPrintJob {
  const LabelPrintJob({
    required this.number,
    required this.title,
    this.subtitle = '',
    this.price,
    this.copies = 1,
  });

  final int number;
  final String title;
  final String subtitle;
  final num? price;
  final int copies;

  Map<String, Object?> toJson() => {
    'number': number,
    // The barcode encodes the number alone. Anything else on it and the
    // scanner's length rule — 14 to 16 digits is an IMEI — stops working.
    'barcode': number.toString(),
    'title': title,
    'subtitle': subtitle,
    'price': price,
    'copies': copies < 1 ? 1 : copies,
  };
}

abstract class PrintServer {
  Future<PrintResult> printLabel(LabelPrintJob job);
}

/// Records what would have been printed, so a flow can be walked end to end
/// in tests and in the offline walk-through.
class RecordingPrintServer implements PrintServer {
  final List<LabelPrintJob> jobs = [];

  /// Set in a test to prove a failed print does not undo the save.
  String? failWith;

  @override
  Future<PrintResult> printLabel(LabelPrintJob job) async {
    if (failWith != null) return PrintResult.failed(failWith!);
    jobs.add(job);
    return const PrintResult.sent();
  }
}
