/// LABELS, WITHOUT A SHOP PC
///
/// The label printer on the counter PC (`HttpPrintServer`) is how the
/// original shop printed stickers. Most shops buying this app have no such
/// PC, and until now that meant labels were only recorded, never printed.
///
/// So a label goes wherever this shop can print:
///
/// - **a print-server address in Settings** — to the counter PC, as before;
/// - **none** — the 50 × 30 mm sticker, as a PDF, to the phone's own print
///   dialog (a Bluetooth label printer, a Wi-Fi printer, or Save as PDF).
///
/// The address is read at print time, so setting it in Settings takes effect
/// on the next label without restarting the app.
library;

import 'package:printing/printing.dart';

import '../print_server.dart';
import '../settings_repository.dart';
import 'documents.dart';

class ShopPrintServer implements PrintServer {
  ShopPrintServer({required this.settings, PrintServer? onDevice})
    : _onDevice = onDevice ?? SystemPrintServer();

  final SettingsRepository settings;
  final PrintServer _onDevice;

  @override
  Future<PrintResult> printLabel(LabelPrintJob job) {
    final url = settings.settings.printServerUrl.trim();
    if (url.isNotEmpty) return HttpPrintServer(baseUrl: url).printLabel(job);
    return _onDevice.printLabel(job);
  }
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
      return PrintResult.failed('Could not print the label: $e');
    }
  }
}
