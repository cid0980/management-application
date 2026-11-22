import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/second_hand_device.dart';
import 'package:fm_shop/domain/inventory/stock_state.dart';

void main() {
  group('every read normalizes, whichever build wrote the document', () {
    test(
      'an ISO date and a Timestamp-shaped object both read as a DateTime',
      () {
        final iso = SecondHandDevice.fromMap('a', {
          'purchasedAt': '2026-03-04T10:00:00.000Z',
        });
        expect(iso.purchasedAt, DateTime.utc(2026, 3, 4, 10));

        final stamp = SecondHandDevice.fromMap('b', {
          'purchasedAt': _FakeTimestamp(DateTime.utc(2026, 3, 4, 10)),
        });
        expect(stamp.purchasedAt, DateTime.utc(2026, 3, 4, 10));
      },
    );

    test('an amount written as a string reads as a number', () {
      final d = SecondHandDevice.fromMap('a', {'purchasePrice': '7,500'});
      expect(d.purchasePrice, 7500);
    });

    test('an IMEI with spaces reads as digits', () {
      final d = SecondHandDevice.fromMap('a', {'imei': '354 879 104 523681'});
      expect(d.imei, '354879104523681');
    });

    test("the seller's number is stored clean", () {
      final d = SecondHandDevice.fromMap('a', {
        'sellerPhone': '+91 90000 11111',
      });
      expect(d.sellerPhone, '9000011111');
    });

    test('an unknown status reads as plain stock rather than throwing', () {
      final d = SecondHandDevice.fromMap('a', {'status': 'in_stock_old'});
      expect(d.status, kAvailable);
      expect(d.isSellable, isTrue);
    });

    test(
      'the web app wrote sellingPrice where this build writes askingPrice',
      () {
        final d = SecondHandDevice.fromMap('a', {'sellingPrice': 9500});
        expect(d.askingPrice, 9500);
      },
    );

    test('an empty document does not throw', () {
      final d = SecondHandDevice.fromMap('a', const {});
      expect(d.brand, '');
      expect(d.status, kAvailable);
      expect(d.photos, isEmpty);
      expect(d.soldPrice, isNull);
    });
  });

  group('the checklist as stored', () {
    test(
      'a key with a null value reads back as null, and grades as passed',
      () {
        final d = SecondHandDevice.fromMap('a', {
          'brand': 'Samsung',
          'conditionAnswers': {
            'wifi': null,
            'bluetooth': true,
            'flashlight': false,
          },
        });
        expect(d.conditionAnswers['wifi'], isNull);
        expect(d.conditionAnswers['bluetooth'], isTrue);
        expect(d.conditionAnswers['flashlight'], isFalse);
        expect(d.computedGrade.notWorking, ['Flashlight']);
      },
    );
  });

  group('RAM, storage and the rest of the counter app fields', () {
    test('they round-trip', () {
      final d = SecondHandDevice(
        id: 'a',
        brand: 'Samsung',
        model: 'A54',
        ram: '8GB',
        rom: '128GB',
        supplier: 'Local market',
        sellerAltPhone: '9123456780',
        sellerCustomerId: 'c-1',
        idCardPhotos: const ['id://front', ''],
        gradeDetails: const {kAccessories: 'Charger'},
      );
      final back = SecondHandDevice.fromMap('a', d.toMap());
      expect(back.ram, '8GB');
      expect(back.rom, '128GB');
      expect(back.supplier, 'Local market');
      expect(back.sellerAltPhone, '9123456780');
      expect(back.sellerCustomerId, 'c-1');
      expect(back.idCardPhotos, ['id://front', '']);
      expect(back.gradeDetails[kAccessories], 'Charger');
      expect(back.title, 'Samsung A54 8GB/128GB');
    });

    test('an old record shows its one-box variant in the title', () {
      final d = SecondHandDevice.fromMap('a', {
        'brand': 'Xiaomi',
        'model': 'Note 12',
        'variant': '6/128',
      });
      expect(d.title, 'Xiaomi Note 12 6/128');
    });

    test('an empty front slot is no front photo', () {
      final d = SecondHandDevice.fromMap('a', {
        'photos': ['', 'photo://back'],
      });
      expect(d.frontPhoto, isNull);
    });
  });

  test('a record written here is readable by anything that parses ISO', () {
    final device = SecondHandDevice(
      id: 'a',
      brand: 'Samsung',
      model: 'A54',
      purchasedAt: DateTime.utc(2026, 3, 4, 10),
    );
    final map = device.toMap();
    expect(map['purchasedAt'], '2026-03-04T10:00:00.000Z');
    expect(SecondHandDevice.fromMap('a', map).purchasedAt, device.purchasedAt);
  });

  test('the title skips the parts that are not filled in', () {
    expect(
      const SecondHandDevice(id: 'a', brand: 'Samsung', model: 'A54').title,
      'Samsung A54',
    );
    expect(
      const SecondHandDevice(
        id: 'a',
        brand: 'Samsung',
        model: 'A54',
        variant: '8/128',
      ).title,
      'Samsung A54 8/128',
    );
  });

  test('the front photo is the first one, and may be missing', () {
    expect(
      const SecondHandDevice(id: 'a', brand: 'b', model: 'm').frontPhoto,
      isNull,
    );
    expect(
      const SecondHandDevice(
        id: 'a',
        brand: 'b',
        model: 'm',
        photos: ['front', 'back'],
      ).frontPhoto,
      'front',
    );
  });
  group('battery health', () {
    test('reads as a whole percentage, or not at all', () {
      expect(batteryPercent(91), 91);
      expect(batteryPercent('91'), 91);
      expect(batteryPercent(' 91% '), 91);
      expect(batteryPercent(91.4), 91);
      expect(batteryPercent(''), isNull);
      expect(batteryPercent(null), isNull);
      // A typo is not a battery.
      expect(batteryPercent(0), isNull);
      expect(batteryPercent(910), isNull);
      expect(batteryPercent('abc'), isNull);
    });

    test('round-trips, and an old record has none', () {
      const d = SecondHandDevice(
        id: 'x',
        brand: 'Apple',
        model: 'iPhone 13',
        batteryHealth: 88,
      );
      expect(SecondHandDevice.fromMap('x', d.toMap()).batteryHealth, 88);
      expect(SecondHandDevice.fromMap('x', const {}).batteryHealth, isNull);
    });
  });
}

/// Stands in for `cloud_firestore`'s `Timestamp`: the domain layer reads it
/// through `toDate()` and never imports Firestore.
class _FakeTimestamp {
  _FakeTimestamp(this._value);
  final DateTime _value;
  DateTime toDate() => _value;
}
