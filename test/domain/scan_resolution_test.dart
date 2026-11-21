import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/devices/tac_registry.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/labels/label_target.dart';
import 'package:fm_shop/domain/labels/scan_resolution.dart';

final _entry = LabelEntry(
  number: 26042,
  kind: LabelTargetKind.secondHand,
  recordId: 'sh-1',
  snapshot: const {
    kLabelTitle: 'Samsung Galaxy A54',
    kLabelPrice: 18500,
    kLabelStatus: 'In stock',
  },
);

ScanOutcome _scan(
  String? code, {
  ScannerMode mode = ScannerMode.label,
  Map<int, LabelEntry> registry = const {},
  Map<String, Object?>? live,
  bool recordExists = true,
  TacRegistry? tacs,
}) =>
    resolveScan(
      code,
      mode: mode,
      lookupLabel: (n) => registry[n],
      // Mirrors LabelRepository.liveRecordFor: an entry whose kind is
      // unreadable has no binding to fetch through, so there is no live
      // record to lay over the copy.
      liveRecord: (entry) => recordExists && entry.kind != null
          ? (live ??
              const {kLabelTitle: 'Samsung Galaxy A54', kLabelPrice: 18500})
          : null,
      tacs: tacs ?? SeedTacRegistry(),
    );

void main() {
  group('length alone tells an IMEI from a shop label', () {
    test('a five-digit number is a label, and resolves', () {
      final outcome = _scan('26042', registry: {26042: _entry});
      expect(outcome, isA<ScanOpensRecord>());
      final record = outcome as ScanOpensRecord;
      expect(record.route, '/inventory/second-hand/sh-1');
      expect(record.view.title, 'Samsung Galaxy A54');
    });

    test('fifteen digits is an IMEI even in label mode', () {
      final outcome = _scan('354879104523681', registry: {26042: _entry});
      expect(outcome, isA<ScanIsImei>());
    });

    test('fourteen and sixteen digits are IMEIs too', () {
      expect(_scan('35487910452368'), isA<ScanIsImei>());
      expect(_scan('3548791045236812'), isA<ScanIsImei>());
    });
  });

  group('scanning a phone in label mode says what it is', () {
    test('rather than failing, which is what sent staff to print a second '
        'sticker', () {
      final outcome = _scan('354879104523681', mode: ScannerMode.label)
          as ScanIsImei;
      expect(outcome.wasLookingForALabel, isTrue);
      expect(outcome.imei, '354879104523681');
      expect(outcome.tac, '35487910');
      // And the device table has already been asked, so the offer to start an
      // intake is a useful one.
      expect(outcome.device!.brand, 'Samsung');
    });

    test('in an intake mode the same scan is not a mistake', () {
      final outcome =
          _scan('354879104523681', mode: ScannerMode.intakeService)
              as ScanIsImei;
      expect(outcome.wasLookingForALabel, isFalse);
    });

    test('the mode does not change what the code IS', () {
      for (final mode in ScannerMode.values) {
        expect(_scan('354879104523681', mode: mode), isA<ScanIsImei>(),
            reason: '$mode');
        expect(_scan('26042', mode: mode, registry: {26042: _entry}),
            isA<ScanOpensRecord>(), reason: '$mode');
      }
    });

    test('an IMEI the table does not know still resolves as an IMEI', () {
      final outcome = _scan('999999999999999') as ScanIsImei;
      expect(outcome.device, isNull);
      expect(outcome.imei, '999999999999999');
    });
  });

  group('a label the registry has never heard of', () {
    test('says so with the number, which is what is on the sticker', () {
      final outcome = _scan('26099') as ScanUnknownLabel;
      expect(outcome.number, 26099);
    });
  });

  group('a label whose record is gone', () {
    test('still resolves off the printed copy, with nowhere to open', () {
      final outcome = _scan(
        '26042',
        registry: {26042: _entry},
        recordExists: false,
      ) as ScanOpensRecord;
      expect(outcome.view.title, 'Samsung Galaxy A54');
      expect(outcome.view.recordExists, isFalse);
      expect(outcome.route, isNull);
    });

    test('a label with an unreadable kind has nowhere to open either', () {
      final outcome = _scan('26042', registry: {
        26042: LabelEntry(
          number: 26042,
          kind: null,
          recordId: 'x',
          snapshot: const {kLabelTitle: 'Something'},
        ),
      }) as ScanOpensRecord;
      expect(outcome.route, isNull);
      expect(outcome.view.title, 'Something');
    });
  });

  group('a price corrected since printing shows correctly', () {
    test('and the scan flags that the sticker is out of date', () {
      final outcome = _scan(
        '26042',
        registry: {26042: _entry},
        live: const {kLabelTitle: 'Samsung Galaxy A54', kLabelPrice: 16900},
      ) as ScanOpensRecord;
      expect(outcome.view.price, 16900);
      expect(outcome.view.staleFields, [kLabelPrice]);
    });
  });

  group('not a number this shop uses', () {
    test('a retail barcode, a word, nothing at all', () {
      expect(_scan('SKU-ABC-9'), isA<ScanUnreadable>());
      expect(_scan(''), isA<ScanUnreadable>());
      expect(_scan(null), isA<ScanUnreadable>());
      expect(_scan('   '), isA<ScanUnreadable>());
    });

    test('a thirteen-digit number is neither a label nor an IMEI', () {
      // Shorter than an IMEI but far longer than any label this shop will
      // print. classifyScan calls it a label candidate, so it resolves as an
      // unknown label rather than being silently dropped.
      expect(_scan('1234567890123'), isA<ScanUnknownLabel>());
    });
  });

  test('every mode has a label and a hint, so the segmented control is never '
      'blank', () {
    for (final mode in ScannerMode.values) {
      expect(kScannerModeLabels[mode], isNotNull);
      expect(kScannerModeHints[mode], isNotNull);
    }
  });
}
