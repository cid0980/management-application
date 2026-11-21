/// CONDITION AND GRADE
///
/// What a used handset is worth is an argument, and the shop loses it when the
/// grade is a feeling. So the grade is a FUNCTION of the condition checklist:
/// answer the checklist, and the grade falls out. The person buying the phone
/// cannot talk it up, and the person selling it cannot talk it down.
///
/// This is the checklist and the grading the shop already works with on its
/// counter (the French Mobiles POS), so staff moving to this app find the same
/// questions in the same groups and get the same letter:
///
/// - **Every check starts as passed** — "Working", or "No" for a fault
///   question. Staff tap only what is wrong. A phone is checked by looking for
///   faults, and twenty taps of "Working" on a good phone is twenty chances to
///   give up on the checklist altogether.
/// - **D** if the phone is physically damaged or bent, or iCloud-locked.
/// - **C** if four or more things are not working, or the display has been
///   replaced or has white spots.
/// - **B** if one to three things are not working.
/// - **A** otherwise.
///
/// An iPhone gets the iPhone checks and anything else the Android ones, on
/// top of the common checks every phone gets.
library;

import '../settings/option_set.dart';

/// "Working / Not working", or a yes/no question where "Yes" is the fault.
enum CheckKind { working, yesNo }

/// What a fault on this line does to the grade.
enum CheckEffect {
  /// Counts towards "how many things are not working".
  counts,

  /// Grade C at best, whatever else passes.
  capsAtC,

  /// Grade D, whatever else passes.
  capsAtD,
}

/// One line of the condition checklist.
class ConditionItem {
  const ConditionItem(
    this.key,
    this.label,
    this.category, {
    this.kind = CheckKind.working,
    this.effect = CheckEffect.counts,
  });

  /// Stored in the record's answers. Never shown, never translated.
  final String key;

  /// The English wording; the screen shows the shop's language.
  final String label;

  /// The group it is shown under — Display, Camera, Audio...
  final String category;

  final CheckKind kind;
  final CheckEffect effect;
}

const String kGradeA = 'A';
const String kGradeB = 'B';
const String kGradeC = 'C';
const String kGradeD = 'D';

const Map<String, String> kGradeLabels = {
  kGradeA: 'A — like new',
  kGradeB: 'B — good',
  kGradeC: 'C — fair',
  kGradeD: 'D — poor / for parts',
};

/// Grade labels in the order the form offers them.
const List<String> kGradeOrder = [kGradeA, kGradeB, kGradeC, kGradeD];

const _yesNo = CheckKind.yesNo;

/// Asked of every phone.
const List<ConditionItem> kCommonChecks = [
  ConditionItem('display_clarity', 'Display Clarity', 'Display'),
  ConditionItem(
    'white_spots',
    'White Spots on Display',
    'Display',
    kind: _yesNo,
    effect: CheckEffect.capsAtC,
  ),
  ConditionItem(
    'display_replaced',
    'Display Replaced',
    'Display',
    kind: _yesNo,
    effect: CheckEffect.capsAtC,
  ),
  ConditionItem(
    'physical_damage',
    'Physical Damage / Bent',
    'Physical',
    kind: _yesNo,
    effect: CheckEffect.capsAtD,
  ),
];

/// Asked of an iPhone.
const List<ConditionItem> kIphoneChecks = [
  ConditionItem('face_touch_id', 'Face ID / Touch ID', 'Security'),
  ConditionItem(
    'icloud_lock',
    'iCloud Lock Check',
    'Security',
    kind: _yesNo,
    effect: CheckEffect.capsAtD,
  ),
  ConditionItem('battery_health', 'Battery Health %', 'Battery'),
  ConditionItem('true_tone', 'True Tone Display', 'Display'),
  ConditionItem('front_camera', 'Front Camera (Clear dust)', 'Camera'),
  ConditionItem('rear_camera', 'Rear Camera (Clear dust)', 'Camera'),
  ConditionItem('earpiece', 'Earpiece Speaker', 'Audio'),
  ConditionItem('loudspeaker', 'Loudspeaker', 'Audio'),
  ConditionItem('microphone', 'Microphone', 'Audio'),
  ConditionItem('mobile_data', 'Mobile Data', 'Connectivity'),
  ConditionItem('bluetooth', 'Bluetooth', 'Connectivity'),
  ConditionItem('wifi', 'Wi-Fi', 'Connectivity'),
  ConditionItem('power_button', 'Power Button', 'Physical'),
  ConditionItem('volume_buttons', 'Volume Buttons', 'Physical'),
  ConditionItem('mute_switch', 'Mute Switch', 'Physical'),
  ConditionItem('lightning_port', 'Lightning / USB-C Port', 'Physical'),
  ConditionItem('sim_slot', 'SIM Slot', 'SIM'),
  ConditionItem('flashlight', 'Flashlight', 'Physical'),
];

