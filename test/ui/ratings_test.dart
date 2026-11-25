import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/rating_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/ui/screens/ratings/rating_button.dart';
import 'package:fm_shop/domain/ratings/rating.dart';
import 'package:fm_shop/domain/service/service_order.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/screens/ratings/rate_screen.dart';
import 'package:fm_shop/ui/screens/ratings/ratings_screen.dart';

ServiceOrder _order(String id, {String status = 'Completed'}) => ServiceOrder(
  id: id,
  orderNumber: 'SO-$id',
  customerName: 'Ravi Kumar',
  customerPhone: '9876543210',
  brand: 'Apple',
  model: 'iPhone 11',
  status: status,
);

Widget _app(Widget child, InMemoryRatingStore store) => MultiProvider(
  providers: [
    ChangeNotifierProvider<RatingRepository>.value(value: store),
    Provider<PublicRatings>.value(value: store.public),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('the shop asks', () {
    test('one link per job: asking twice gives the same token', () async {
      final store = InMemoryRatingStore(shopId: 's1');
      final first = await store.requestFor(_order('o1'), shopName: 'FM');
      final second = await store.requestFor(_order('o1'), shopName: 'FM');
      expect(second.token, first.token);
      expect(store.ratings, hasLength(1));
    });

    test('a job still on the bench cannot be asked', () async {
      final store = InMemoryRatingStore(shopId: 's1');
      expect(
        () => store.requestFor(
          _order('o1', status: 'In Progress'),
          shopName: 'FM',
        ),
        throwsA(isA<RatingNotAllowed>()),
      );
    });

    test("a shop sees only its own ratings", () async {
      final other = ratingRequestFor(
        order: _order('x'),
        shopId: 'other-shop',
        shopName: 'Other',
        now: DateTime(2026),
      );
      final store = InMemoryRatingStore(shopId: 's1', seed: [other]);
      expect(store.ratings, isEmpty);
    });
  });

  group('the customer answers', () {
    testWidgets('picks stars, writes a comment, and is thanked', (
      tester,
    ) async {
      final store = InMemoryRatingStore(shopId: 's1');
      final r = await store.requestFor(
        _order('o1'),
        shopName: 'French Mobiles',
      );
      await tester.pumpWidget(_app(RateScreen(token: r.token), store));
      await tester.pumpAndSettle();

      expect(find.text('French Mobiles'), findsOneWidget);
      expect(find.text('How did we do?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('star-4')));
      await tester.enterText(find.byKey(const Key('rate-comment')), 'Quick');
      await tester.tap(find.byKey(const Key('rate-send')));
      await tester.pumpAndSettle();

      expect(
        find.text('Thank you. Your rating has been sent.'),
        findsOneWidget,
      );
      final saved = await store.fetch(r.token);
      expect(saved!.stars, 4);
      expect(saved.comment, 'Quick');
    });

    testWidgets('sending with no stars says to pick them', (tester) async {
      final store = InMemoryRatingStore(shopId: 's1');
      final r = await store.requestFor(_order('o1'), shopName: 'FM');
      await tester.pumpWidget(_app(RateScreen(token: r.token), store));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rate-send')));
      await tester.pumpAndSettle();
      expect(find.text('Tap the stars to choose a rating.'), findsOneWidget);
      expect((await store.fetch(r.token))!.answered, isFalse);
    });

    testWidgets('an answered job shows that, not the form', (tester) async {
      final store = InMemoryRatingStore(shopId: 's1');
      final r = await store.requestFor(_order('o1'), shopName: 'FM');
      await store.answer(r.token, 5, '');
      await tester.pumpWidget(_app(RateScreen(token: r.token), store));
      await tester.pumpAndSettle();
      expect(
        find.text('This job has already been rated. Thank you.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('rate-send')), findsNothing);
    });

    testWidgets('a link that leads nowhere says so', (tester) async {
      final store = InMemoryRatingStore(shopId: 's1');
      await tester.pumpWidget(_app(const RateScreen(token: 'nope'), store));
      await tester.pumpAndSettle();
      expect(find.textContaining('not valid'), findsOneWidget);
    });
  });

  group('the admin reads', () {
    testWidgets('nothing yet says how to get one', (tester) async {
      final store = InMemoryRatingStore(shopId: 's1');
      await tester.pumpWidget(_app(const RatingsScreen(), store));
      expect(find.textContaining('No ratings yet'), findsOneWidget);
    });

    testWidgets('average over answers only, with how many answered', (
      tester,
    ) async {
      final store = InMemoryRatingStore(shopId: 's1');
      final a = await store.requestFor(_order('o1'), shopName: 'FM');
      final b = await store.requestFor(_order('o2'), shopName: 'FM');
      await store.requestFor(_order('o3'), shopName: 'FM');
      await store.answer(a.token, 5, 'Great');
      await store.answer(b.token, 4, '');
      await tester.pumpWidget(_app(const RatingsScreen(), store));
      expect(find.text('4.5'), findsOneWidget);
      // A star icon, not a star character typed into the text.
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.textContaining('★'), findsNothing);
      expect(find.text('2 of 3 answered'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);
      expect(find.text('Waiting for the customer'), findsOneWidget);
    });
  });

  group('the button on a service order', () {
    Future<void> pump(
      WidgetTester tester,
      InMemoryRatingStore store,
      InMemorySettingsStore settings,
      ServiceOrder order,
    ) async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: auth),
            ChangeNotifierProvider<SettingsRepository>.value(value: settings),
          ],
          child: _app(RatingButton(order: order), store),
        ),
      );
    }

    testWidgets('is not offered while the phone is on the bench', (
      tester,
    ) async {
      await pump(
        tester,
        InMemoryRatingStore(),
        InMemorySettingsStore(),
        _order('o1', status: 'In Progress'),
      );
      expect(find.byKey(const Key('ask-rating')), findsNothing);
    });

    testWidgets('with no public web address, says what to set and asks '
        'nothing', (tester) async {
      final store = InMemoryRatingStore();
      await pump(tester, store, InMemorySettingsStore(), _order('o1'));
      await tester.tap(find.byKey(const Key('ask-rating')));
      await tester.pumpAndSettle();
      expect(find.textContaining('public web address'), findsOneWidget);
      expect(store.ratings, isEmpty);
    });

    testWidgets('an answered job shows the stars instead', (tester) async {
      final store = InMemoryRatingStore();
      final r = await store.requestFor(_order('o1'), shopName: 'FM');
      await store.answer(r.token, 4, '');
      await pump(tester, store, InMemorySettingsStore(), _order('o1'));
      expect(find.text('Customer rated 4 of 5'), findsOneWidget);
    });
  });
}
