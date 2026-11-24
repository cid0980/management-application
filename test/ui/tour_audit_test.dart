import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/app/router.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/demo_stores.dart';
import 'package:fm_shop/data/enquiry_repository.dart';
import 'package:fm_shop/data/expense_repository.dart';
import 'package:fm_shop/data/label_repository.dart';
import 'package:fm_shop/data/print_server.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/rating_repository.dart';
import 'package:fm_shop/data/recent_records.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/data/task_repository.dart';
import 'package:fm_shop/domain/common/form_draft.dart';
import 'package:fm_shop/domain/devices/tac_registry.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/theme/app_theme.dart';
import 'package:fm_shop/ui/tour/app_tour.dart';

/// THE TOUR AUDIT
///
/// Runs every tour chapter on the real screens, with the same practice data
/// the phone uses, and fails on any step that points at something it could
/// not find — on the phone that step is a card in the middle with no circle
/// around anything.
void main() {
  testWidgets('every page in the app has a tour', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // Every page inside the app (router.dart), and a record page of each kind.
    const pages = [
      '/dashboard',
      '/search',
      '/customers',
      '/customers/c-1',
      '/inventory/second-hand',
      '/inventory/second-hand/sh-1',
      '/products',
      '/products/p-1',
      '/service',
      '/service/so-1',
      '/sales',
      '/sales/s-1',
      '/enquiries',
      '/enquiries/e-1',
      '/due-payments',
      '/scanner',
      '/reports',
      '/expenses',
      '/tasks',
      '/admin/labels',
      '/admin/staff',
      '/admin/ratings',
      '/admin/tasks',
      '/admin/import-contacts',
      '/admin/settings',
      '/more',
    ];
    final missing = [
      for (final p in pages)
        if (tourForPage(l10n, p) == null) p,
    ];
    expect(missing, isEmpty, reason: 'A new page needs a tour step');
  });

  testWidgets('every tour step lights up what it talks about', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = AuthState();
    await auth.signInLocally(email: 'owner@shop.com', role: Role.admin);
    final own = DemoStores.create();
    final sandbox = TourSandbox();
    final router = buildRouter(auth);
    final recent = RecentRecords();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: sandbox,
        builder: (context, _) {
          final d = sandbox.demo ?? own;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthState>.value(value: auth),
              ChangeNotifierProvider<SettingsRepository>.value(
                value: d.settings,
              ),
              ChangeNotifierProvider<SecondHandRepository>.value(
                value: d.secondHand,
              ),
              ChangeNotifierProvider<CustomerRepository>.value(
                value: d.customers,
              ),
              ChangeNotifierProvider<ServiceRepository>.value(value: d.service),
              ChangeNotifierProvider<ProductRepository>.value(
                value: d.products,
              ),
              ChangeNotifierProvider<EnquiryRepository>.value(
                value: d.enquiries,
              ),
              ChangeNotifierProvider<ExpenseRepository>.value(
                value: d.expenses,
              ),
              ChangeNotifierProvider<TaskRepository>.value(value: d.tasks),
              ChangeNotifierProvider<SalesRepository>.value(value: d.sales),
              ChangeNotifierProvider<LabelRepository>.value(value: d.labels),
              ChangeNotifierProvider<RatingRepository>.value(value: d.ratings),
              Provider<PublicRatings>.value(value: d.ratings.public),
              Provider<TacRegistry>.value(value: SeedTacRegistry()),
              Provider<PrintServer>.value(value: d.printer),
              Provider<DraftStore>.value(value: d.drafts),
              ChangeNotifierProvider<TourSandbox>.value(value: sandbox),
              ChangeNotifierProvider<RecentRecords>.value(value: recent),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final misses = <String>[];
    var shown = 0;
    debugOnTourStep = (chapter, i, step, lit) {
      shown++;
      if (!lit) {
        misses.add(
          '${chapter.id} step ${i + 1}: "${step.title}" '
          '-> ${step.target} not found',
        );
      }
    };
    addTearDown(() => debugOnTourStep = null);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final chapters = [gettingAround(l10n), ...tourChapters(l10n)];
    for (final chapter in chapters) {
      final ctx = tester.element(find.byType(Scaffold).first);
      var done = false;
      runTour(ctx, chapter).then((_) => done = true);
      for (var guard = 0; guard < 400 && !done; guard++) {
        await tester.pump(const Duration(milliseconds: 300));
        final next = find.byKey(const Key('tour-next'));
        if (next.evaluate().isNotEmpty) {
          await tester.pump(const Duration(milliseconds: 300));
          if (next.evaluate().isNotEmpty) {
            await tester.tap(next.first, warnIfMissed: false);
          }
        }
      }
      expect(done, isTrue, reason: '${chapter.id} never finished');
      await tester.pumpAndSettle();
    }

    // ignore: avoid_print
    print(
      'TOUR AUDIT: $shown steps shown, ${misses.length} unlit\n'
      '${misses.join('\n')}',
    );
    expect(misses, isEmpty);
    own.dispose();
  });
}
