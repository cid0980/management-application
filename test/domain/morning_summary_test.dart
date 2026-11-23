import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/reminders/morning_summary.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  final day = DateTime(2026, 11, 24);
  ServiceOrder job(String id, String status, DateTime? due) => ServiceOrder(
    id: id,
    orderNumber: id,
    brand: 'Samsung',
    model: 'A54',
    status: status,
    receivedAt: DateTime(2026, 11, 20),
    expectedCompletionAt: due,
  );

  test('counts what the morning holds', () {
    final s = morningSummary(
      day: day,
      orders: [
        job('a', 'In Progress', DateTime(2026, 11, 24, 18)), // due today
        job('b', 'In Progress', DateTime(2026, 11, 22, 18)), // late
        job('c', 'Ready', DateTime(2026, 11, 23, 18)), // ready
        job('d', 'In Progress', DateTime(2026, 11, 28, 18)), // later
      ],
      enquiries: [
        Enquiry(id: 'e1', followUpAt: DateTime(2026, 11, 24)),
        Enquiry(id: 'e2', followUpAt: DateTime(2026, 11, 23)),
        Enquiry(id: 'e3', followUpAt: DateTime(2026, 11, 30)),
        Enquiry(id: 'e4', status: 'Lost', followUpAt: DateTime(2026, 11, 24)),
      ],
    );
    expect(s.dueToday, 1);
    expect(s.late, 1);
    expect(s.ready, 1);
    expect(s.ringBack, 2);
    expect(s.isEmpty, isFalse);
    // A tap goes to the most pressing list first.
    expect(s.route, '/service?tab=Overdue');
  });

  test('a quiet day says nothing', () {
    expect(
      morningSummary(day: day, orders: const [], enquiries: const []).isEmpty,
      isTrue,
    );
  });

  test('the next reminder is today if the time is still ahead', () {
    expect(
      nextReminderAt(DateTime(2026, 11, 24, 8, 0), 9, 30),
      DateTime(2026, 11, 24, 9, 30),
    );
    expect(
      nextReminderAt(DateTime(2026, 11, 24, 10, 0), 9, 30),
      DateTime(2026, 11, 25, 9, 30),
    );
  });
}
