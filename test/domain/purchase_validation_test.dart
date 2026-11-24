import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/condition_grade.dart';
import 'package:fm_shop/domain/inventory/purchase_costing.dart';
import 'package:fm_shop/domain/inventory/purchase_validation.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

/// A record that saves cleanly, which each test then breaks in one place.
SecondHandDevice _good({
  String brand = 'Samsung',
  String ram = '8GB',
  String rom = '128GB',
  String serial = '',
  DateTime? purchasedAt,
  String imei = '490154203237518',
  String imei2 = '',
  num purchasePrice = 6000,
  num askingPrice = 9000,
  List<String> photos = const ['photo://front'],
  String sellerName = 'Ramesh K',
  String sellerPhone = '9876543210',
  String sellerIdProof = 'Aadhaar 4412',
  String? signature = 'signature://captured',
  List<RepairCost> repairs = const [],
  String status = kAvailable,
  Map<String, bool?>? answers,
}) {
  final conditionAnswers = answers ?? const <String, bool?>{};
  return SecondHandDevice(
    id: 'x',
    brand: brand,
    model: 'Galaxy A54',
    ram: ram,
    rom: rom,
    serial: serial,
    purchasedAt: purchasedAt ?? DateTime(2026, 10, 26),
    imei: imei,
    imei2: imei2,
    status: status,
    grade: gradeForSave(
        answers: conditionAnswers, checklist: checklistFor(brand)),
    conditionAnswers: conditionAnswers,
    repairs: repairs,
    purchasePrice: purchasePrice,
    askingPrice: askingPrice,
    photos: photos,
    sellerName: sellerName,
    sellerPhone: sellerPhone,
    sellerIdProof: sellerIdProof,
    sellerSignature: signature,
  );
}

