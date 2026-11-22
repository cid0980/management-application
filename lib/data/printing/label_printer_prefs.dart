import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/printing/tspl.dart';

/// How this phone prints labels.
enum LabelPrintMode {
  /// A 2-inch TSPL label printer paired with this phone over Bluetooth.
  bluetooth,

  /// The sticker as a PDF to the phone's own print menu.
  phoneMenu,
}

/// WHICH PRINTER THIS PHONE USES
///
/// Kept on the phone, not in the shop's settings: a Bluetooth printer pairs
/// with one phone, and the counter phone and the owner's phone can each have
/// their own (or none). Read at print time, so a change takes effect on the
/// next label.
class LabelPrinterPrefs extends ChangeNotifier {
  LabelPrinterPrefs({SharedPreferencesAsync? store}) : _given = store;

  final SharedPreferencesAsync? _given;
  SharedPreferencesAsync? _made;

  /// Made on first use, inside the try blocks below: without a platform
  /// (a test) it throws, and the choices simply live for the session.
  SharedPreferencesAsync get _store =>
      _given ?? (_made ??= SharedPreferencesAsync());

  static const _kMode = 'labelPrinter.mode';
  static const _kAddress = 'labelPrinter.address';
  static const _kName = 'labelPrinter.name';
  static const _kSize = 'labelPrinter.size';
  static const _kDarkness = 'labelPrinter.darkness';

  LabelPrintMode _mode = LabelPrintMode.phoneMenu;
  String _address = '';
  String _name = '';
  LabelSize _size = LabelSize.mm50x25;
  int _darkness = kDefaultDarkness;

  LabelPrintMode get mode => _mode;
  String get address => _address;
  String get name => _name;
  LabelSize get size => _size;
  int get darkness => _darkness;

  /// Whether labels go to a Bluetooth printer that has been chosen.
  bool get usesBluetooth =>
      _mode == LabelPrintMode.bluetooth && _address.isNotEmpty;

  Future<void> load() async {
    try {
      final mode = await _store.getString(_kMode);
      _mode = mode == LabelPrintMode.bluetooth.name
          ? LabelPrintMode.bluetooth
          : LabelPrintMode.phoneMenu;
      _address = await _store.getString(_kAddress) ?? '';
      _name = await _store.getString(_kName) ?? '';
      _size = LabelSize.fromName(await _store.getString(_kSize));
      _darkness = (await _store.getInt(_kDarkness) ?? kDefaultDarkness).clamp(
        kMinDarkness,
        kMaxDarkness,
      );
    } catch (_) {
      // No stored choice (or no storage in a test): the defaults stand.
    }
    notifyListeners();
  }

  Future<void> setMode(LabelPrintMode mode) async {
    _mode = mode;
    notifyListeners();
    await _save(() => _store.setString(_kMode, mode.name));
  }

  Future<void> setPrinter({
    required String address,
    required String name,
  }) async {
    _address = address;
    _name = name;
    _mode = LabelPrintMode.bluetooth;
    notifyListeners();
    await _save(() async {
      await _store.setString(_kAddress, address);
      await _store.setString(_kName, name);
      await _store.setString(_kMode, LabelPrintMode.bluetooth.name);
    });
  }

  Future<void> setSize(LabelSize size) async {
    _size = size;
    notifyListeners();
    await _save(() => _store.setString(_kSize, size.name));
  }

  Future<void> setDarkness(int darkness) async {
    _darkness = darkness.clamp(kMinDarkness, kMaxDarkness);
    notifyListeners();
    await _save(() => _store.setInt(_kDarkness, _darkness));
  }

  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // The choice still holds for this session.
    }
  }
}
