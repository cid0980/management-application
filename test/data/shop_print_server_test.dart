import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/printing/bluetooth_label_printer.dart';
import 'package:fm_shop/data/printing/label_printer_prefs.dart';
import 'package:fm_shop/data/printing/system_print_server.dart';

/// A radio that does what it is told, and remembers what it was sent.
class FakeLink implements BluetoothLink {
  bool on = true;
  bool permitted = true;
  bool connected = false;
  bool connectWorks = true;
  int failWrites = 0;
  final List<String> sent = [];
  int connects = 0;

  @override
  Future<bool> get isOn async => on;
  @override
  Future<bool> get hasPermission async => permitted;
  @override
  Future<List<PairedPrinter>> paired() async => const [
    PairedPrinter(name: 'XP-P323B', address: 'AA:BB'),
  ];
  @override
  Future<bool> get isConnected async => connected;
  @override
  Future<bool> connect(String address) async {
    connects++;
    connected = connectWorks;
    return connectWorks;
  }

  @override
  Future<bool> write(List<int> bytes) async {
    if (failWrites > 0) {
      failWrites--;
      return false;
    }
    sent.add(String.fromCharCodes(bytes));
    return true;
  }

  @override
  Future<void> disconnect() async => connected = false;
}

Future<LabelPrinterPrefs> _bluetoothPrefs() async {
  final prefs = LabelPrinterPrefs();
  await prefs.setPrinter(address: 'AA:BB', name: 'XP-P323B');
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const job = LabelPrintJob(number: 26042, title: 'Galaxy A54', price: 18500);

  group('where a label goes', () {
    test('with no Bluetooth printer chosen, to the phone print menu', () async {
      final prefs = LabelPrinterPrefs();
      final onDevice = RecordingPrintServer();
      final bluetooth = RecordingPrintServer();
      final printer = ShopPrintServer(
        prefs: prefs,
        bluetooth: bluetooth,
        onDevice: onDevice,
      );
      expect((await printer.printLabel(job)).sent, isTrue);
      expect(onDevice.jobs.single.number, 26042);
      expect(bluetooth.jobs, isEmpty);
    });

    test('with one chosen, to the Bluetooth printer', () async {
      final prefs = await _bluetoothPrefs();
      final onDevice = RecordingPrintServer();
      final bluetooth = RecordingPrintServer();
      final printer = ShopPrintServer(
        prefs: prefs,
        bluetooth: bluetooth,
        onDevice: onDevice,
      );
      await printer.printLabel(job);
      expect(bluetooth.jobs.single.number, 26042);
      expect(onDevice.jobs, isEmpty);
    });
  });

  group('the Bluetooth printer', () {
    test('sends the TSPL label, connecting first', () async {
      final link = FakeLink();
      final printer = BluetoothLabelPrinter(
        prefs: await _bluetoothPrefs(),
        link: link,
      );
      final result = await printer.printLabel(job);
      expect(result.sent, isTrue);
      expect(link.connects, 1);
      expect(link.sent.single, startsWith('SIZE 50 mm,25 mm'));
      expect(link.sent.single, contains('"26042"'));
      expect(link.sent.single, contains('Rs.18,500'));
    });

    test('stays connected for the next label', () async {
      final link = FakeLink();
      final printer = BluetoothLabelPrinter(
        prefs: await _bluetoothPrefs(),
        link: link,
      );
      await printer.printLabel(job);
      await printer.printLabel(job);
      expect(link.connects, 1);
      expect(link.sent, hasLength(2));
    });

    test('a dropped link is reconnected once', () async {
      final link = FakeLink()
        ..connected = true
        ..failWrites = 1;
      final printer = BluetoothLabelPrinter(
        prefs: await _bluetoothPrefs(),
        link: link,
      );
      expect((await printer.printLabel(job)).sent, isTrue);
      expect(link.connects, 1);
    });

    test('says why it could not print', () async {
      final prefs = await _bluetoothPrefs();
      Future<String?> errorWith(FakeLink link) async =>
          (await BluetoothLabelPrinter(
            prefs: prefs,
            link: link,
          ).printLabel(job)).error;

      expect(await errorWith(FakeLink()..on = false), BluetoothPrintError.off);
      expect(
        await errorWith(FakeLink()..permitted = false),
        BluetoothPrintError.permission,
      );
      expect(
        await errorWith(FakeLink()..connectWorks = false),
        BluetoothPrintError.connect,
      );
      expect(
        await errorWith(
          FakeLink()
            ..connected = true
            ..failWrites = 2,
        ),
        BluetoothPrintError.write,
      );
    });

    test('with no printer chosen, says so', () async {
      final result = await BluetoothLabelPrinter(
        prefs: LabelPrinterPrefs(),
        link: FakeLink(),
      ).printLabel(job);
      expect(result.error, BluetoothPrintError.noPrinter);
    });
  });
}
