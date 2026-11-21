import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/ui/screens/enquiries/enquiry_detail_screen.dart';
import 'package:fm_shop/ui/screens/enquiries/enquiry_list_screen.dart';

DateTime get _today => DateTime.now();

Enquiry _e(
  String id, {
  String status = 'Open',
  String question = 'Wants an A54 in second hand',
  String outcomeRef = '',
  DateTime? followUp,
  DateTime? closedAt,
  num budget = 0,
  num quoted = 0,
  String phone = '9876543210',
  String name = 'Ramesh K',
}) =>
    Enquiry(
      id: id,
      customerName: name,
      customerPhone: phone,
      question: question,
      status: status,
      outcomeRef: outcomeRef,
      budget: budget,
      quotedPrice: quoted,
      handledBy: 'Suresh',
      askedAt: _today.subtract(const Duration(days: 3)),
      followUpAt: followUp,
      closedAt: closedAt,
    );

class Harness {
  Harness(this.enquiries, this.settings);
  final InMemoryEnquiryStore enquiries;
  final InMemorySettingsStore settings;
}

Future<Harness> pumpEnquiries(
  WidgetTester tester,
  Widget screen, {
  List<Enquiry>? seed,
}) async {
  tester.view.physicalSize = const Size(540, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final enquiries = InMemoryEnquiryStore(seed: seed ?? []);
  final customers = InMemoryCustomerStore();
  final settings = InMemorySettingsStore();
  addTearDown(enquiries.dispose);
  addTearDown(customers.dispose);
  addTearDown(settings.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EnquiryRepository>.value(value: enquiries),
        ChangeNotifierProvider<CustomerRepository>.value(value: customers),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        Provider<DraftStore>.value(value: InMemoryDraftStore()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return Harness(enquiries, settings);
}

Future<void> tapTab(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('the list is a call list', () {
    testWidgets('the question leads, because that is what is scanned for',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [_e('a')]);
      expect(find.text('Wants an A54 in second hand'), findsOneWidget);
    });

    testWidgets('an overdue follow-up is marked, and counted', (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [
        _e('late', followUp: _today.subtract(const Duration(days: 2))),
      ]);
      expect(find.text('Overdue 1'), findsOneWidget);
      expect(find.text('Follow-up overdue'), findsOneWidget);
    });

    testWidgets('a won enquiry from last month is not overdue', (tester) async {
      // Closed beats overdue, the same rule as a service order.
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [
        _e('won',
            status: 'Won',
            outcomeRef: 'INV-1',
            followUp: _today.subtract(const Duration(days: 40)),
            closedAt: _today.subtract(const Duration(days: 36))),
      ]);
      expect(find.text('Overdue 0'), findsOneWidget);
      expect(find.text('Won 1'), findsOneWidget);
    });

    testWidgets('one with no follow-up says so rather than looking urgent',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(),
          seed: [_e('a')]);
      expect(find.text('No follow-up set'), findsOneWidget);
      expect(find.text('Open'), findsWidgets);
    });

    testWidgets('a status this build has never seen shows as itself',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [
        _e('a', status: 'Call Back Later'),
      ]);
      expect(find.text('Call Back Later'), findsOneWidget);
      expect(find.text('Open 1'), findsOneWidget);
    });

    testWidgets('nothing closed yet reads as that, not as a zero rate',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(),
          seed: [_e('a')]);
      expect(find.textContaining('nothing closed yet'), findsOneWidget);
    });

    testWidgets('and a rate once something has closed', (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [
        _e('won', status: 'Won', outcomeRef: 'INV-1'),
        _e('lost', status: 'Lost'),
      ]);
      expect(find.textContaining('1 of 2 closed became business (50%)'),
          findsOneWidget);
    });

    testWidgets('search covers the question and the number', (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen(), seed: [
        _e('a', question: 'Wants an A54'),
        _e('b', question: 'Asked about a charger', phone: '9123456780',
            name: 'Priya S'),
      ]);
      await tester.enterText(
          find.byKey(const Key('enquiry-search')), 'charger');
      await tester.pumpAndSettle();
      expect(find.text('Asked about a charger'), findsOneWidget);
      expect(find.text('Wants an A54'), findsNothing);
    });
  });

  group('recording one', () {
    testWidgets('a number and one line are enough', (tester) async {
      final h = await pumpEnquiries(tester, const EnquiryListScreen());
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('enquiry-customerPhone')), '9000000001');
      await tester.enterText(find.byKey(const Key('enquiry-question')),
          'Asked whether we stock 65W chargers');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(h.enquiries.enquiries, hasLength(1));
      expect(h.enquiries.enquiries.single.question,
          'Asked whether we stock 65W chargers');
    });

    testWidgets('a number is required — the point is ringing them back',
        (tester) async {
      final h = await pumpEnquiries(tester, const EnquiryListScreen());
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('enquiry-question')), 'Asked something');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(h.enquiries.enquiries, isEmpty);
      expect(find.textContaining('ringing them back'), findsWidgets);
    });

    testWidgets('the follow-up defaults to a date and can be cleared',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryListScreen());
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      // Offered with a default rather than left empty and hoped about.
      expect(find.text('Not set — this will not come up again on its own'),
          findsNothing);

      final clear = find.byKey(const Key('enquiry-followup-clear'));
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.text('Not set — this will not come up again on its own'),
          findsOneWidget);
    });

    testWidgets('a brand typed in is filed to the shop lists', (tester) async {
      final h = await pumpEnquiries(tester, const EnquiryListScreen());
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('enquiry-customerPhone')), '9000000001');
      await tester.enterText(
          find.byKey(const Key('enquiry-question')), 'Wants a Honor X9b');
      await tester.enterText(
          find.byKey(const Key('enquiry-brand')), 'Honor');
      await tester.enterText(
          find.byKey(const Key('enquiry-model')), 'X9b');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(h.settings.settings.modelsFor('Honor').values, ['X9b']);
    });
  });

  group('Won asks what it became', () {
    testWidgets('and refuses to move without an answer', (tester) async {
      final h = await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a')],
      );
      final chip = find.byKey(const Key('enquiry-status-Won'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.text('What did this become?'), findsOneWidget);
      // Cancelling leaves the status alone, which is the whole point.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(h.enquiries.byId('a')!.status, 'Open');
    });

    testWidgets('an invoice number closes it as won', (tester) async {
      final h = await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a')],
      );
      final chip = find.byKey(const Key('enquiry-status-Won'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('outcome-ref')), 'INV-20260304-007');
      await tester.tap(find.widgetWithText(FilledButton, 'Mark won'));
      await tester.pumpAndSettle();

      expect(h.enquiries.byId('a')!.won, isTrue);
      expect(h.enquiries.byId('a')!.outcomeRef, 'INV-20260304-007');
      expect(h.enquiries.byId('a')!.closedAt, isNotNull);
    });

    testWidgets('an empty answer is still refused', (tester) async {
      final h = await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a')],
      );
      final chip = find.byKey(const Key('enquiry-status-Won'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Mark won'));
      await tester.pumpAndSettle();

      expect(h.enquiries.byId('a')!.status, 'Open');
      expect(find.textContaining('cannot be counted'), findsWidgets);
    });

    testWidgets('and the page says beforehand what Won will ask for',
        (tester) async {
      // So nobody avoids Won because they do not know what it will want.
      await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a')],
      );
      expect(
        find.textContaining('asks which sale or repair it became'),
        findsOneWidget,
      );
    });
  });

  group('the detail page', () {
    testWidgets('any other status moves freely, with no workflow to protect',
        (tester) async {
      final h = await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a', status: 'Lost')],
      );
      final chip = find.byKey(const Key('enquiry-status-Open'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      // Reopening a Lost enquiry because they came back is an ordinary
      // Tuesday.
      expect(h.enquiries.byId('a')!.status, 'Open');
      expect(h.enquiries.byId('a')!.closedAt, isNull);
    });

    testWidgets('a zero budget reads as "they did not say"', (tester) async {
      await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a', quoted: 2600)],
      );
      expect(find.text('they did not say'), findsOneWidget);
    });

    testWidgets('quoted over their budget is called out', (tester) async {
      await pumpEnquiries(
        tester,
        const EnquiryDetailScreen(id: 'a'),
        seed: [_e('a', budget: 17000, quoted: 19000)],
      );
      // Twice: the dedicated line under Money, and the warnings card.
      expect(find.textContaining('against a ₹17000 budget'), findsWidgets);
    });

    testWidgets('a missing enquiry is said so, not shown blank',
        (tester) async {
      await pumpEnquiries(tester, const EnquiryDetailScreen(id: 'nope'));
      expect(find.text('No enquiry nope'), findsOneWidget);
    });
  });
}