void main() {
  test('a complete purchase saves with no errors', () {
    final result = validatePurchase(_good());
    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  group('the device has to be identifiable', () {
    test('brand and model are needed', () {
      final result = validatePurchase(
        SecondHandDevice(id: 'x', brand: '', model: ''),
      );
      expect(result.errors, contains('brand'));
      expect(result.errors, contains('model'));
    });

    test('a missing IMEI blocks the save', () {
      expect(validatePurchase(_good(imei: '')).errors, contains('imei'));
    });

    test('a shop label typed into the IMEI field is refused', () {
      final result = validatePurchase(_good(imei: '26001'));
      expect(result.errors['imei'], contains('14 to 16 digits'));
    });

    test('the same number in both IMEI fields is a slip', () {
      final result = validatePurchase(
        _good(imei: '490154203237518', imei2: '490154203237518'),
      );
      expect(result.errors, contains('imei2'));
    });
  });

  group('stock is bought on a real IMEI (FM #40)', () {
    test('a bad check digit is refused', () {
      final result = validatePurchase(_good(imei: '123456789012345'));
      expect(result.errors, contains('imei'));
    });
  });

  group('sizes and battery (FM #21, #41)', () {
    test('battery health is 0 to 100', () {
      expect(
        validatePurchase(_good().copyWith(batteryHealth: 150)).errors,
        contains('batteryHealth'),
      );
      expect(
        validatePurchase(_good().copyWith(batteryHealth: 87)).errors,
        isNot(contains('batteryHealth')),
      );
    });
    test('RAM and storage are sizes, not any number', () {
      expect(
        validatePurchase(_good().copyWith(ram: '1234567890123')).errors,
        contains('ram'),
      );
      expect(
        validatePurchase(_good().copyWith(ram: '8GB', rom: '1 TB')).errors,
        isNot(contains('rom')),
      );
    });
  });

  test('a listing with no front view is not a listing', () {
    expect(validatePurchase(_good(photos: const [])).errors, contains('photos'));
  });

  group('the seller, for the declaration', () {
    test('a name is needed', () {
      expect(
        validatePurchase(_good(sellerName: '  ')).errors,
        contains('sellerName'),
      );
    });

    test('a number that cannot be rung is refused', () {
      expect(
        validatePurchase(_good(sellerPhone: '12345')).errors,
        contains('sellerPhone'),
      );
    });

    test('a number written with +91 and spaces is accepted', () {
      expect(
        validatePurchase(_good(sellerPhone: '+91 98765 43210')).isValid,
        isTrue,
      );
    });
  });

  test('what was paid is needed', () {
    expect(
      validatePurchase(_good(purchasePrice: 0)).errors,
      contains('purchasePrice'),
    );
  });

  group('repairs', () {
    test('a negative repair cost is refused', () {
      final result = validatePurchase(_good(
        repairs: const [RepairCost(description: 'Display', amount: -100)],
      ));
      expect(result.errors, contains('repairs'));
    });

    test('a costed repair has to say what it was', () {
      final result = validatePurchase(_good(
        repairs: const [RepairCost(description: '', amount: 500)],
      ));
      expect(result.errors, contains('repairs'));
    });

    test('a zero-cost note is allowed', () {
      final result = validatePurchase(_good(
        repairs: const [RepairCost(description: 'Cleaned', amount: 0)],
      ));
      expect(result.isValid, isTrue);
    });
  });

  group('what the counter app also requires', () {
    test('RAM and storage are needed', () {
      final result = validatePurchase(_good(ram: '', rom: ''));
      expect(result.errors.keys, containsAll(['ram', 'rom']));
    });

    test('an old record with the one-box variant is not made invalid', () {
      final old = _good(ram: '', rom: '');
      final legacy = SecondHandDevice.fromMap(
          'x', {...old.toMap(), 'variant': '8/128'});
      final result = validatePurchase(legacy);
      expect(result.errors.keys, isNot(contains('ram')));
    });

    test('an iPhone needs its serial; anything else does not', () {
      expect(validatePurchase(_good(brand: 'Apple')).errors,
          contains('serial'));
      expect(
          validatePurchase(_good(brand: 'Apple', serial: 'F2LX1234')).isValid,
          isTrue);
      expect(validatePurchase(_good()).errors, isNot(contains('serial')));
    });

    test('a selling price is needed', () {
      expect(validatePurchase(_good(askingPrice: 0)).errors,
          contains('askingPrice'));
    });

    test('an unchecked phone is not a warning — every check starts passed',
        () {
      final result = validatePurchase(_good(answers: const {}));
      expect(result.isValid, isTrue);
      expect(result.warnings, isNot(contains('grade')));
    });
  });

  group('warnings the shop is allowed to overrule', () {
    test('a clearance price warns but saves', () {
      final result = validatePurchase(
        _good(purchasePrice: 9000, askingPrice: 8500),
      );
      expect(result.isValid, isTrue);
      expect(result.warnings, contains('askingPrice'));
    });

    test('sellable while damaged is called out', () {
      final result = validatePurchase(_good(
        status: kAvailable,
        answers: const {'physical_damage': false},
      ));
      expect(result.isValid, isTrue);
      expect(result.warnings['status'], contains('Physical Damage'));
    });
  });

  group('printing the declaration asks for more than saving does', () {
    test('the same record that saves cannot print unsigned', () {
      final unsigned = _good(signature: null);
      expect(validatePurchase(unsigned).isValid, isTrue);
      expect(
        validateDeclaration(unsigned).errors,
        contains('sellerSignature'),
      );
    });

    test('an ID proof reference is needed to print', () {
      final noId = _good(sellerIdProof: '');
      expect(validatePurchase(noId).isValid, isTrue);
      expect(validateDeclaration(noId).errors, contains('sellerIdProof'));
    });

    test('a fully signed record prints', () {
      expect(validateDeclaration(_good()).isValid, isTrue);
    });

    test('a save error is a print error too — one validator', () {
      final result = validateDeclaration(_good(photos: const []));
      expect(result.errors, contains('photos'));
    });
  });
}
