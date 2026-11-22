import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/tour/app_tour.dart';
import 'package:go_router/go_router.dart';

/// A bare app with the tour's five pages, each carrying the keys the tour
/// points at, and a button on Home that starts it.
Future<GoRouter> _pumpApp(WidgetTester tester) async {
  Widget page(String name, List<String> keys) => Scaffold(
    body: Builder(
      builder: (context) => ListView(
        children: [
          Text('page $name'),
          for (final k in keys)
            SizedBox(key: Key(k), height: 60, child: Text(k)),
          TextButton(
            onPressed: () => runAppTour(context),
            child: Text('start on $name'),
          ),
        ],
      ),
    ),
  );
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => page('home', [
          'home-search',
          'home-today',
          'home-actions',
          'home-queue',
          'nav-bar',
        ]),
      ),
      GoRoute(
        path: '/inventory/second-hand',
        builder: (_, _) =>
            page('mobiles', ['mobiles-summary', 'mobiles-tabs', 'mobiles-buy']),
      ),
      GoRoute(
        path: '/service',
        builder: (_, _) => page('repairs', ['repairs-tabs', 'repairs-new']),
      ),
      GoRoute(
        path: '/sales',
        builder: (_, _) => page('sales', ['sales-tabs', 'sales-new']),
      ),
      // No Settings row here, as for a staff member: that step is still
      // shown, as a card in the middle.
      GoRoute(path: '/more', builder: (_, _) => page('more', const [])),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the tour walks forward and back, and Skip ends it', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('start on home'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tour-card')), findsOneWidget);
    expect(find.text('Welcome to your shop app'), findsOneWidget);
    expect(find.text('1 of 15'), findsOneWidget);
    // No Back on the first card.
    expect(find.byKey(const Key('tour-back')), findsNothing);

    await _tap(tester, 'tour-next');
    expect(find.text('Find anything'), findsOneWidget);
    expect(find.text('2 of 15'), findsOneWidget);

    await _tap(tester, 'tour-back');
    expect(find.text('Welcome to your shop app'), findsOneWidget);

    await _tap(tester, 'tour-skip');
    expect(find.byKey(const Key('tour-card')), findsNothing);
    expect(find.text('page home'), findsOneWidget);
  });

  testWidgets('the whole tour visits every page and ends on Home', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    await tester.tap(find.text('start on home'));
    await tester.pumpAndSettle();

    final seen = <String>{};
    for (var i = 0; i < 14; i++) {
      seen.add(router.routerDelegate.currentConfiguration.uri.path);
      await _tap(tester, 'tour-next');
    }
    seen.add(router.routerDelegate.currentConfiguration.uri.path);
    expect(seen, {
      '/dashboard',
      '/inventory/second-hand',
      '/service',
      '/sales',
      '/more',
    });
    // The last card says Done and has no Skip.
    expect(find.text("That's the tour"), findsOneWidget);
    expect(find.byKey(const Key('tour-skip')), findsNothing);
    await _tap(tester, 'tour-next');

    expect(find.byKey(const Key('tour-card')), findsNothing);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
  });

  testWidgets('every step has words in Tamil and Hindi too', (tester) async {
    for (final code in ['en', 'ta', 'hi']) {
      final l = lookupAppLocalizations(Locale(code));
      final stops = appTour(l);
      final steps = [for (final s in stops) ...s.steps];
      expect(steps, hasLength(15));
      for (final s in steps) {
        expect(s.title.trim(), isNotEmpty);
        expect(s.body.trim(), isNotEmpty);
      }
    }
  });
}
