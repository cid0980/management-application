import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/enquiries/enquiry_list.dart';
import 'package:fm_shop/domain/enquiries/enquiry_state.dart';

final _now = DateTime(2026, 3, 4, 12);

Enquiry _e(
  String id, {
  String status = 'Open',
  DateTime? followUp,
  DateTime? closedAt,
  String question = 'Wants an A54 in second hand',
  String outcomeRef = '',
  num budget = 0,
  num quoted = 0,
  String phone = '9876543210',
  String? customerId,
  String handledBy = 'Suresh',
}) =>
    Enquiry(
      id: id,
      customerId: customerId,
      customerPhone: phone,
      question: question,
      status: status,
      outcomeRef: outcomeRef,
      budget: budget,
      quotedPrice: quoted,
      handledBy: handledBy,
      followUpAt: followUp,
      closedAt: closedAt,
      askedAt: DateTime(2026, 3, 1),
    );

void main() {
  group('derived state, not the raw status', () {
    test('a follow-up date in the past is overdue', () {
      expect(_e('a', followUp: DateTime(2026, 3, 2)).lifecycleAt(_now),
          EnquiryLifecycle.overdue);
    });

    test('closed beats overdue — the same rule as a service order', () {
      final won = _e('a',
          status: 'Won',
          outcomeRef: 'INV-1',
          followUp: DateTime(2026, 1, 1));
      expect(won.lifecycleAt(_now), EnquiryLifecycle.closed);
      expect(won.isOverdueAt(_now), isFalse);
    });

    test('Won, Lost and Closed are all dealt with', () {
      for (final status in ['Won', 'Lost', 'Closed']) {
        expect(isEnquiryClosed(status), isTrue, reason: status);
      }
      for (final status in ['Open', 'Quoted', 'Waiting For Stock']) {
        expect(isEnquiryClosed(status), isFalse, reason: status);
      }
    });

    test('due today is the follow-up day, not the instant', () {
      expect(_e('a', followUp: DateTime(2026, 3, 4, 1)).isDueTodayAt(_now),
          isTrue);
      expect(_e('a', followUp: DateTime(2026, 3, 5)).isDueTodayAt(_now),
          isFalse);
    });

    test('no follow-up date is open, never overdue', () {
      final enquiry = _e('a');
      expect(enquiry.lifecycleAt(_now), EnquiryLifecycle.open);
      expect(enquiry.isOverdueAt(_now), isFalse);
    });

    test('a status this build has never seen is still open', () {
      final unknown = _e('a', status: 'Call Back Later');
      expect(unknown.closed, isFalse);
      expect(unknown.status, 'Call Back Later');
      // And it is offered back, rather than vanishing from the chips.
      expect(enquiryStatusOptions('Call Back Later').first, 'Call Back Later');
      expect(enquiryStatusOptions('Open'), kEnquiryStatuses);
    });
  });

  group('Won needs something to point at', () {
    test('because a conversion with nothing behind it means nothing', () {
      expect(wonBlockFor(''), WonBlock.noOutcome);
      expect(wonBlockFor('   '), WonBlock.noOutcome);
      expect(wonBlockFor(null), WonBlock.noOutcome);
    });

    test('an invoice number, or a note, both count', () {
      // Refusing a note that says "sold over the counter, no bill" would just
      // stop the enquiry being closed at all.
      expect(wonBlockFor('INV-20260304-007'), isNull);
      expect(wonBlockFor('sold over the counter, no bill'), isNull);
    });

    test('and the validator refuses a saved Won with no outcome', () {
      final result = validateEnquiry(_e('a', status: 'Won'));
      expect(result.errors, contains('outcomeRef'));
      expect(
        validateEnquiry(_e('a', status: 'Won', outcomeRef: 'INV-1')).isValid,
        isTrue,
      );
    });
  });

  group('the bar for recording one is low on purpose', () {
    test('a number and one line are enough', () {
      expect(validateEnquiry(_e('a')).isValid, isTrue);
    });

    test('but a number is required — the point is ringing them back', () {
      final result = validateEnquiry(_e('a', phone: ''));
      expect(result.errors['customerPhone'], contains('ringing them back'));
    });

    test('a customer record counts instead of a typed number', () {
      final result = validateEnquiry(_e('a', phone: '', customerId: 'c-1'));
      expect(result.isValid, isTrue);
    });

    test('a number that cannot be rung is refused', () {
      expect(validateEnquiry(_e('a', phone: '12345')).errors,
          contains('customerPhone'));
    });

    test('something has to say what was asked', () {
      final blank = Enquiry(id: 'a', customerPhone: '9876543210');
      expect(validateEnquiry(blank).errors, contains('question'));
      // The category alone is enough.
      final about = Enquiry(
        id: 'a',
        customerPhone: '9876543210',
        about: 'Price only',
      );
      expect(validateEnquiry(about).isValid, isTrue);
    });
  });

  group('warnings the shop may overrule', () {
    test('no follow-up date will not come up again on its own', () {
      final result = validateEnquiry(_e('a'));
      expect(result.isValid, isTrue);
      expect(result.warnings['followUpAt'], contains('on its own'));
    });

    test('a closed enquiry does not warn about a follow-up', () {
      expect(
        validateEnquiry(_e('a', status: 'Closed')).warnings,
        isNot(contains('followUpAt')),
      );
    });

    test('quoted over their budget is flagged', () {
      final result = validateEnquiry(_e('a', budget: 17000, quoted: 19000));
      expect(result.warnings['quotedPrice'], contains('17000'));
    });

    test('a zero budget is "they did not say", not a zero budget', () {
      final enquiry = _e('a', quoted: 19000);
      expect(enquiry.hasBudget, isFalse);
      expect(enquiry.quotedOverBudget, isFalse);
    });

    test('nobody recorded as having taken it is worth saying', () {
      expect(validateEnquiry(_e('a', handledBy: '')).warnings,
          contains('handledBy'));
    });
  });

  group('the headline', () {
    test('is the question, because that is what the list is scanned for', () {
      expect(_e('a').headline, 'Wants an A54 in second hand');
    });

    test('falls back to the device, then the category, then a last resort', () {
      expect(
        Enquiry(id: 'a', brand: 'Samsung', model: 'A54').headline,
        'Asked about Samsung A54',
      );
      expect(Enquiry(id: 'a', about: 'Price only').headline, 'Price only');
      expect(const Enquiry(id: 'a').headline, 'Walk-in enquiry');
    });
  });

  group('every read normalizes', () {
    test('the older key for the question is still read', () {
      expect(
        Enquiry.fromMap('a', {'enquiry': 'Asked about a trade-in'}).question,
        'Asked about a trade-in',
      );
    });

    test('a number written with +91 reads as ten digits', () {
      expect(
        Enquiry.fromMap('a', {'customerPhone': '+91 90000 11111'})
            .customerPhone,
        '9000011111',
      );
    });

    test('an amount written as a string reads as a number', () {
      expect(Enquiry.fromMap('a', {'budget': '8,000'}).budget, 8000);
    });

    test('a missing status reads as Open', () {
      expect(Enquiry.fromMap('a', const {}).status, 'Open');
    });

    test('a record written here reads back the same', () {
      final enquiry = _e('a',
          status: 'Won',
          outcomeRef: 'INV-1',
          followUp: DateTime.utc(2026, 3, 6),
          closedAt: DateTime.utc(2026, 3, 5));
      final back = Enquiry.fromMap('a', enquiry.toMap());
      expect(back.status, 'Won');
      expect(back.outcomeRef, 'INV-1');
      expect(back.followUpAt, DateTime.utc(2026, 3, 6));
    });
  });

  group('the list is a call list', () {
    final all = [
      _e('overdue', followUp: DateTime(2026, 3, 2)),
      _e('today', followUp: DateTime(2026, 3, 4, 16)),
      _e('later', followUp: DateTime(2026, 3, 10)),
      _e('unscheduled'),
      _e('won',
          status: 'Won',
          outcomeRef: 'INV-1',
          followUp: DateTime(2026, 1, 1),
          closedAt: DateTime(2026, 1, 2)),
    ];

    test('follow-up soonest first, unscheduled last', () {
      // Not urgent, just not scheduled — letting it sit at the top would
      // imply otherwise.
      expect(
        enquiryRows(all, tab: EnquiryTab.open, now: _now).map((e) => e.id),
        ['overdue', 'today', 'later', 'unscheduled'],
      );
    });

    test('the won tab reads newest first', () {
      expect(
        enquiryRows(all, tab: EnquiryTab.won, now: _now).map((e) => e.id),
        ['won'],
      );
    });

    test('a won enquiry from January is not overdue', () {
      expect(
        enquiryRows(all, tab: EnquiryTab.overdue, now: _now).map((e) => e.id),
        ['overdue'],
      );
    });

    test('counts are against the same query the list is showing', () {
      final counts =
          enquiryTabCounts(all, query: 'A54', now: _now);
      expect(counts[EnquiryTab.all], 5);
      final narrow = enquiryTabCounts(all, query: 'nothing matches', now: _now);
      expect(narrow[EnquiryTab.all], 0);
    });

    test('the call list is overdue first, then today', () {
      expect(
        enquiryCallList(all, now: _now).map((e) => e.id),
        ['overdue', 'today'],
      );
    });

    test('the dashboard tile counts the open ones', () {
      expect(openEnquiryCount(all), 4);
    });
  });

  group('conversion is counted over what has been closed', () {
    test('so writing a new enquiry down does not move the number', () {
      // A number that drops because somebody did their job is a number that
      // discourages doing it.
      final closed = [
        _e('won1', status: 'Won', outcomeRef: 'INV-1'),
        _e('lost1', status: 'Lost'),
      ];
      final withOpen = [...closed, _e('open1')];
      expect(enquiryConversion(closed).rate, 0.5);
      expect(enquiryConversion(withOpen).rate, 0.5);
      expect(enquiryConversion(withOpen).open, 1);
    });

    test('nothing closed yet is null, not zero', () {
      // Zero would read as "the shop wins nothing".
      expect(enquiryConversion([_e('a')]).rate, isNull);
      expect(enquiryConversion(const []).rate, isNull);
    });

    test('won, lost and closed are counted apart', () {
      final conversion = enquiryConversion([
        _e('a', status: 'Won', outcomeRef: 'x'),
        _e('b', status: 'Lost'),
        _e('c', status: 'Closed'),
        _e('d'),
      ]);
      expect(conversion.won, 1);
      expect(conversion.lost, 1);
      expect(conversion.closed, 3);
      expect(conversion.open, 1);
    });
  });

  test('every lifecycle and tab has a label', () {
    for (final state in EnquiryLifecycle.values) {
      expect(kEnquiryStateLabels[state], isNotNull);
    }
    for (final tab in EnquiryTab.values) {
      expect(kEnquiryTabLabels[tab], isNotNull);
    }
  });
}
