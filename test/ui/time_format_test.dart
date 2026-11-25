import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';

void main() {
  test('times on the 12-hour clock', () {
    expect(formatTime12(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(formatTime12(DateTime(2026, 1, 1, 9)), '9:00 AM');
    expect(formatTime12(DateTime(2026, 1, 1, 12, 30)), '12:30 PM');
    expect(formatTime12(DateTime(2026, 1, 1, 18)), '6:00 PM');
    expect(formatDayTime(DateTime(2026, 11, 5, 18)), '05/11/2026, 6:00 PM');
  });
}
