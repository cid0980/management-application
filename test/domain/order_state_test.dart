import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/order_state.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 0);
  final yesterday = DateTime(2026, 10, 15, 9, 0);
  final laterToday = DateTime(2026, 10, 16, 18, 0);
  final tomorrow = DateTime(2026, 10, 17, 9, 0);

  group('overdue', () {
    test('a promise already past is overdue', () {
      final order = ServiceOrderState(
          status: 'In Progress', expectedCompletionAt: yesterday);
      expect(isOverdue(order, now: now), isTrue);
    });

    test('a finished job is never an alarm, however late', () {
      for (final status in ['Completed', 'Returned']) {
        final order =
            ServiceOrderState(status: status, expectedCompletionAt: yesterday);
        expect(isOverdue(order, now: now), isFalse, reason: status);
        expect(stateOf(order, now: now), OrderLifecycle.closed, reason: status);
      }
    });

    test('no promised date means nothing to be late for', () {
      const order = ServiceOrderState(status: 'Received');
      expect(isOverdue(order, now: now), isFalse);
      expect(stateOf(order, now: now), OrderLifecycle.open);
    });

    test('reads an ISO string as readily as a DateTime', () {
      final order = ServiceOrderState(
          status: 'Received', expectedCompletionAt: yesterday.toIso8601String());
      expect(isOverdue(order, now: now), isTrue);
    });
  });

  group('due today', () {
    test('later the same day counts', () {
      final order = ServiceOrderState(
          status: 'In Progress', expectedCompletionAt: laterToday);
      expect(isDueToday(order, now: now), isTrue);
    });

    test('tomorrow does not', () {
      final order = ServiceOrderState(
          status: 'In Progress', expectedCompletionAt: tomorrow);
      expect(isDueToday(order, now: now), isFalse);
    });
  });

  group('tabs', () {
    test('Open is everything still in the shop', () {
      expect(
          matchesTab(const ServiceOrderState(status: 'Parts Awaiting'), 'Open',
              now: now),
          isTrue);
      expect(
          matchesTab(const ServiceOrderState(status: 'Completed'), 'Open',
              now: now),
          isFalse);
    });

    test('a status tab matches that status exactly', () {
      expect(
          matchesTab(const ServiceOrderState(status: 'Returned'), 'Returned',
              now: now),
          isTrue);
    });

    test('All takes everything', () {
      expect(
          matchesTab(const ServiceOrderState(status: 'Completed'), 'All',
              now: now),
          isTrue);
    });
  });

  group('status options', () {
    test('Completed is never offered — the checklist is the only way out', () {
      expect(statusOptionsFor('In Progress'), isNot(contains('Completed')));
      expect(statusOptionsFor('In Progress', isAdmin: true),
          isNot(contains('Completed')));
    });

    test('staff cannot send an order back to Received', () {
      expect(statusOptionsFor('In Progress'), isNot(contains('Received')));
    });

    test('an order still on Received keeps seeing it', () {
      expect(statusOptionsFor('Received'), contains('Received'));
    });

    test('an admin may set Received again', () {
      expect(statusOptionsFor('In Progress', isAdmin: true),
          contains('Received'));
    });

    test('approval can go back to the bench', () {
      expect(statusOptionsFor('Awaiting Customer Approval'),
          contains('In Progress'));
    });

    test('an unknown status is still shown, first', () {
      final options = statusOptionsFor('Sent Outside');
      expect(options.first, 'Sent Outside');
    });
  });

  group('required dates', () {
    test('both present returns both', () {
      final dates = requireOrderDates(yesterday, tomorrow);
      expect(dates.received, yesterday);
      expect(dates.expected, tomorrow);
    });

    test('an unparseable date throws rather than being written', () {
      expect(() => requireOrderDates('not a date', tomorrow), throwsArgumentError);
      expect(() => requireOrderDates(yesterday, null), throwsArgumentError);
    });
  });
}
