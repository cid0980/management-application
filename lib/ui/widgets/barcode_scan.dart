import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/l10n.dart';
import 'input_sheet.dart';

/// READ ONE BARCODE WITH THE CAMERA
///
/// Ported from the French Mobiles Flutter port's scanner screen. Opens the
/// camera, takes the first barcode it sees, and closes — the caller decides
/// what the code means (a label, an IMEI), so nothing about meaning lives in
/// the camera path.
///
/// The torch is one tap away: labels are read under a counter, and phone
/// boxes are read in a back room.
Future<String?> scanOneBarcode(BuildContext context) => showInputSheet<String>(
  context: context,
  builder: (_) => const _ScanDialog(),
);

class _ScanDialog extends StatefulWidget {
  const _ScanDialog();

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.qrCode,
    ],
  );
  bool _done = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? '').trim();
      if (raw.isEmpty) continue;
      // A label's QR code is a link ending in the number; keep the number.
      final value = raw.contains('/scan/') ? raw.split('/scan/').last : raw;
      _done = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.scanWithCamera,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.scanTorch,
                  icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
                  onPressed: () {
                    _controller.toggleTorch();
                    setState(() => _torch = !_torch);
                  },
                ),
                IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 280,
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.imeiScanNoCamera,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.scanPointAtLabel, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
