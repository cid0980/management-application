import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/live_window.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/ui/widgets/empty_state.dart';

void main() {
  group('merging the window queries', () {
    test('one entry per id, whichever queries returned it', () {
      final merged = mergedById([
        ['a', 'b'],
        ['b', 'c'],
        null,
      ], (s) => s);
      expect(merged, unorderedEquals(['a', 'b', 'c']));
    });

    test('the window reaches 90 days back, in both stored date shapes', () {
      final now = DateTime(2026, 11, 22, 10);
      final since = liveWindowStart(now);
      expect(since.iso, startsWith('2026-08-24'));
      expect(since.ts.toDate(), DateTime(2026, 8, 24, 10));
    });
  });

  group('older records, from the store', () {
    final orders = [
      ServiceOrder(
        id: 'old',
        orderNumber: 'SO-20250101-004',
        customerId: 'c-1',
        customerPhone: '9876543210',
        brand: 'Nokia',
        model: '3310',
        status: 'Completed',
        completedAt: DateTime(2025, 1, 2),
      ),
      ServiceOrder(
        id: 'new',
        orderNumber: 'SO-20261120-001',
        customerPhone: '9000011111',
        brand: 'Vivo',
        model: 'Y21',
        status: 'In Progress',
      ),
    ];

    test("a customer's jobs by id or number", () async {
      final store = InMemoryServiceStore(seed: orders);
      addTearDown(store.dispose);
      expect((await store.fetchOlder(customerId: 'c-1')).map((o) => o.id), [
        'old',
      ]);
      expect((await store.fetchOlder(phone: '98765 43210')).map((o) => o.id), [
        'old',
      ]);
      expect(
        (await store.fetchOlder(number: 'SO-20261120-001')).map((o) => o.id),
        ['new'],
      );
    });

    test('jobs handed back in a range', () async {
      final store = InMemoryServiceStore(seed: orders);
      addTearDown(store.dispose);
      final got = await store.fetchClosedBetween(
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 31),
      );
      expect(got.map((o) => o.id), ['old']);
    });

    test('one job by id', () async {
      final store = InMemoryServiceStore(seed: orders);
      addTearDown(store.dispose);
      expect((await store.fetchById('old'))?.id, 'old');
      expect(await store.fetchById('gone'), isNull);
    });
  });

  group('a record page for an older record', () {
    testWidgets('asks first, then says not found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FetchingRecord(
            fetch: () => Future<Object?>.delayed(
              const Duration(milliseconds: 50),
              () => null,
            ),
            notFound: const Text('No such job'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('No such job'), findsOneWidget);
    });

    testWidgets('a failed ask is not a crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FetchingRecord(
            fetch: () => Future<Object?>.error(Exception('offline')),
            notFound: const Text('No such job'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('No such job'), findsOneWidget);
    });
  });
}
