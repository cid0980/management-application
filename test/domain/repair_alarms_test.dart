import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/reminders/repair_alarms.dart';
import 'package:fm_shop/domain/service/service_order.dart';

void main() {
  final now = DateTime(2026, 11, 25, 10);
  ServiceOrder job(
    String id, {
    String tech = '',
    String status = 'In Progress',
    Duration dueIn = const Duration(hours: 5),
    String by = 'owner',
    DateTime? assignedAt,
  }) => ServiceOrder(
    id: id,
    brand: 'Xiaomi',
    model: 'Redmi 12',
    status: status,
    technicianUid: tech,
    assignedBy: by,
    assignedAt: assignedAt ?? now,
    expectedCompletionAt: now.add(dueIn),
  );

  group('alarms', () {
    test('an hour before, and at the promised time, on the technician', () {
      final a = repairAlarms(
        [job('a', tech: 'suresh')],
        myUid: 'suresh',
        isAdmin: false,
        now: now,
      );
      expect(a.map((x) => x.kind), [
        RepairAlarmKind.hourBefore,
        RepairAlarmKind.dueNow,
      ]);
      expect(a.first.at, DateTime(2026, 11, 25, 14));
      expect(a.last.at, DateTime(2026, 11, 25, 15));
    });

    test("somebody else's job does not ring on my phone", () {
      expect(
        repairAlarms(
          [job('a', tech: 'mani')],
          myUid: 'suresh',
          isAdmin: true,
          now: now,
        ),
        isEmpty,
      );
    });

    test('a job with no technician rings on admins, not on staff', () {
      final jobs = [job('a')];
      expect(
        repairAlarms(jobs, myUid: 'owner', isAdmin: true, now: now),
        hasLength(2),
      );
      expect(
        repairAlarms(jobs, myUid: 'suresh', isAdmin: false, now: now),
        isEmpty,
      );
    });

    test('ready, handed back and returned jobs ring for nobody', () {
      for (final s in ['Ready', 'Completed', 'Returned']) {
        expect(
          repairAlarms(
            [job('a', tech: 'suresh', status: s)],
            myUid: 'suresh',
            isAdmin: false,
            now: now,
          ),
          isEmpty,
          reason: s,
        );
      }
    });

    test('due in 30 minutes: no "hour before" (gone), only the due alarm; '
        'already late: nothing ahead', () {
      final soon = repairAlarms(
        [job('a', tech: 's', dueIn: const Duration(minutes: 30))],
        myUid: 's',
        isAdmin: false,
        now: now,
      );
      expect(soon.map((x) => x.kind), [RepairAlarmKind.dueNow]);
      expect(
        repairAlarms(
          [job('b', tech: 's', dueIn: const Duration(hours: -2))],
          myUid: 's',
          isAdmin: false,
          now: now,
        ),
        isEmpty,
      );
    });

    test(
      'soonest first; ids differ per job and kind, stable on replanning',
      () {
        final jobs = [
          job('late', tech: 's', dueIn: const Duration(days: 2)),
          job('soon', tech: 's', dueIn: const Duration(hours: 3)),
        ];
        final a = repairAlarms(jobs, myUid: 's', isAdmin: false, now: now);
        expect(a.first.order.id, 'soon');
        expect(a.map((x) => x.id).toSet(), hasLength(4));
        final again = repairAlarms(jobs, myUid: 's', isAdmin: false, now: now);
        expect(again.map((x) => x.id), a.map((x) => x.id));
      },
    );

    test('at most the limit', () {
      final many = [
        for (var i = 0; i < 50; i++)
          job(
            'j$i',
            tech: 's',
            dueIn: Duration(hours: 2 + i),
          ),
      ];
      expect(
        repairAlarms(many, myUid: 's', isAdmin: false, now: now, max: 40),
        hasLength(40),
      );
    });
  });

  group('a job given to you', () {
    test('announced once; not when you gave it to yourself; not when done', () {
      final jobs = [
        job('a', tech: 'suresh'),
        job('mine', tech: 'suresh', by: 'suresh'),
        job('ready', tech: 'suresh', status: 'Ready'),
        job('other', tech: 'mani'),
      ];
      final fresh = newAssignments(jobs, myUid: 'suresh', seen: {});
      expect(fresh.map((o) => o.id), ['a']);
      expect(
        newAssignments(
          jobs,
          myUid: 'suresh',
          seen: {assignmentKey(jobs.first)},
        ),
        isEmpty,
      );
    });

    test('given to somebody else and back again is news again', () {
      final first = job('a', tech: 'suresh');
      final back = job(
        'a',
        tech: 'suresh',
        assignedAt: now.add(const Duration(hours: 2)),
      );
      expect(
        newAssignments(
          [back],
          myUid: 'suresh',
          seen: {assignmentKey(first)},
        ).map((o) => o.id),
        ['a'],
      );
    });
  });

  test('the technician survives a save and a read', () {
    final o = job('a', tech: 'suresh', by: 'owner');
    final back = ServiceOrder.fromMap('a', o.toMap());
    expect(back.technicianUid, 'suresh');
    expect(back.assignedBy, 'owner');
    expect(back.assignedAt, now);
  });
}
