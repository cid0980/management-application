import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/enquiries/enquiry_state.dart';

Enquiry _e(String id, {String status = 'Open', String outcomeRef = ''}) =>
    Enquiry(
      id: id,
      customerPhone: '9876543210',
      question: 'Wants an A54',
      status: status,
      outcomeRef: outcomeRef,
    );

void main() {
  group('an enquiry has no workflow to protect', () {
    test('any status may follow any other', () async {
      final store = InMemoryEnquiryStore(seed: [_e('a')]);
      addTearDown(store.dispose);
      expect((await store.setStatus('a', 'Lost')).ok, isTrue);
      // Reopening a Lost enquiry because they came back is an ordinary
      // Tuesday.
      expect((await store.setStatus('a', 'Open')).ok, isTrue);
      expect(store.byId('a')!.closed, isFalse);
    });

    test('closing stamps the date, and keeps the first one', () async {
      final store = InMemoryEnquiryStore(seed: [_e('a')]);
      addTearDown(store.dispose);
      await store.setStatus('a', 'Closed');
      final first = store.byId('a')!.closedAt;
      expect(first, isNotNull);
      await store.setStatus('a', 'Lost');
      expect(store.byId('a')!.closedAt, first);
    });

    test('reopening clears the closed date', () async {
      final store = InMemoryEnquiryStore(seed: [_e('a', status: 'Lost')]);
      addTearDown(store.dispose);
      await store.setStatus('a', 'Open');
      expect(store.byId('a')!.closedAt, isNull);
    });
  });

  group('Won needs something to point at', () {
    test('and is refused without it, leaving the status alone', () async {
      final store = InMemoryEnquiryStore(seed: [_e('a')]);
      addTearDown(store.dispose);
      final result = await store.setStatus('a', 'Won');
      expect(result.ok, isFalse);
      expect(result.block, WonBlock.noOutcome);
      expect(result.message, contains('cannot be counted'));
      expect(store.byId('a')!.status, 'Open');
    });

    test('an outcome given at the time is accepted and kept', () async {
      final store = InMemoryEnquiryStore(seed: [_e('a')]);
      addTearDown(store.dispose);
      final result =
          await store.setStatus('a', 'Won', outcomeRef: 'INV-20260304-007');
      expect(result.ok, isTrue);
      expect(store.byId('a')!.outcomeRef, 'INV-20260304-007');
      expect(store.byId('a')!.won, isTrue);
    });

    test('an outcome already on the record is enough', () async {
      final store =
          InMemoryEnquiryStore(seed: [_e('a', outcomeRef: 'INV-1')]);
      addTearDown(store.dispose);
      expect((await store.setStatus('a', 'Won')).ok, isTrue);
    });
  });

  group('the follow-up date', () {
    test('can be set and cleared', () async {
      // Clearing it is a real thing to want, and copyWith cannot set a date
      // back to null — which is why the repository rebuilds the record.
      final store = InMemoryEnquiryStore(seed: [_e('a')]);
      addTearDown(store.dispose);
      await store.setFollowUp('a', DateTime(2026, 3, 6));
      expect(store.byId('a')!.followUpAt, DateTime(2026, 3, 6));
      await store.setFollowUp('a', null);
      expect(store.byId('a')!.followUpAt, isNull);
    });

    test('a missing enquiry is said so', () {
      final store = InMemoryEnquiryStore(seed: []);
      addTearDown(store.dispose);
      expect(() => store.setFollowUp('nope', null),
          throwsA(isA<NoSuchEnquiry>()));
      expect(() => store.setStatus('nope', 'Open'),
          throwsA(isA<NoSuchEnquiry>()));
    });
  });

  test('saving an enquiry normalizes the number and stamps the dates',
      () async {
    final store = InMemoryEnquiryStore(seed: []);
    addTearDown(store.dispose);
    final saved = await store.save(Enquiry(
      id: 'a',
      customerPhone: '+91 98765 43210',
      question: 'Wants an A54',
    ));
    expect(saved.customerPhone, '9876543210');
    expect(saved.askedAt, isNotNull);
    expect(saved.updatedAt, isNotNull);
    expect(saved.closedAt, isNull);
  });

  test('the store notifies, so its list redraws', () async {
    final enquiries = InMemoryEnquiryStore(seed: [_e('a')]);
    addTearDown(enquiries.dispose);

    var notices = 0;
    enquiries.addListener(() => notices++);

    await enquiries.setStatus('a', 'Lost');
    // Won with nothing to point at is refused, and a refused write changed
    // nothing, so it notifies nobody.
    await enquiries.setStatus('a', 'Won');

    expect(notices, 1);
  });

  test('the enquiry seed holds the states the list has to get right', () {
    final store = InMemoryEnquiryStore();
    addTearDown(store.dispose);
    final now = DateTime.now();
    expect(store.enquiries.any((e) => e.isOverdueAt(now)), isTrue);
    expect(store.enquiries.any((e) => e.isDueTodayAt(now)), isTrue);
    // Won last month, with something to point at, and not an alarm.
    expect(store.byId('enq-3')!.won, isTrue);
    expect(store.byId('enq-3')!.isOverdueAt(now), isFalse);
    // No follow-up: not urgent, just not scheduled.
    expect(store.byId('enq-4')!.followUpAt, isNull);
    // A status this build has never seen is kept.
    expect(store.byId('enq-5')!.status, 'Call Back Later');
    expect(store.byId('enq-5')!.budget, 8000);
  });
}
