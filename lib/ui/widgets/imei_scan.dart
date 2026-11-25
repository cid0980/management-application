import '../../data/firestore_errors.dart';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory/imei.dart';
import '../../data/text_reading/text_reader.dart';
import '../../domain/inventory/serial.dart';
import '../../domain/inventory/text_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import 'busy.dart';
import 'input_sheet.dart';

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
  const ImeiScanButton({super.key, required this.onScanned, this.hint});

  /// The first IMEI, and the second if one was scanned in the same go.
  final void Function(String first, String? second) onScanned;

  /// Where to point the camera, when it is not the usual box or sticker —
  /// a repair's phone is in the hand and often switches on.
  final String? hint;

  Future<void> _scan(BuildContext context) async {
    final pair = await showInputSheet<(String, String?)>(
      context: context,
      builder: (_) => _ImeiScanDialog(hint: hint),
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
  const _ImeiScanDialog({this.hint});

  final String? hint;

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

  /// Said after a photo that had no IMEI in it.
  String? _note;

  /// No barcode on the screen or sticker: a photo, and the digits read.
  Future<void> _readText() async {
    final l10n = context.l10n;
    final TextCodes? found;
    try {
      found = await _readCodes(context, _controller, l10n);
    } catch (e) {
      if (mounted) setState(() => _note = l10n.readFailed(plainError(e)));
      return;
    }
    if (!mounted || found == null) return;
    final codes = found;
    setState(() {
      if (codes.imeis.isEmpty) {
        _note = l10n.readNoImei;
      } else {
        _note = null;
        _first = codes.imeis.first;
        _second = codes.imeis.length > 1 ? codes.imeis[1] : null;
      }
    });
  }

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
        ? widget.hint ?? l10n.imeiScanPoint
        : _second == null
        ? l10n.imeiScanSecond
        : l10n.imeiScanBoth;

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
            if (_note != null) ...[
              const SizedBox(height: 8),
              Text(
                _note!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (canReadText)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('read-text'),
                  onPressed: _readText,
                  icon: const Icon(Icons.text_fields),
                  label: Text(l10n.readNumbersButton),
                ),
              ),
            const SizedBox(height: 8),
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

/// SCANNING A SERIAL NUMBER
///
/// The serial is printed as a barcode on the box label (next to "Serial No."
/// on an iPhone box), so it is scanned like the IMEI rather than typed. Only
/// a code that reads as a serial is taken (see `serialFromBarcode`).
class SerialScanButton extends StatelessWidget {
  const SerialScanButton({
    super.key,
    required this.onScanned,
    this.apple = false,
  });

  final ValueChanged<String> onScanned;

  /// An Apple box: its serial barcode carries a leading S.
  final bool apple;

  Future<void> _scan(BuildContext context) async {
    final serial = await showInputSheet<String>(
      context: context,
      builder: (_) => _SerialScanDialog(apple: apple),
    );
    if (serial == null) return;
    onScanned(serial);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('serial-scan'),
      tooltip: context.l10n.serialScanTitle,
      icon: Icon(
        Icons.qr_code_scanner,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => _scan(context),
    );
  }
}

class _SerialScanDialog extends StatefulWidget {
  const _SerialScanDialog({required this.apple});

  final bool apple;

  @override
  State<_SerialScanDialog> createState() => _SerialScanDialogState();
}

class _SerialScanDialogState extends State<_SerialScanDialog> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.qrCode,
    ],
  );

  String? _serial;

  /// Said after a photo that had no serial in it.
  String? _note;

  /// No barcode (an iPhone's Settings › About): a photo, and the serial read.
  Future<void> _readText() async {
    final l10n = context.l10n;
    final TextCodes? found;
    try {
      found = await _readCodes(context, _controller, l10n);
    } catch (e) {
      if (mounted) setState(() => _note = l10n.readFailed(plainError(e)));
      return;
    }
    if (!mounted || found == null) return;
    final codes = found;
    setState(() {
      if (codes.serials.isEmpty) {
        _note = l10n.readNoSerial;
      } else {
        _note = null;
        _serial = codes.serials.first;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // The first serial-looking code is kept, so a second barcode in frame
    // does not swap it; "Scan again" clears it.
    if (_serial != null) return;
    for (final barcode in capture.barcodes) {
      final serial = serialFromBarcode(
        barcode.rawValue ?? '',
        apple: widget.apple,
      );
      if (serial == null) continue;
      setState(() => _serial = serial);
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
                    l10n.serialScanTitle,
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
                          l10n.serialScanNoCamera,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_serial == null)
              Text(l10n.serialScanPoint, style: theme.textTheme.bodyMedium)
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.serial}   $_serial',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _serial = null),
                    child: Text(l10n.serialScanAgain),
                  ),
                ],
              ),
            if (_note != null) ...[
              const SizedBox(height: 8),
              Text(
                _note!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (canReadText)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('read-text'),
                  onPressed: _readText,
                  icon: const Icon(Icons.text_fields),
                  label: Text(l10n.readNumbersButton),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: _serial == null
                  ? null
                  : () => Navigator.of(context).pop(_serial),
              icon: const Icon(Icons.check),
              label: Text(l10n.imeiScanDone),
            ),
          ],
        ),
      ),
    );
  }
}

/// The camera is handed from the barcode scanner to a photo, the photo's
/// words are read ("Reading the numbers…" while they are), and the scanner
/// gets the camera back. Null when the photo was cancelled; a failure is
/// thrown, for the sheet to say in red under the camera.
Future<TextCodes?> _readCodes(
  BuildContext context,
  MobileScannerController scanner,
  AppLocalizations l10n,
) async {
  try {
    await scanner.stop();
  } catch (_) {
    // Already stopped.
  }
  if (!context.mounted) return null;
  try {
    final text = await whileBusy(
      context,
      readTextWithCamera(),
      label: l10n.readingNumbers,
    );
    return text == null ? null : codesInText(text);
  } finally {
    try {
      await scanner.start();
    } catch (_) {
      // The sheet was closed meanwhile.
    }
  }
}
