import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/complaints.dart';

void main() {
  test('the shared vocabulary has no duplicates', () {
    expect(kComplaintTypes.toSet(), hasLength(kComplaintTypes.length));
    expect(kLockTypes.toSet(), hasLength(kLockTypes.length));
    expect(kAccessories.toSet(), hasLength(kAccessories.length));
  });

  test('None is the first lock type, and Other the last escape hatch', () {
    expect(kLockTypes.first, 'None');
    expect(kLockTypes.last, 'Other');
    expect(kComplaintTypes.last, 'Other');
  });

  group('a pattern is one a person could have drawn', () {
    test('a sequence of distinct dots on a 3x3 grid', () {
      expect(isValidPattern([1, 2, 3, 6, 9]), isTrue);
      expect(isValidPattern([1, 2]), isTrue);
      expect(isValidPattern([1, 2, 3, 4, 5, 6, 7, 8, 9]), isTrue);
    });

    test('one dot is not a pattern', () {
      expect(isValidPattern([5]), isFalse);
      expect(isValidPattern([]), isFalse);
    });

    test('a dot cannot be used twice', () {
      expect(isValidPattern([1, 2, 1]), isFalse);
    });

    test('a dot off the grid is not a dot', () {
      expect(isValidPattern([0, 1]), isFalse);
      expect(isValidPattern([1, 10]), isFalse);
    });
  });

  group('a pattern is stored in the order it was drawn', () {
    test('because the order is the pattern', () {
      expect(formatPattern([1, 2, 3, 6, 9]), '1-2-3-6-9');
      expect(parsePattern('1-2-3-6-9'), [1, 2, 3, 6, 9]);
      // Not the same pattern, and must not read as one.
      expect(parsePattern('9-6-3-2-1'), isNot(parsePattern('1-2-3-6-9')));
    });

    test('however it was written down', () {
      expect(parsePattern('1 2 3'), [1, 2, 3]);
      expect(parsePattern('1,2,3'), [1, 2, 3]);
      expect(parsePattern(''), isEmpty);
      expect(parsePattern(null), isEmpty);
    });
  });
}
