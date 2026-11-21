import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/order_state.dart';

final _now = DateTime(2026, 11, 22, 12);

void main() {
  group('ready for pickup', () {
    test('a finished phone past its promised time is not overdue', () {
      final ready = ServiceOrderState(
        status: 'Ready',
        expectedCompletionAt: DateTime(2026, 11, 20),
      );
      expect(isOverdue(ready, now: _now), isFalse);
      expect(stateOf(ready, now: _now), OrderLifecycle.open);
    });

    test('nor is it "due today" — the clock is the customer\'s now', () {
      final ready = ServiceOrderState(
        status: 'Ready',
        expectedCompletionAt: DateTime(2026, 11, 22, 18),
      );
      expect(isDueToday(ready, now: _now), isFalse);
    });

    test('it is still open: the phone is in the shop', () {
      expect(isClosed('Ready'), isFalse);
      expect(matchesTab(const ServiceOrderState(status: 'Ready'), 'Open'),
          isTrue);
      expect(matchesTab(const ServiceOrderState(status: 'Ready'), 'Ready'),
          isTrue);
    });

    test('staff can move an order to Ready; Completed still never appears',
        () {
      final options = statusOptionsFor('In Progress');
      expect(options, contains('Ready'));
      expect(options, isNot(contains('Completed')));
    });
  });
}