/// Asked of every phone that is not an iPhone.
const List<ConditionItem> kAndroidChecks = [
  ConditionItem('fingerprint', 'Fingerprint Sensor', 'Security'),
  ConditionItem('face_unlock', 'Face Unlock', 'Security'),
  ConditionItem('front_camera', 'Front Camera (Clear dust)', 'Camera'),
  ConditionItem('rear_camera', 'Rear Camera (Clear dust)', 'Camera'),
  ConditionItem('earpiece', 'Earpiece Speaker', 'Audio'),
  ConditionItem('loudspeaker', 'Loudspeaker', 'Audio'),
  ConditionItem('microphone', 'Microphone', 'Audio'),
  ConditionItem('mobile_data', 'Mobile Data', 'Connectivity'),
  ConditionItem('bluetooth', 'Bluetooth', 'Connectivity'),
  ConditionItem('wifi', 'Wi-Fi', 'Connectivity'),
  ConditionItem('power_button', 'Power Button', 'Physical'),
  ConditionItem('volume_buttons', 'Volume Buttons', 'Physical'),
  ConditionItem('charging_port', 'Charging Port', 'Physical'),
  ConditionItem('sim_slot_1', 'SIM Slot 1', 'SIM'),
  ConditionItem('sim_slot_2', 'SIM Slot 2', 'SIM'),
  ConditionItem('sd_card_slot', 'SD Card Slot', 'SIM'),
  ConditionItem('flashlight', 'Flashlight', 'Physical'),
  ConditionItem('proximity_sensor', 'Proximity Sensor', 'Physical'),
];

bool isApple(String? brand) => normalizeOption(brand) == 'apple';

/// The checks for a phone of this brand: the common ones, then the iPhone or
/// the Android ones.
List<ConditionItem> checklistFor(String? brand) => [
  ...kCommonChecks,
  ...(isApple(brand) ? kIphoneChecks : kAndroidChecks),
];

/// Whether this line passed. Not answered counts as passed: every check
/// starts as "Working" (or "No" for a fault question).
bool passed(ConditionItem item, Map<String, bool?> answers) =>
    answers[item.key] ?? true;

/// The grade, and what earned it, so the form can name the faults rather
/// than show a letter nobody can explain.
class GradeResult {
  const GradeResult({
    required this.grade,
    required this.notWorking,
    required this.gradeFaults,
    required this.total,
  });

  final String grade;

  /// Labels of the lines marked "Not working" (or a counted fault).
  final List<String> notWorking;

  /// Labels of the faults that set the grade on their own — damage, an
  /// iCloud lock, a replaced or spotted display.
  final List<String> gradeFaults;

  final int total;

  List<String> get faults => [...gradeFaults, ...notWorking];
  int get passedCount => total - faults.length;
}

/// The grade for a set of answers, recalculated on every tap.
GradeResult gradeFrom(
  Map<String, bool?> answers, {
  required List<ConditionItem> checklist,
}) {
  final notWorking = <String>[];
  final capsC = <String>[];
  final capsD = <String>[];

  for (final item in checklist) {
    if (passed(item, answers)) continue;
    switch (item.effect) {
      case CheckEffect.counts:
        notWorking.add(item.label);
      case CheckEffect.capsAtC:
        capsC.add(item.label);
      case CheckEffect.capsAtD:
        capsD.add(item.label);
    }
  }

  final grade = capsD.isNotEmpty
      ? kGradeD
      : (notWorking.length >= 4 || capsC.isNotEmpty)
      ? kGradeC
      : notWorking.isNotEmpty
      ? kGradeB
      : kGradeA;

  return GradeResult(
    grade: grade,
    notWorking: notWorking,
    gradeFaults: [...capsD, ...capsC],
    total: checklist.length,
  );
}

/// The answers to store: every line of [checklist], the untouched ones as
/// passed, so the record says what was checked rather than leaving it to be
/// inferred.
Map<String, bool> answersForSave(
  Map<String, bool?> answers, {
  required List<ConditionItem> checklist,
}) => {for (final item in checklist) item.key: passed(item, answers)};

/// The grade to store.
///
/// A manual [override] wins — a buyer who has handled ten thousand phones can
/// see something the checklist does not ask about, and the shop would rather
/// have the honest grade than the computed one. It is stored as an override so
/// the record shows a human decided, and [gradeFrom] stays the default.
String gradeForSave({
  String? override,
  required Map<String, bool?> answers,
  required List<ConditionItem> checklist,
}) {
  if (override != null && kGradeLabels.containsKey(override)) return override;
  return gradeFrom(answers, checklist: checklist).grade;
}
