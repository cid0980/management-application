import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory/imei.dart';
import '../../l10n/l10n.dart';

/// SCANNING AN IMEI
///
/// Ported from the French Mobiles Flutter port (`ui/widgets/imei_field.dart`)
/// into this app's languages.
///
/// An IMEI is fifteen digits nobody types right, so the IMEI box carries a
/// camera button. The camera stays open after the first barcode: a phone box
/// has two IMEIs printed one above the other, and closing the camera between
/// them meant opening it twice. Scan one, scan the other, done.
///
/// Only what looks like an IMEI is taken — a box also carries an EAN and a
/// serial barcode, and picking one of those up would fill the IMEI with the
/// wrong number.
class ImeiScanButton extends StatelessWidget {
  const ImeiScanButton({super.key, required this.onScanned});

  /// The first IMEI, and the second if one was scanned in the same go.
  final void Function(String first, String? second) onScanned;

  Future<void> _scan(BuildContext context) async {
    final pair = await showDialog<(String, String?)>(
      context: context,
      builder: (_) => const _ImeiScanDialog(),
    );
    if (pair == null) return;
    onScanned(pair.$1, pair.$2);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('imei-scan'),
      tooltip: context.l10n.imeiScanTitle,
      icon: Icon(
        Icons.qr_code_scanner,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => _scan(context),
    );
  }
}

class _ImeiScanDialog extends StatefulWidget {
  const _ImeiScanDialog();

  @override
  State<_ImeiScanDialog> createState() => _ImeiScanDialogState();
}

class _ImeiScanDialogState extends State<_ImeiScanDialog> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.qrCode,
    ],
  );

  String? _first;
  String? _second;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? '').replaceAll(RegExp(r'\s'), '');
      if (!looksLikeImei(raw)) continue;
      // The same barcode stays in frame for several frames: ignoring a repeat
      // is what lets the second scan be a different number.
      if (raw == _first || raw == _second) continue;
      setState(() {
        if (_first == null) {
          _first = raw;
        } else {
          _second ??= raw;
        }
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final message = _first == null
        ? l10n.imeiScanPoint
        : _second == null
        ? l10n.imeiScanSecond
        : l10n.imeiScanBoth;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.imeiScanTitle,
                    style: theme.textTheme.titleMedium,
                  ),
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
                height: 240,
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
            Text(message, style: theme.textTheme.bodyMedium),
            if (_first != null) ...[
              const SizedBox(height: 8),
              Text('IMEI 1   $_first', style: theme.textTheme.titleSmall),
              if (_second != null)
                Text('IMEI 2   $_second', style: theme.textTheme.titleSmall),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: _first == null
                  ? null
                  : () => Navigator.of(context).pop((_first!, _second)),
              icon: const Icon(Icons.check),
              label: Text(l10n.imeiScanDone),
            ),
          ],
        ),
      ),
    );
  }
}
