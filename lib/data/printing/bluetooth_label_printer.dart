import 'dart:convert';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../domain/printing/tspl.dart';
import '../print_server.dart';
import 'label_printer_prefs.dart';

/// A printer this phone is paired with.
class PairedPrinter {
  const PairedPrinter({required this.name, required this.address});

  final String name;
  final String address;
}

/// The Bluetooth calls the label printer needs, behind an interface so the
/// printing rules can be tested without a radio.
abstract class BluetoothLink {
  Future<bool> get isOn;
  Future<bool> get hasPermission;
  Future<List<PairedPrinter>> paired();
  Future<bool> get isConnected;
  Future<bool> connect(String address);
  Future<bool> write(List<int> bytes);
  Future<void> disconnect();
}

/// The real radio, through `print_bluetooth_thermal` (Bluetooth Classic on
/// Android, which is what these printers speak).
class PluginBluetoothLink implements BluetoothLink {
  @override
  Future<bool> get isOn => PrintBluetoothThermal.bluetoothEnabled;

  @override
  Future<bool> get hasPermission =>
      PrintBluetoothThermal.isPermissionBluetoothGranted;

  @override
  Future<List<PairedPrinter>> paired() async => [
    for (final d in await PrintBluetoothThermal.pairedBluetooths)
      PairedPrinter(name: d.name, address: d.macAdress),
  ];

  @override
  Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  @override
  Future<bool> connect(String address) =>
      PrintBluetoothThermal.connect(macPrinterAddress: address);

  @override
  Future<bool> write(List<int> bytes) =>
      PrintBluetoothThermal.writeBytes(bytes);

  @override
  Future<void> disconnect() => PrintBluetoothThermal.disconnect;
}

/// What went wrong, as a code the screen turns into the shop's language.
abstract final class BluetoothPrintError {
  static const noPrinter = 'bt-no-printer';
  static const off = 'bt-off';
  static const permission = 'bt-permission';
  static const connect = 'bt-connect';
  static const write = 'bt-write';
}

/// LABELS TO A BLUETOOTH PRINTER
///
/// Sends the TSPL program for the label (see `tspl.dart`) to the printer
/// chosen in Settings. Stays connected between labels — taking in a batch of
/// phones prints one after another — and reconnects once if the link has
/// dropped (printer switched off and on, phone walked away and back).
///
/// Never throws: a failed print is reported, and never undoes a save.
class BluetoothLabelPrinter implements PrintServer {
  BluetoothLabelPrinter({required this.prefs, BluetoothLink? link})
    : link = link ?? PluginBluetoothLink();

  final LabelPrinterPrefs prefs;
  final BluetoothLink link;

  @override
  Future<PrintResult> printLabel(LabelPrintJob job) async {
    if (prefs.address.isEmpty) {
      return const PrintResult.failed(BluetoothPrintError.noPrinter);
    }
    try {
      if (!await link.hasPermission) {
        return const PrintResult.failed(BluetoothPrintError.permission);
      }
      if (!await link.isOn) {
        return const PrintResult.failed(BluetoothPrintError.off);
      }
      final bytes = ascii.encode(
        tsplLabel(
          number: job.number,
          title: job.title,
          subtitle: job.subtitle,
          price: job.price,
          copies: job.copies,
          size: prefs.size,
          darkness: prefs.darkness,
        ),
      );
      if (!await link.isConnected && !await link.connect(prefs.address)) {
        return const PrintResult.failed(BluetoothPrintError.connect);
      }
      if (await link.write(bytes)) return const PrintResult.sent();
      // The link said it was up but the write did not go: drop it and try
      // once more from a fresh connection.
      await link.disconnect();
      if (!await link.connect(prefs.address)) {
        return const PrintResult.failed(BluetoothPrintError.connect);
      }
      return await link.write(bytes)
          ? const PrintResult.sent()
          : const PrintResult.failed(BluetoothPrintError.write);
    } catch (_) {
      return const PrintResult.failed(BluetoothPrintError.connect);
    }
  }
}
