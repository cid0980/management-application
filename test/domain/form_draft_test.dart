import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/form_draft.dart';

void main() {
  group('a draft is per form instance', () {
    test('a new intake and an edit do not share a drawer', () {
      expect(draftKey('second_hand'), 'draft:second_hand:new');
      expect(draftKey('second_hand', id: 'sh-2'), 'draft:second_hand:sh-2');
      expect(
        draftKey('second_hand', id: 'sh-2'),
        isNot(draftKey('second_hand', id: 'sh-3')),
      );
    });

    test('a half-typed new purchase cannot overwrite an existing record', () async {
      final store = InMemoryDraftStore();
      await store.write(draftKey('second_hand'), {'brand': 'Vivo'});
      await store.write(draftKey('second_hand', id: 'sh-2'), {'brand': 'Oppo'});
      expect(
        (await store.read(draftKey('second_hand')))!.values['brand'],
        'Vivo',
      );
      expect(
        (await store.read(draftKey('second_hand', id: 'sh-2')))!.values['brand'],
        'Oppo',
      );
    });
  });

  group('dismissing is not discarding', () {
    test('dragging the sheet down keeps the work — it may be a slip', () {
      expect(keepsDraft(SheetExit.dismissed), isTrue);
    });

    test('the X is the only thing that throws it away', () {
      expect(keepsDraft(SheetExit.discarded), isFalse);
    });

    test('a saved form has no draft left to keep', () {
      expect(keepsDraft(SheetExit.saved), isFalse);
    });
  });

  group('an empty draft is not a draft', () {
    test('blank strings, empty lists and zeros are all nothing typed', () {
      const draft = FormDraft(key: 'k', values: {
        'brand': '',
        'model': '   ',
        'photos': <String>[],
        'purchasePrice': 0,
        'stillBeingRepaired': false,
        'conditionAnswers': <String, bool?>{},
      });
      expect(draft.isEmpty, isTrue);
    });

    test('one typed field makes it a draft', () {
      const draft = FormDraft(key: 'k', values: {'brand': 'Samsung'});
      expect(draft.isEmpty, isFalse);
    });

    test('writing a blank form does not resurrect a discarded draft', () async {
      final store = InMemoryDraftStore();
      await store.write('k', {'brand': 'Samsung'});
      await store.clear('k');
      await store.write('k', {'brand': ''});
      expect(await store.read('k'), isNull);
    });
  });
}
