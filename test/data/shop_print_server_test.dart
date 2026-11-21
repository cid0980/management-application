import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/printing/system_print_server.dart';
import 'package:fm_shop/data/settings_repository.dart';

void main() {
  const job = LabelPrintJob(number: 26042, title: 'Galaxy A54');

  test('with no print server in settings, a label goes to the phone',
      () async {
    final settings = InMemorySettingsStore();
    addTearDown(settings.dispose);
    final onDevice = RecordingPrintServer();
    final printer = ShopPrintServer(settings: settings, onDevice: onDevice);

    expect((await printer.printLabel(job)).sent, isTrue);
    expect(onDevice.jobs.single.number, 26042);
  });

  test('with one, the phone is not used', () async {
    final settings = InMemorySettingsStore();
    addTearDown(settings.dispose);
    await settings.setPrintServerUrl('http://127.0.0.1:9');
    final onDevice = RecordingPrintServer();
    final printer = ShopPrintServer(settings: settings, onDevice: onDevice);

    // Nothing listens there, so it fails — and says so, without throwing.
    final result = await printer.printLabel(job);
    expect(result.sent, isFalse);
    expect(onDevice.jobs, isEmpty);
  });
}
