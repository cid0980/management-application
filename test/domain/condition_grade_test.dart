import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/inventory/condition_grade.dart';

GradeResult android(Map<String, bool?> answers) =>
    gradeFrom(answers, checklist: checklistFor('Samsung'));

GradeResult iphone(Map<String, bool?> answers) =>
    gradeFrom(answers, checklist: checklistFor('Apple'));

void main() {
  group('every check starts as passed', () {
    test('a phone with nothing marked is an A', () {
      expect(android(const {}).grade, kGradeA);
      expect(android(const {}).faults, isEmpty);
    });

    test('answers saved are the whole checklist, untouched ones passed', () {
      final saved = answersForSave(const {'wifi': false},
          checklist: checklistFor('Samsung'));
      expect(saved.length, checklistFor('Samsung').length);
      expect(saved['wifi'], isFalse);
      expect(saved['bluetooth'], isTrue);
    });
  });

  group('the grade follows the counter app rules', () {
    test('one to three things not working is a B', () {
      expect(android(const {'wifi': false}).grade, kGradeB);
      expect(
          android(const {'wifi': false, 'bluetooth': false, 'microphone': false})
              .grade,
          kGradeB);
    });

    test('four or more not working is a C', () {
      expect(
        android(const {
          'wifi': false,
          'bluetooth': false,
          'microphone': false,
          'flashlight': false,
        }).grade,
        kGradeC,
      );
    });

    test('a replaced display or white spots is a C, whatever else works', () {
      expect(android(const {'display_replaced': false}).grade, kGradeC);
      expect(android(const {'white_spots': false}).grade, kGradeC);
    });

    test('physical damage is a D, whatever else works', () {
      expect(android(const {'physical_damage': false}).grade, kGradeD);
    });

    test('an iCloud-locked iPhone is a D', () {
      expect(iphone(const {'icloud_lock': false}).grade, kGradeD);
    });

    test('D wins over C', () {
      expect(
        android(const {'physical_damage': false, 'display_replaced': false})
            .grade,
        kGradeD,
      );
    });

    test('the faults behind the grade are named', () {
      final r = android(const {'physical_damage': false, 'wifi': false});
      expect(r.gradeFaults, ['Physical Damage / Bent']);
      expect(r.notWorking, ['Wi-Fi']);
    });
  });

  group('an iPhone gets the iPhone checks', () {
    test('Apple gets iCloud and Face ID, not the SD card slot', () {
      final keys = checklistFor('apple').map((i) => i.key).toSet();
      expect(keys, containsAll(['icloud_lock', 'face_touch_id', 'mute_switch']));
      expect(keys, isNot(contains('sd_card_slot')));
    });

    test('anything else gets the Android checks', () {
      final keys = checklistFor('Vivo').map((i) => i.key).toSet();
      expect(keys, containsAll(['fingerprint', 'sd_card_slot', 'sim_slot_2']));
      expect(keys, isNot(contains('icloud_lock')));
    });

    test('both get the common checks first', () {
      for (final brand in ['Apple', 'Samsung']) {
        final keys = checklistFor(brand).take(4).map((i) => i.key);
        expect(keys, kCommonChecks.map((i) => i.key));
      }
    });

    test('no key repeats within one checklist', () {
      for (final brand in ['Apple', 'Samsung']) {
        final keys = checklistFor(brand).map((i) => i.key).toList();
        expect(keys.toSet().length, keys.length, reason: brand);
      }
    });
  });

  group('gradeForSave', () {
    test('a manual grade wins', () {
      expect(
        gradeForSave(
          override: kGradeC,
          answers: const {},
          checklist: checklistFor('Samsung'),
        ),
        kGradeC,
      );
    });

    test('an unknown override is ignored', () {
      expect(
        gradeForSave(
          override: 'Z',
          answers: const {'wifi': false},
          checklist: checklistFor('Samsung'),
        ),
        kGradeB,
      );
    });
  });
}
