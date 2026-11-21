import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/labels/label_entry.dart';
import 'package:fm_shop/domain/labels/label_target.dart';

LabelEntry _entry({
  int number = 26042,
  LabelTargetKind? kind = LabelTargetKind.secondHand,
  String recordId = 'sh-1',
  Map<String, Object?>? snapshot,
}) =>
    LabelEntry(
      number: number,
      kind: kind,
      recordId: recordId,
      snapshot: snapshot ??
          const {
            kLabelTitle: 'Samsung Galaxy A54',
            kLabelSubtitle: 'Grade A',
            kLabelPrice: 18500,
            kLabelStatus: 'In stock',
          },
    );

void main() {
  group('a label opens the record itself', () {
    test('each kind has its own path, the same ones the web app used', () {
      expect(routeForTarget(LabelTargetKind.secondHand, 'sh-1'),
          '/inventory/second-hand/sh-1');
      expect(routeForTarget(LabelTargetKind.service, 'so-1'), '/service/so-1');
      expect(routeForTarget(LabelTargetKind.sale, 's-1'), '/sales/s-1');
      expect(routeForTarget(LabelTargetKind.product, 'p-1'), '/products/p-1');
    });

    test('an unreadable kind has nowhere to go, rather than a guess', () {
      // A label whose kind this build does not understand must not open a
      // random record.
      expect(targetKindFrom('teleporter'), isNull);
      expect(_entry(kind: null).route, isNull);
    });

    test('the spellings older builds wrote are still read', () {
      expect(targetKindFrom('second_hand'), LabelTargetKind.secondHand);
      expect(targetKindFrom('second-hand'), LabelTargetKind.secondHand);
      expect(targetKindFrom('service_order'), LabelTargetKind.service);
      expect(targetKindFrom(null), isNull);
    });
  });

  group('the live record is laid over the printed copy', () {
    test('live wins, and what changed is flagged', () {
      final view = resolveLabel(_entry(), const {
        kLabelTitle: 'Samsung Galaxy A54',
        kLabelSubtitle: 'Grade A',
        // Corrected since the sticker was printed.
        kLabelPrice: 17500,
        kLabelStatus: 'In stock',
      });
      expect(view.price, 17500);
      expect(view.staleFields, [kLabelPrice]);
      expect(view.isStale, isTrue);
      expect(view.recordExists, isTrue);
      expect(view.canOpen, isTrue);
    });

    test('nothing changed, nothing flagged', () {
      final view = resolveLabel(_entry(), const {
        kLabelTitle: 'Samsung Galaxy A54',
        kLabelSubtitle: 'Grade A',
        kLabelPrice: 18500,
        kLabelStatus: 'In stock',
      });
      expect(view.isStale, isFalse);
      expect(view.price, 18500);
    });

    test('a price written as a string is not a change', () {
      // A label written by an older build stored '18500'; comparing as text
      // would flag every one of them as out of date.
      final view = resolveLabel(_entry(), const {kLabelPrice: '18500'});
      expect(view.staleFields, isEmpty);
      expect(view.price, 18500);
    });

    test('the copy fills in what live does not carry', () {
      // A repository that has stopped writing one of these fields must not
      // blank it on old labels.
      final view = resolveLabel(_entry(), const {kLabelPrice: 17500});
      expect(view.title, 'Samsung Galaxy A54');
      expect(view.subtitle, 'Grade A');
      expect(view.status, 'In stock');
      expect(view.staleFields, [kLabelPrice]);
    });

    test('a blank live value does not blank the label', () {
      final view = resolveLabel(_entry(), const {kLabelTitle: '   '});
      expect(view.title, 'Samsung Galaxy A54');
    });
  });

  group('a deleted record still scans', () {
    test('off the copy, and says so', () {
      // The label is stuck to a phone. "Not found" is less use at the counter
      // than what was printed on it.
      final view = resolveLabel(_entry(), null);
      expect(view.title, 'Samsung Galaxy A54');
      expect(view.price, 18500);
      expect(view.recordExists, isFalse);
      // Nothing to open, and nothing flagged as changed — there is nothing to
      // compare against.
      expect(view.canOpen, isFalse);
      expect(view.staleFields, isEmpty);
    });

    test('a readable kind with a missing record still cannot be opened', () {
      expect(resolveLabel(_entry(), null).canOpen, isFalse);
    });
  });

  test('an empty snapshot resolves to empty fields rather than throwing', () {
    final view = resolveLabel(_entry(snapshot: const {}), null);
    expect(view.title, '');
    expect(view.price, isNull);
    expect(view.status, '');
  });

  group('reading and writing an entry', () {
    test('an entry written here reads back the same', () {
      final entry = LabelEntry(
        number: 26042,
        kind: LabelTargetKind.service,
        recordId: 'so-1',
        snapshot: const {kLabelTitle: 'Samsung M14', kLabelPrice: 1400},
        printedAt: DateTime.utc(2026, 3, 4, 10),
        reprints: 2,
      );
      final back = LabelEntry.fromMap(entry.toMap());
      expect(back.number, 26042);
      expect(back.kind, LabelTargetKind.service);
      expect(back.recordId, 'so-1');
      expect(back.snapshot[kLabelTitle], 'Samsung M14');
      expect(back.printedAt, DateTime.utc(2026, 3, 4, 10));
      expect(back.reprints, 2);
    });

    test('a number written as a string reads as a number', () {
      expect(LabelEntry.fromMap({'number': '26042'}).number, 26042);
    });

    test('an empty document does not throw', () {
      final entry = LabelEntry.fromMap(const {});
      expect(entry.number, 0);
      expect(entry.kind, isNull);
      expect(entry.snapshot, isEmpty);
      expect(entry.reprints, 0);
    });
  });
}
