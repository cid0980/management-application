import '../../data/printing/bluetooth_label_printer.dart';
import '../../l10n/app_localizations.dart';

/// A failed print, said in the shop's language. Bluetooth failures come back
/// as codes (see `BluetoothPrintError`); anything else is shown as itself.
String printErrorText(AppLocalizations l10n, String error) {
  return switch (error) {
    BluetoothPrintError.noPrinter => l10n.btNoPrinter,
    BluetoothPrintError.off => l10n.btOff,
    BluetoothPrintError.permission => l10n.btPermission,
    BluetoothPrintError.connect => l10n.btConnect,
    BluetoothPrintError.write => l10n.btWrite,
    _ => error,
  };
}
