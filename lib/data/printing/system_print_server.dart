/// WHERE A LABEL GOES
///
/// No shop PC, no print server: a label is printed from the phone.
///
/// - **a Bluetooth label printer chosen in Settings** — the TSPL program for
///   the sticker, straight to the printer (`bluetooth_label_printer.dart`);
/// - **otherwise** — the sticker as a PDF to the phone's own print menu
///   (a Wi-Fi printer, or Save as PDF).
///
/// The choice is read at print time, so changing it in Settings takes effect
/// on the next label.
library;

import '../firestore_errors.dart';

import 'package:printing/printing.dart';

import '../print_server.dart';
import 'bluetooth_label_printer.dart';
import 'documents.dart';
import 'label_printer_prefs.dart';

class ShopPrintServer implements PrintServer {
  ShopPrintServer({
    required this.prefs,
    PrintServer? bluetooth,
    PrintServer? onDevice,
  }) : _bluetooth = bluetooth ?? BluetoothLabelPrinter(prefs: prefs),
       _onDevice = onDevice ?? SystemPrintServer();

  final LabelPrinterPrefs prefs;
  final PrintServer _bluetooth;
  final PrintServer _onDevice;

  @override
  Future<PrintResult> printLabel(LabelPrintJob job) => prefs.usesBluetooth
      ? _bluetooth.printLabel(job)
      : _onDevice.printLabel(job);
}

/// The sticker as a PDF, to the phone's print dialog.
class SystemPrintServer implements PrintServer {
  @override
  Future<PrintResult> printLabel(LabelPrintJob job) async {
    try {
      final bytes = await buildLabelPdf(
        number: job.number,
        title: job.title,
        subtitle: job.subtitle,
        price: job.price,
        copies: job.copies,
      );
      final printed = await Printing.layoutPdf(
        name: 'label-${job.number}',
        onLayout: (_) async => bytes,
      );
      // Backing out of the print dialog is not a failure of the label: the
      // number is assigned and the sticker can be printed again from the
      // phone's page.
      return printed
          ? const PrintResult.sent()
          : PrintResult.failed('Printing was cancelled');
    } catch (e) {
      // Reported, never thrown: the save it followed has already happened.
      return PrintResult.failed('Could not print the label. ${plainError(e)}');
    }
  }
}
